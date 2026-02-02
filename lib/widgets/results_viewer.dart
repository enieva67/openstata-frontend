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
      return const Center(child: Text("Sin resultados."));
    }

    return DefaultTabController(
      length: listaResultados.length,
      initialIndex: listaResultados.length - 1,
      child: Column(
        children: [
          // Barra de Pestañas (Igual que antes)
          Container(
            color: Colors.grey[100],
            width: double.infinity,
            child: TabBar(
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelColor: Colors.blue[900],
              indicatorColor: Colors.blue,
              tabs: listaResultados.asMap().entries.map((entry) {
                return Tab(text: entry.value['titulo'] ?? "Result ${entry.key + 1}");
              }).toList(),
            ),
          ),

          // Contenido
          Expanded(
            child: TabBarView(
              children: listaResultados.map((res) {
                
                Widget contenidoPrincipal;
                String tipo = res['tipo'] ?? 'tabla';
                var datos = res['datos'];
                
                // --- EXTRACCIÓN DEL REPORTE ESTADÍSTICO ---
                String? reporteStat;
                
                // Intentamos buscar la clave 'reporte_stat' que mandamos desde Python
                if (datos is Map && datos.containsKey('reporte_stat')) {
                  reporteStat = datos['reporte_stat'];
                }
                // ------------------------------------------

                if (tipo == 'grafico_hibrido') {
                  String base64Img = datos['imagen'];
                  String? htmlExtra = datos['html_extra'];
                  var imagenBytes = base64Decode(base64Img);
                  
                  contenidoPrincipal = Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      Center(child: InteractiveViewer(minScale: 0.5, maxScale: 4.0, child: Image.memory(imagenBytes, fit: BoxFit.contain))),
                      if (htmlExtra != null)
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: FloatingActionButton.extended(
                            onPressed: () => WebOpener.abrirHtml(htmlExtra),
                            icon: const Icon(Icons.open_in_browser),
                            label: const Text("Interactivo"),
                            backgroundColor: Colors.deepOrange,
                            foregroundColor: Colors.white,
                          ),
                        ),
                    ],
                  );
                } 
                else if (tipo == 'imagen') {
                   // ... (Mismo código de imagen simple) ...
                   var imagenBytes = base64Decode(datos); // Si viene directo
                   contenidoPrincipal = Center(child: Image.memory(imagenBytes));
                }
                else if (tipo == 'html') {
                   contenidoPrincipal = HtmlChartViewer(htmlContent: datos);
                }
                else {
                  // Tabla
                  contenidoPrincipal = DataGrid(data: datos);
                }

                return Column( // Usamos Column para apilar el reporte y el contenido
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // CABECERA
                    Padding(
                      padding: const EdgeInsets.fromLTRB(15, 15, 15, 5),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(res['titulo'] ?? "Resultado", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          const Divider(),
                        ],
                      ),
                    ),

                    // --- PANEL DE CONCLUSIONES (NUEVO) ---
                    if (reporteStat != null && reporteStat.isNotEmpty)
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          border: Border.all(color: Colors.blue.shade200),
                          borderRadius: BorderRadius.circular(8)
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.analytics, color: Colors.blue, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                reporteStat, 
                                style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.3, fontFamily: 'Courier New'), // Monoespaciado para alinear números
                              ),
                            ),
                          ],
                        ),
                      ),
                    // -------------------------------------

                    // CONTENIDO PRINCIPAL (Tabla o Gráfico)
                    Expanded(child: contenidoPrincipal),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

