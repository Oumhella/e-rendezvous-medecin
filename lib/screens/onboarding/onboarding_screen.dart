import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../home_screen.dart';

class OnboardingData {
  final Color bgColor;
  final Color circleColor;
  final IconData icon;
  final Color iconColor;
  final Color titleColor;
  final Color subtitleColor;
  final String title;
  final String subtitle;
  final bool isLast;
  final bool hasHeartOverlay;

  OnboardingData({
    required this.bgColor,
    required this.circleColor,
    required this.icon,
    required this.iconColor,
    required this.titleColor,
    required this.subtitleColor,
    required this.title,
    required this.subtitle,
    this.isLast = false,
    this.hasHeartOverlay = false,
  });
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  late AnimationController _bgAnimationController;
  late Animation<Color?> _bgColorAnimation;

  final List<OnboardingData> _slides = [
    OnboardingData(
      bgColor: const Color(0xFF1B4A4A), // dark teal
      circleColor: const Color(0xFF2A5E5E), // lighter teal
      icon: Icons.medical_services_outlined,
      iconColor: Colors.white,
      titleColor: Colors.white,
      subtitleColor: Colors.white.withOpacity(0.8),
      title: "Trouvez votre médecin",
      subtitle: "Des spécialistes près de chez vous",
      isLast: false,
    ),
    OnboardingData(
      bgColor: const Color(0xFFF9B90E), // amber
      circleColor: const Color(0xFFFAD06A), // lighter amber
      icon: Icons.calendar_month_outlined,
      iconColor: const Color(0xFF1A1A1A), // dark
      titleColor: const Color(0xFF1A1A1A),
      subtitleColor: const Color(0xFF3A3A3A),
      title: "Réservez facilement",
      subtitle: "Choisissez votre créneau en 2 clics",
      isLast: false,
      hasHeartOverlay: true,
    ),
    OnboardingData(
      bgColor: const Color(0xFFFBEBDC), // cream
      circleColor: const Color(0xFFEDD9C8), // darker cream
      icon: Icons.notifications_active_outlined,
      iconColor: const Color(0xFF1B4A4A), // dark teal
      titleColor: const Color(0xFF1B4A4A),
      subtitleColor: const Color(0xFF5A5A5A),
      title: "Rappels intelligents",
      subtitle: "Ne ratez plus jamais un rendez-vous",
      isLast: true,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _bgAnimationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _bgColorAnimation = ColorTween(
      begin: _slides[0].bgColor,
      end: _slides[0].bgColor,
    ).animate(_bgAnimationController);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _bgAnimationController.dispose();
    super.dispose();
  }

  Color _getInactiveDotColor(int slideIndex) {
    switch (slideIndex) {
      case 0: // dark teal bg
        return Colors.white.withOpacity(0.35);
      case 1: // amber bg
        return Colors.black.withOpacity(0.25);
      case 2: // cream bg
        return const Color(0xFF1B4A4A).withOpacity(0.25);
      default:
        return Colors.white.withOpacity(0.35);
    }
  }

  void _nextPage() {
    if (_currentPage < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    }
  }

  Widget _buildIcon(OnboardingData slide) {
    if (slide.hasHeartOverlay) {
      // Slide 2: Calendar + Heart
      return Container(
        width: 160,
        height: 160,
        decoration: BoxDecoration(
          color: slide.circleColor,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: SizedBox(
            width: 80,
            height: 80,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  Icons.calendar_month_outlined,
                  size: 72,
                  color: slide.iconColor,
                ),
                Positioned(
                  bottom: 2,
                  right: 2,
                  child: Icon(
                    Icons.favorite,
                    size: 24,
                    color: slide.iconColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Default icon
    return Container(
      width: 160,
      height: 160,
      decoration: BoxDecoration(
        color: slide.circleColor,
        shape: BoxShape.circle,
      ),
      child: Icon(
        slide.icon,
        size: 72,
        color: slide.iconColor,
      ),
    );
  }

  Widget _buildButton(OnboardingData slide) {
    if (slide.isLast) {
      // Slide 3: Filled amber button
      return SizedBox(
        width: double.infinity,
        height: 58,
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFF9B90E),
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(50),
            ),
          ),
          label: Text(
            "Commencer",
            style: GoogleFonts.inter(
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
          icon: const Icon(Icons.arrow_forward, size: 18),
          onPressed: () => Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          ),
        ),
      );
    } else if (_currentPage == 1) {
      // Slide 2: TextButton (no border, no bg)
      return GestureDetector(
        onTap: _nextPage,
        child: Container(
          width: double.infinity,
          height: 58,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Suivant",
                style: GoogleFonts.inter(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: slide.titleColor,
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.arrow_forward,
                size: 18,
                color: slide.titleColor,
              ),
            ],
          ),
        ),
      );
    } else {
      // Slide 1: OutlinedButton
      return SizedBox(
        width: double.infinity,
        height: 58,
        child: OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            side: const BorderSide(
              color: Colors.white,
              width: 2,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(50),
            ),
          ),
          icon: const SizedBox.shrink(),
          label: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Suivant",
                style: GoogleFonts.inter(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward, size: 18),
            ],
          ),
          onPressed: _nextPage,
        ),
      );
    }
  }

  Widget _buildSlide(int index) {
    final slide = _slides[index];
    
    return AnimatedBuilder(
      animation: _bgColorAnimation,
      builder: (context, child) {
        return Container(
          color: slide.bgColor,
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(height: 60),

                // CENTER — Icon + Texts
                Column(
                  children: [
                    // Icon Circle with animation
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 400),
                      transitionBuilder: (child, animation) => ScaleTransition(
                        scale: animation,
                        child: FadeTransition(
                          opacity: animation,
                          child: child,
                        ),
                      ),
                      child: _buildIcon(slide),
                    ),

                    const SizedBox(height: 52),

                    // Title
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      switchInCurve: Curves.easeIn,
                      child: Padding(
                        key: ValueKey('title_$index'),
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          slide.title,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                            color: slide.titleColor,
                            height: 1.25,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    // Subtitle
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      switchInCurve: Curves.easeIn,
                      child: Padding(
                        key: ValueKey('subtitle_$index'),
                        padding: const EdgeInsets.symmetric(horizontal: 40),
                        child: Text(
                          slide.subtitle,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            color: slide.subtitleColor,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                // BOTTOM — Dots + Button
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
                  child: Column(
                    children: [
                      // Dots Indicator
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(3, (i) => AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          margin: const EdgeInsets.symmetric(horizontal: 5),
                          width: i == _currentPage ? 28 : 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: i == _currentPage
                                ? const Color(0xFFF9B90E)     // amber active
                                : _getInactiveDotColor(i),   // varies by slide
                            borderRadius: BorderRadius.circular(50),
                          ),
                        )),
                      ),

                      const SizedBox(height: 32),

                      // Button
                      _buildButton(slide),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView.builder(
        controller: _pageController,
        itemCount: 3,
        onPageChanged: (index) {
          setState(() {
            _currentPage = index;
            // Animate background color transition
            _bgColorAnimation = ColorTween(
              begin: _bgColorAnimation.value,
              end: _slides[index].bgColor,
            ).animate(CurvedAnimation(
              parent: _bgAnimationController,
              curve: Curves.easeInOut,
            ));
            _bgAnimationController.forward(from: 0.0);
          });
        },
        itemBuilder: (context, index) => _buildSlide(index),
      ),
    );
  }
}
