import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'package:reality_cart/l10n/app_localizations.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  List<Map<String, dynamic>> _getLocalizedOnboardingData(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return [
      {
        "title": l10n.onboardingTitle1,
        "description": l10n.onboardingDesc1,
        "image": "assets/images/app_logo.png",
      },
      {
        "title": l10n.onboardingTitle2,
        "description": l10n.onboardingDesc2,
        "icon": Icons.shopping_bag_outlined,
      },
      {
        "title": l10n.onboardingTitle3,
        "description": l10n.onboardingDesc3,
        "icon": Icons.local_shipping_outlined,
      },
    ];
  }

  void _onNext(int dataLength) {
    if (_currentPage < dataLength - 1) {
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
    final onboardingData = _getLocalizedOnboardingData(context);
    final l10n = AppLocalizations.of(context)!;
    int currentStep = _currentPage + 1;
    int totalSteps = onboardingData.length;
    double progress = currentStep / totalSteps;
    const Color orangeColor = Color(0xFFFB8C00);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
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
                  if (_currentPage < onboardingData.length - 1)
                    TextButton(
                      onPressed: _onGetStarted,
                      child: Text(
                        l10n.skip,
                        style: const TextStyle(
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
                itemCount: onboardingData.length,
                itemBuilder: (context, index) => OnboardingContent(
                  title: onboardingData[index]["title"],
                  description: onboardingData[index]["description"],
                  icon: onboardingData[index]["icon"],
                  image: onboardingData[index]["image"],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () => _onNext(onboardingData.length),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: orangeColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  child: Text(
                    _currentPage == onboardingData.length - 1 ? l10n.getStarted : l10n.next,
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
