import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

extension Navigation on BuildContext {
  double get width => MediaQuery.of(this).size.width;
  double get height => MediaQuery.of(this).size.height;
  Future<dynamic> push(Widget widget) {
    return Navigator.of(this)
        .push(MaterialPageRoute(builder: (context) => widget));
  }

  Future<dynamic> pushNamed(String routeName, {Object? arguments}) {
    return Navigator.of(this).pushNamed(routeName, arguments: arguments);
  }

  Future<dynamic> pushReplacement(Widget widget) {
    return Navigator.of(this)
        .pushReplacement(MaterialPageRoute(builder: (context) => widget));
  }

  Future<dynamic> pushReplacementNamed(String routeName, {Object? arguments}) {
    return Navigator.of(this)
        .pushReplacementNamed(routeName, arguments: arguments);
  }

  Future<dynamic> pushAndRemoveUntil(Widget widget) {
    return Navigator.of(this).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => widget),
      (route) => false,
    );
  }

  Future<dynamic> pushNamedAndRemoveUntil(String newRouteName,
      {Object? arguments}) {
    return Navigator.of(this).pushNamedAndRemoveUntil(
        newRouteName, (route) => false,
        arguments: arguments);
  }

  void pop<T>([T? result]) {
    return Navigator.of(this).pop(result);
  }

  void popByCount(int count) {
    if (count < 1) return;
    var navigator = Navigator.of(this);
    for (var i = 0; i < count; i++) {
      navigator.pop();
    }
  }

  Future<dynamic> pushWithAnimation(Widget widget) {
    if (Platform.isIOS) {
      return Navigator.of(this).push(CupertinoPageRoute(builder: (context) => widget));
    }
    return Navigator.of(this).push(_animatedRoute(widget));
  }

  Future<dynamic> pushReplacementWithAnimation(Widget widget) {
    if (Platform.isIOS) {
      return Navigator.of(this).pushReplacement(
          CupertinoPageRoute(builder: (context) => widget));
    }
    return Navigator.of(this).pushReplacement(_animatedRoute(widget));
  }

  Future<dynamic> pushAndRemoveUntilWithAnimation(Widget widget) {
    if(Platform.isIOS){
      return Navigator.of(this).pushAndRemoveUntil(CupertinoPageRoute(builder: (context) => widget), (route) => false);
    }
    return Navigator.of(this)
        .pushAndRemoveUntil(_animatedRoute(widget), (route) => false);
  }

  PageRouteBuilder _animatedRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const curve = Curves.easeInOut;
        var tween = context.locale == const Locale('en')
            ? Tween<Offset>(begin: const Offset(-1.0, 0.0), end: Offset.zero)
            : Tween(begin: const Offset(1.0, 0.0), end: Offset.zero)
                .chain(CurveTween(curve: curve));

        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 500),
    );
  }
}

extension StringValidator on String? {
  bool get isNullOrEmpty {
    return this == null || this == '';
  }
}
