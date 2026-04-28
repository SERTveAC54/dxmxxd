#include <Arduino.h>
#include <WiFi.h>
#include <WebServer.h>
#include <ArtnetWifi.h>
#include <driver/uart.h>
#include <Update.h> 
#include "esp_mac.h" 
#include <DNSServer.h> 
#include <WebSocketsServer.h>
#include <WiFiUdp.h>
#include <ESPmDNS.h>
#include <esp_task_wdt.h>

// --- FREE RTOS MUTEX KİLİDİ ---
SemaphoreHandle_t dmxMutex;
uint16_t targetUniverse = 0; // Varsayılan olarak Universe 0 dinlensin
WiFiUDP heartbeatUDP;
unsigned long lastArtPollTime = 0;

// --- DONANIM PINLERI ---
#define DMX_TX_PIN 4      // RS485 Modülü TX pini
#define DMX_RX_PIN 6      // RS485 Modülü RX pini
#define LED_PIN 8         // Dahili Mavi LED
#define BATTERY_PIN 3     // Pil Voltajı Okuma Pini

#define LED_ON LOW        
#define LED_OFF HIGH

const float VOLTAGE_MULTIPLIER = 1.8032; // Multimetre 4.17V ölçümüne göre kalibre edildi

// --- AĞ AYARLARI ---
char ssidName[32]; 
const char* SSID_PASS = "dmx12345";

// --- NESNELER VE DEĞİŞKENLER ---
ArtnetWifi artnet;
WebServer server(80);
DNSServer dnsServer;
WebSocketsServer webSocket = WebSocketsServer(81);

const byte DNS_PORT = 53;
QueueHandle_t dmx_rx_queue;

uint8_t dmxData[513]; 
uint8_t grandMaster = 255; // GRANDMASTER DEĞİŞKENİ (0-255)

unsigned long lastDataTime = 0; 
unsigned long lastWsTx = 0;        
int previousClientCount = 0;

enum DeviceMode {
    MODE_STANDBY,   // Cihaz boşta, yayın yapmıyor
    MODE_CONSOLE,   // Web/ArtNet üzerinden DMX gönderiyor
    MODE_SNIFFER,   // Dışarıdan gelen DMX'i dinliyor
    MODE_OTA        // Güncelleme modunda
};

DeviceMode currentMode = MODE_CONSOLE;
bool ota_in_progress = false;

// --- WEB LOG SİSTEMİ ---
#define MAX_LOG_MESSAGES 50
String logMessages[MAX_LOG_MESSAGES];
int logIndex = 0;
SemaphoreHandle_t logMutex;

void webLog(String message) {
  if (xSemaphoreTake(logMutex, pdMS_TO_TICKS(10)) == pdTRUE) {
    logMessages[logIndex] = String(millis()/1000) + "s: " + message;
    logIndex = (logIndex + 1) % MAX_LOG_MESSAGES;
    xSemaphoreGive(logMutex);
  }
}

float readBattery() {
  static float filteredVoltage = 0;
  
  uint32_t rawSum = 0;
  for(int i=0; i<16; i++) {
      rawSum += analogRead(BATTERY_PIN);
  }
  float rawAvg = rawSum / 16.0;

  float pinVoltage = (rawAvg / 4095.0) * 3.3; 
  float currentVoltage = pinVoltage * VOLTAGE_MULTIPLIER;
  
  if (filteredVoltage == 0) filteredVoltage = currentVoltage; 
  filteredVoltage = (filteredVoltage * 0.9) + (currentVoltage * 0.1); 
  
  return filteredVoltage;
}

void generateSSID() {
  uint8_t mac[6];
  esp_read_mac(mac, ESP_MAC_WIFI_STA);
  snprintf(ssidName, sizeof(ssidName), "DMX_Tester_%02X%02X%02X", mac[3], mac[4], mac[5]);
}

// --- DMX GÖNDERME MOTORU ---
void sendDMXNative() {
  if (ota_in_progress) return; 
  
  uint8_t txBuffer[513];
  txBuffer[0] = 0; // Start Code sıfır olmak zorunda
  
  if (xSemaphoreTake(dmxMutex, pdMS_TO_TICKS(5)) == pdTRUE) {
      
      // TÜM İLETİŞİMLER İÇİN GRANDMASTER UYGULANMASI:
      // Ham DMX verisi (dmxData) üzerinde değişiklik yapmıyoruz (UI'da değişmesin diye).
      // Sadece çıkışa (txBuffer) yazarken GM üzerinden matematiksel oranlama yapıyoruz.
      for (int i = 1; i <= 512; i++) {
          txBuffer[i] = (uint8_t)((dmxData[i] * grandMaster) / 255);
      }
      
      xSemaphoreGive(dmxMutex);
      
      // 513 byte'ı UART üzerinden gönder
      uart_write_bytes_with_break(UART_NUM_1, (const char*)txBuffer, 513, 50);
  }
}

// --- FREERTOS GÖREV TANIMLARI ---
TaskHandle_t DmxTaskHandle = NULL;

void dmxCoreTask(void *pvParameters) {
  esp_task_wdt_add(NULL); 

  TickType_t xLastWakeTime = xTaskGetTickCount();
  const TickType_t xFrequency = pdMS_TO_TICKS(25); 

  for (;;) {
    esp_task_wdt_reset(); 

    if (ota_in_progress) {
      vTaskDelay(pdMS_TO_TICKS(100));
      continue;
    }

    if (currentMode == MODE_CONSOLE) {
      uart_flush_input(UART_NUM_1); 
      xQueueReset(dmx_rx_queue);
      
      sendDMXNative();
      vTaskDelayUntil(&xLastWakeTime, xFrequency); 
      
    } else if (currentMode == MODE_SNIFFER) {
      uart_event_t event;
      if (xQueueReceive(dmx_rx_queue, (void *)&event, pdMS_TO_TICKS(50))) {
        
        static int dmxIndex = 514; 
        switch (event.type) {
          case UART_BREAK:
          case UART_FRAME_ERR:
              if (xSemaphoreTake(dmxMutex, pdMS_TO_TICKS(5)) == pdTRUE) {
                  dmxIndex = 0; 
                  xSemaphoreGive(dmxMutex);
              }
              break;

          case UART_DATA: {
              int len = event.size;
              while (len > 0) {
                  uint8_t rx_buf[128];
                  int to_read = min((int)len, (int)sizeof(rx_buf));
                  int rxBytes = uart_read_bytes(UART_NUM_1, rx_buf, to_read, 0);
                  
                  if (rxBytes <= 0) break; 

                  if (xSemaphoreTake(dmxMutex, pdMS_TO_TICKS(5)) == pdTRUE) {
                      for (int i = 0; i < rxBytes; i++) {
                          if (dmxIndex <= 512) {
                              dmxData[dmxIndex++] = rx_buf[i];
                              lastDataTime = millis();
                          }
                      }
                      xSemaphoreGive(dmxMutex);
                  }
                  len -= rxBytes;
              }
              break;
          }
          case UART_FIFO_OVF:
          case UART_BUFFER_FULL:
          case UART_PARITY_ERR:
              uart_flush_input(UART_NUM_1);
              xQueueReset(dmx_rx_queue);
              if (xSemaphoreTake(dmxMutex, pdMS_TO_TICKS(5)) == pdTRUE) {
                  dmxIndex = 515;
                  xSemaphoreGive(dmxMutex);
              }
              break;
          default: break;
        }
      }
    } else {
        vTaskDelay(pdMS_TO_TICKS(100)); 
    }
  }
}

// --- WEBSOCKET OLAY YÖNETİCİSİ ---
void webSocketEvent(uint8_t num, WStype_t type, uint8_t * payload, size_t length) {
  switch(type) {
    case WStype_DISCONNECTED:
      break;
    case WStype_CONNECTED: {
      uint8_t wsBuffer[512];
      if (xSemaphoreTake(dmxMutex, pdMS_TO_TICKS(5)) == pdTRUE) {
          memcpy(wsBuffer, &dmxData[1], 512);
          xSemaphoreGive(dmxMutex);
      }
      webSocket.sendBIN(num, wsBuffer, 512);
      
      // İstemci bağlandığında ona mevcut Grandmaster değerini de bildir
      String gmMsg = "M," + String(grandMaster);
      webSocket.sendTXT(num, gmMsg);
      break;
    }
    case WStype_TEXT:
      if (currentMode == MODE_CONSOLE) {
          // KANAL VERİSİ GELDİĞİNDE
          if (payload[0] == 'S' && payload[1] == ',') {
            int ch = 0, val = 0;
            if (sscanf((const char*)payload, "S,%d,%d", &ch, &val) == 2) {
              if (ch >= 1 && ch <= 512) {
                if (xSemaphoreTake(dmxMutex, pdMS_TO_TICKS(5)) == pdTRUE) {
                    dmxData[ch] = val;
                    lastDataTime = millis();
                    xSemaphoreGive(dmxMutex);
                }
              }
            }
          }
          // GRANDMASTER VERİSİ GELDİĞİNDE
          else if (payload[0] == 'M' && payload[1] == ',') {
            int val = 0;
            if (sscanf((const char*)payload, "M,%d", &val) == 1) {
              if (val >= 0 && val <= 255) {
                grandMaster = val;
                // Diğer açık olan arayüzlere de yeni GM değerini yayınla (Senkronizasyon)
                String gmMsg = "M," + String(grandMaster);
                webSocket.broadcastTXT(gmMsg);
              }
            }
          }
      }
      break;
    case WStype_BIN:
      break;
  }
}

// --- ART-NET ISIM YAYINI (HEARTBEAT) ---
void broadcastArtPollReply() {
  uint8_t pollReply[239];
  memset(pollReply, 0, 239);
  
  memcpy(pollReply, "Art-Net\0", 8);
  pollReply[8] = 0x00; 
  pollReply[9] = 0x21; 
  
  IPAddress ip = WiFi.softAPIP();
  pollReply[10] = ip[0]; pollReply[11] = ip[1]; pollReply[12] = ip[2]; pollReply[13] = ip[3];
  pollReply[14] = 0x36; pollReply[15] = 0x19; 
  
  pollReply[16] = 0x00; pollReply[17] = 0x01; 
  
  strncpy((char*)&pollReply[26], "DMX Pro", 17);
  strncpy((char*)&pollReply[44], "DMX Tester Pro - Node", 63);
  
  pollReply[173] = 1;          
  pollReply[174] = 0b10000000; 
  pollReply[182] = 0b10000000; 

  heartbeatUDP.beginPacket(IPAddress(255, 255, 255, 255), 6454);
  heartbeatUDP.write(pollReply, 239);
  heartbeatUDP.endPacket();
}

// === GİZLİ OTA ARAYÜZÜ ===
const char* update_html = R"rawliteral(
<!DOCTYPE html>
<html lang="tr">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>DMX TESTER OTA</title>
<style>
*{margin:0;padding:0;box-sizing:border-box}
body{font-family:'Segoe UI',system-ui,sans-serif;background:linear-gradient(135deg,#1a1a2e 0%,#16213e 50%,#0f3460 100%);min-height:100vh;color:#e8e8e8;padding:20px;display:flex;align-items:center;justify-content:center}
.container{max-width:400px;width:100%}
.header{text-align:center;margin-bottom:30px}
.logo{font-size:48px;margin-bottom:10px}
.title{font-size:32px;font-weight:700;background:linear-gradient(90deg,#00d4ff,#7b2cbf);-webkit-background-clip:text;-webkit-text-fill-color:transparent;background-clip:text}
.subtitle{color:#888;font-size:14px;margin-top:5px}
.card{background:rgba(255,255,255,0.05);backdrop-filter:blur(10px);border-radius:16px;padding:24px;margin-bottom:20px;border:1px solid rgba(255,255,255,0.1);box-shadow:0 8px 32px rgba(0,0,0,0.3)}
.card-title{font-size:14px;color:#00d4ff;text-transform:uppercase;letter-spacing:1px;margin-bottom:15px;display:flex;align-items:center;gap:8px}
.card-title::before{content:'';width:4px;height:16px;background:linear-gradient(180deg,#00d4ff,#7b2cbf);border-radius:2px}
.upload-area{border:2px dashed rgba(255,255,255,0.3);border-radius:12px;padding:40px 20px;text-align:center;cursor:pointer;background:rgba(0,0,0,0.2)}
.upload-area:hover{border-color:#00d4ff;background:rgba(0,212,255,0.1)}
.upload-icon{font-size:48px;margin-bottom:15px}
.upload-text{color:#888;font-size:14px;line-height:1.6}
.upload-text span{color:#00d4ff}
.filename{margin-top:12px;color:#00d4ff;font-weight:600}
.btn{display:block;width:100%;padding:16px;border:none;border-radius:12px;font-size:16px;font-weight:600;cursor:pointer;transition:all 0.3s;margin-top:15px;text-align:center}
.btn-primary{background:linear-gradient(90deg,#00d4ff,#7b2cbf);color:#fff}
.btn-primary:hover{transform:translateY(-2px);box-shadow:0 10px 30px rgba(0,212,255,0.3)}
.btn-primary:disabled{opacity:0.5;cursor:not-allowed;transform:none}
.progress-container{margin-top:20px;display:none}
.progress-bar{height:12px;background:#333;border-radius:6px;overflow:hidden}
.progress-fill{height:100%;background:linear-gradient(90deg,#00d4ff,#7b2cbf);border-radius:6px;width:0%;transition:width 0.3s}
.progress-text{text-align:center;margin-top:10px;font-size:14px;color:#888}
.status{text-align:center;padding:15px;border-radius:10px;margin-top:15px;display:none}
.status.success{background:rgba(74,222,128,0.1);color:#4ade80;display:block}
.status.error{background:rgba(239,68,68,0.1);color:#ef4444;display:block}
.footer{text-align:center;margin-top:20px;color:#555;font-size:12px}
</style>
</head>
<body>
<div class="container">
<div class="header">
<div class="logo">⚙️</div>
<div class="title">DMX TESTER</div>
<div class="subtitle">Firmware Güncelleme (OTA)</div>
</div>
<div class="card">
<div class="card-title">ESP32-C3 Firmware Yukle</div>
<form id="form" enctype="multipart/form-data">
<div class="upload-area" id="drop" onclick="document.getElementById('file').click()">
<div class="upload-icon">📦</div>
<div class="upload-text">Dosya seçmek için tıklayın<br>veya <span>sürükleyip bırakın</span></div>
<div class="filename" id="fname"></div>
</div>
<input type="file" name="update" id="file" accept=".bin" style="display:none">
<div class="progress-container" id="pbox">
<div class="progress-bar"><div class="progress-fill" id="prog"></div></div>
<div class="progress-text" id="ptxt">%0</div>
</div>
<div class="status" id="stat"></div>
<button type="submit" class="btn btn-primary" id="btn" disabled>Güncellemeyi Başlat</button>
</form>
</div>
</div>
<script>
const drop=document.getElementById('drop'),file=document.getElementById('file'),fname=document.getElementById('fname'),btn=document.getElementById('btn'),form=document.getElementById('form'),pbox=document.getElementById('pbox'),prog=document.getElementById('prog'),ptxt=document.getElementById('ptxt'),stat=document.getElementById('stat');
['dragenter','dragover'].forEach(e=>drop.addEventListener(e,ev=>{ev.preventDefault();ev.stopPropagation();drop.style.borderColor='#00d4ff';drop.style.background='rgba(0,212,255,0.1)'}));
['dragleave','drop'].forEach(e=>drop.addEventListener(e,ev=>{ev.preventDefault();ev.stopPropagation();drop.style.borderColor='rgba(255,255,255,0.3)';drop.style.background='rgba(0,0,0,0.2)'}));
drop.addEventListener('drop',e=>{file.files=e.dataTransfer.files;upd()});
file.addEventListener('change',upd);
function upd(){if(file.files.length){fname.textContent=file.files[0].name;btn.disabled=false}else{fname.textContent='';btn.disabled=true}}
form.addEventListener('submit',function(e){e.preventDefault();if(!file.files.length)return;
const data=new FormData(form),xhr=new XMLHttpRequest();
pbox.style.display='block';stat.className='status';btn.disabled=true;
xhr.upload.addEventListener('progress',function(e){if(e.lengthComputable){const p=Math.round((e.loaded/e.total)*100);prog.style.width=p+'%';ptxt.textContent='%'+p}});
xhr.onreadystatechange=function(){if(xhr.readyState==4){if(xhr.status==200){stat.className='status success';stat.textContent='Basarılı! Yeniden başlatılıyor...';prog.style.background='#4ade80'}else{stat.className='status error';stat.textContent='Hata! Tekrar deneyin.';btn.disabled=false}}};
xhr.open('POST','/update_upload',true);xhr.send(data)});
</script>
</body>
</html>
)rawliteral";

// === PWA GEREKSINIMLERI ===
const char MANIFEST_JSON[] PROGMEM = R"=====(
{
  "name": "DMX Tester Pro",
  "short_name": "DMX Pro",
  "start_url": "/",
  "display": "standalone",
  "background_color": "#0a0a0a",
  "theme_color": "#1a1a1a",
  "icons": [
    {
      "src": "/icon.svg",
      "sizes": "512x512",
      "type": "image/svg+xml"
    }
  ]
}
)=====";

const char SW_JS[] PROGMEM = R"=====(
self.addEventListener('fetch', function(event) {});
)=====";

const char ICON_SVG[] PROGMEM = R"=====(
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512">
  <rect width="512" height="512" rx="100" fill="#1a1a1a"/>
  <text x="50%" y="45%" font-family="Arial, sans-serif" font-size="160" fill="#00ffcc" text-anchor="middle" dominant-baseline="central" font-weight="bold">DMX</text>
  <text x="50%" y="75%" font-family="Arial, sans-serif" font-size="60" fill="#ff9900" text-anchor="middle" font-weight="bold">PRO</text>
</svg>
)=====";

// === WEB TABANLI LOG MONİTÖRÜ ===
const char LOG_HTML[] PROGMEM = R"=====(
<!DOCTYPE html>
<html lang="tr">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>DMX Tester - Log Monitor</title>
<style>
*{margin:0;padding:0;box-sizing:border-box}
body{font-family:'Courier New',monospace;background:#0a0a0a;color:#00ff00;padding:20px}
.header{background:#1a1a1a;padding:15px;border-radius:8px;margin-bottom:20px;border:2px solid #00ff00}
.title{font-size:24px;font-weight:bold;color:#00ff00;text-align:center}
.controls{display:flex;gap:10px;margin-top:10px;justify-content:center}
.btn{padding:8px 16px;background:#00ff00;color:#000;border:none;border-radius:4px;cursor:pointer;font-weight:bold}
.btn:hover{background:#00cc00}
.btn.clear{background:#ff3333;color:#fff}
.btn.clear:hover{background:#cc0000}
.status{text-align:center;margin-top:5px;font-size:12px;color:#888}
.status.connected{color:#00ff00}
.log-container{background:#1a1a1a;border:2px solid #00ff00;border-radius:8px;padding:15px;height:calc(100vh - 200px);overflow-y:auto;font-size:14px;line-height:1.6}
.log-line{margin-bottom:5px;padding:5px;border-left:3px solid #00ff00;padding-left:10px}
.log-line:hover{background:#222}
.log-line.error{border-left-color:#ff3333;color:#ff6666}
.log-line.warning{border-left-color:#ffaa00;color:#ffcc66}
.log-line.info{border-left-color:#00aaff;color:#66ccff}
.timestamp{color:#888;margin-right:10px}
.no-logs{text-align:center;color:#666;padding:50px;font-style:italic}
</style>
</head>
<body>
<div class="header">
<div class="title">📡 DMX TESTER - LOG MONITOR</div>
<div class="controls">
<button class="btn" onclick="toggleAutoScroll()">Auto Scroll: <span id="autoScrollStatus">ON</span></button>
<button class="btn clear" onclick="clearLogs()">Temizle</button>
<button class="btn" onclick="location.href='/'">Ana Sayfa</button>
</div>
<div class="status" id="status">Bağlanıyor...</div>
</div>
<div class="log-container" id="logContainer">
<div class="no-logs">Log mesajları bekleniyor...</div>
</div>
<script>
let autoScroll = true;
let logCount = 0;

function toggleAutoScroll() {
autoScroll = !autoScroll;
document.getElementById('autoScrollStatus').innerText = autoScroll ? 'ON' : 'OFF';
}

function clearLogs() {
document.getElementById('logContainer').innerHTML = '<div class="no-logs">Log mesajları bekleniyor...</div>';
logCount = 0;
}

function addLog(message) {
const container = document.getElementById('logContainer');
if(logCount === 0) container.innerHTML = '';
logCount++;

const line = document.createElement('div');
line.className = 'log-line';

if(message.includes('ERROR') || message.includes('HATA')) line.classList.add('error');
else if(message.includes('WARNING') || message.includes('UYARI')) line.classList.add('warning');
else if(message.includes('INFO')) line.classList.add('info');

line.innerHTML = message;
container.appendChild(line);

if(autoScroll) container.scrollTop = container.scrollHeight;
if(logCount > 200) {
container.removeChild(container.firstChild);
logCount--;
}
}

function fetchLogs() {
fetch('/getLogs')
.then(r => r.json())
.then(data => {
document.getElementById('status').innerText = '🟢 Bağlı - ' + data.logs.length + ' log';
document.getElementById('status').className = 'status connected';
data.logs.forEach(log => {
if(log && log.trim() !== '') addLog(log);
});
})
.catch(e => {
document.getElementById('status').innerText = '🔴 Bağlantı Hatası';
document.getElementById('status').className = 'status';
});
}

fetchLogs();
setInterval(fetchLogs, 2000);
</script>
</body>
</html>
)=====";

// === WEBSOCKET UYUMLU VE PWA DESTEKLI HTML ARAYÜZÜ ===
const char INDEX_HTML[] PROGMEM = R"=====(
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no, touch-action=none">
    
    <link rel="manifest" href="/manifest.json">
    <meta name="theme-color" content="#1a1a1a">
    <meta name="apple-mobile-web-app-capable" content="yes">
    <meta name="apple-mobile-web-app-status-bar-style" content="black-translucent">
    <meta name="apple-mobile-web-app-title" content="DMX Pro">
    <link rel="apple-touch-icon" href="/icon.svg">
    
    <title>DMX Tester Pro</title>
    <style>
        body { font-family: 'Segoe UI', Tahoma, sans-serif; background: #0a0a0a; color: white; margin: 0; padding-bottom: 40px; }
        .header { background: #1a1a1a; padding: 12px 15px; border-bottom: 2px solid #333; display: flex; justify-content: space-between; align-items: center; }
        .title-area { display: flex; align-items: center; gap: 10px; }
        .title { color: #ff9900; margin: 0; font-size: 1.1em; font-weight: bold; }
        .bat { font-size: 0.85em; color: #00ffcc; font-weight: bold; background: #333; padding: 4px 8px; border-radius: 4px;}
        .ws-status { width: 12px; height: 12px; border-radius: 50%; background: red; margin-right: 5px; box-shadow: 0 0 5px red;}
        .ws-status.online { background: #00ffcc; box-shadow: 0 0 8px #00ffcc; }
        
        .header-controls { display: flex; align-items: center; gap: 10px; }
        .gm-wrapper { display: flex; align-items: center; gap: 6px; background: #222; padding: 4px 10px; border-radius: 6px; border: 1px solid #444; }
        .gm-wrapper label { color: #ff9900; font-weight: bold; font-size: 0.9em; }
        .gm-wrapper input[type=range] { width: 70px; -webkit-appearance: none; background: #444; height: 6px; border-radius: 3px; outline: none;}
        .gm-wrapper input[type=range]::-webkit-slider-thumb { -webkit-appearance: none; width: 14px; height: 14px; background: #00ffcc; border-radius: 50%; cursor: pointer;}
        .gm-val { color: #00ffcc; font-weight: bold; font-size: 0.9em; width: 28px; text-align: right; }
        
        .btn-reset { background: #cc0000; color: white; border: 2px solid #ff3333; font-weight: bold; padding: 8px 12px; border-radius: 5px; cursor: pointer; text-transform: uppercase; font-size: 0.9em; }
        .btn-reset:active { background: #ff0000; transform: scale(0.95); }
        .btn-reset:disabled { opacity: 0.4; cursor: not-allowed; }

        .mode-switch { display: flex; width: 100%; background: #111; padding: 10px; box-sizing: border-box; gap: 10px; border-bottom: 1px solid #333; }
        .btn-mode { flex: 1; padding: 10px; font-weight: bold; border-radius: 6px; border: 2px solid #444; background: #222; color: #888; cursor: pointer; transition: all 0.2s; font-size: 1em; }
        .btn-mode.active-console { background: #0066cc; color: white; border-color: #0099ff; box-shadow: 0 0 10px rgba(0,153,255,0.4); }
        .btn-mode.active-sniffer { background: #9900cc; color: white; border-color: #cc33ff; box-shadow: 0 0 10px rgba(153,0,204,0.4); }
        .tabs { display: flex; background: #111; border-bottom: 2px solid #333; }
        .tab-btn { flex: 1; padding: 12px; background: transparent; color: #888; border: none; font-size: 1em; font-weight: bold; cursor: pointer; border-bottom: 3px solid transparent; }
        .tab-btn.active { color: #ff9900; border-bottom: 3px solid #ff9900; background: #1a1a1a; }
        .map-view { display: none; padding: 10px; }
        .grid-container { display: grid; grid-template-columns: repeat(auto-fill, minmax(35px, 1fr)); gap: 5px; }
        .dmx-cell { background: #222; border: 1px solid #444; border-radius: 4px; display: flex; flex-direction: column; align-items: center; justify-content: center; height: 38px; color: #666; transition: background-color 0.05s ease; }
        .dmx-cell .ch { font-size: 0.7em; font-weight: bold; margin-bottom: 2px; }
        .dmx-cell .val { font-size: 0.85em; font-weight: bold; }
        .dmx-cell.active { border-color: #00ffcc; color: #000; box-shadow: 0 0 5px rgba(0,255,204,0.5);}
        .dmx-cell.active .val { color: #000; }
        .nav-controls { display: flex; gap: 10px; align-items: center; justify-content: center; padding: 12px 15px; background: #151515; border-bottom: 1px solid #333; }
        select { padding: 8px; font-size: 1em; background: #222; color: white; border: 1px solid #444; border-radius: 4px; font-weight: bold; outline: none; flex-grow: 1; text-align: center;}
        button.nav-btn { padding: 8px 15px; font-size: 1.2em; background: #444; color: white; border: none; border-radius: 4px; font-weight: bold; cursor: pointer;}
        button.nav-btn:active { background: #ff9900; color: #000; }
        
        .faders-view { display: flex; flex-direction: column; }
        .faders-grid { display: flex; flex-wrap: wrap; justify-content: center; gap: 8px; padding: 15px 10px; }
        .fader-col { display: flex; flex-direction: column; align-items: center; background: #1a1a1a; padding: 15px 5px; border-radius: 8px; border: 1px solid #333; width: 42px; transition: border-color 0.2s; }
        .fader-col:hover { border-color: #555; }
        .ch-label { font-size: 0.85em; font-weight: bold; color: #888; margin-bottom: 12px; }
        .val { font-size: 0.95em; font-weight: bold; color: #00ffcc; margin-top: 12px; text-align: center; }
        input[type=range] { -webkit-appearance: slider-vertical; appearance: slider-vertical; width: 25px; height: 180px; margin: 0; cursor: pointer; background: transparent; }
        input[type=range]:disabled { opacity: 0.4; cursor: not-allowed; }
        
        .fixture-view { display: none; flex-direction: column; padding: 10px; gap: 10px; }
        .fixture-row { display: flex; flex-direction: column; background: #1a1a1a; padding: 12px 10px; border-radius: 8px; border: 1px solid #333; gap: 8px;}
        .fix-header { display: flex; align-items: center; justify-content: space-between; border-bottom: 1px solid #333; padding-bottom: 6px;}
        .fix-name { font-weight: bold; color: #ff9900;}
        .fix-patch input { width: 45px; padding: 6px 4px; background: #222; color: #00ffcc; border: 1px solid #555; text-align: center; }
        .fix-controls { display: flex; width: 100%; align-items: center; gap: 10px;}
        .fix-controls input[type=range] { -webkit-appearance: none; appearance: none; width: 100%; height: 24px; background: #333; border-radius: 12px; outline: none; }
        .fix-val { width: 40px; text-align: right; font-weight: bold; color: #00ffcc;}
        .joystick-wrapper { background: #151515; padding: 15px; border-radius: 8px; border: 2px solid #333; display: flex; flex-direction: column; align-items: center; gap: 15px;}
        .pt-patch-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 8px; font-size: 0.9em; color: #aaa; text-align: right; }
        .pt-patch-grid input { width: 40px; padding: 4px; background: #222; color: #00ffcc; border: 1px solid #555; text-align: center; }
        .joystick-area { width: 220px; height: 220px; background: radial-gradient(circle, #333 0%, #111 100%); border-radius: 15px; position: relative; border: 2px solid #555; touch-action: none; }
        .joystick-knob { width: 50px; height: 50px; background: #ff9900; border-radius: 50%; position: absolute; top: 50%; left: 50%; transform: translate(-50%, -50%); pointer-events: none; }
        .pt-vals { display: flex; justify-content: space-between; width: 100%; font-size: 1.1em; font-weight: bold; color: #aaa;}
        .pt-vals span { color: #00ffcc; font-size: 1.2em;}
        .sniff-indicator { display: none; text-align: center; color: #cc33ff; font-weight: bold; padding: 5px; animation: pulse 1s infinite; }
        @keyframes pulse { 0% { opacity: 0.5; } 50% { opacity: 1; } 100% { opacity: 0.5; } }
    </style>
</head>
<body>
    <div class="header">
        <div class="title-area">
            <div id="wsIndicator" class="ws-status"></div>
            <div class="title">DMX KONSOL</div>
            <div class="bat" id="batUI">Bat: -- V</div>
        </div>
        <div class="header-controls">
            <div class="gm-wrapper">
                <label>GM</label>
                <input type="range" id="gmSlider" min="0" max="255" value="255" oninput="updateGM(this.value)">
                <div class="gm-val" id="gmVal">255</div>
            </div>
            <button class="btn-reset" id="btnReset" onclick="resetAll()">RESET</button>
        </div>
    </div>

    <div class="mode-switch">
        <button class="btn-mode active-console" id="btn-mode-console" onclick="changeDeviceMode('console')">🕹️ KONSOL MODU</button>
        <button class="btn-mode" id="btn-mode-sniffer" onclick="changeDeviceMode('sniffer')">📡 SNIFFER MODU</button>
    </div>
    
    <div class="sniff-indicator" id="sniffIndicator">DIŞARIDAN VERİ DİNLENİYOR...</div>

    <div class="tabs">
        <button class="tab-btn" id="tab-btn-map" onclick="showTab('map')" style="display: none;">Harita</button>
        <button class="tab-btn active" id="tab-btn-faders" onclick="showTab('faders')">Kanallar</button>
        <button class="tab-btn" id="tab-btn-fixture" onclick="showTab('fixture')">Fixture</button>
    </div>
    
    <div class="map-view" id="view-map">
        <div class="grid-container" id="dmx-grid"></div>
    </div>

    <div class="faders-view" id="view-faders">
        <div class="nav-controls">
            <button class="nav-btn" onclick="changePage(-1)">&#8592;</button>
            <select id="pageSelect" onchange="goToPage(this.value)"></select>
            <button class="nav-btn" onclick="changePage(1)">&#8594;</button>
        </div>
        <div id="controls"></div>
    </div>

    <div class="fixture-view" id="view-fixture"></div>

    <script>
        if ('serviceWorker' in navigator) {
            navigator.serviceWorker.register('/sw.js').catch(err => console.log('SW Kayit Hatasi:', err));
        }

        let ws;
        let dmxValues = new Uint8Array(513); 
        let pendingWsMsgs = {}; 
        let isSendingWs = false; 
        
        let gmValue = 255;
        let currentPage = 0;
        const perPage = 32; 
        const totalPages = Math.ceil(512 / perPage);

        let panCh = 0, tiltCh = 0;
        let activeMode = 'console';

        const fixtureParams = [
            { id: 'dimmer', name: 'Dimmer', ch: 0 }, { id: 'strobe', name: 'Strobe', ch: 0 },
            { id: 'color_r', name: 'Red', ch: 0 }, { id: 'color_g', name: 'Green', ch: 0 },
            { id: 'color_b', name: 'Blue', ch: 0 }, { id: 'color_w', name: 'White', ch: 0 }
        ];

        function updateFixturePatch(id, val) {
            let param = fixtureParams.find(p => p.id === id);
            if (param) param.ch = parseInt(val) || 0;
        }

        function updateGM(val) {
            if(activeMode === 'sniffer') return;
            gmValue = parseInt(val);
            document.getElementById('gmVal').innerText = gmValue;
            if (ws && ws.readyState === WebSocket.OPEN) {
                ws.send(`M,${gmValue}`);
            }
        }

        let reconnectAttempts = 0;

        function initWebSocket() {
            let gateway = `ws://${window.location.hostname}:81/`;
            ws = new WebSocket(gateway);
            ws.binaryType = 'arraybuffer'; 

            ws.onopen = () => { 
                reconnectAttempts = 0;
                document.getElementById('wsIndicator').classList.add('online'); 
            };
            
            ws.onerror = (error) => { console.log('WebSocket Hatası:', error); };
            
            ws.onclose = () => { 
                document.getElementById('wsIndicator').classList.remove('online'); 
                reconnectAttempts++;
                let delay = Math.min(1000 * reconnectAttempts, 5000);
                setTimeout(initWebSocket, delay); 
            };
            
            ws.onmessage = (event) => {
                if (event.data instanceof ArrayBuffer) {
                    let view = new Uint8Array(event.data);
                    for(let i=1; i<=512; i++) {
                        dmxValues[i] = view[i-1]; 
                    }
                    requestAnimationFrame(updateVisibleUIElements); 
                } else if (typeof event.data === "string") {
                    if (event.data.startsWith("M,")) {
                        let val = parseInt(event.data.split(",")[1]);
                        gmValue = val;
                        let gSlider = document.getElementById('gmSlider');
                        let gVal = document.getElementById('gmVal');
                        if (gSlider && gSlider.value != val) gSlider.value = val;
                        if (gVal) gVal.innerText = val;
                    }
                }
            };
        }
        window.addEventListener('load', initWebSocket);

        function processWsQueue() {
            let keys = Object.keys(pendingWsMsgs);
            if (keys.length > 0 && ws && ws.readyState === WebSocket.OPEN) {
                let ch = keys[0];
                let val = pendingWsMsgs[ch];
                ws.send(`S,${ch},${val}`);
                delete pendingWsMsgs[ch]; 
                setTimeout(processWsQueue, 15); 
            } else {
                isSendingWs = false;
            }
        }

        function renderGrid() {
            let html = '';
            for(let i=1; i<=512; i++) {
                html += `<div class="dmx-cell" id="gc${i}" data-val="0"><div class="ch">${i}</div><div class="val" id="gv${i}">0</div></div>`;
            }
            document.getElementById('dmx-grid').innerHTML = html;
        }

        function changeDeviceMode(mode) {
            activeMode = mode;
            fetch(`/setMode?m=${mode}`);
            const isSniffer = (mode === 'sniffer');
            document.getElementById('btn-mode-console').classList.toggle('active-console', !isSniffer);
            document.getElementById('btn-mode-sniffer').classList.toggle('active-sniffer', isSniffer);
            
            document.getElementById('btnReset').disabled = isSniffer;
            document.getElementById('btnReset').style.opacity = isSniffer ? '0.4' : '1';
            
            document.getElementById('gmSlider').disabled = isSniffer;
            document.getElementById('gmSlider').style.opacity = isSniffer ? '0.4' : '1';

            document.getElementById('sniffIndicator').style.display = isSniffer ? 'block' : 'none';
            document.querySelectorAll('#controls input[type=range], #view-fixture input[type=range]').forEach(el => el.disabled = isSniffer);

            if (isSniffer) {
                document.getElementById('tab-btn-map').style.display = '';
                document.getElementById('tab-btn-faders').style.display = 'none';
                document.getElementById('tab-btn-fixture').style.display = 'none';
                showTab('map'); 
            } else {
                document.getElementById('tab-btn-map').style.display = 'none';
                document.getElementById('tab-btn-faders').style.display = '';
                document.getElementById('tab-btn-fixture').style.display = '';
                showTab('faders'); 
            }
        }

        function updateVisibleUIElements() {
            if (document.getElementById('view-map').style.display !== 'none') {
                for(let i=1; i<=512; i++) {
                    let cell = document.getElementById(`gc${i}`);
                    let valDiv = document.getElementById(`gv${i}`);
                    if (cell && valDiv) {
                        let val = dmxValues[i];
                        if (cell.dataset.val != val) { 
                            cell.dataset.val = val;
                            valDiv.innerText = val;
                            if (val > 0) {
                                cell.style.backgroundColor = `rgba(0, 255, 204, ${Math.max(0.3, val/255)})`;
                                cell.classList.add('active');
                            } else {
                                cell.style.backgroundColor = '#222';
                                cell.classList.remove('active');
                            }
                        }
                    }
                }
            }
            
            if (document.getElementById('view-faders').style.display !== 'none') {
                let start = currentPage * perPage + 1;
                let end = Math.min(start + perPage - 1, 512);
                for(let i = start; i <= end; i++) {
                    let slider = document.getElementById(`s${i}`);
                    let vLabel = document.getElementById(`v${i}`);
                    if (slider && vLabel && slider.value != dmxValues[i]) {
                        slider.value = dmxValues[i];
                        vLabel.innerText = dmxValues[i];
                    }
                }
            }
            
            if (document.getElementById('view-fixture').style.display !== 'none') {
                fixtureParams.forEach(p => {
                    if (p.ch > 0) {
                        let slider = document.getElementById(`slider_${p.id}`);
                        let vLabel = document.getElementById(`val_${p.id}`);
                        if(slider && slider.value != dmxValues[p.ch]) slider.value = dmxValues[p.ch];
                        if(vLabel && vLabel.innerText != dmxValues[p.ch]) vLabel.innerText = dmxValues[p.ch];
                    }
                });
                if (panCh > 0) document.getElementById('val_pan').innerText = dmxValues[panCh];
                if (tiltCh > 0) document.getElementById('val_tilt').innerText = dmxValues[tiltCh];
                updateKnobPosition(); 
            }
        }

        function showTab(tabName) {
            document.getElementById('view-map').style.display = (tabName === 'map') ? 'block' : 'none';
            document.getElementById('view-faders').style.display = (tabName === 'faders') ? 'flex' : 'none';
            document.getElementById('view-fixture').style.display = (tabName === 'fixture') ? 'flex' : 'none';
            
            document.getElementById('tab-btn-map').classList.toggle('active', tabName === 'map');
            document.getElementById('tab-btn-faders').classList.toggle('active', tabName === 'faders');
            document.getElementById('tab-btn-fixture').classList.toggle('active', tabName === 'fixture');
            
            if(tabName === 'faders') renderSliders();
            if(tabName === 'fixture') renderFixtureControls();
            
            updateVisibleUIElements(); 
            if (activeMode === 'sniffer') document.querySelectorAll('#controls input[type=range], #view-fixture input[type=range]').forEach(el => el.disabled = true);
        }

        function resetAll() {
            if(activeMode === 'sniffer') return; 
            if(confirm("Tüm çıkışlar sıfırlanacak. Emin misiniz?")) {
                dmxValues.fill(0);
                updateVisibleUIElements();
                fetch('/reset');
            }
        }

        function updateDmx(ch, val) {
            if(activeMode === 'sniffer') return; 
            ch = parseInt(ch);
            dmxValues[ch] = parseInt(val);
            let vLabel = document.getElementById('v' + ch);
            if(vLabel) vLabel.innerText = val;
            
            let cell = document.getElementById(`gc${ch}`);
            if (cell) cell.dataset.val = val; 

            pendingWsMsgs[ch] = val; 
            
            if (!isSendingWs) {
                isSendingWs = true;
                processWsQueue();
            }
        }

        let sel = document.getElementById('pageSelect');
        for(let i=0; i<totalPages; i++) {
            let opt = document.createElement('option');
            opt.value = i; 
            let start = i * perPage + 1;
            let end = Math.min((i + 1) * perPage, 512);
            opt.text = `Kanal: ${start} - ${end}`;
            sel.add(opt);
        }

        function renderSliders() {
            let html = '<div class="faders-grid">';
            let start = currentPage * perPage + 1;
            let end = Math.min(start + perPage - 1, 512);
            for(let i=start; i<=end; i++) {
                html += `
                <div class="fader-col">
                    <div class="ch-label">CH ${i}</div>
                    <input type="range" id="s${i}" orient="vertical" min="0" max="255" value="${dmxValues[i]}" oninput="updateDmx(${i}, this.value)">
                    <div class="val" id="v${i}">${dmxValues[i]}</div>
                </div>`;
            }
            html += '</div>';
            document.getElementById('controls').innerHTML = html;
            sel.value = currentPage;
        }

        function changePage(dir) {
            currentPage += dir;
            if(currentPage < 0) currentPage = 0;
            if(currentPage >= totalPages) currentPage = totalPages - 1;
            renderSliders();
            if (activeMode === 'sniffer') document.querySelectorAll('#controls input[type=range]').forEach(el => el.disabled = true);
        }
        function goToPage(val) {
            currentPage = parseInt(val);
            renderSliders();
            if (activeMode === 'sniffer') document.querySelectorAll('#controls input[type=range]').forEach(el => el.disabled = true);
        }

        function renderFixtureControls() {
            let pVal = panCh > 0 ? dmxValues[panCh] : 127;
            let tVal = tiltCh > 0 ? dmxValues[tiltCh] : 127;
            let html = `
            <div class="joystick-wrapper">
                <div class="fix-header" style="align-items:flex-start; width:100%;">
                    <div class="fix-name">Pan & Tilt</div>
                    <div class="pt-patch-grid">
                        <span>P: <input type="number" value="${panCh}" onchange="panCh=this.value"></span>
                        <span>T: <input type="number" value="${tiltCh}" onchange="tiltCh=this.value"></span>
                    </div>
                </div>
                <div class="joystick-area" id="joystick-area">
                    <div class="joystick-knob" id="joystick-knob"></div>
                </div>
                <div class="pt-vals">
                    <div>Pan: <span id="val_pan">${pVal}</span></div>
                    <div>Tilt: <span id="val_tilt">${tVal}</span></div>
                </div>
            </div>`;
            fixtureParams.forEach(param => {
                let currentVal = param.ch > 0 ? dmxValues[param.ch] : 0;
                html += `
                <div class="fixture-row">
                    <div class="fix-header">
                        <div class="fix-name">${param.name}</div>
                        <input type="number" class="fix-patch" value="${param.ch}" onchange="updateFixturePatch('${param.id}', this.value)">
                    </div>
                    <div class="fix-controls">
                        <input type="range" style="-webkit-appearance: none; appearance: none; width: 100%; height: 24px;" id="slider_${param.id}" min="0" max="255" value="${currentVal}" oninput="updateDmx(fixtureParams.find(p=>p.id==='${param.id}').ch, this.value)">
                        <div class="fix-val" id="val_${param.id}">${currentVal}</div>
                    </div>
                </div>`;
            });
            document.getElementById('view-fixture').innerHTML = html;
            updateKnobPosition();
            initJoystick();
        }

        function updateKnobPosition() {
            const knob = document.getElementById('joystick-knob');
            if(!knob) return;
            let curP = panCh > 0 ? dmxValues[panCh] : 127; 
            let curT = tiltCh > 0 ? dmxValues[tiltCh] : 127; 
            knob.style.left = (curP / 255 * 100) + '%';
            knob.style.top = (100 - (curT / 255 * 100)) + '%';
        }

        function initJoystick() {
            const area = document.getElementById('joystick-area');
            const knob = document.getElementById('joystick-knob');
            let isDragging = false;
            area.addEventListener('pointerdown', (e) => {
                if(activeMode === 'sniffer') return; 
                isDragging = true; area.setPointerCapture(e.pointerId); updateKnobDrag(e);
            });
            area.addEventListener('pointermove', (e) => { if(isDragging) updateKnobDrag(e); });
            area.addEventListener('pointerup', (e) => { isDragging = false; area.releasePointerCapture(e.pointerId); });
            function updateKnobDrag(e) {
                let rect = area.getBoundingClientRect();
                let x = Math.max(0, Math.min(e.clientX - rect.left, rect.width));
                let y = Math.max(0, Math.min(e.clientY - rect.top, rect.height));
                let xPercent = (x / rect.width) * 100;
                let yPercent = (y / rect.height) * 100;
                knob.style.left = xPercent + '%'; 
                knob.style.top = yPercent + '%';
                let pVal = Math.round((x / rect.width) * 255);
                let tVal = Math.round(((rect.height - y) / rect.height) * 255); 
                document.getElementById('val_pan').innerText = pVal;
                document.getElementById('val_tilt').innerText = tVal;
                if(panCh > 0) updateDmx(panCh, pVal);
                if(tiltCh > 0) updateDmx(tiltCh, tVal);
            }
        }

        setInterval(() => {
            fetch('/status').then(r => r.json()).then(data => {
                document.getElementById('batUI').innerText = "Bat: " + data.vbat + " V";
            }).catch(e => console.log("Hata"));
        }, 5000);

        renderGrid();
        renderSliders();
    </script>
</body>
</html>
)=====";

// --- WEB SERVER ROTAJLARI ---
void handleRoot() { server.send(200, "text/html", INDEX_HTML); }
void handleUpdatePage() { server.send(200, "text/html", update_html); }
void handleLogPage() { server.send(200, "text/html", LOG_HTML); }

void handleGetLogs() {
  String json = "{\"logs\":[";
  
  if (xSemaphoreTake(logMutex, pdMS_TO_TICKS(10)) == pdTRUE) {
    bool first = true;
    for(int i = 0; i < MAX_LOG_MESSAGES; i++) {
      int idx = (logIndex + i) % MAX_LOG_MESSAGES;
      if(logMessages[idx].length() > 0) {
        if(!first) json += ",";
        json += "\"" + logMessages[idx] + "\"";
        first = false;
      }
    }
    xSemaphoreGive(logMutex);
  }
  
  json += "]}";
  server.send(200, "application/json", json);
}

void handleStatus() {
    char json[128];
    snprintf(json, sizeof(json), 
             "{\"vbat\":%.2f, \"clients\":%d, \"mode\":%d}", 
             readBattery(), WiFi.softAPgetStationNum(), currentMode);
    server.send(200, "application/json", json);
}

// ARTIK BLACKOUT DEĞİL, RESETALL FONKSİYONU
void handleReset() {
  if(currentMode == MODE_CONSOLE) {
      uint8_t wsBuffer[512];
      
      if (xSemaphoreTake(dmxMutex, pdMS_TO_TICKS(5)) == pdTRUE) {
          memset(&dmxData[1], 0, 512); // Ham veriyi sıfırlar
          lastDataTime = millis();
          memcpy(wsBuffer, &dmxData[1], 512);
          xSemaphoreGive(dmxMutex);
      }
      
      webSocket.broadcastBIN(wsBuffer, 512); 
  }
  server.send(200, "text/plain", "OK");
}

void handleSetMode() {
  if (server.hasArg("m")) {
    String m = server.arg("m");
    if (m == "sniffer") {
        currentMode = MODE_SNIFFER;
        uart_flush_input(UART_NUM_1);
        xQueueReset(dmx_rx_queue);
        webLog("Mod değişti: SNIFFER MODU");
    } else {
        currentMode = MODE_CONSOLE;
        uart_flush_input(UART_NUM_1);
        xQueueReset(dmx_rx_queue);
        webLog("Mod değişti: KONSOL MODU");
    }
  }
  server.send(200, "text/plain", "OK");
}

// --- ARTNET CALLBACK ---
void onDmxFrame(uint16_t universe, uint16_t length, uint8_t sequence, uint8_t* data) {
  if (universe != targetUniverse) return;

  if (currentMode == MODE_CONSOLE) {
      bool isChanged = false;
      int lastChangedCh = -1; 
      int lastChangedVal = -1; 
      
      if (xSemaphoreTake(dmxMutex, pdMS_TO_TICKS(5)) == pdTRUE) {
          for (int i = 0; i < length && i < 512; i++) {
            if (dmxData[i + 1] != data[i]) {
                dmxData[i + 1] = data[i]; // Ham veriyi kaydet (GM sonradan uygulanacak)
                isChanged = true;
                lastChangedCh = i + 1; 
                lastChangedVal = data[i]; 
            }
          }
          xSemaphoreGive(dmxMutex);
      }
      
      if (isChanged) {
          lastDataTime = millis();    
          
          static unsigned long lastArtNetLogTime = 0;
          if (millis() - lastArtNetLogTime > 500) {
              webLog("INFO: ArtNet Verisi Alındı -> CH " + String(lastChangedCh) + " = " + String(lastChangedVal));
              lastArtNetLogTime = millis();
          }
          
          if (millis() - lastWsTx > 50) {
              uint8_t wsBuffer[512];
              if (xSemaphoreTake(dmxMutex, pdMS_TO_TICKS(5)) == pdTRUE) {
                  memcpy(wsBuffer, &dmxData[1], 512); // Arayüze yine ham veriyi yayınlıyoruz
                  xSemaphoreGive(dmxMutex);
              }
              webSocket.broadcastBIN(wsBuffer, 512); 
              lastWsTx = millis();
          }
      }
  }
}

void setup() {
  pinMode(LED_PIN, OUTPUT);
  digitalWrite(LED_PIN, LED_OFF); 
  
  analogReadResolution(12);
  memset(dmxData, 0, 513); 

  dmxMutex = xSemaphoreCreateMutex();
  logMutex = xSemaphoreCreateMutex();
  
  webLog("=== DMX TESTER PRO v1.1 ===");
  webLog("Sistem başlatılıyor...");

  generateSSID();
  WiFi.softAP(ssidName, SSID_PASS);
  
  webLog("WiFi AP: " + String(ssidName));
  webLog("WiFi Pass: " + String(SSID_PASS));
  webLog("IP: " + WiFi.softAPIP().toString());
  
  dnsServer.start(DNS_PORT, "*", WiFi.softAPIP());
  
  webSocket.begin();
  webSocket.onEvent(webSocketEvent);
  
  server.on("/", handleRoot);
  server.on("/status", handleStatus);
  server.on("/reset", handleReset); // Güncellendi
  server.on("/setMode", handleSetMode);
  server.on("/update", HTTP_GET, handleUpdatePage);
  server.on("/logs", handleLogPage);
  server.on("/getLogs", handleGetLogs);
  
  server.on("/manifest.json", []() { server.send(200, "application/json", MANIFEST_JSON); });
  server.on("/sw.js", []() { server.send(200, "application/javascript", SW_JS); });
  server.on("/icon.svg", []() { server.send(200, "image/svg+xml", ICON_SVG); });

  server.on("/update_upload", HTTP_POST, []() {
    server.sendHeader("Connection", "close");
    server.send(200, "text/plain", (Update.hasError()) ? "HATA" : "OK");
    delay(1000);
    ESP.restart();
  }, []() {
    HTTPUpload& upload = server.upload();
    if (upload.status == UPLOAD_FILE_START) {
      ota_in_progress = true; 
      if (!Update.begin(UPDATE_SIZE_UNKNOWN)) Update.printError(Serial);
    } else if (upload.status == UPLOAD_FILE_WRITE) {
      if (Update.write(upload.buf, upload.currentSize) != upload.currentSize) Update.printError(Serial);
    } else if (upload.status == UPLOAD_FILE_END) {
      if (Update.end(true)) {} else ota_in_progress = false; 
    }
  }); 

  server.onNotFound([]() {
    server.sendHeader("Location", String("http://") + WiFi.softAPIP().toString(), true);
    server.send(302, "text/plain", "");
  });

  server.begin();

  if (MDNS.begin("dmxpro")) {
    MDNS.addService("http", "tcp", 80);
  }

  artnet.setArtDmxCallback(onDmxFrame);
  artnet.begin();

  uart_config_t uart_config = {
      .baud_rate = 250000,
      .data_bits = UART_DATA_8_BITS,
      .parity    = UART_PARITY_DISABLE,
      .stop_bits = UART_STOP_BITS_2,
      .flow_ctrl = UART_HW_FLOWCTRL_DISABLE,
      .source_clk = UART_SCLK_APB,
  };
  uart_param_config(UART_NUM_1, &uart_config);
  uart_set_pin(UART_NUM_1, DMX_TX_PIN, DMX_RX_PIN, UART_PIN_NO_CHANGE, UART_PIN_NO_CHANGE);
  uart_driver_install(UART_NUM_1, 1024, 1024, 20, &dmx_rx_queue, 0);

  webLog("DMX UART yapılandırıldı (250kbps)");
  webLog("ArtNet dinleniyor (Universe " + String(targetUniverse) + ")");

  xTaskCreateUniversal(
      dmxCoreTask,       
      "DMX_Task",        
      4096,              
      NULL,              
      3,                 
      &DmxTaskHandle,    
      CONFIG_ARDUINO_RUNNING_CORE
  );
  
  webLog("DMX Task başlatıldı");
  webLog("Sistem hazır! Log sayfası: http://" + WiFi.softAPIP().toString() + "/logs");
}

void loop() {
  unsigned long currentMillis = millis();

  dnsServer.processNextRequest();
  server.handleClient();
  webSocket.loop();
  
  if (ota_in_progress) return; 
  
  artnet.read(); // ArtNet paketlerini oku

  int connectedClients = WiFi.softAPgetStationNum();

  if (currentMode == MODE_SNIFFER) {
      if (currentMillis - lastDataTime > 1500) { 
          if (xSemaphoreTake(dmxMutex, pdMS_TO_TICKS(5)) == pdTRUE) {
              if (dmxData[1] != 0 || dmxData[512] != 0) { 
                  memset(&dmxData[1], 0, 512);
              }
              xSemaphoreGive(dmxMutex);
          }
          lastDataTime = currentMillis; 
      }
      
      if (connectedClients > 0 && (currentMillis - lastWsTx > 100)) {
          uint8_t wsBuffer[512];
          if (xSemaphoreTake(dmxMutex, pdMS_TO_TICKS(5)) == pdTRUE) {
              memcpy(wsBuffer, &dmxData[1], 512);
              xSemaphoreGive(dmxMutex);
          }
          webSocket.broadcastBIN(wsBuffer, 512);
          lastWsTx = currentMillis;
      }
  }

  if (connectedClients != previousClientCount) {
     if (connectedClients > previousClientCount) {
       webLog("INFO: Client bağlandı (Toplam: " + String(connectedClients) + ")");
     } else {
       webLog("INFO: Client ayrıldı (Toplam: " + String(connectedClients) + ")");
     }
     previousClientCount = connectedClients;
  }

  if (currentMode == MODE_SNIFFER) {
    if (currentMillis - lastDataTime < 1000) {
      digitalWrite(LED_PIN, LED_ON); 
    } else {
      bool slowBlink = (currentMillis / 500) % 2;
      digitalWrite(LED_PIN, slowBlink ? LED_ON : LED_OFF); 
    }
  } else {
    if (currentMillis - lastDataTime < 300) {
      bool fastBlink = (currentMillis / 50) % 2; 
      digitalWrite(LED_PIN, fastBlink ? LED_ON : LED_OFF);
    } else if (connectedClients > 0) {
      digitalWrite(LED_PIN, LED_ON); 
    } else {
      bool slowBlink = (currentMillis / 500) % 2;
      digitalWrite(LED_PIN, slowBlink ? LED_ON : LED_OFF);
    }
  }
  
  if (currentMillis - lastArtPollTime > 3000) {
      broadcastArtPollReply();
      lastArtPollTime = currentMillis;
  }

  vTaskDelay(pdMS_TO_TICKS(1)); 
}