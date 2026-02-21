import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  final List<Map<String, String>> _faqs = const [
    {
      "question": "How do I track my order?",
      "answer": "You can track your order by going to the 'My Orders' section in your profile and selecting the order you want to track."
    },
    {
      "question": "What is the return policy?",
      "answer": "We offer a 30-day return policy for all unused items in their original packaging. Please contact support to initiate a return."
    },
    {
      "question": "How can I change my shipping address?",
      "answer": "You can manage your shipping addresses in the 'Shipping Addresses' section of your profile."
    },
    {
      "question": "Do you offer international shipping?",
      "answer": "Yes, we ship to select international destinations. Shipping costs and times vary by location."
    },
  ];

  Future<void> _contactSupport(BuildContext context, String method) async {
    Uri? uri;
    if (method == "Email") {
      uri = Uri.parse("mailto:spharsh32@gmail.com?subject=Support Request&body=Hi Support Team,");
    } else if (method == "Phone") {
      uri = Uri.parse("tel:+919998312146");
    }

    if (uri != null) {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Could not launch $method support")),
          );
        }
      }
    } else if (method == "Chat") {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Live Chat feature coming soon!")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text("Help & Support", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                "Frequently Asked Questions",
                style: TextStyle(
                  fontSize: 18, 
                  fontWeight: FontWeight.bold,
                  color: theme.textTheme.titleLarge?.color,
                ),
              ),
            ),
            ..._faqs.map((faq) => Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ExpansionTile(
                iconColor: const Color(0xFFFB8C00),
                collapsedIconColor: theme.disabledColor,
                title: Text(
                  faq['question']!,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: theme.textTheme.titleMedium?.color,
                  ),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Text(
                      faq['answer']!,
                      style: TextStyle(color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7)),
                    ),
                  ),
                ],
              ),
            )),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 30, 20, 10),
              child: Text(
                "Contact Us",
                style: TextStyle(
                  fontSize: 18, 
                  fontWeight: FontWeight.bold,
                  color: theme.textTheme.titleLarge?.color,
                ),
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.email_outlined, color: Color(0xFFFB8C00)),
                    title: Text(
                      "Email Support",
                      style: TextStyle(color: theme.textTheme.titleMedium?.color),
                    ),
                    subtitle: Text(
                      "spharsh32@gmail.com",
                      style: TextStyle(color: theme.textTheme.bodySmall?.color),
                    ),
                    trailing: Icon(Icons.arrow_forward_ios, size: 16, color: theme.disabledColor),
                    onTap: () => _contactSupport(context, "Email"),
                  ),
                  Divider(height: 1, color: theme.dividerColor.withOpacity(0.1)),
                  ListTile(
                    leading: const Icon(Icons.phone_outlined, color: Color(0xFFFB8C00)),
                    title: Text(
                      "Call Us",
                      style: TextStyle(color: theme.textTheme.titleMedium?.color),
                    ),
                    subtitle: Text(
                      "+91 99983 12146",
                      style: TextStyle(color: theme.textTheme.bodySmall?.color),
                    ),
                    trailing: Icon(Icons.arrow_forward_ios, size: 16, color: theme.disabledColor),
                    onTap: () => _contactSupport(context, "Phone"),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
