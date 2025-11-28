import 'package:flutter/material.dart';
import 'package:rive/rive.dart' hide LinearGradient;
import 'package:KmerLingo/presentation/screens/userDashboard_screen.dart';
import '../../../core/services/api_service.dart';
import '../../../data/models/referral_source.dart';

class ReferralSourceScreen extends StatefulWidget {
  final String userId;
  final String languageId;
  final String goalId;
  const ReferralSourceScreen({
    super.key,
    required this.userId,
    required this.languageId,
    required this.goalId,
  });

  @override
  State<ReferralSourceScreen> createState() => _ReferralSourceScreenState();
}

class _ReferralSourceScreenState extends State<ReferralSourceScreen> with SingleTickerProviderStateMixin {
  final ApiService api = ApiService();
  List<ReferralSource> sources = [];
  String? selectedSourceId;
  bool loading = true;
  bool saving = false;
  
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
    loadSources();
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
      'State Machine 1',
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
    
    final x = (localPosition.dx / size.width) * 2 - 1;
    final y = (localPosition.dy / size.height) * 2 - 1;
    
    _lookX?.value = x.clamp(-1.0, 1.0);
    _lookY?.value = y.clamp(-1.0, 1.0);
  }

  Future<void> loadSources() async {
    try {
      final res = await api.fetchReferralSources();
      setState(() {
        sources = res;
        loading = false;
      });
      _fadeController.forward();
    } catch (e) {
      setState(() {
        loading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: const Color(0xFFE63946),
          ),
        );
      }
    }
  }

  Future<void> finishOnboarding() async {
    if (selectedSourceId == null) return;

    setState(() => saving = true);

    try {
      await api.updateUserPreference(
        widget.userId,
        sourceId: selectedSourceId!,
      );

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => MainScreen(userId: widget.userId),
          ),
        );
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

  IconData _getSourceIcon(String sourceLabel) {
    final label = sourceLabel.toLowerCase();
    if (label.contains('social') || label.contains('facebook') || 
        label.contains('instagram') || label.contains('twitter')) {
      return Icons.share;
    }
    if (label.contains('friend') || label.contains('ami')) return Icons.people;
    if (label.contains('ad') || label.contains('pub')) return Icons.campaign;
    if (label.contains('search') || label.contains('google')) return Icons.search;
    if (label.contains('store') || label.contains('app')) return Icons.apps;
    return Icons.info;
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
                  colors: [Color(0xFF74C69D), Color(0xFFB7E4C7)],
                ),
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: RiveAnimation.asset(
                      'assets/animations/animal.rive',
                      fit: BoxFit.contain,
                      onInit: _onRiveInit,
                    ),
                  ),
                  Positioned(
                    bottom: 20,
                    left: 24,
                    right: 24,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Comment nous\nas-tu connu ?',
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
                        const SizedBox(height: 8),
                        Text(
                          'Dernière étape !',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white.withOpacity(0.9),
                            fontWeight: FontWeight.w500,
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
                              const Color(0xFF74C69D),
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Chargement...',
                            style: TextStyle(
                              color: Color(0xFF74C69D),
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    )
                  : FadeTransition(
                      opacity: _fadeAnimation,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: sources.length,
                        itemBuilder: (context, index) {
                          final src = sources[index];
                          final isSelected = selectedSourceId == src.id;
                          
                          return GestureDetector(
                            onTapDown: (details) => _moveEyes(details.globalPosition),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                gradient: isSelected
                                    ? const LinearGradient(
                                        colors: [Color(0xFF74C69D), Color(0xFF95D5B2)],
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
                                        ? const Color(0xFF74C69D).withOpacity(0.3)
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
                                    setState(() => selectedSourceId = src.id);
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
                                          child: Icon(
                                            _getSourceIcon(src.label),
                                            color: isSelected
                                                ? Colors.white
                                                : const Color(0xFF2D6A4F),
                                            size: 28,
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Text(
                                            src.label,
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
                    onPressed: selectedSourceId == null || saving
                        ? null
                        : finishOnboarding,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFE66D),
                      foregroundColor: const Color(0xFF1B4332),
                      disabledBackgroundColor: Colors.grey[300],
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
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
                                "Commencer !",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(width: 8),
                              Icon(Icons.celebration, size: 24),
                            ],
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}