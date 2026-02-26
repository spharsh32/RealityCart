import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:reality_cart/providers/theme_provider.dart';
import 'package:reality_cart/openingphase/login_screen.dart';
import 'package:reality_cart/l10n/app_localizations.dart';

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  bool _notificationsEnabled = true;
  final User? _user = FirebaseAuth.instance.currentUser;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadAdminPreferences();
  }

  Future<void> _loadAdminPreferences() async {
    if (_user != null) {
      final doc = await FirebaseFirestore.instance.collection('admins').doc(_user!.uid).get();
      if (doc.exists && mounted) {
        setState(() {
          _notificationsEnabled = doc.data()?['notifications'] ?? true;
        });
      }
    }
  }

  Future<void> _updatePreference(String key, dynamic value) async {
    if (_user != null) {
      await FirebaseFirestore.instance.collection('admins').doc(_user!.uid).set({
        key: value,
      }, SetOptions(merge: true));
    }
  }

  Future<void> _changePassword() async {
    final _formKey = GlobalKey<FormState>();
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    bool oldPasswordVisible = false;
    bool newPasswordVisible = false;
    bool confirmPasswordVisible = false;

    double passwordStrength = 0;
    String strengthText = AppLocalizations.of(context)!.enterPassword;
    Color strengthColor = Colors.grey;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final theme = Theme.of(context);
        return StatefulBuilder(
          builder: (context, setDialogState) {

            void checkPasswordStrength(String value) {
              double strength = 0;
              if (value.length >= 8) strength += 0.25;
              if (RegExp(r'[A-Z]').hasMatch(value)) strength += 0.25;
              if (RegExp(r'[0-9]').hasMatch(value)) strength += 0.25;
              if (RegExp(r'[!@#\$&*~]').hasMatch(value)) strength += 0.25;

              setDialogState(() {
                passwordStrength = strength;
                if (strength <= 0.25) {
                  strengthText = AppLocalizations.of(context)!.pwdWeak;
                  strengthColor = Colors.red;
                } else if (strength <= 0.5) {
                  strengthText = AppLocalizations.of(context)!.pwdMedium;
                  strengthColor = Colors.orange;
                } else if (strength <= 0.75) {
                  strengthText = AppLocalizations.of(context)!.pwdGood;
                  strengthColor = Colors.blue;
                } else {
                  strengthText = AppLocalizations.of(context)!.pwdStrong;
                  strengthColor = Colors.green;
                }
              });
            }

            Widget buildCheckItem(String text, bool isValid) {
              return Row(
                children: [
                  Icon(
                    isValid ? Icons.check_circle : Icons.radio_button_unchecked,
                    size: 18,
                    color: isValid ? Colors.green : theme.disabledColor,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    text,
                    style: TextStyle(
                      color: isValid ? Colors.green : theme.disabledColor,
                      fontSize: 12,
                    ),
                  ),
                ],
              );
            }

            return AlertDialog(
              backgroundColor: theme.dialogBackgroundColor,
              title: Text(AppLocalizations.of(context)!.changePasswordTitle),
              content: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: oldPasswordController,
                        obscureText: !oldPasswordVisible,
                        decoration: InputDecoration(
                          labelText: AppLocalizations.of(context)!.oldPassword,
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(oldPasswordVisible ? Icons.visibility : Icons.visibility_off),
                            onPressed: () => setDialogState(() => oldPasswordVisible = !oldPasswordVisible),
                          ),
                        ),
                        validator: (value) => (value == null || value.isEmpty) ? AppLocalizations.of(context)!.enterOldPassword : null,
                      ),
                      const SizedBox(height: 15),
                      TextFormField(
                        controller: newPasswordController,
                        obscureText: !newPasswordVisible,
                        onChanged: checkPasswordStrength,
                        decoration: InputDecoration(
                          labelText: AppLocalizations.of(context)!.newPassword,
                          prefixIcon: const Icon(Icons.lock),
                          suffixIcon: IconButton(
                            icon: Icon(newPasswordVisible ? Icons.visibility : Icons.visibility_off),
                            onPressed: () => setDialogState(() => newPasswordVisible = !newPasswordVisible),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) return AppLocalizations.of(context)!.enterNewPassword;
                          if (value.length < 8) return AppLocalizations.of(context)!.min8Chars;
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: passwordStrength,
                        backgroundColor: theme.dividerColor,
                        color: strengthColor,
                        minHeight: 6,
                      ),
                      const SizedBox(height: 5),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(strengthText, style: TextStyle(color: strengthColor, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(height: 8),
                      buildCheckItem(AppLocalizations.of(context)!.min8CharsCheck, newPasswordController.text.length >= 8),
                      buildCheckItem(AppLocalizations.of(context)!.uppercaseCheck, RegExp(r'[A-Z]').hasMatch(newPasswordController.text)),
                      buildCheckItem(AppLocalizations.of(context)!.numberCheck, RegExp(r'[0-9]').hasMatch(newPasswordController.text)),
                      buildCheckItem(AppLocalizations.of(context)!.specialCtrlCheck, RegExp(r'[!@#\$&*~]').hasMatch(newPasswordController.text)),
                      const SizedBox(height: 15),
                      TextFormField(
                        controller: confirmPasswordController,
                        obscureText: !confirmPasswordVisible,
                        decoration: InputDecoration(
                          labelText: AppLocalizations.of(context)!.confirmPassword,
                          prefixIcon: const Icon(Icons.lock_reset),
                          suffixIcon: IconButton(
                            icon: Icon(confirmPasswordVisible ? Icons.visibility : Icons.visibility_off),
                            onPressed: () => setDialogState(() => confirmPasswordVisible = !confirmPasswordVisible),
                          ),
                        ),
                        validator: (value) => value != newPasswordController.text ? AppLocalizations.of(context)!.passwordsDoNotMatch : null,
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    oldPasswordController.dispose();
                    newPasswordController.dispose();
                    confirmPasswordController.dispose();
                    Navigator.pop(context);
                  },
                  child: Text(AppLocalizations.of(context)!.cancel),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      try {
                        AuthCredential credential = EmailAuthProvider.credential(
                          email: _user!.email!,
                          password: oldPasswordController.text.trim(),
                        );
                        await _user!.reauthenticateWithCredential(credential);
                        await _user!.updatePassword(newPasswordController.text.trim());
                        if (mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(AppLocalizations.of(context)!.pwdUpdatedSuccess)),
                          );
                        }
                      } on FirebaseAuthException catch (e) {
                        String message = AppLocalizations.of(context)!.updateFailed;
                        if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
                          message = AppLocalizations.of(context)!.incorrectOldPwd;
                        } else if (e.message != null) {
                          message = e.message!;
                        }
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
                        }
                      } finally {
                        oldPasswordController.dispose();
                        newPasswordController.dispose();
                        confirmPasswordController.dispose();
                      }
                    }
                  },
                  child: Text(AppLocalizations.of(context)!.update),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _logout() async {
    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("${AppLocalizations.of(context)!.logoutFailed} $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.settingsBtn, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFFB8C00),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _buildSectionHeader(context, AppLocalizations.of(context)!.accountLabel),
              Card(
                color: theme.cardColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: Column(
                  children: [
                    ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Colors.orange,
                        child: Icon(Icons.person, color: Colors.white),
                      ),
                      title: Text(AppLocalizations.of(context)!.adminProfile, style: TextStyle(color: theme.textTheme.titleMedium?.color)),
                      subtitle: Text(_user?.email ?? "admin@realitycart.com", style: TextStyle(color: theme.textTheme.bodySmall?.color)),
                      trailing: Icon(Icons.arrow_forward_ios, size: 16, color: theme.disabledColor),
                      onTap: () {},
                    ),
                    Divider(height: 1, color: theme.dividerColor.withOpacity(0.1)),
                    ListTile(
                      leading: Icon(Icons.lock_outline, color: theme.disabledColor),
                      title: Text(AppLocalizations.of(context)!.changePasswordTitle, style: TextStyle(color: theme.textTheme.titleMedium?.color)),
                      subtitle: Text(AppLocalizations.of(context)!.verifyOldPwdToUpdate, style: TextStyle(color: theme.textTheme.bodySmall?.color)),
                      trailing: Icon(Icons.arrow_forward_ios, size: 16, color: theme.disabledColor),
                      onTap: _changePassword,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 25),
              _buildSectionHeader(context, AppLocalizations.of(context)!.preferencesLabel),
              Card(
                color: theme.cardColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: Column(
                  children: [
                    SwitchListTile(
                      secondary: Icon(Icons.notifications_none, color: theme.disabledColor),
                      title: Text(AppLocalizations.of(context)!.notificationsTitle, style: TextStyle(color: theme.textTheme.titleMedium?.color)),
                      value: _notificationsEnabled,
                      activeTrackColor: const Color(0xFFFB8C00),
                      onChanged: (value) {
                        setState(() => _notificationsEnabled = value);
                        _updatePreference('notifications', value);
                      },
                    ),
                    Divider(height: 1, color: theme.dividerColor.withOpacity(0.1)),
                    ListTile(
                      leading: Icon(Icons.brightness_6, color: theme.disabledColor),
                      title: Text(AppLocalizations.of(context)!.themeMode, style: TextStyle(color: theme.textTheme.titleMedium?.color)),
                      subtitle: Text(_getThemeName(context, themeProvider.themeMode), style: TextStyle(color: theme.textTheme.bodySmall?.color)),
                      trailing: DropdownButton<ThemeMode>(
                        underline: const SizedBox(),
                        value: themeProvider.themeMode,
                        onChanged: (ThemeMode? newValue) {
                          if (newValue != null) {
                            themeProvider.toggleTheme(newValue == ThemeMode.dark);
                            if (newValue == ThemeMode.system) {
                              themeProvider.setSystemTheme();
                              _updatePreference('darkMode', null);
                            } else {
                              _updatePreference('darkMode', newValue == ThemeMode.dark);
                            }
                          }
                        },
                        items: [
                          DropdownMenuItem(value: ThemeMode.system, child: Text(AppLocalizations.of(context)!.systemMode)),
                          DropdownMenuItem(value: ThemeMode.light, child: Text(AppLocalizations.of(context)!.lightModeOption)),
                          DropdownMenuItem(value: ThemeMode.dark, child: Text(AppLocalizations.of(context)!.darkModeOption)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _logout,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[50],
                    foregroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    elevation: 0,
                  ),
                  child: _isLoading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.red))
                    : Text(AppLocalizations.of(context)!.logout, style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
          if (_isLoading)
            const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 5),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: theme.textTheme.bodySmall?.color?.withOpacity(0.6),
        ),
      ),
    );
  }

  String _getThemeName(BuildContext context, ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system: return AppLocalizations.of(context)!.systemDefault;
      case ThemeMode.light: return AppLocalizations.of(context)!.lightMode;
      case ThemeMode.dark: return AppLocalizations.of(context)!.darkMode;
    }
  }
}
