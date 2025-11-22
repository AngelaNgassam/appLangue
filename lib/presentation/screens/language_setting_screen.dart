import 'package:KmerLingo/core/services/api_service.dart';
import 'package:KmerLingo/data/models/language.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageSettingsScreen extends StatefulWidget {
  final String userId;
  final String? currentLanguageId;

  const LanguageSettingsScreen({
    Key? key,
    required this.userId,
    this.currentLanguageId,
  }) : super(key: key);

  @override
  State<LanguageSettingsScreen> createState() => _LanguageSettingsScreenState();
}

class _LanguageSettingsScreenState extends State<LanguageSettingsScreen> {
  final ApiService apiService = ApiService();
  String? selectedLanguageId;
  late Future<List<Language>> _languagesFuture;

  @override
  void initState() {
    super.initState();
    selectedLanguageId = widget.currentLanguageId;
    _languagesFuture = apiService.fetchLanguages();
  }

  Future<void> _updateLanguage() async {
    if (selectedLanguageId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner une langue.')),
      );
      return;
    }

    try {
      bool success = await apiService.updateUserPreference(
        widget.userId,
        languageId: selectedLanguageId,
      );

      if (success) {
        final updatedPref = await apiService.getUserPreference(widget.userId);
        final newToken = updatedPref['access_token'];

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('access_token', newToken ?? '');

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Langue mise à jour avec succès !')),
        );

        Navigator.pop(context, selectedLanguageId);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur lors de la mise à jour.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur : $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        elevation: 0,
        title: const Text(
          'Changer la langue',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue.shade700,
      ),
      body: FutureBuilder<List<Language>>(
        future: _languagesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(strokeWidth: 2));
          } else if (snapshot.hasError) {
            return Center(child: Text('Erreur : ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Aucune langue disponible.'));
          } else {
            final languages = snapshot.data!;

            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Sélectionnez votre langue :',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 20),

                  Expanded(
                    child: ListView.separated(
                      itemCount: languages.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final lang = languages[index];

                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              )
                            ],
                          ),
                          child: RadioListTile<String>(
                            value: lang.id,
                            groupValue: selectedLanguageId,
                            activeColor: Colors.blue.shade700,
                            title: Text(
                              lang.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            onChanged: (value) {
                              setState(() {
                                selectedLanguageId = value;
                              });
                            },
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 15),

                  ElevatedButton(
                    onPressed: _updateLanguage,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(55),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      backgroundColor: Colors.blue.shade700,
                      elevation: 4,
                    ),
                    child: const Text(
                      'Enregistrer',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            );
          }
        },
      ),
    );
  }
}
