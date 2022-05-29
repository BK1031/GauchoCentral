import 'dart:convert';
import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:cool_alert/cool_alert.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:fluro/fluro.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:storke_central/models/user.dart';
import 'package:storke_central/utils/config.dart';
import 'package:storke_central/utils/theme.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({Key? key}) : super(key: key);

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {

  final PageController _pageController = PageController();
  User registerUser = User();
  bool validUsername = true;
  int registerStage = 0;

  TextEditingController firstNameController = TextEditingController();
  TextEditingController lastNameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController phoneNumberController = TextEditingController();

  List<String> genderList = ["Male", "Female", "Other", "Prefer not to say"];

  Future<void> loginGoogle() async {
    // Google sign in
    GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ["email", "profile", "openid"]);
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser != null) {
        print("Signed into Google as ${googleUser.displayName} (${googleUser.email})");
        if (googleUser.email.contains("ucsb.edu")) {
          final GoogleSignInAuthentication? googleAuth = await googleUser?.authentication;
          final credential = fb.GoogleAuthProvider.credential(
            accessToken: googleAuth?.accessToken,
            idToken: googleAuth?.idToken,
          );
          fb.UserCredential fbUser = await fb.FirebaseAuth.instance.signInWithCredential(credential);
          setState(() {
              registerUser.id = fbUser.user!.uid;
              registerUser.firstName = fbUser.user!.displayName!.split(" ")[0];
              registerUser.lastName = fbUser.user!.displayName!.split(" ")[1];
              registerUser.email = fbUser.user!.email!;
              registerUser.phoneNumber = fbUser.user!.phoneNumber ?? "";
              registerUser.profilePictureURL = fbUser.user!.photoURL!;
          });
          firstNameController.text = registerUser.firstName;
          lastNameController.text = registerUser.lastName;
          emailController.text = registerUser.email;
          _pageController.animateToPage(1, duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
        } else {
          CoolAlert.show(
              context: context,
              type: CoolAlertType.warning,
              title: "Authentication Error",
              widget: const Text("You must be a UCSB student and use a ucsb email addresss to sign in."),
              backgroundColor: SB_NAVY,
              confirmBtnColor: SB_AMBER,
              confirmBtnText: "OK"
          );
        }
      }
    } catch (err) {
      print(err);
      CoolAlert.show(
          context: context,
          type: CoolAlertType.error,
          title: "Google Sign-in Error",
          widget: Text(err.toString()),
          backgroundColor: SB_NAVY,
          confirmBtnColor: SB_RED,
          confirmBtnText: "OK"
      );
    }
  }

  Future<void> loginAnon() async {
    fb.FirebaseAuth.instance.signInAnonymously().then((value) {
      router.navigateTo(context, "/check-auth", transition: TransitionType.fadeIn, replace: true, clearStack: true);
    });
  }

  Future<void> usernameCheck() async {
    http.get(Uri.parse("$API_HOST/users/${registerUser.userName}"), headers: {"SC-API-KEY": SC_API_KEY}).then((value) {
      if (value.statusCode == 200) {
        // User exists with username
        setState(() {
            validUsername = false;
        });
      } else {
        setState(() {
          validUsername = true;
        });
      }
    });
  }

  Widget buildPage1(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          OutlinedButton(
            style: ButtonStyle(
                shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                    RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        side: const BorderSide(color: Colors.red)
                    )
                )
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Image.asset("images/icons/google-icon.png", height: 25, width: 25,),
                ),
                const Padding(padding: EdgeInsets.all(4),),
                const Text("Sign in with Google", style: TextStyle(fontSize: 16)),
              ],
            ),
            onPressed: () {
              loginGoogle();
            },
          ),
          const Padding(padding: EdgeInsets.all(8),),
          const Text("–– OR ––"),
          // Padding(padding: EdgeInsets.all(8),),
          SizedBox(
            width: MediaQuery.of(context).size.width,
            child: CupertinoButton(
              onPressed: () {
                loginAnon();
              },
              child: const Text("Continue as guest"),
            ),
          )
        ],
      ),
    );
  }

  Widget buildPage2(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("Let's start by picking a username.", style: TextStyle(fontSize: 18),),
              Row(
                children: [
                  Text("@", style: TextStyle(color: registerUser.userName != "" ? Colors.black : Colors.black54, fontSize: 25),),
                  const Padding(padding: EdgeInsets.all(2)),
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: "bk1031",
                      ),
                      textCapitalization: TextCapitalization.none,
                      style: const TextStyle(fontSize: 25),
                      onChanged: (input) {
                        setState(() {
                          registerUser.userName = input.toLowerCase().replaceAll(" ", "");
                        });
                        if (registerUser.userName != "") usernameCheck();
                      },
                    ),
                  ),
                  registerUser.userName != "" ? validUsername ? Icon(Icons.check_circle, color: SB_GREEN,) : Icon(Icons.cancel, color: SB_RED,) : Container()
                ],
              ),
              validUsername ? Text("Your username will be @${registerUser.userName}", style: TextStyle(fontSize: 16, color: SB_GREEN),) : registerUser.userName != "" ? Text("That username is taken!", style: TextStyle(fontSize: 16, color: SB_RED)): Container(),
              const Padding(padding: EdgeInsets.all(8)),
              SizedBox(
                width: MediaQuery.of(context).size.width,
                child: CupertinoButton.filled(
                  child: const Text("Next"),
                  onPressed: () {
                    if (validUsername && registerUser.userName != "") {
                      _pageController.animateToPage(2, duration: const Duration(milliseconds: 100), curve: Curves.easeOut);
                    } else {
                      CoolAlert.show(
                          context: context,
                          type: CoolAlertType.error,
                          title: "Invalid Username",
                          widget: Text("Unfortunately, someone already has that username. If you really want that name, reach out to us on Discord and we might be able to help."),
                          backgroundColor: SB_NAVY,
                          confirmBtnColor: SB_RED,
                          confirmBtnText: "OK"
                      );
                    }
                  },
                ),
              )
            ],
          ),
        ],
      ),
    );
  }

  Widget buildPage3(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("Nice! Let's continue creating your account.", style: TextStyle(fontSize: 18),),
              Row(
                children: [
                  Text("First Name", style: TextStyle(color: Colors.black54, fontSize: 25),),
                  const Padding(padding: EdgeInsets.all(2)),
                  Expanded(
                    child: TextField(
                      controller: firstNameController,
                      textAlign: TextAlign.end,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: "Alex",
                      ),
                      textCapitalization: TextCapitalization.words,
                      keyboardType: TextInputType.name,
                      style: const TextStyle(fontSize: 25),
                      onChanged: (input) {
                        setState(() {
                          registerUser.firstName = input;
                        });
                      },
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Text("Last Name", style: TextStyle(color: Colors.black54, fontSize: 25),),
                  const Padding(padding: EdgeInsets.all(2)),
                  Expanded(
                    child: TextField(
                      controller: lastNameController,
                      textAlign: TextAlign.end,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: "Lopes",
                      ),
                      textCapitalization: TextCapitalization.words,
                      keyboardType: TextInputType.name,
                      style: const TextStyle(fontSize: 25),
                      onChanged: (input) {
                        setState(() {
                          registerUser.lastName = input;
                        });
                      },
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Text("Email", style: TextStyle(color: Colors.black54, fontSize: 25),),
                  const Padding(padding: EdgeInsets.all(2)),
                  Expanded(
                    child: TextField(
                      controller: emailController,
                      textAlign: TextAlign.end,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: "alopes@ucsb.edu",
                      ),
                      textCapitalization: TextCapitalization.words,
                      keyboardType: TextInputType.name,
                      enabled: false,
                      style: const TextStyle(fontSize: 25),
                      onChanged: (input) {},
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Text("Phone #", style: TextStyle(color: Colors.black54, fontSize: 25),),
                  const Padding(padding: EdgeInsets.all(2)),
                  Expanded(
                    child: TextField(
                      controller: phoneNumberController,
                      textAlign: TextAlign.end,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: "(510) 123-4567",
                      ),
                      textCapitalization: TextCapitalization.words,
                      keyboardType: TextInputType.name,
                      style: const TextStyle(fontSize: 25),
                      onChanged: (input) {
                        setState(() {
                          registerUser.phoneNumber = input;
                        });
                      },
                    ),
                  ),
                ],
              ),
              const Padding(padding: EdgeInsets.all(8)),
              SizedBox(
                width: MediaQuery.of(context).size.width,
                child: CupertinoButton.filled(
                  child: const Text("Next"),
                  onPressed: () {
                    if (validUsername && registerUser.userName != "") {
                      if (registerUser.firstName != "" && registerUser.lastName != "") {
                        _pageController.animateToPage(3, duration: const Duration(milliseconds: 100), curve: Curves.easeOut);
                      }
                      else {
                        CoolAlert.show(
                            context: context,
                            type: CoolAlertType.error,
                            title: "Empty Name",
                            widget: const Text("Please enter your first and last name."),
                            backgroundColor: SB_NAVY,
                            confirmBtnColor: SB_RED,
                            confirmBtnText: "OK"
                        );
                      }
                    } else {
                      CoolAlert.show(
                          context: context,
                          type: CoolAlertType.error,
                          title: "Invalid Username",
                          widget: Text("Unfortunately, someone already has that username. If you really want that name, reach out to us on Discord and we might be able to help."),
                          backgroundColor: SB_NAVY,
                          confirmBtnColor: SB_RED,
                          confirmBtnText: "OK"
                      );
                    }
                  },
                ),
              )
            ],
          ),
        ],
      ),
    );
  }

  Widget buildPage4(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text("Looking good! Just need a few more things.", style: TextStyle(fontSize: 18),),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Gender", style: TextStyle(color: Colors.black54, fontSize: 25),),
              const Padding(padding: EdgeInsets.all(2)),
              Card(
                child: Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: DropdownButton<String>(
                    value: registerUser.gender,
                    alignment: Alignment.centerRight,
                    underline: Container(),
                    style: TextStyle(fontSize: 18, color: AdaptiveTheme.of(context).theme.textTheme.bodyLarge!.color),
                    items: const [
                      DropdownMenuItem(
                        child: Text("Male"),
                        value: "Male",
                      ),
                      DropdownMenuItem(
                        child: Text("Female"),
                        value: "Female",
                      ),
                      DropdownMenuItem(
                        child: Text("Other"),
                        value: "Other",
                      ),
                      DropdownMenuItem(
                        child: Text("Prefer not to say"),
                        value: "Prefer not to say",
                      ),
                    ],
                    borderRadius: BorderRadius.circular(8),
                    onChanged: (item) {
                      setState(() {
                        registerUser.gender = item!;
                      });
                    },
                  ),
                ),
              )
            ],
          ),
          const Padding(padding: EdgeInsets.all(8)),
          SizedBox(
            width: MediaQuery.of(context).size.width,
            child: CupertinoButton.filled(
              child: const Text("Create Account"),
              onPressed: () {
                if (validUsername && registerUser.userName != "") {
                  if (registerUser.firstName != "" && registerUser.lastName != "") {
                    _pageController.animateToPage(1, duration: const Duration(milliseconds: 100), curve: Curves.easeOut);
                  }
                  else {
                    CoolAlert.show(
                        context: context,
                        type: CoolAlertType.error,
                        title: "Empty Name",
                        widget: const Text("Please enter your first and last name."),
                        backgroundColor: SB_NAVY,
                        confirmBtnColor: SB_RED,
                        confirmBtnText: "OK"
                    );
                  }
                } else {
                  CoolAlert.show(
                      context: context,
                      type: CoolAlertType.error,
                      title: "Invalid Username",
                      widget: Text("Unfortunately, someone already has that username. If you really want that name, reach out to us on Discord and we might be able to help."),
                      backgroundColor: SB_NAVY,
                      confirmBtnColor: SB_RED,
                      confirmBtnText: "OK"
                  );
                }
              },
            ),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Stack(
            alignment: Alignment.bottomLeft,
            children: [
              SizedBox(
                height: 250,
                width: MediaQuery.of(context).size.width,
                child: const Hero(
                  tag: "storke-banner",
                  child: Image(
                    image: AssetImage('images/storke.jpeg'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(registerUser.firstName == "" ? "Welcome" : "Hey there,\n${registerUser.firstName}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 35, color: Colors.white)),
              )
            ],
          ),
          Expanded(
            child: PageView(
              physics: const NeverScrollableScrollPhysics(),
              controller: _pageController,
              children: [
                buildPage1(context),
                buildPage2(context),
                buildPage3(context),
                buildPage4(context)
              ],
            ),
          )
        ],
      ),
    );
  }
}
