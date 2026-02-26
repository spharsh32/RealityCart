import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:reality_cart/providers/theme_provider.dart';
import 'package:reality_cart/l10n/app_localizations.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final User? _user = FirebaseAuth.instance.currentUser;
  bool _isLoading = false;
  bool _pushNotifications = true;

  @override
  void initState() {
    super.initState();
    _loadUserSettings();
  }

  Future<void> _loadUserSettings() async {
    if (_user != null) {
      setState(() => _isLoading = true);
      try {
        final doc = await FirebaseFirestore.instance.collection('users').doc(_user!.uid).get();
        if (doc.exists && mounted) {
          setState(() {
            _pushNotifications = doc.data()?['pushNotifications'] ?? true;
          });
        }
        // Load theme via provider
        if (mounted) {
          await Provider.of<ThemeProvider>(context, listen: false).loadTheme();
        }
      } catch (e) {
        debugPrint("Error loading settings: $e");
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _updateSetting(String key, dynamic value) async {
    if (_user != null) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(_user!.uid).set({
          key: value,
        }, SetOptions(merge: true));
      } catch (e) {
        debugPrint("Error updating setting: $e");
      }
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
    String strengthText = AppLocalizations.of(context)!.enterOldPassword;
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
                  strengthText = "Weak";
                  strengthColor = Colors.red;
                } else if (strength <= 0.5) {
                  strengthText = "Medium";
                  strengthColor = Colors.orange;
                } else if (strength <= 0.75) {
                  strengthText = "Good";
                  strengthColor = Colors.blue;
                } else {
                  strengthText = "Strong";
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
              title: const Text("Change Password"),
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
                          if (value.length < 8) return AppLocalizations.of(context)!.minimum8CharactersRequired;
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
                      buildCheckItem("Minimum 8 characters", newPasswordController.text.length >= 8),
                      buildCheckItem("1 Uppercase letter", RegExp(r'[A-Z]').hasMatch(newPasswordController.text)),
                      buildCheckItem("1 Number", RegExp(r'[0-9]').hasMatch(newPasswordController.text)),
                      buildCheckItem("1 Special character", RegExp(r'[!@#\$&*~]').hasMatch(newPasswordController.text)),
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
                            SnackBar(content: Text(AppLocalizations.of(context)!.passwordUpdatedSuccessfully)),
                          );
                        }
                      } on FirebaseAuthException catch (e) {
                        String message = AppLocalizations.of(context)!.updateFailed;
                        if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
                          message = "Incorrect old password";
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

  @override
  Widget build(BuildContext context) {
    if (_user == null) {
      return const Scaffold(body: Center(child: Text("Please login to access settings")));
    }

    final theme = Theme.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.settings, style: const TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
              child: Text(AppLocalizations.of(context)!.general, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5)),
                ],
              ),
              child: Column(
                children: [
                  SwitchListTile(
                    activeColor: const Color(0xFFFB8C00),
                    title: Text(AppLocalizations.of(context)!.pushNotifications),
                    value: _pushNotifications,
                    onChanged: (value) {
                      setState(() => _pushNotifications = value);
                      _updateSetting('pushNotifications', value);
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    title: Text(AppLocalizations.of(context)!.themeMode),
                    subtitle: Text(_getThemeName(themeProvider.themeMode, context)),
                    trailing: DropdownButton<ThemeMode>(
                      underline: const SizedBox(),
                      value: themeProvider.themeMode,
                      onChanged: (ThemeMode? newValue) {
                        if (newValue != null) {
                          themeProvider.toggleTheme(newValue == ThemeMode.dark);
                          if (newValue == ThemeMode.system) {
                            themeProvider.setSystemTheme();
                            _updateSetting('darkMode', null);
                          } else {
                            _updateSetting('darkMode', newValue == ThemeMode.dark);
                          }
                        }
                      },
                      items: [
                        DropdownMenuItem(value: ThemeMode.system, child: Text(AppLocalizations.of(context)!.system)),
                        DropdownMenuItem(value: ThemeMode.light, child: Text(AppLocalizations.of(context)!.light)),
                        DropdownMenuItem(value: ThemeMode.dark, child: Text(AppLocalizations.of(context)!.dark)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 30, 20, 10),
              child: Text(AppLocalizations.of(context)!.account, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5)),
                ],
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.lock_outline, color: Colors.grey),
                    title: Text(AppLocalizations.of(context)!.changePassword),
                    subtitle: Text(AppLocalizations.of(context)!.verifyOldPasswordToUpdate),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: _changePassword,
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(30),
              child: Center(
                child: Text("Version 1.0.0", style: TextStyle(color: Colors.grey)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getThemeName(ThemeMode mode, BuildContext context) {
    switch (mode) {
      case ThemeMode.system: return "${AppLocalizations.of(context)!.system} Default";
      case ThemeMode.light: return "${AppLocalizations.of(context)!.light} Mode";
      case ThemeMode.dark: return "${AppLocalizations.of(context)!.dark} Mode";
    }
  }
}
