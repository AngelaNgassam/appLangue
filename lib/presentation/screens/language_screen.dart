import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/services/api_service.dart';
import '../../../data/models/language.dart';
import 'goal_screen.dart';

class LanguageScreen extends StatefulWidget {
  final String userId;
  final String token; // ✅ Ajout du paramètre token
  
  const LanguageScreen({
    super.key,
    required this.userId,
    required this.token, // ✅ Ajout du paramètre token
  });

  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> {
  final ApiService api = ApiService();
  List<Language> languages = [];
  String? selectedLanguageId;
  bool loading = true;
  bool saving = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeAndLoadLanguages(); // ✅ Sauvegarde token + charge langues
  }

  /// 🔹 Sauvegarde le token puis charge les langues
  Future<void> _initializeAndLoadLanguages() async {
    print('🔄 Initialisation de LanguageScreen');
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('jwt_token', widget.token);
    print('💾 Token sauvegardé : ${widget.token.substring(0, 20)}...');

    final savedToken = prefs.getString('jwt_token');
    print('🔍 Token relu : ${savedToken?.substring(0, 20)}...');

    await loadLanguages();
  }

  /// 🔹 Charge la liste des langues depuis l’API
  Future<void> loadLanguages() async {
    try {
      print('📡 Chargement des langues...');
      final langs = await api.fetchLanguages();
      setState(() {
        languages = langs;
        loading = false;
        errorMessage = null;
      });
      print('✅ ${langs.length} langues chargées avec succès');
    } catch (e) {
      print('❌ Erreur chargement langues : $e');
      setState(() {
        loading = false;
        errorMessage = 'Erreur lors du chargement des langues: ${e.toString()}';
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage!),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  /// 🔹 Sauvegarde la préférence utilisateur (étape 1 : langue)
  Future<void> saveAndContinue() async {
    if (selectedLanguageId == null) return;

    setState(() => saving = true);

    try {
      final success = await api.createUserPreference(
        widget.userId,
        selectedLanguageId!,
        goalId: null,   // ✅ Étape 1 : goalId null
        referralSourceId: null, // ✅ Étape 1 : sourceId null
      );

      if (success && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => GoalScreen(
              userId: widget.userId,
              languageId: selectedLanguageId!,
            ),
          ),
        );
      } else {
        throw Exception('Échec de la sauvegarde de la préférence');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Choose your language"),
        centerTitle: true,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Colors.red,
                          size: 64,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () {
                            setState(() {
                              loading = true;
                              errorMessage = null;
                            });
                            loadLanguages();
                          },
                          icon: const Icon(Icons.refresh),
                          label: const Text('Réessayer'),
                        ),
                      ],
                    ),
                  ),
                )
              : languages.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.language,
                            size: 64,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Aucune langue disponible',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: loadLanguages,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Actualiser'),
                          ),
                        ],
                      ),
                    )
                  : Column(
                      children: [
                        Expanded(
                          child: ListView(
                            padding: const EdgeInsets.all(16),
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(bottom: 16),
                                child: Text(
                                  'Sélectionnez la langue que vous souhaitez apprendre :',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              ...languages.map(
                                (lang) => Card(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  child: RadioListTile<String>(
                                    title: Text(
                                      lang.name,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    value: lang.id,
                                    groupValue: selectedLanguageId,
                                    onChanged: (value) {
                                      setState(() => selectedLanguageId = value);
                                    },
                                    activeColor: Theme.of(context).primaryColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, -5),
                              ),
                            ],
                          ),
                          child: SafeArea(
                            child: SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: selectedLanguageId == null || saving
                                    ? null
                                    : saveAndContinue,
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: saving
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text(
                                        "Suivant",
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
    );
  }
}
