
import 'package:flutter/material.dart';

class AppNavigator extends StatelessWidget {
  final GlobalKey<NavigatorState> navigatorKey;
  final Widget child;
  const AppNavigator({super.key,required this.child, required this.navigatorKey});

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: navigatorKey,
      onGenerateRoute: (settings){
        return MaterialPageRoute(builder: (context) => child);
      },
    );
  }
}

