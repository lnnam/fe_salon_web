import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:salonapp/constants.dart';
import 'package:salonapp/services/helper.dart';
import 'package:salonapp/api/api_manager.dart';
import 'package:salonapp/model/user.dart';
import 'package:salonapp/main.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class Login extends StatefulWidget {
  const Login({super.key});
  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final GlobalKey<FormState> _key = GlobalKey();
  AutovalidateMode _validate = AutovalidateMode.disabled;
  String? salonkey, username, password;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Beauty Salon", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(COLOR_PRIMARY),
        iconTheme: IconThemeData(
            color: isDarkMode(context) ? Colors.white : Colors.black),
        elevation: 0.0,
      ),
      body: Form(
        key: _key,
        child: ListView(
          children: <Widget>[
            // Your form fields here...
            Padding(
              padding:
                  const EdgeInsets.only(top: 32.0, right: 16.0, left: 16.0),
              child: const Text(
                'signIn',
                style: TextStyle(
                    color: Color(COLOR_PRIMARY),
                    fontSize: 25.0,
                    fontWeight: FontWeight.bold),
              ).tr(),
            ),
            ConstrainedBox(
              constraints: const BoxConstraints(minWidth: double.infinity),
              child: Padding(
                padding:
                    const EdgeInsets.only(top: 32.0, right: 24.0, left: 24.0),
                child: TextFormField(
                    initialValue: "uk0001",
                    textAlignVertical: TextAlignVertical.center,
                    textInputAction: TextInputAction.next,
                    validator: validateFeild,
                    onSaved: (String? val) {
                      salonkey = val;
                    },
                    style: const TextStyle(fontSize: 18.0),
                    cursorColor: const Color(COLOR_PRIMARY),
                    decoration: InputDecoration(
                      contentPadding:
                          const EdgeInsets.only(left: 16, right: 16),
                      fillColor: Colors.white,
                      hintText: 'Salon ID'.tr(),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25.0),
                          borderSide: const BorderSide(
                              color: Color(COLOR_PRIMARY), width: 2.0)),
                      errorBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                            color: Theme.of(context).colorScheme.error),
                        borderRadius: BorderRadius.circular(25.0),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                            color: Theme.of(context).colorScheme.error),
                        borderRadius: BorderRadius.circular(25.0),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey.shade200),
                        borderRadius: BorderRadius.circular(25.0),
                      ),
                    )),
              ),
            ),
            ConstrainedBox(
              constraints: const BoxConstraints(minWidth: double.infinity),
              child: Padding(
                padding:
                    const EdgeInsets.only(top: 32.0, right: 24.0, left: 24.0),
                child: TextFormField(
                    initialValue: "lnnam",
                    textAlignVertical: TextAlignVertical.center,
                    textInputAction: TextInputAction.next,
                    validator: validateName,
                    onSaved: (String? val) {
                      username = val;
                    },
                    style: const TextStyle(fontSize: 18.0),
                    cursorColor: const Color(COLOR_PRIMARY),
                    decoration: InputDecoration(
                      contentPadding:
                          const EdgeInsets.only(left: 16, right: 16),
                      fillColor: Colors.white,
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25.0),
                          borderSide: const BorderSide(
                              color: Color(COLOR_PRIMARY), width: 2.0)),
                      errorBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                            color: Theme.of(context).colorScheme.error),
                        borderRadius: BorderRadius.circular(25.0),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                            color: Theme.of(context).colorScheme.error),
                        borderRadius: BorderRadius.circular(25.0),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey.shade200),
                        borderRadius: BorderRadius.circular(25.0),
                      ),
                    )),
              ),
            ),
            ConstrainedBox(
              constraints: const BoxConstraints(minWidth: double.infinity),
              child: Padding(
                padding:
                    const EdgeInsets.only(top: 32.0, right: 24.0, left: 24.0),
                child: TextFormField(
                    initialValue: "lnnam",
                    textAlignVertical: TextAlignVertical.center,
                    obscureText: true,
                    validator: validatePassword,
                    onSaved: (String? val) {
                      password = val;
                    },
                    onFieldSubmitted: (password) => _login(),
                    textInputAction: TextInputAction.done,
                    style: const TextStyle(fontSize: 18.0),
                    cursorColor: const Color(COLOR_PRIMARY),
                    decoration: InputDecoration(
                      contentPadding:
                          const EdgeInsets.only(left: 16, right: 16),
                      fillColor: Colors.white,
                      hintText: 'Password'.tr(),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25.0),
                          borderSide: const BorderSide(
                              color: Color(COLOR_PRIMARY), width: 2.0)),
                      errorBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                            color: Theme.of(context).colorScheme.error),
                        borderRadius: BorderRadius.circular(25.0),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                            color: Theme.of(context).colorScheme.error),
                        borderRadius: BorderRadius.circular(25.0),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey.shade200),
                        borderRadius: BorderRadius.circular(25.0),
                      ),
                    )),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(
                  right: 40.0, left: 40.0, top: 40),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                    minWidth: double.infinity),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(COLOR_PRIMARY),
                    padding:
                        const EdgeInsets.only(top: 12, bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25.0),
                      side: const BorderSide(
                        color: Color(COLOR_PRIMARY),
                      ),
                    ),
                  ),
                  child: Text(
                    'Login'.tr(),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode(context)
                          ? Colors.black
                          : Colors.white,
                    ),
                  ),
                  onPressed: () => _login(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _login() async {
  if (_key.currentState?.validate() ?? false) {
    _key.currentState!.save();

    try {
      dynamic result = await apiManager.salonLogin(
        salonkey!.trim(), username!.trim(), password!.trim());

      print('salonLogin result: $result');

      if (result != null && result is User) {
         // Save token and user info
        if (kIsWeb) {
          // Store in cookies
          //setCookie('objuser', json.encode(result.toJson()));
           await setUserInfo(result);
        } else {
          // Store in SharedPreferences
          
          await setUserInfo(result);
        }
        MyAppState.currentUser = result;
        Navigator.pushReplacementNamed(context, '/dashboard');
      } else {
        showAlertDialog(
          context,
          'Couldn\'t Authenticate'.tr(),
          'Login failed, Please try again.'.tr());
      }
    } catch (e) {
      // Show dialog if server is not connected
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Error'),
          content: const Text('Unable to connect to the server'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  } else {
    setState(() {
      _validate = AutovalidateMode.onUserInteraction;
    });
  }
}


  // Function to set the cookie on the web platform
/*   void setCookie(String name, String value) {
    final cookieString = '$name=$value; Path=/';
    html.window.document.cookie = cookieString;
  } */

  // Function to save user information using SharedPreferences
  Future<void> setUserInfo(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', user.token);
    await prefs.setString('objuser', json.encode(user.toJson()));
  }
}
