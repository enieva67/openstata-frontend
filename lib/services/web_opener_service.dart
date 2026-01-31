import 'dart:io';
import 'package:url_launcher/url_launcher.dart';
import 'package:path_provider/path_provider.dart';

class WebOpener {
  static Future<void> abrirHtml(String htmlContent) async {
    try {
      final tempDir = await getTemporaryDirectory();
      // Usamos un nombre aleatorio o timestamp para que no se pisen si abres varios
      final nombre = "grafico_${DateTime.now().millisecondsSinceEpoch}.html";
      final archivo = File('${tempDir.path}/$nombre');
      
      await archivo.writeAsString(htmlContent);
      
      final uri = Uri.file(archivo.path);
      if (!await launchUrl(uri)) {
        throw 'No se pudo lanzar el navegador';
      }
    } catch (e) {
      print("Error abriendo navegador: $e");
    }
  }
}
