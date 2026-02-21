import 'package:flutter/material.dart';
import 'login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, dynamic>> _onboardingData = [
    {
      "title": "Welcome to Reality Cart",
      "description": "Experience shopping like never before with Augmented Reality.",
      "image": "assets/images/app_logo.png",
    },
    {
      "title": "Try Before You Buy",
      "description": "Visualize products in your own space to make confident decisions.",
      "icon": Icons.shopping_bag_outlined,
    },
    {
      "title": "Fast & Secure",
      "description": "Enjoy seamless checkout and reliable delivery right to your door.",
      "icon": Icons.local_shipping_outlined,
    },
  ];

  void _onNext() {
    if (_currentPage < _onboardingData.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeIn,
      );
    } else {
      _onGetStarted();
    }
  }

  void _onGetStarted() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => const LoginScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    int currentStep = _currentPage + 1;
    int totalSteps = _onboardingData.length;
    double progress = currentStep / totalSteps;
    const Color orangeColor = Color(0xFFFB8C00);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "ONBOARDING",
                    style: TextStyle(
                      color: orangeColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      letterSpacing: 1.2,
                    ),
                  ),
                  if (_currentPage < _onboardingData.length - 1)
                    TextButton(
                      onPressed: _onGetStarted,
                      child: const Text(
                        "Skip",
                        style: TextStyle(
                          color: orangeColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  else
                    const SizedBox.shrink(),
                ],
              ),
            ),
            // Progress Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: orangeColor.withOpacity(0.1),
                color: orangeColor,
                minHeight: 6,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (value) {
                  setState(() {
                    _currentPage = value;
                  });
                },
                itemCount: _onboardingData.length,
                itemBuilder: (context, index) => OnboardingContent(
                  title: _onboardingData[index]["title"],
                  description: _onboardingData[index]["description"],
                  icon: _onboardingData[index]["icon"],
                  image: _onboardingData[index]["image"],
                ),
              ),
            ),
            
            // Bottom Button
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _onNext,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: orangeColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  child: Text(
                    _currentPage == _onboardingData.length - 1 ? "Get Started" : "Next",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
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

class OnboardingContent extends StatelessWidget {
  final String title;
  final String description;
  final IconData? icon;
  final String? image;

  const OnboardingContent({
    super.key,
    required this.title,
    required this.description,
    this.icon,
    this.image,
  });

  @override
  Widget build(BuildContext context) {
    const Color orangeColor = Color(0xFFFB8C00);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (image != null)
             Image.asset(
              image!,
              height: 200,
            )
          else
            Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                 color: orangeColor.withOpacity(0.2),
                 shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 80,
                color: orangeColor,
              ),
            ),
          const SizedBox(height: 48),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Theme.of(context).textTheme.headlineMedium?.color,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            description,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
