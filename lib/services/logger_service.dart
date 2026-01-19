import 'dart:io';
import 'package:flutter/foundation.dart'; 
import 'package:path_provider/path_provider.dart';

class LogService {
  static File? _logFile;

  static Future<void> init() async {
    try {
      Directory dir;
      if (Platform.isLinux) {
         // Fallback simple para desarrollo en Linux si XDG falla
         dir = Directory('/tmp'); 
      } else {
         dir = await getApplicationDocumentsDirectory();
      }
      _logFile = File('${dir.path}/openstata_dev.log');
    } catch (e) {
      if (kDebugMode) print("Error log init: $e");
    }
  }

  static Future<void> info(String msg) async {
    if (kDebugMode) debugPrint("[INFO] $msg");
    await _write("[INFO] $msg");
  }

  static Future<void> error(String msg, [dynamic e]) async {
    if (kDebugMode) debugPrint("[ERROR] $msg $e");
    await _write("[ERROR] $msg $e");
  }

  static Future<void> _write(String line) async {
    if (_logFile != null) await _logFile!.writeAsString('$line\n', mode: FileMode.append);
  }
}
