import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rive/rive.dart' hide LinearGradient;
import '../../../core/services/api_service.dart';
import '../../../data/models/language.dart';
import 'goal_screen.dart';

class LanguageScreen extends StatefulWidget {
  final String userId;
  final String token;
  
  const LanguageScreen({
    super.key,
    required this.userId,
    required this.token,
  });

  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> with SingleTickerProviderStateMixin {
  final ApiService api = ApiService();
  List<Language> languages = [];
  String? selectedLanguageId;
  bool loading = true;
  bool saving = false;
  String? errorMessage;
  
  // Rive animation
  SMIInput<double>? _lookX;
  SMIInput<double>? _lookY;
  StateMachineController? _controller;
  
  // Animation
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );
    _initializeAndLoadLanguages();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _controller?.dispose();
    super.dispose();
  }

  void _onRiveInit(Artboard artboard) {
    final controller = StateMachineController.fromArtboard(
      artboard,
      'State Machine 1', // Remplacez par le nom de votre state machine
    );
    
    if (controller != null) {
      artboard.addController(controller);
      _controller = controller;
      _lookX = controller.findInput<double>('lookX');
      _lookY = controller.findInput<double>('lookY');
    }
  }

  void _moveEyes(Offset globalPosition) {
    if (_lookX == null || _lookY == null) return;
    
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    
    final localPosition = renderBox.globalToLocal(globalPosition);
    final size = renderBox.size;
    
    // Normaliser les coordonnées entre -1 et 1
    final x = (localPosition.dx / size.width) * 2 - 1;
    final y = (localPosition.dy / size.height) * 2 - 1;
    
    _lookX?.value = x.clamp(-1.0, 1.0);
    _lookY?.value = y.clamp(-1.0, 1.0);
  }

  Future<void> _initializeAndLoadLanguages() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('jwt_token', widget.token);
    await loadLanguages();
  }

  Future<void> loadLanguages() async {
    try {
      final langs = await api.fetchLanguages();
      setState(() {
        languages = langs;
        loading = false;
        errorMessage = null;
      });
      _fadeController.forward();
    } catch (e) {
      setState(() {
        loading = false;
        errorMessage = 'Erreur lors du chargement des langues: ${e.toString()}';
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage!),
            backgroundColor: const Color(0xFFE63946),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> saveAndContinue() async {
    if (selectedLanguageId == null) return;

    setState(() => saving = true);

    try {
      final success = await api.createUserPreference(
        widget.userId,
        selectedLanguageId!,
        goalId: null,
        referralSourceId: null,
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
            backgroundColor: const Color(0xFFE63946),
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
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Rive Animation Header
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF2D6A4F), Color(0xFF52B788)],
                ),
              ),
              child: Stack(
                children: [
                  // Animation Rive
                  Positioned.fill(
                    child: RiveAnimation.asset(
                      'assets/animations/animal.rive',
                      fit: BoxFit.contain,
                      onInit: _onRiveInit,
                    ),
                  ),
                  // Titre par-dessus
                  Positioned(
                    bottom: 20,
                    left: 24,
                    right: 24,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Quelle langue\nveux-tu apprendre ?',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            height: 1.2,
                            shadows: [
                              Shadow(
                                color: Colors.black.withOpacity(0.3),
                                offset: const Offset(0, 2),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: loading
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              const Color(0xFF2D6A4F),
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Chargement des langues...',
                            style: TextStyle(
                              color: Color(0xFF52B788),
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    )
                  : errorMessage != null
                      ? _buildErrorView()
                      : languages.isEmpty
                          ? _buildEmptyView()
                          : _buildLanguageList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFFFE66D).withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline,
                color: Color(0xFFE63946),
                size: 64,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF1B4332),
              ),
            ),
            const SizedBox(height: 32),
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
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2D6A4F),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFFFE66D).withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.language,
              size: 64,
              color: Color(0xFF52B788),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Aucune langue disponible',
            style: TextStyle(
              fontSize: 18,
              color: Color(0xFF1B4332),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: loadLanguages,
            icon: const Icon(Icons.refresh),
            label: const Text('Actualiser'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2D6A4F),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageList() {
    return Column(
      children: [
        Expanded(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: languages.length,
              itemBuilder: (context, index) {
                final lang = languages[index];
                final isSelected = selectedLanguageId == lang.id;
                
                return GestureDetector(
                  onTapDown: (details) => _moveEyes(details.globalPosition),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? const LinearGradient(
                              colors: [Color(0xFF2D6A4F), Color(0xFF52B788)],
                            )
                          : null,
                      color: isSelected ? null : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? Colors.transparent
                            : const Color(0xFFD8F3DC),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isSelected
                              ? const Color(0xFF2D6A4F).withOpacity(0.3)
                              : Colors.black.withOpacity(0.05),
                          blurRadius: isSelected ? 12 : 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () {
                          setState(() => selectedLanguageId = lang.id);
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Row(
                            children: [
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? Colors.white.withOpacity(0.2)
                                      : const Color(0xFFFFE66D).withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Center(
                                  child: Text(
                                    lang.name[0].toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: isSelected
                                          ? Colors.white
                                          : const Color(0xFF2D6A4F),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  lang.name,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: isSelected
                                        ? Colors.white
                                        : const Color(0xFF1B4332),
                                  ),
                                ),
                              ),
                              if (isSelected)
                                const Icon(
                                  Icons.check_circle,
                                  color: Colors.white,
                                  size: 28,
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        
        // Bottom Button
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
          child: GestureDetector(
            onTapDown: (details) => _moveEyes(details.globalPosition),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: selectedLanguageId == null || saving
                    ? null
                    : saveAndContinue,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFE66D),
                  foregroundColor: const Color(0xFF1B4332),
                  disabledBackgroundColor: Colors.grey[300],
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  shadowColor: const Color(0xFFFFE66D).withOpacity(0.5),
                ),
                child: saving
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Color(0xFF1B4332),
                          ),
                        ),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Continuer",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward, size: 24),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}