import 'package:KmerLingo/core/services/api_service.dart';
import 'package:KmerLingo/presentation/screens/chapter_screen.dart';
import 'package:flutter/material.dart';
import '../../data/models/module.dart';

class ModuleScreen extends StatefulWidget {
  const ModuleScreen({Key? key}) : super(key: key);

  @override
  State<ModuleScreen> createState() => _ModuleScreenState();
}

class _ModuleScreenState extends State<ModuleScreen> {
  final ApiService apiService = ApiService();
  late Future<List<Module>> _modulesFuture;

  @override
  void initState() {
    super.initState();
    _modulesFuture = fetchModules();
  }

  Future<List<Module>> fetchModules() async {
    final modulesJson = await apiService.fetchModules();
    return modulesJson.map<Module>((m) => Module.fromJson(m)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Modules'),
      ),
      body: FutureBuilder<List<Module>>(
        future: _modulesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Erreur: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Aucun module disponible.'));
          } else {
            final modules = snapshot.data!;
            return ListView.builder(
              itemCount: modules.length,
              itemBuilder: (context, index) {
                final module = modules[index];
                return Card(
                  margin: const EdgeInsets.all(8),
                  child: ListTile(
                    title: Text(module.title),
                    subtitle: Text(module.description),
                    trailing: const Icon(Icons.arrow_forward),
                    onTap: () {
                      // Naviguer vers les chapitres
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              ChapterScreen(module: module),
                        ),
                      );
                    },
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}
