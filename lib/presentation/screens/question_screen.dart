import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../../data/models/lesson.dart';
import '../../data/models/question.dart';
import '../../data/models/answer.dart';
import '../../core/services/api_service.dart';
// ... (Les imports, les enums et les classes Question/Answer/Lesson sont inchangés)

class QuestionScreen extends StatefulWidget {
  final Lesson lesson;
  const QuestionScreen({Key? key, required this.lesson}) : super(key: key);

  @override
  State<QuestionScreen> createState() => _QuestionScreenState();
}

class _QuestionScreenState extends State<QuestionScreen>
    with TickerProviderStateMixin {
  final ApiService apiService = ApiService();
  late Future<List<Question>> _questionsFuture;
  // Voice to Text
  late SpeechToText _speech;
  bool _isRecording = false;
  String _voiceText = "";

  // 🔊 AudioPlayers
  final AudioPlayer _winPlayer = AudioPlayer();
  final AudioPlayer _losePlayer = AudioPlayer();
  final AudioPlayer _questionAudioPlayer = AudioPlayer();
  final AudioPlayer _achievementPlayer = AudioPlayer();

  // 🔊 TTS
  late FlutterTts _flutterTts;

  int _currentIndex = 0;
  bool? _isCorrect;
  String? _selectedChoice;
  late TextEditingController _answerController;
  List<String> _correctAnswers = [];
  bool _hasSpoken = false;

  // 💰 Points animés
  int _totalLessonPoints = 0;
  int _animatedPoints = 0;
  bool _lessonFinished = false;

  // ⏱️ Temps passé
  late DateTime _startTime;
  Duration? _timeSpent;

  // 📝 Gestion des questions ratées
  List<Question> _incorrectQuestions = [];
  bool _isReviewMode = false;

  // 📊 Animation de progression
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;

  // 💬 Animation du panneau de feedback
  late AnimationController _feedbackController;
  late Animation<Offset> _feedbackOffsetAnimation;
  List<String> _selectedWords =
      []; // 👈 NOUVEAU : Pour stocker les mots cliqués

  Widget _buildWordBuilder(Question question) {
    print(
      "🔤 Construction du widget Word Builder pour question id=${question.id}",
    );

    // Récupère les mots suggérés depuis la première réponse correcte
    final correctAnswer = question.answers.firstWhere(
      (a) => a.isCorrect,
      orElse: () =>
          Answer(id: "0", questionId: question.id, text: "", isCorrect: false),
    );

    final List<String> wordOptions = correctAnswer.wordOptions;

    print("📦 Mots disponibles : $wordOptions");

    if (wordOptions.isEmpty) {
      print("⚠️ Aucun mot disponible pour cette question");
      return const Text(
        "Aucun mot disponible pour cette question",
        style: TextStyle(color: Colors.red),
      );
    }

    final bool isChecked = _isCorrect != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 📦 ZONE D'AFFICHAGE DE LA PHRASE CONSTRUITE
        Container(
          height: 100,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isChecked
                  ? (_isCorrect! ? Colors.green : Colors.red)
                  : Colors.grey.shade300,
              width: 2,
            ),
          ),
          child: _selectedWords.isEmpty
              ? Center(
                  child: Text(
                    "Cliquez sur les mots ci-dessous pour former la phrase",
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 16,
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                )
              : Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _selectedWords.asMap().entries.map((entry) {
                    final index = entry.key;
                    final word = entry.value;

                    return GestureDetector(
                      onTap: isChecked
                          ? null
                          : () {
                              // Retire le mot de la phrase construite
                              setState(() {
                                _selectedWords.removeAt(index);
                              });
                              print("❌ Mot retiré : '$word'");
                              print(
                                "📝 Phrase actuelle : ${_selectedWords.join(' ')}",
                              );
                            },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade600,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              word,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (!isChecked) ...[
                              const SizedBox(width: 6),
                              const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 16,
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
        ),

        const SizedBox(height: 20),

        // 🔤 MOTS DISPONIBLES À CLIQUER
        const Text(
          "Mots disponibles :",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),

        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: wordOptions.map((word) {
            final isUsed = _selectedWords.contains(word);

            return GestureDetector(
              onTap: (isChecked || isUsed)
                  ? null
                  : () {
                      // Ajoute le mot à la phrase construite
                      setState(() {
                        _selectedWords.add(word);
                      });
                      print("✅ Mot ajouté : '$word'");
                      print("📝 Phrase actuelle : ${_selectedWords.join(' ')}");
                    },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: isUsed ? Colors.grey.shade300 : Colors.green.shade100,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isUsed
                        ? Colors.grey.shade400
                        : Colors.green.shade600,
                    width: 2,
                  ),
                ),
                child: Text(
                  word,
                  style: TextStyle(
                    color: isUsed ? Colors.grey.shade600 : Colors.black87,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    decoration: isUsed
                        ? TextDecoration.lineThrough
                        : TextDecoration.none,
                  ),
                ),
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 20),

        // 🔘 BOUTON DE VALIDATION
        ElevatedButton(
          onPressed: (_selectedWords.isNotEmpty && _isCorrect == null)
              ? () => _submitWordBuilderAnswer(question)
              : null,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            backgroundColor: Colors.green.shade700,
            foregroundColor: Colors.white,
            disabledBackgroundColor: Colors.grey.shade400,
          ),
          child: const Text(
            "Valider",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  void _submitWordBuilderAnswer(Question question) async {
    final answerToSend = _selectedWords.join(' ').trim();

    print("📤 Soumission réponse Word Builder : '$answerToSend'");
    print("🔍 ID de la question : ${question.id}");

    if (answerToSend.isEmpty) {
      print("⚠️ Aucun mot sélectionné");
      return;
    }

    FocusScope.of(context).unfocus();

    bool localIsCorrect = false;
    List<String> localCorrectAnswers = [];
    int newTotalLessonPoints = _totalLessonPoints;

    if (!_isReviewMode) {
      print("🔄 Mode normal : envoi à l'API");
      final result = await apiService.checkAnswer(question.id, answerToSend);
      print("📦 Réponse de l'API : $result");

      if (result['correctAnswers'] != null &&
          result['correctAnswers'] is List) {
        localCorrectAnswers = List<String>.from(
          result['correctAnswers'].map((e) => e.toString()),
        );
        print("✅ Réponses correctes de l'API : $localCorrectAnswers");
      }

      localIsCorrect = result['isCorrect'] ?? false;
      print("🔍 Réponse correcte ? $localIsCorrect");

      if (result['totalLessonPoints'] != null) {
        newTotalLessonPoints = (result['totalLessonPoints'] as num).toInt();
        print("💰 Points totaux : $newTotalLessonPoints");
      }

      if (!localIsCorrect && !_incorrectQuestions.contains(question)) {
        _incorrectQuestions.add(question);
        print("⚠️ Question ajoutée aux incorrectes");
      }
    } else {
      print("🔄 Mode révision : vérification locale");
      localIsCorrect = _checkAnswerLocally(question, answerToSend);
      print("🔍 Réponse correcte (local) ? $localIsCorrect");

      localCorrectAnswers = question.answers
          .where((a) => a.isCorrect && a.text != null)
          .map((a) => a.text!.trim().toLowerCase())
          .toList();
      print("✅ Réponses correctes (local) : $localCorrectAnswers");

      if (localIsCorrect) {
        _incorrectQuestions.remove(question);
        print("✅ Question retirée des incorrectes");
      }
    }

    setState(() {
      _isCorrect = localIsCorrect;
      _correctAnswers = localCorrectAnswers;
      _totalLessonPoints = newTotalLessonPoints;
    });

    print("🔊 Lecture du son");
    await _playSound(_isCorrect!);

    print("📢 Animation feedback");
    await _feedbackController.forward(from: 0.0);

    print("✅ Soumission Word Builder terminée");
  }

  @override
  void initState() {
    super.initState();
    print("⚡ Initialisation de l'écran de questions...");

    _startTime = DateTime.now();
    print("🕒 Début de la session à $_startTime");

    _questionsFuture = apiService.getQuestionsByLesson(widget.lesson.id);
    print("📦 Récupération des questions pour la leçon id=${widget.lesson.id}");

    _answerController = TextEditingController();
    _preloadSounds();

    _flutterTts = FlutterTts();
    _flutterTts.setLanguage("fr-FR");
    _flutterTts.setSpeechRate(0.9);
    _flutterTts.setPitch(1.0);

    _speech = SpeechToText();
    print("🎤 SpeechToText initialisé");

    // Initialisation de la progression
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 0.0,
    ).animate(_progressController);

    // Initialisation du feedback
    _feedbackController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _feedbackOffsetAnimation =
        Tween<Offset>(begin: const Offset(0.0, 1.0), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _feedbackController,
            curve: Curves.easeOutCubic,
          ),
        );

    // Démarre l'animation de progression initiale (si des questions sont déjà là)
    _questionsFuture.then((questions) {
      print("✅ Questions récupérées: ${questions.length}");
      if (questions.isNotEmpty) {
        _updateProgress(questions.length, initial: true);
      }
    });
  }

  void _startVoiceRecording() async {
    print("🎤 Initialisation de la reconnaissance vocale...");

    bool available = await _speech.initialize();
    print("ℹ️ Reconnaissance vocale disponible ? $available");

    if (available) {
      setState(() => _isRecording = true);
      print("ℹ️ _isRecording mis à true");

      _speech.listen(
        onResult: (result) {
          setState(() {
            _voiceText = result.recognizedWords; // variable pour stocker texte
          });
          print("📝 Texte capturé : '$_voiceText'");
        },
        listenMode: ListenMode.confirmation, // optionnel
        onSoundLevelChange: (level) {
          print("🎚️ Niveau sonore : $level"); // optionnel pour debug audio
        },
        cancelOnError: true,
        partialResults: true, // permet de voir le texte en temps réel
      );
      print("🎧 Écoute démarrée...");
    } else {
      print("❌ La reconnaissance vocale n'est pas disponible");
    }
  }

  void _stopVoiceRecordingAndSubmit(Question question) async {
    print("🛑 Arrêt de l'enregistrement vocal...");
    _speech.stop();

    setState(() => _isRecording = false);
    print("ℹ️ _isRecording mis à false");

    print("📤 Envoi de la réponse vocale pour la question id=${question.id}");
    print("📝 Texte capturé : $_voiceText");

    _submitVoiceAnswer(
      question,
      _voiceText,
    ); // fonction pour envoyer la réponse
  }

  void _submitVoiceAnswer(Question question, String voiceText) async {
    final answerToSend = voiceText.trim();

    print(
      "📤 Préparation envoi réponse vocale : '$answerToSend' pour la question id=${question.id}",
    );

    if (answerToSend.isEmpty) {
      print("⚠️ Texte vide, rien à envoyer");
      return; // rien à envoyer
    }

    // Masque le clavier si besoin
    FocusScope.of(context).unfocus();

    bool localIsCorrect = false;
    List<String> localCorrectAnswers = [];
    int newTotalLessonPoints = _totalLessonPoints;

    if (!_isReviewMode) {
      print("🔄 Mode normal : envoi à l'API");
      final result = await apiService.checkAnswer(question.id, answerToSend);
      print("📦 Réponse de l'API : $result");

      if (result['correctAnswers'] != null &&
          result['correctAnswers'] is List) {
        localCorrectAnswers = List<String>.from(
          result['correctAnswers'].map((e) => e.toString()),
        );
        print("✅ CorrectAnswers reçues de l'API : $localCorrectAnswers");
      }

      localIsCorrect = result['isCorrect'] ?? false;
      print(
        "🔍 L'API a déterminé que la réponse est correcte ? $localIsCorrect",
      );

      if (result['totalLessonPoints'] != null) {
        newTotalLessonPoints = (result['totalLessonPoints'] as num).toInt();
        print("💰 Nouveau total de points de la leçon : $newTotalLessonPoints");
      }

      if (!localIsCorrect && !_incorrectQuestions.contains(question)) {
        _incorrectQuestions.add(question);
        print("⚠️ Question ajoutée à la liste des questions incorrectes");
      }
    } else {
      print("🔄 Mode révision : vérification locale");
      localIsCorrect = _checkAnswerLocally(question, answerToSend);
      print("🔍 Vérification locale : réponse correcte ? $localIsCorrect");

      localCorrectAnswers = question.answers
          .where((a) => a.isCorrect && a.text != null)
          .map((a) => a.text!.trim().toLowerCase())
          .toList();
      print("✅ CorrectAnswers locales : $localCorrectAnswers");

      if (localIsCorrect) {
        _incorrectQuestions.remove(question);
        print("✅ Question retirée de la liste des questions incorrectes");
      }
    }

    setState(() {
      _isCorrect = localIsCorrect;
      _correctAnswers = localCorrectAnswers;
      _totalLessonPoints = newTotalLessonPoints;
      _answerController.text = voiceText; // affiche le texte transcrit
    });

    print("🔊 Lecture du son de feedback");
    await _playSound(_isCorrect!);

    print("📢 Animation de feedback");
    await _feedbackController.forward(from: 0.0);
    print("✅ Traitement terminé pour la réponse vocale");
  }

  void _updateProgress(int totalLength, {bool initial = false}) {
    if (totalLength > 0) {
      final target = (_currentIndex + 1) / totalLength;

      // Assurez-vous que l'animation est correcte si la taille change (ex: passage au mode révision)
      if (_progressAnimation.value * totalLength != _currentIndex + 1 ||
          initial) {
        _progressAnimation = Tween<double>(
          begin: initial ? 0.0 : _progressAnimation.value,
          end: target,
        ).animate(_progressController);

        // Redémarre l'animation pour le nouveau segment
        if (!initial) {
          _progressController.forward(from: _progressAnimation.value);
        } else {
          // Pour le premier chargement, mettez simplement à jour la valeur.
          _progressController.value = target;
        }
      }
    }
  }

  @override
  void dispose() {
    _answerController.dispose();
    _winPlayer.dispose();
    _losePlayer.dispose();
    _questionAudioPlayer.dispose();
    _achievementPlayer.dispose();
    _flutterTts.stop();
    _progressController.dispose();
    _feedbackController.dispose();
    super.dispose();
  }

Future<void> _preloadSounds() async {
  try {
    await _winPlayer.setSource(AssetSource("win_question.mp3"));
    print("✅ Son de victoire préchargé");
  } catch (e) {
    print("❌ Erreur lors du préchargement du son de victoire : $e");
  }

  try {
    await _losePlayer.setSource(AssetSource("lost.mp3"));
    print("✅ Son de défaite préchargé");
  } catch (e) {
    print("❌ Erreur lors du préchargement du son de défaite : $e");
  }

  try {
    await _achievementPlayer.setSource(AssetSource("achievement.mp3"));
    print("✅ Son d'accomplissement préchargé");
  } catch (e) {
    print("❌ Erreur lors du préchargement du son d'accomplissement : $e");
  }
}

Future<void> _playSound(bool isCorrect) async {
  final player = isCorrect ? _winPlayer : _losePlayer;

  try {
    await player.stop();
    print("ℹ️ Son arrêté pour lecture");

    await player.resume();
    print("✅ Son joué avec succès (${isCorrect ? 'victoire' : 'défaite'})");
  } catch (e) {
    print("❌ Erreur lors de la lecture du son (${isCorrect ? 'victoire' : 'défaite'}): $e");
  }
}

  Future<void> _playAchievementSound() async {
    await _achievementPlayer.stop();
    // Re-joue car la source est déjà préchargée
    await _achievementPlayer.resume();
  }

  Future<void> _speakText(String text) async {
    await _flutterTts.stop();
    await _flutterTts.speak(text);
  }

  Future<void> _playQuestionAudio(Question question) async {
    if (question.audioPath != null && question.audioPath!.isNotEmpty) {
      // Remplacez 'localhost' par votre URL de base si nécessaire
      final url = "http://localhost:3000/${question.audioPath}";
      await _questionAudioPlayer.stop();
      await _questionAudioPlayer.play(UrlSource(url));
    } else {
      await _speakText(question.text);
    }
  }

  void _nextQuestion() async {
    // Cache la barre de feedback
    await _feedbackController.reverse();

    // Détermine la liste de questions actuelle pour la taille
    final questionsList = _isReviewMode
        ? _incorrectQuestions
        : await _questionsFuture;

    setState(() {
      _currentIndex++;
      _selectedChoice = null;
      _isCorrect = null;
      _correctAnswers = [];
      _answerController.clear();
      _hasSpoken = false;
      _selectedWords = []; // 👈 AJOUTEZ CETTE LIGNE
    });

    // Mise à jour de la progression pour la nouvelle question
    if (_currentIndex < questionsList.length) {
      _updateProgress(questionsList.length);
      // Prépare le TTS/Audio pour la nouvelle question si nécessaire
      final question = questionsList[_currentIndex];
      if (question.type == QuestionType.AUDIO_TO_TEXT ||
          question.type == QuestionType.AUDIO_TO_TRANSLATION) {
        _playQuestionAudio(question);
      }
    } else {
      // Fin de la leçon / révision
      if (_isReviewMode) {
        // Fin du mode révision
        _timeSpent = DateTime.now().difference(_startTime);
        _animatePoints();
      } else {
        // Fin de la première passe
        if (_incorrectQuestions.isNotEmpty) {
          _showReviewDialog();
        } else {
          _timeSpent = DateTime.now().difference(_startTime);
          _animatePoints();
        }
      }
    }
  }

  void _submitAnswer(Question question) async {
    final answerToSend = question.type == QuestionType.MULTIPLE_CHOICE
        ? (_selectedChoice ?? "")
        : _answerController.text.trim();

    // Prévention de l'envoi d'une réponse vide
    if (answerToSend.isEmpty && question.type != QuestionType.MULTIPLE_CHOICE)
      return;
    if (answerToSend.isEmpty &&
        question.type == QuestionType.MULTIPLE_CHOICE &&
        _selectedChoice == null)
      return;

    // Masque le clavier si c'est une question textuelle
    FocusScope.of(context).unfocus();

    bool localIsCorrect = false;
    List<String> localCorrectAnswers = [];
    int newTotalLessonPoints = _totalLessonPoints;
    bool needsApiCall = !_isReviewMode;
    bool isFirstTimeCorrect = false;

    if (needsApiCall) {
      // Appel API pour la première passe
      final result = await apiService.checkAnswer(question.id, answerToSend);

      if (result['correctAnswers'] != null &&
          result['correctAnswers'] is List) {
        localCorrectAnswers = List<String>.from(
          result['correctAnswers'].map((e) => e.toString()),
        );
      }
      localIsCorrect = result['isCorrect'] ?? false;

      if (result['totalLessonPoints'] != null) {
        newTotalLessonPoints = (result['totalLessonPoints'] as num).toInt();
      }

      // Stocke la question manquée si la réponse est fausse
      if (!localIsCorrect && !_incorrectQuestions.contains(question)) {
        _incorrectQuestions.add(question);
      }

      // Détecte si la réponse est correcte pour la première fois (si on veut marquer ce point)
      isFirstTimeCorrect = localIsCorrect;
    } else {
      // Mode révision : vérification locale
      localIsCorrect = _checkAnswerLocally(question, answerToSend);

      // Liste des bonnes réponses textuelles (sécurisée)
      localCorrectAnswers = question.answers
          .where((a) => a.isCorrect && a.text != null)
          .map((a) => a.text!.trim().toLowerCase())
          .toList();

      // En mode révision, si correct on retire la question
      if (localIsCorrect) {
        _incorrectQuestions.remove(question);
      }
    }

    setState(() {
      _isCorrect = localIsCorrect;
      _correctAnswers = localCorrectAnswers;
      _totalLessonPoints = newTotalLessonPoints;
    });

    await _playSound(_isCorrect!);
    await _feedbackController.forward(from: 0.0);
  }

  // Fonction de vérification locale pour le mode révision (utilise les données client)
  bool _checkAnswerLocally(Question question, String userAnswer) {
    final normalizedUser = userAnswer.trim().toLowerCase();

    // ---------------------------
    // 1️⃣ MULTIPLE_CHOICE
    // ---------------------------
    if (question.type == QuestionType.MULTIPLE_CHOICE) {
      final correctAnswer = question.answers.firstWhere(
        (a) => a.isCorrect,
        orElse: () => Answer(
          id: "0",
          questionId: question.id,
          text: "",
          isCorrect: false,
        ),
      );

      if (correctAnswer.text == null) return false;

      return correctAnswer.text!.trim().toLowerCase() == normalizedUser;
    }

    // ---------------------------
    // 2️⃣ VOICE_TO_TEXT
    // L'utilisateur parle → on compare la transcription texte
    // Certaines réponses peuvent avoir text = null
    // ---------------------------
    if (question.type == QuestionType.VOICE_TO_TEXT) {
      return question.answers.any((a) {
        if (!a.isCorrect || a.text == null) return false;

        return a.text!.trim().toLowerCase() == normalizedUser;
      });
    }

    // ---------------------------
    // 3️⃣ AUDIO_TO_TEXT
    // L'utilisateur écoute un audio → répond en texte
    // ---------------------------
    if (question.type == QuestionType.AUDIO_TO_TEXT ||
        question.type == QuestionType.AUDIO_TO_TRANSLATION) {
      return question.answers.any((a) {
        if (!a.isCorrect || a.text == null) return false;

        return a.text!.trim().toLowerCase() == normalizedUser;
      });
    }
    if (question.type == QuestionType.WORD_BUILDER) {
      return question.answers.any((a) {
        if (!a.isCorrect || a.text == null) return false;
        return a.text!.trim().toLowerCase() == normalizedUser;
      });
    }

    // ---------------------------
    // 4️⃣ TEXT (simple)
    // ---------------------------
    return question.answers.any((a) {
      if (!a.isCorrect || a.text == null) return false;

      return a.text!.trim().toLowerCase() == normalizedUser;
    });
  }

  void _showReviewDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Row(
          children: [
            Icon(Icons.auto_stories, color: Colors.orange, size: 28),
            SizedBox(width: 10),
            Text("Révision"),
          ],
        ),
        content: Text(
          "Vous avez ${_incorrectQuestions.length} question(s) à revoir. "
          "Voulez-vous les réviser maintenant ?\n\n"
          "Note : Le mode révision est pour l'apprentissage, il ne changera pas votre score actuel.",
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _timeSpent = DateTime.now().difference(_startTime);
              _animatePoints(); // Termine la leçon sans révision
            },
            child: const Text(
              "Non, terminer",
              style: TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _startReviewMode();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade600,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              "Oui, réviser",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _autoSpeakQuestion(Question question) async {
    if (_hasSpoken) return; // Empêche de lire deux fois
    _hasSpoken = true;

    // Si la question a un audio → joue l’audio
    if (question.audioPath != null && question.audioPath!.isNotEmpty) {
      final url = "http://localhost:3000/${question.audioPath}";
      await _questionAudioPlayer.stop();
      await _questionAudioPlayer.play(UrlSource(url));
    }
    // Sinon → lire le texte avec TTS
    else {
      await _speakText(question.text);
    }
  }

  void _startReviewMode() {
    setState(() {
      _isReviewMode = true;
      _currentIndex = 0;
      _selectedChoice = null;
      _isCorrect = null;
      _correctAnswers = [];
      _answerController.clear();
      _hasSpoken = false;
    });
    // Met à jour la progression pour la liste de révision
    _updateProgress(_incorrectQuestions.length, initial: true);

    // Démarre l'audio pour la première question de révision
    if (_incorrectQuestions.isNotEmpty) {
      final question = _incorrectQuestions[_currentIndex];
      if (question.type == QuestionType.AUDIO_TO_TEXT ||
          question.type == QuestionType.AUDIO_TO_TRANSLATION) {
        _playQuestionAudio(question);
      }
    }
  }

  void _animatePoints() {
    setState(() {
      _lessonFinished = true;
    });
    _animatedPoints = 0;
    Timer.periodic(const Duration(milliseconds: 30), (timer) {
      if (_animatedPoints >= _totalLessonPoints) {
        timer.cancel();
      } else {
        setState(() {
          _animatedPoints += (_totalLessonPoints / 50).ceil();
          if (_animatedPoints > _totalLessonPoints) {
            _animatedPoints = _totalLessonPoints;
          }
        });
      }
    });
    _playAchievementSound();
  }

  Widget _buildMultipleChoice(Question question) {
    return Column(
      children: question.answers.map((answer) {
        final answerText = answer.text;
        final isSelected = _selectedChoice == answerText;
        final isCorrectAnswer = _correctAnswers.contains(answerText);
        final bool isChecked = _isCorrect != null;

        Color getColor() {
          if (!isChecked) {
            return isSelected ? (Colors.green.shade100) : Colors.white;
          } else {
            if (isCorrectAnswer) return Colors.green.shade300;
            if (isSelected && !isCorrectAnswer) return Colors.red.shade300;
            return Colors.grey.shade100; // Couleur neutre après vérification
          }
        }

        Icon? getIcon() {
          if (!isChecked) {
            return isSelected
                ? const Icon(Icons.check_circle, color: Colors.green)
                : null;
          } else {
            if (isCorrectAnswer)
              return const Icon(Icons.check_circle, color: Colors.white);
            if (isSelected && !isCorrectAnswer)
              return const Icon(Icons.cancel, color: Colors.white);
            return null;
          }
        }

        Color getTextColor() {
          if (!isChecked) {
            return isSelected ? Colors.green.shade900 : Colors.black87;
          } else {
            if (isCorrectAnswer || (isSelected && !isCorrectAnswer))
              return Colors.white;
            return Colors.black87;
          }
        }

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6.0),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            decoration: BoxDecoration(
              color: getColor(),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isChecked
                    ? (isCorrectAnswer
                          ? Colors.green.shade600
                          : Colors.red.shade600)
                    : (isSelected
                          ? Colors.green.shade300
                          : Colors.grey.shade300),
                width: isSelected ? 2 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: Colors.green.withOpacity(0.2),
                        blurRadius: 5,
                      ),
                    ]
                  : [],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _isCorrect == null
                    ? () {
                        setState(() {
                          _selectedChoice = answerText;
                        });
                      }
                    : null,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          answerText!,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: getTextColor(),
                          ),
                        ),
                      ),
                      if (getIcon() != null)
                        Padding(
                          padding: const EdgeInsets.only(left: 10.0),
                          child: getIcon(),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTextField(Question question) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _answerController,
          enabled: _isCorrect == null,
          decoration: InputDecoration(
            labelText: "Votre réponse",
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: _isCorrect != null
                    ? (_isCorrect! ? Colors.green : Colors.red)
                    : Colors.grey.shade400,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade400, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: (_isReviewMode ? Colors.orange : Colors.green),
                width: 2,
              ),
            ),
            filled: true,
            fillColor: _isCorrect != null ? Colors.grey.shade50 : Colors.white,
          ),
          style: const TextStyle(fontSize: 17),
        ),

        const SizedBox(height: 15),

        // 🔘 VALIDATION BUTTON
        ElevatedButton(
          onPressed: _isCorrect == null ? () => _submitAnswer(question) : null,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            backgroundColor: Colors.green.shade700,
            foregroundColor: Colors.white,
            disabledBackgroundColor: Colors.grey.shade400,
          ),
          child: const Text(
            "Valider",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildResultsScreen() {
    final minutes = _timeSpent?.inMinutes ?? 0;
    final seconds = (_timeSpent?.inSeconds ?? 0) % 60;
    final primaryColor = Colors.lightGreen.shade700;
    final secondaryColor = Colors.amber.shade700;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [primaryColor, primaryColor.withOpacity(0.8)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),
                  // Trophée animé
                  TweenAnimationBuilder<double>(
                    duration: const Duration(milliseconds: 1000),
                    curve: Curves.elasticOut,
                    tween: Tween<double>(begin: 0.5, end: 1.0),
                    builder: (context, double value, child) {
                      return Transform.scale(
                        scale: value,
                        child: Icon(
                          Icons.emoji_events,
                          size: 140,
                          color: secondaryColor,
                          shadows: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 10,
                              offset: const Offset(5, 5),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 40),

                  // Titre
                  const Text(
                    "Leçon Complétée !",
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 15),
                  Text(
                    "Vous avez terminé ${widget.lesson.title}",
                    style: const TextStyle(fontSize: 18, color: Colors.white70),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 50),

                  // Carte des résultats
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(30),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 25,
                          offset: const Offset(0, 15),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Points obtenus
                        _buildResultRow(
                          icon: Icons.stars,
                          iconColor: secondaryColor,
                          label: "Points obtenus (XP)",
                          value: _animatedPoints.toString(),
                          valueStyle: TextStyle(
                            fontSize: 42,
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                        const Divider(height: 40, thickness: 1.5),

                        // Temps passé
                        _buildResultRow(
                          icon: Icons.access_time_filled,
                          iconColor: Colors.blue.shade600,
                          label: "Temps passé",
                          value: "${minutes}min ${seconds}s",
                          valueStyle: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 50),

                  // Bouton Continuer
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: primaryColor,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 60,
                        vertical: 20,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 8,
                    ),
                    child: const Text(
                      "Continuer l'Apprentissage",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResultRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required TextStyle valueStyle,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, color: iconColor, size: 30),
            const SizedBox(width: 15),
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        Text(value, style: valueStyle),
      ],
    );
  }

  Widget _buildQuestionContent(Question question, int totalQuestions) {
    return AnimatedBuilder(
      animation: _progressAnimation,
      builder: (context, child) {
        final bool isChecked = _isCorrect != null;

        return Stack(
          children: [
            Column(
              children: [
                // Progression et points
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 0,
                    vertical: 8.0,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: LinearProgressIndicator(
                          value: _progressAnimation.value,
                          backgroundColor: Colors.grey.shade300,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _isReviewMode
                                ? Colors.orange.shade600
                                : Colors.green.shade600,
                          ),
                          minHeight: 12,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Text(
                        '${_currentIndex + 1}/$totalQuestions',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Badge mode révision
                if (_isReviewMode)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.orange.shade300),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.refresh,
                            size: 16,
                            color: Colors.orange.shade600,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            "Mode Révision - Ne compte pas",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Carte de la question
                Card(
                  elevation: 5,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                question.text,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),

                            // Bouton audio (hors voice-to-text)
                            if (question.type != QuestionType.VOICE_TO_TEXT)
                              AnimatedOpacity(
                                opacity: isChecked ? 0.0 : 1.0,
                                duration: const Duration(milliseconds: 300),
                                child: IconButton(
                                  icon: Icon(
                                    Icons.volume_up,
                                    size: 30,
                                    color: _isReviewMode
                                        ? Colors.orange.shade600
                                        : Colors.green.shade600,
                                  ),
                                  onPressed: isChecked
                                      ? null
                                      : () => _playQuestionAudio(question),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // 🎯 CHOIX MULTIPLES
                        if (question.type == QuestionType.MULTIPLE_CHOICE)
                          _buildMultipleChoice(question),

                        // 🔥 BOUTON VALIDER POUR MULTIPLE CHOICE
                        if (question.type == QuestionType.MULTIPLE_CHOICE) ...[
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed:
                                (_selectedChoice != null && _isCorrect == null)
                                ? () => _submitAnswer(question)
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              "Valider",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],

                        // 🎯 CHAMPS TEXTE
                        if (question.type == QuestionType.TEXT ||
                            question.type == QuestionType.AUDIO_TO_TEXT ||
                            question.type == QuestionType.AUDIO_TO_TRANSLATION)
                          _buildTextField(question),
                        if (question.type == QuestionType.WORD_BUILDER)
                          _buildWordBuilder(question),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // 🔴 BOUTON VOICE_TO_TEXT (style WhatsApp)
            if (question.type == QuestionType.VOICE_TO_TEXT) ...[
              Positioned(
                bottom: 30,
                right: 30,
                child: GestureDetector(
                  // Mobile : long press
                  onLongPressStart: kIsWeb
                      ? null
                      : (_) => _startVoiceRecording(),
                  onLongPressEnd: kIsWeb
                      ? null
                      : (_) => _stopVoiceRecordingAndSubmit(question),
                  // Web : tap down/up
                  onTapDown: kIsWeb ? (_) => _startVoiceRecording() : null,
                  onTapUp: kIsWeb
                      ? (_) => _stopVoiceRecordingAndSubmit(question)
                      : null,
                  onTapCancel: kIsWeb
                      ? () {
                          if (_isRecording)
                            _stopVoiceRecordingAndSubmit(question);
                        }
                      : null,
                  child: Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: _isRecording ? Colors.red : Colors.green,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.mic, color: Colors.white, size: 36),
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  // Fonction complétée pour la barre de validation et de feedback
  Widget _buildBottomBar(Question question) {
    final bool isChecked = _isCorrect != null;
    final bool canSubmit = question.type == QuestionType.MULTIPLE_CHOICE
        ? (_selectedChoice != null)
        : _answerController.text.trim().isNotEmpty;

    final Color buttonColor = isChecked
        ? (_isCorrect! ? Colors.green.shade600 : Colors.red.shade600)
        : (canSubmit
              ? (_isReviewMode ? Colors.orange.shade600 : Colors.green.shade600)
              : Colors.grey.shade400);

    return SlideTransition(
      position: _feedbackOffsetAnimation,
      child: Container(
        padding: const EdgeInsets.only(
          top: 20,
          left: 24,
          right: 24,
          bottom: 40,
        ),
        decoration: BoxDecoration(
          color: isChecked
              ? (_isCorrect! ? Colors.green.shade100 : Colors.red.shade100)
              : Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isChecked)
              Padding(
                padding: const EdgeInsets.only(bottom: 10.0),
                child: Row(
                  children: [
                    Icon(
                      _isCorrect! ? Icons.check_circle : Icons.cancel,
                      color: _isCorrect!
                          ? Colors.green.shade700
                          : Colors.red.shade700,
                      size: 30,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isCorrect! ? "Correct !" : "Faux.",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: _isCorrect!
                                  ? Colors.green.shade700
                                  : Colors.red.shade700,
                            ),
                          ),
                          if (!_isCorrect! && _correctAnswers.isNotEmpty)
                            Text(
                              "La bonne réponse était : ${_correctAnswers.join(' / ')}",
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.red.shade700,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ElevatedButton(
              onPressed: isChecked
                  ? _nextQuestion
                  : (canSubmit ? () => _submitAnswer(question) : null),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 60),
                backgroundColor: buttonColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 5,
              ),
              child: Text(
                isChecked ? "Continuer >" : "Vérifier",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget de construction principal (le 'build' de la classe State)
  @override
  Widget build(BuildContext context) {
    // Si la leçon est terminée, affiche l'écran de résultats
    if (_lessonFinished) {
      return _buildResultsScreen();
    }

    // Sinon, affiche l'écran de la question
    return FutureBuilder<List<Question>>(
      future: _questionsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text("Erreur")),
            body: Center(
              child: Text(
                "Erreur de chargement des questions: ${snapshot.error}",
              ),
            ),
          );
        }

        List<Question> questions = _isReviewMode
            ? _incorrectQuestions
            : (snapshot.data ?? []);
        final int totalQuestions = questions.length;

        if (totalQuestions == 0) {
          return Scaffold(
            appBar: AppBar(title: Text(widget.lesson.title)),
            body: const Center(
              child: Text("Aucune question disponible pour cette leçon."),
            ),
          );
        }

        // Index sécurisé
        final Question currentQuestion =
            questions[_currentIndex.clamp(0, totalQuestions - 1)];

        // 🔊🔥 Lecture automatique juste ici
        _autoSpeakQuestion(currentQuestion);

        return Scaffold(
          appBar: AppBar(
            title: Text(_isReviewMode ? "Révision" : widget.lesson.title),
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
            ),
            backgroundColor: _isReviewMode
                ? Colors.orange.shade600
                : Colors.green.shade600,
            foregroundColor: Colors.white,
          ),
          body: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 10.0,
                ),
                child: SingleChildScrollView(
                  child: _buildQuestionContent(currentQuestion, totalQuestions),
                ),
              ),

              // Barre en bas
              Align(
                alignment: Alignment.bottomCenter,
                child: _buildBottomBar(currentQuestion),
              ),
            ],
          ),
        );
      },
    );
  }
}
