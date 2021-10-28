import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:ontime/src/services/authentication.dart';

import 'package:ontime/src/ui/pages/splash_screen.dart';

class App extends StatelessWidget {


  @override
  Widget build(BuildContext context) {
    return MaterialApp(

      theme: ThemeData.light(),
      home: Scaffold(body: SplashScreenWidget(auth: Auth())),
      debugShowCheckedModeBanner: false,
    );
  }
}
