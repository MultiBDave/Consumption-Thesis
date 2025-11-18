// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:loading_overlay/loading_overlay.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../components/components.dart';
import '../home_page.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  static String id = 'login_screen';

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late String _email = '';
  late String _password = '';
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    // WillPopScope is deprecated; keep current behavior and ignore the deprecation
    // until a full migration to `PopScope` is done.
    // ignore: deprecated_member_use
    return WillPopScope(
      onWillPop: () async {
        Navigator.popAndPushNamed(context, HomeScreen.id);
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: LoadingOverlay(
          isLoading: _saving,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  const TopScreenImage(screenImageName: 'welcome.png'),
                  Expanded(
                    flex: 2,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const ScreenTitle(title: 'Login'),
                        CustomTextField(
                          textField: TextField(
                              onChanged: (value) {
                                if (value.isNotEmpty &&
                                    value.contains('@') &&
                                    value.contains('.') &&
                                    value != _email) {
                                  _email = value;
                                }
                              },
                              style: const TextStyle(
                                fontSize: 20,
                              ),
                              decoration: kTextInputDecoration.copyWith(
                                  hintText: 'Email')),
                        ),
                        CustomTextField(
                          textField: TextField(
                            obscureText: true,
                            onChanged: (value) {
                              if (value.isNotEmpty && value != _password) {
                                _password = value;
                              }
                            },
                            style: const TextStyle(
                              fontSize: 20,
                            ),
                            decoration: kTextInputDecoration.copyWith(
                                hintText: 'Password'),
                          ),
                        ),
                        CustomBottomScreen(
                          textButton: 'Login',
                          heroTag: 'login_btn',
                          question: 'Forgot password?',
                          buttonPressed: () async {
                            FocusManager.instance.primaryFocus?.unfocus();
                            // Capture navigator/context before awaiting to avoid
                            // using BuildContext after async gaps.
                            final navigator = Navigator.of(context);

                            setState(() {
                              _saving = true;
                            });
                            try {
                              await auth.signInWithEmailAndPassword(
                                  email: _email, password: _password);
                              if (!mounted) return;
                              // stop loading first, then navigate
                              setState(() {
                                _saving = false;
                              });
                              navigator.popAndPushNamed(LoginScreen.id);
                              navigator.pushNamed(HomePage.id);
                            } catch (e) {
                              if (!mounted) return;
                              // Use current context immediately after mounted check
                              signUpAlert(
                                context: context,
                                onPressed: () {
                                  if (!mounted) return;
                                  setState(() {
                                    _saving = false;
                                  });
                                  navigator.popAndPushNamed(LoginScreen.id);
                                },
                                title: 'WRONG PASSWORD OR EMAIL',
                                desc:
                                    'Confirm your email and password and try again',
                                btnText: 'Try Now',
                              ).show();
                            }
                          },
                          questionPressed: () {
                            signUpAlert(
                              onPressed: () async {
                                await FirebaseAuth.instance
                                    .sendPasswordResetEmail(email: _email);
                              },
                              title: 'RESET YOUR PASSWORD',
                              desc:
                                  'Click on the button to reset your password',
                              btnText: 'Reset Now',
                              context: context,
                            ).show();
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
