import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/fixture_manager.dart';
import '../models/fixture.dart';

class PatchScreen extends StatefulWidget {
  const PatchScreen({super.key});

  @override
  State<PatchScreen> createState() => _PatchScreenState();
}

class _PatchScreenState extends State<PatchScreen> {
  @override
  Widget build(BuildContext context) {
    final fixtureManager = context.watch<FixtureManager>();
    
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1F3A),
        title: const Text('Fixture Patch'),
      ),
      body: Row(
        children: [
          // Sol panel - Fikstür kütüphanesi
          Expanded(
            child: Container(
              color: const Color(0xFF0A0E27),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Fixture Library',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF00D9FF),
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: fixtureManager.fixtureLibrary.length,
                      itemBuilder: (context, index) {
                        final fixture = fixtureManager.fixtureLibrary[index];
                        return _FixtureLibraryCard(
                          fixture: fixture,
                          onPatch: () => _showPatchDialog(context, fixture),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Sağ panel - Yamalı fikstürler
          Expanded(
            child: Container(
              color: const Color(0xFF1A1F3A),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Patched Fixtures',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFF6B35),
                      ),
                    ),
                  ),
                  Expanded(
                    child: fixtureManager.patchedFixtures.isEmpty
                        ? Center(
                            child: Text(
                              'No patched fixtures',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.5),
                              ),
                            ),
                          )
                        : ListView.builder(
                            itemCount: fixtureManager.patchedFixtures.length,
                            itemBuilder: (context, index) {
                              final fixture = fixtureManager.patchedFixtures[index];
                              return _PatchedFixtureCard(
                                fixture: fixture,
                                onUnpatch: () {
                                  fixtureManager.unpatchFixture(fixture.id);
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  void _showPatchDialog(BuildContext context, Fixture fixture) {
    final controller = TextEditingController(text: '1');
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1F3A),
        title: Text('Patch ${fixture.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Channels: ${fixture.channelCount}'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Start Address (1-512)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final address = int.tryParse(controller.text);
              if (address != null && address >= 1 && address <= 512) {
                try {
                  context.read<FixtureManager>().patchFixture(fixture, address);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${fixture.name} patched to Ch $address')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(e.toString())),
                  );
                }
              }
            },
            child: const Text('Patch'),
          ),
        ],
      ),
    );
  }
}

class _FixtureLibraryCard extends StatelessWidget {
  final Fixture fixture;
  final VoidCallback onPatch;
  
  const _FixtureLibraryCard({
    required this.fixture,
    required this.onPatch,
  });
  
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: const Color(0xFF1A1F3A),
      child: ListTile(
        leading: const Icon(Icons.lightbulb_outline, color: Color(0xFF00D9FF)),
        title: Text(fixture.name),
        subtitle: Text('${fixture.channelCount} channels'),
        trailing: IconButton(
          icon: const Icon(Icons.add_circle, color: Color(0xFF00D9FF)),
          onPressed: onPatch,
        ),
      ),
    );
  }
}

class _PatchedFixtureCard extends StatelessWidget {
  final Fixture fixture;
  final VoidCallback onUnpatch;
  
  const _PatchedFixtureCard({
    required this.fixture,
    required this.onUnpatch,
  });
  
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: const Color(0xFF0A0E27),
      child: ListTile(
        leading: const Icon(Icons.lightbulb, color: Color(0xFFFF6B35)),
        title: Text(fixture.name),
        subtitle: Text('Ch ${fixture.startAddress} - ${fixture.startAddress! + fixture.channelCount - 1}'),
        trailing: IconButton(
          icon: const Icon(Icons.remove_circle, color: Colors.red),
          onPressed: onUnpatch,
        ),
      ),
    );
  }
}
