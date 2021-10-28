import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:ontime/src/services/fetch_IMEI.dart';
import 'package:ontime/src/ui/constants/colors.dart';
import 'package:ontime/src/ui/pages/homepage.dart';
import 'package:ontime/src/ui/widgets/Info_dialog_box.dart';
import 'package:ontime/src/ui/widgets/loader_dialog.dart';

import '../../services/authentication.dart';

class Login extends StatefulWidget {
  Login({this.auth});

  final BaseAuth auth;

  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final _formKey = GlobalKey<FormState>();
  FirebaseDatabase db = FirebaseDatabase.instance;
  DatabaseReference _empIdRef, _userRef;

  String _username;
  String _password;
  String _errorMessage = "";
  User _user;
  bool formSubmit = false;
  Auth authObject;
  final _auth = FirebaseAuth.instance;


  @override
  void initState() {
    _userRef = db.reference().child("users");
    _empIdRef = db.reference().child('EmployeeID');
    authObject = Auth();

    super.initState();
  }

  bool validateAndSave() {
    final form = _formKey.currentState;
    if (form.validate()) {
      form.save();
      setState(() {
        _errorMessage = "";
      });
      return true;
    }
    return false;
  }

  void validateAndSubmit() async {
    if (validateAndSave()) {
      FocusScope.of(context).unfocus();
      onLoadingDialog(context);
      String email;
      try {
        print("welcome");
        _empIdRef.child(_username).once().then((snapshot) {
          if (snapshot == null) {
            print("popped");
            _errorMessage = "Invalid Login Details";
          } else {
            print("welcome2");
            email = snapshot.value;
          }
        loginUser(email);
        }).timeout(const Duration(seconds: 10), onTimeout: (){
          print("timeout");
        });
      } catch (e) {
        print("A7A");
        print(e);
      }
    }
  }

  Future<List> checkForSingleSignOn(User _user) async {
    DataSnapshot dataSnapshot = await _userRef.child(_user.uid).once();

    if (dataSnapshot != null) {
      var uuid = dataSnapshot.value["UUID"];
      List listOfDetails = await getDeviceDetails();

      if (uuid != null) {
        if (listOfDetails[2] == uuid) {
          return List.from([true, listOfDetails[2], true]);
        } else {
          return List.from([false, listOfDetails[2], true]);
        }
      }
      return List.from([true, listOfDetails[2], false]);
    }
    return List.from([false, null, false]);
  }

  void loginUser(String email) async {
    if (email != null) {
      try {
        _user = await authObject.signIn(email, _password);

        checkForSingleSignOn(_user).then((list) {
          Navigator.of(context).pop();

          // Adding UUID to database

          if (list[0] == true && list[2] == false) {
            _userRef.child(_user.uid).update({"UUID": list[1]});
          }

          if (list[0] == true) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => HomePage(user: _user)),
            );
          } else {
            showDialogTemplate(
                context,
                "ATTENTION!",
                "\nUnauthorized Access Detected!\nIf you are a Legit user, Kindly Contact HR Dept for the same",
                "assets/gif/no_entry.gif",
                Color.fromRGBO(170, 160, 160, 1.0),
                "Ok");
          }
        });
      } catch (e) {
        Navigator.of(context).pop();
        print("Error" + e.toString());
        setState(() {
          _errorMessage = e.message.toString();
          _formKey.currentState.reset();
        });
      }
    } else {
      setState(() {
        _errorMessage = "Invalid Login Details";
        _formKey.currentState.reset();
        Navigator.of(context).pop();
      });
    }
  }

  Widget radioButton(bool isSelected) => Container(
        width: 16.0,
        height: 16.0,
        padding: const EdgeInsets.all(2.0),
        decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(width: 2.0, color: Colors.black)),
        child: isSelected
            ? Container(
                width: double.infinity,
                height: double.infinity,
                decoration:
                    BoxDecoration(shape: BoxShape.circle, color: Colors.black),
              )
            : Container(),
      );

  Widget horizontalLine() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Container(
          width: 70,
          height: 1.0,
          color: Colors.black26.withOpacity(.2),
        ),
      );

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations(
        [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
    // ScreenUtil.instance = ScreenUtil.getInstance()..init(context);
    // ScreenUtil.instance =
    //     ScreenUtil(width: 750, height: 1334, allowFontScaling: true);
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/back.jpg'),
            fit: BoxFit.fill,
          ),
//          gradient: LinearGradient(
//            colors: <Color>[Colors.white, Colors.grey[350]],
//            begin: Alignment.topCenter,
//            end: Alignment.bottomCenter,
//          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            /* Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                Padding(
                  padding: EdgeInsets.only(top: 20.0),
                  child: Image.asset("assets/image_01.png"),
                ),
                Expanded(
                  child: Container(),
                ),
                Image.asset("assets/image_02.png")
              ],
            ),*/
            SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.only(left: 28.0, right: 28.0, top: 60.0),
                child: Column(
                  children: <Widget>[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: <Widget>[
                        Image.asset(
                          "assets/logo/logo.png",
                          width: 80,
                          height: 80,
                        ),
                        const SizedBox(
                          width: 40,
                        ),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: const <Widget>[
                              Text("GeoFlix",
                                  style: TextStyle(
                                      fontFamily: "Poppins-Bold",
                                      color: appbarcolor,
                                      fontSize: 40,
                                      letterSpacing: .6,
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                        )
                      ],
                    ),
                    const SizedBox(
                      height: 30,
                    ),
                    formCard(),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        /*Row(
                          children: <Widget>[
                            SizedBox(
                              width: 12.0,
                            ),
                            GestureDetector(
                              onTap: _radio,
                              child: radioButton(_isSelected),
                            ),
                            SizedBox(
                              width: 8.0,
                            ),
                            Text("Remember me",
                                style: TextStyle(
                                    fontSize: 12, fontFamily: "Poppins-Medium"))
                          ],
                        ),*/
                        InkWell(
                          child: Container(
                            width: 130,
                            height: 50,
                            decoration: BoxDecoration(
                                gradient: const LinearGradient(colors: [
                                  splashScreenColorBottom,
                                  Color(0xFF6078ea)
                                ]),
                                borderRadius: BorderRadius.circular(6.0),
                                boxShadow: [
                                  BoxShadow(
                                      color: const Color(0xFF6078ea).withOpacity(.3),
                                      offset: const Offset(0.0, 8.0),
                                      blurRadius: 8.0)
                                ]),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () => validateAndSubmit(),
                                child: const Center(
                                  child: Text("LOGIN",
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontFamily: "Poppins-Bold",
                                          fontSize: 15,
                                          letterSpacing: 1.0)),
                                ),
                              ),
                            ),
                          ),
                        )
                      ],
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        horizontalLine(),
                        const Text("Other Options",
                            style: TextStyle(
                                fontSize: 12.0, fontFamily: "Poppins-Medium")),
                        horizontalLine()
                      ],
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    const SizedBox(
                      height: 5,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        const Text(
                          "Don't have Login Details? ",
                          style: TextStyle(fontSize:12, fontFamily: "Poppins-Medium"),
                        ),
                        InkWell(
                          onTap: () {},
                          child: const Text("Contact Admin",
                              style: TextStyle(
                                fontSize: 12,
                                  color: splashScreenColorTop,
                                  fontFamily: "Poppins-Bold")),
                        )
                      ],
                    )
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget formCard() {
    return Container(
      width: double.infinity,
      height: 220,
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8.0),
          boxShadow: const [
            BoxShadow(
                color: Colors.black12,
                offset: Offset(0.0, 15.0),
                blurRadius: 15.0),
            BoxShadow(
                color: Colors.black12,
                offset: Offset(0.0, -10.0),
                blurRadius: 10.0),
          ]),
      child: Padding(
        padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: <Widget>[
              const Text("Login",
                  style: TextStyle(
                      fontSize: 12,
                      fontFamily: "Poppins-Bold",
                      letterSpacing: .6)),
              const SizedBox(
                height: 10,
              ),
              SizedBox(
                height: 30,
                child: TextFormField(
                  decoration: const InputDecoration(
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: dashBoardColor),
                      ),
                      icon: Icon(
                        Icons.person,
                        color: dashBoardColor,
                      ),
                      hintText: "Employee ID",
                      hintStyle: TextStyle(color: Colors.grey, fontSize: 12.0)),
                  validator: (value) =>
                      value.isEmpty ? 'Username can\'t be empty' : null,
                  onSaved: (value) => _username = value.trim(),
                ),
              ),
              SizedBox(
                height: 60,
                child: TextFormField(
                  obscureText: true,
                  decoration: const InputDecoration(
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: dashBoardColor),
                      ),
                      icon: Icon(
                        Icons.lock,
                        color: dashBoardColor,
                      ),
                      hintText: "Password",
                      hintStyle: TextStyle(color: Colors.grey, fontSize: 12.0)),
                  validator: (value) =>
                      value.isEmpty ? 'Password can\'t be empty' : null,
                  onSaved: (value) => _password = value,
                ),
              ),
              Text(
                _errorMessage,
                style: const TextStyle(color: Colors.red),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  FlatButton(
                    onPressed: () => _formKey.currentState.reset(),
                    child: const Text(
                      "Reset",
                      style: TextStyle(
                          color: dashBoardColor,
                          fontFamily: "Poppins-Medium",
                          fontSize: 15),
                    ),
                  ),
                  const Text(
                    "Forgot Password?",
                    style: TextStyle(
                        color: dashBoardColor,
                        fontFamily: "Poppins-Medium",
                        fontSize: 15),
                  )
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
