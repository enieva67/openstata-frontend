import 'dart:io';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path_provider/path_provider.dart'; // Asegúrate de tener este paquete

class HtmlChartViewer extends StatelessWidget {
  final String htmlContent;

  const HtmlChartViewer({super.key, required this.htmlContent});

  Future<void> _abrirEnNavegador(BuildContext context) async {
    try {
      // 1. Crear un archivo temporal con el HTML
      final tempDir = await getTemporaryDirectory();
      final archivo = File('${tempDir.path}/grafico_interactivo.html');
      
      // Escribimos el contenido que vino de Python
      await archivo.writeAsString(htmlContent);

      // 2. Abrir el archivo en el navegador predeterminado
      final uri = Uri.file(archivo.path);
      
      if (!await launchUrl(uri)) {
        throw 'No se pudo abrir el navegador';
      }
    } catch (e) {
      if(context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Card(
        elevation: 4,
        margin: const EdgeInsets.all(30),
        child: Padding(
          padding: const EdgeInsets.all(40.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.public, size: 60, color: Colors.blueAccent),
              const SizedBox(height: 20),
              const Text(
                "Gráfico Interactivo Generado",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text(
                "Este análisis contiene elementos 3D o interactivos complejos.\nSe abrirá en tu navegador web para mejor rendimiento.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                icon: const Icon(Icons.open_in_browser),
                label: const Text("Abrir en Navegador"),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  textStyle: const TextStyle(fontSize: 16),
                ),
                onPressed: () => _abrirEnNavegador(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}