import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:reality_cart/openingphase/login_screen.dart';
import 'package:reality_cart/user/shipping_address_screen.dart';
import 'package:reality_cart/user/payment_method_screen.dart';
import 'package:reality_cart/user/my_orders_screen.dart';
import 'package:reality_cart/user/help_support_screen.dart';
import 'package:reality_cart/user/settings_screen.dart';
import 'package:reality_cart/user/wishlist_screen.dart';
import 'package:reality_cart/l10n/app_localizations.dart';
import 'package:reality_cart/widgets/translated_text.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final User? _user = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_user == null) {
      return Scaffold(
        body: Center(child: Text(AppLocalizations.of(context)!.pleaseLoginToViewProfile)),
      );
    }

    return Scaffold(
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(_user!.uid).snapshots(),
        builder: (context, snapshot) {
          String userName = AppLocalizations.of(context)!.userName;
          String userEmail = _user!.email ?? "user@example.com";

          if (snapshot.hasData && snapshot.data!.exists) {
            final data = snapshot.data!.data() as Map<String, dynamic>;
            userName = data['name'] ?? userName;
            userEmail = data['email'] ?? userEmail;
          }

          return SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: theme.disabledColor.withOpacity(0.1),
                    child: Icon(Icons.person, size: 50, color: theme.iconTheme.color),
                  ),
                  const SizedBox(height: 15),
                  Text(
                    userName,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    userEmail,
                    style: TextStyle(fontSize: 14, color: theme.textTheme.bodySmall?.color),
                  ),
                  const SizedBox(height: 30),
                  _buildProfileOption(context, Icons.shopping_bag_outlined, AppLocalizations.of(context)!.myOrders, () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const MyOrdersScreen()),
                    );
                  }),
                  _buildProfileOption(context, Icons.favorite_border, AppLocalizations.of(context)!.myWishlist, () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const WishlistScreen()),
                    );
                  }),
                  _buildProfileOption(context, Icons.location_on_outlined, AppLocalizations.of(context)!.shippingAddresses, () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ShippingAddressScreen(),
                      ),
                    );
                  }),
                  _buildProfileOption(context, Icons.payment_outlined, AppLocalizations.of(context)!.paymentMethods, () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const PaymentMethodScreen()),
                    );
                  }),
                  _buildProfileOption(context, Icons.settings_outlined, AppLocalizations.of(context)!.settings, () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SettingsScreen()),
                    );
                  }),
                  _buildProfileOption(context, Icons.help_outline, AppLocalizations.of(context)!.helpAndSupport, () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const HelpSupportScreen()),
                    );
                  }),
                  const SizedBox(height: 20),
                  _buildProfileOption(context, Icons.logout, AppLocalizations.of(context)!.logout, () async {
                    await FirebaseAuth.instance.signOut();
                    if (mounted) {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (context) => const LoginScreen()),
                        (route) => false,
                      );
                    }
                  }, textColor: Colors.red, iconColor: Colors.red),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileOption(BuildContext context, IconData icon, String title, VoidCallback onTap,
      {Color? textColor, Color? iconColor}) {
    final theme = Theme.of(context);
    return Container(
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
      child: ListTile(
        leading: Icon(icon, color: iconColor ?? const Color(0xFFFB8C00)),
        title: Text(
          title,
          style: TextStyle(
            color: textColor ?? theme.textTheme.titleMedium?.color,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: Icon(Icons.arrow_forward_ios, size: 16, color: theme.disabledColor),
        onTap: onTap,
      ),
    );
  }
}
