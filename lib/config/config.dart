import 'dart:convert';

import 'package:flutter/services.dart';

class Configguration {
  static Future<Map<String, dynamic>> getConfig() {
    return rootBundle.loadString('assets/config/config.json').then((value) {
      // jsonDecode = Convert String to Object
      return jsonDecode(value) as Map<String, dynamic>;
    });
  }
}
