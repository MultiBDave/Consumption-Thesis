// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:loading_overlay/loading_overlay.dart';

import '../components/components.dart';
import '../main.dart';
import 'home_screen.dart';
import 'login_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});
  static String id = 'signup_screen';

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _auth = FirebaseAuth.instance;
  late String _email;
  late String _password;
  late String _confirmPass;
  bool _saving = false;
// cloud_firestore import removed (we use global `db` from main.dart)

  @override
  Widget build(BuildContext context) {
    // WillPopScope is deprecated; keep current behavior and ignore the deprecation
    // ignore: deprecated_member_use
    return WillPopScope(
      onWillPop: () async {
        Navigator.popAndPushNamed(context, HomeScreen.id);
        return true;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: LoadingOverlay(
          isLoading: _saving,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const TopScreenImage(screenImageName: 'signup.png'),
                  Expanded(
                    flex: 2,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 15,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const ScreenTitle(title: 'Sign Up'),
                          CustomTextField(
                            textField: TextField(
                              onChanged: (value) {
                                _email = value;
                              },
                              style: const TextStyle(
                                fontSize: 20,
                              ),
                              decoration: kTextInputDecoration.copyWith(
                                hintText: 'Email',
                              ),
                            ),
                          ),
                          CustomTextField(
                            textField: TextField(
                              obscureText: true,
                              onChanged: (value) {
                                _password = value;
                              },
                              style: const TextStyle(
                                fontSize: 20,
                              ),
                              decoration: kTextInputDecoration.copyWith(
                                hintText: 'Password',
                              ),
                            ),
                          ),
                          CustomTextField(
                            textField: TextField(
                              obscureText: true,
                              onChanged: (value) {
                                _confirmPass = value;
                              },
                              style: const TextStyle(
                                fontSize: 20,
                              ),
                              decoration: kTextInputDecoration.copyWith(
                                hintText: 'Confirm Password',
                              ),
                            ),
                          ),
                          CustomBottomScreen(
                            textButton: 'Sign Up',
                            heroTag: 'signup_btn',
                            question: 'Have an account?',
                            buttonPressed: () async {
                              FocusManager.instance.primaryFocus?.unfocus();
                              // Capture navigator to use for navigation after async work
                              final navigator = Navigator.of(context);

                              setState(() {
                                _saving = true;
                              });
                              if (_confirmPass == _password) {
                                try {
                                  final newUser = await _auth
                                      .createUserWithEmailAndPassword(
                                          email: _email, password: _password);
                                  db
                                      .collection('users')
                                      .doc(newUser.user!.uid)
                                      .set({
                                    'id': newUser.user!.uid,
                                    'email': _email,
                                    'roleId': 'undefined',
                                    'role': 'undefined',
                                    'approved': false,
                                  });
                                                                  if (!mounted) return;
                                                                  // stop loading then show dialog and navigate
                                                                  setState(() {
                                                                    _saving = false;
                                                                  });
                                                                  // Use current context right after mounted check
                                                                  signUpAlert(
                                                                    context: context,
                                                                    title: 'GOOD JOB',
                                                                    desc: 'Go login now',
                                                                    btnText: 'Login Now',
                                                                    onPressed: () {
                                                                      navigator.popAndPushNamed(SignUpScreen.id);
                                                                      navigator.pushNamed(LoginScreen.id);
                                                                    },
                                                                  ).show();
                                } catch (e) {
                                    if (!mounted) return;
                                      signUpAlert(
                                      context: context,
                                      onPressed: () {
                                        SystemNavigator.pop();
                                      },
                                      title: 'SOMETHING WRONG',
                                      desc: 'Close the app and try again',
                                      btnText: 'Close Now').show();
                                }
                              } else {
                                showAlert(
                                    context: context,
                                    title: 'WRONG PASSWORD',
                                    desc:
                                        'Make sure that you write the same password twice',
                                    onPressed: () {
                                      Navigator.pop(context);
                                    }).show();
                              }
                            },
                            questionPressed: () async {
                              Navigator.pushNamed(context, LoginScreen.id);
                            },
                          ),
                        ],
                      ),
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
