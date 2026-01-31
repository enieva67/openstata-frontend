import 'package:flutter/material.dart';
import 'datagrid.dart';
import 'dart:convert';
import 'html_chart_viewer.dart'; 
import '../services/web_opener_service.dart';
class ResultsViewer extends StatelessWidget {
  final List<Map<String, dynamic>> listaResultados;

  // CORRECCIÓN: Quitamos 'super.key' de los paréntesis y lo dejamos solo en el super.
  // Además quitamos 'const' porque ValueKey con una variable no puede ser constante.
  ResultsViewer({
    Key? key, // Aceptamos una key opcional (aunque no la usemos directo)
    required this.listaResultados
  }) : super(key: ValueKey(listaResultados.length)); 
  // ↑ Este truco del ValueKey es el que arregla el congelamiento:
  // Le dice a Flutter: "Si cambia la cantidad de resultados, destruye todo y reconstrúyelo limpio".

  @override
  Widget build(BuildContext context) {
    if (listaResultados.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assessment_outlined, size: 80, color: Colors.grey),
            SizedBox(height: 20),
            Text("No hay análisis realizados aún.", style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    // DefaultTabController maneja la magia automáticamente
    return DefaultTabController(
      length: listaResultados.length,
      initialIndex: listaResultados.length - 1, // Ir al último siempre
      child: Column(
        children: [
          // BARRA DE PESTAÑAS
          Container(
            color: Colors.grey[100],
            width: double.infinity,
            child: TabBar(
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelColor: Colors.blue[900],
              indicatorColor: Colors.blue,
              tabs: listaResultados.asMap().entries.map((entry) {
                return Tab(
                  text: entry.value['titulo'] ?? "Result ${entry.key + 1}",
                  icon: const Icon(Icons.analytics, size: 16),
                );
              }).toList(),
            ),
          ),

          // CONTENIDO
          Expanded(
            child: TabBarView(
              children: listaResultados.map((res) {
            
            Widget contenidoPrincipal;
            String tipo = res['tipo'] ?? 'tabla'; // Usamos la variable 'tipo' siempre
            
            // --- ESTRUCTURA IF-ELSE IF CORREGIDA ---
            
            if (tipo == 'grafico_hibrido') {
              var datos = res['datos'];
              String base64Img = datos['imagen'];
              String? htmlExtra = datos['html_extra'];
              var imagenBytes = base64Decode(base64Img);
              
              contenidoPrincipal = Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Center(
                    child: InteractiveViewer(
                      minScale: 0.5, maxScale: 4.0,
                      child: Image.memory(imagenBytes, fit: BoxFit.contain),
                    ),
                  ),
                  if (htmlExtra != null)
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: FloatingActionButton.extended(
                        onPressed: () => WebOpener.abrirHtml(htmlExtra),
                        icon: const Icon(Icons.open_in_browser),
                        label: const Text("Explorar Interactivo"),
                        backgroundColor: Colors.deepOrange,
                        foregroundColor: Colors.white,
                      ),
                    ),
                ],
              );
            } 
            else if (tipo == 'imagen') { // Usamos 'else if' para encadenar
              var imagenBytes = base64Decode(res['datos']);
              contenidoPrincipal = Center(
                child: InteractiveViewer(
                  panEnabled: true, minScale: 0.5, maxScale: 4.0,
                  child: Image.memory(imagenBytes, fit: BoxFit.contain),
                ),
              );
            }
            else if (tipo == 'html') {
               // En realidad ya no usamos HtmlChartViewer incrustado,
               // sino el botón de abrir externo, pero si decides mantener el visor simple:
               contenidoPrincipal = HtmlChartViewer(htmlContent: res['datos']);
            }
            else {
              // Si no es ninguno de los anteriores, asumimos Tabla
              contenidoPrincipal = DataGrid(data: res['datos']);
            }
            // ---------------------------------------

            return Padding(
              padding: const EdgeInsets.all(15.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(res['titulo'] ?? "Resultado", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const Divider(),
                  Expanded(child: contenidoPrincipal),
                ],
              ),
            );
          }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}