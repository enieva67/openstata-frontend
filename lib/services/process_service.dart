import 'dart:io';
import 'package:flutter/foundation.dart'; 
import 'package:path/path.dart' as p; // Necesario para rutas seguras
import 'logger_service.dart';

class ProcessService {
  static Process? _backendProcess;

  static Future<void> iniciarBackend() async {
    if (kDebugMode) {
      LogService.info("Modo Debug: Backend manual.");
      return;
    }

    String nombreEjecutable = Platform.isWindows ? 'backend_api.exe' : 'backend_api';
    
    // --- SOLUCIÓN: RUTA ABSOLUTA ---
    // Buscamos dónde está instalado el ejecutable 'frontend' y buscamos ahí mismo
    String directorioBase = p.dirname(Platform.resolvedExecutable);
    String rutaAbsoluta = p.join(directorioBase, nombreEjecutable);

    LogService.info("Buscando backend en: $rutaAbsoluta");

    if (!File(rutaAbsoluta).existsSync()) {
      LogService.error("CRÍTICO: No existe el backend en $rutaAbsoluta");
      return;
    }

    try {
      // Lanzamos el proceso
      _backendProcess = await Process.start(rutaAbsoluta, []);
      LogService.info("✅ Backend iniciado (PID: ${_backendProcess!.pid})");
      
      // Capturamos errores de arranque de Python
      _backendProcess!.stderr.listen((data) {
         LogService.error("Python Stderr: ${String.fromCharCodes(data)}");
      });

    } catch (e) {
      LogService.error("🛑 FALLO AL INICIAR BACKEND", e);
    }
  }

  static void cerrarBackend() {
    if (_backendProcess != null) {
      _backendProcess!.kill();
    }
  }
}
