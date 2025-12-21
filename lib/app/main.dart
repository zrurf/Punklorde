import 'package:flutter/material.dart';
import 'package:punklorde/app/route/app_route.dart';
import 'package:toastification/toastification.dart';

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return ToastificationWrapper(
      child: MaterialApp.router(
        title: 'Punklorde',
        theme: ThemeData(),
        darkTheme: ThemeData.dark(),
        routerConfig: appRoute,
      ),
    );
  }
}
