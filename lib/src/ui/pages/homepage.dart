import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:ontime/src/models/office.dart';
import 'package:ontime/src/services/fetch_offices.dart';
import 'package:ontime/src/ui/constants/colors.dart';
import 'package:ontime/src/ui/constants/strings.dart';
import 'package:ontime/src/ui/pages/dashboard.dart';
import 'package:geofencing/geofencing.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../services/geofence.dart';

class HomePage extends StatefulWidget {
  final User user;

  HomePage({this.user});

  @override
  _HomePageState createState() => new _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  AnimationController controller;

  OfficeDatabase officeDatabase = new OfficeDatabase();
  final _databaseReference = FirebaseDatabase.instance.reference();
  var geoFenceActive = false;
  var result;
  String error;
  Office allottedOffice;
  FirebaseMessaging firebaseMessaging = FirebaseMessaging.instance;
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

  Future<void> _initializeGeoFence() async {
    try {
      result = await Permission
          .locationWhenInUse.serviceStatus.isEnabled;
      print("YESSS");
      print(result);
      if (result) {
          GeofencingManager.initialize().then((_) {
            officeDatabase.getOfficeBasedOnUID(widget.user.uid).then((office) {
              print(office.latitude);
              GeoFenceClass.startListening(
                  office.latitude, office.longitude, office.radius);
              setState(() {
                geoFenceActive = true;
                allottedOffice = office;
              });
            });
          });
      }else{
        print("denied");
      }
    } on PlatformException catch (e) {
      print(e);
      if (e.code == 'PERMISSION_DENIED') {
        error = e.message;
      } else if (e.code == 'SERVICE_STATUS_ERROR') {
        error = e.message;
      }
    }
  }

  void showDialogNotification(BuildContext context, String text) {
    Dialog simpleDialog = Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Container(
        height: 300.0,
        width: 300.0,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Padding(
              padding: EdgeInsets.all(15.0),
              child: Text(
                text,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Colors.blue,
                    fontFamily: "poppins-medium",
                    fontSize: 18),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 10, right: 10, top: 50),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  RaisedButton(
                    color: Colors.blue,
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text(
                      'Okay',
                      style: TextStyle(fontSize: 18.0, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
    showDialog(
        context: context, builder: (BuildContext context) => simpleDialog);
  }

  @override
  void initState() {
    super.initState();

    FirebaseMessaging.onMessageOpenedApp.listen((event) {
      showDialogNotification(context, event.messageId);
    });


    firebaseMessaging.requestPermission(alert: true,badge: true,sound: true);

    firebaseMessaging.getToken().then((token) {
      _databaseReference.child("users").child(widget.user.uid).update({
        "notificationToken": token,
      });
    });
    _initializeGeoFence();

    controller = AnimationController(
        vsync: this, duration: new Duration(milliseconds: 300), value: 1.0);
  }

  @override
  void dispose() {
    super.dispose();
    controller.dispose();
    GeoFenceClass.closePort();
    GeofencingManager.removeGeofenceById(fence_id);
  }

  bool get isPanelVisible {
    final AnimationStatus status = controller.status;
    return status == AnimationStatus.completed ||
        status == AnimationStatus.forward;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Padding(
            padding: EdgeInsets.only(left: 55.0),
            child: Text(
              "DASHBOARD",
              style: TextStyle(
                  fontSize: 25.0,
                  fontFamily: "Poppins-Medium",
                  fontWeight: FontWeight.w200),
            ),
          ),
          elevation: 0.0,
          backgroundColor: dashBoardColor,
          leading: IconButton(
            onPressed: () {
              double velocity = 2.0;
              controller.fling(velocity: isPanelVisible ? -velocity : velocity);
            },
            icon: AnimatedIcon(
              icon: AnimatedIcons.close_menu,
              progress: controller.view,
            ),
          ),
        ),
        body: geoFenceActive == false
            ? Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      splashScreenColorBottom,
                      splashScreenColorTop
                    ],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topRight,
                  ),
                ),
                child: Column(children: const <Widget>[
                  LinearProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                        splashScreenColorBottom),
                  ),
                  Padding(
                    padding: EdgeInsets.all(40.0),
                    child: Text(
                      "Please Wait..\nwhile we are setting up things",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w700),
                      textAlign: TextAlign.center,
                    ),
                  )
                ]))
            : Dashboard(
                controller: controller,
                user: widget.user,
              ));
  }
}
