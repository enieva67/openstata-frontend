import 'dart:io'; // <--- ESTO FALTABA (Para File)
import 'dart:convert'; // Para base64Decode
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart'; // <--- ESTO FALTABA (Para FilePicker)
import 'package:frontend/services/web_opener_service.dart';

import 'datagrid.dart';
import 'html_chart_viewer.dart';


class ResultsViewer extends StatelessWidget {
  final Function(String prompt, Map<String, dynamic> datos)? onInterpretar; // Nuevo callback
  final List<Map<String, dynamic>> listaResultados;

  // Constructor
  ResultsViewer({
    Key? key, 
    required this.listaResultados,
    this.onInterpretar, // Recibimos la función
  }) : super(key: ValueKey(listaResultados.length));

  // --- MÉTODO PARA GUARDAR CSV ---
  Future<void> _guardarResultadoCSV(BuildContext context, Map<String, dynamic> datosJson, String tituloDefault) async {
    try {
      // Validación básica por si datosJson no tiene la estructura esperada
      if (!datosJson.containsKey('columns') || !datosJson.containsKey('data')) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("No hay datos tabulares para exportar.")));
        return;
      }

      List<dynamic> cols = datosJson['columns'];
      List<dynamic> rows = datosJson['data'];

      // Construir CSV String
      StringBuffer csvBuffer = StringBuffer();
      csvBuffer.writeln(cols.join(',')); // Cabecera
      for (var row in rows) {
        // Aseguramos que cada celda sea string y unimos con comas
        csvBuffer.writeln((row as List).map((e) => e.toString()).join(','));
      }

      // Guardar
      String? ruta = await FilePicker.platform.saveFile(
        dialogTitle: 'Guardar Tabla de Resultados',
        fileName: '${tituloDefault.replaceAll(" ", "_")}.csv',
        allowedExtensions: ['csv'],
        type: FileType.custom,
      );

      if (ruta != null) {
        if (!ruta.endsWith('.csv')) ruta += ".csv";
        final file = File(ruta);
        await file.writeAsString(csvBuffer.toString());
        
        // Verificamos si el contexto sigue montado antes de usarlo
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Tabla guardada en $ruta")));
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error guardando: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (listaResultados.isEmpty) {
      return const Center(child: Text("Sin resultados aún."));
    }

    return DefaultTabController(
      length: listaResultados.length,
      initialIndex: listaResultados.length - 1, 
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
                String tipo = res['tipo'] ?? 'tabla';
                
                // Lógica de visualización unificada
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
                            label: const Text("Interactivo"),
                            backgroundColor: Colors.deepOrange,
                            foregroundColor: Colors.white,
                          ),
                        ),
                    ],
                  );
                } 
                else if (tipo == 'imagen') {
                  var imagenBytes = base64Decode(res['datos']);
                  contenidoPrincipal = Center(
                    child: InteractiveViewer(
                      panEnabled: true, minScale: 0.5, maxScale: 4.0,
                      child: Image.memory(imagenBytes, fit: BoxFit.contain),
                    ),
                  );
                }
                else if (tipo == 'html') {
                   // Usamos el visor con botón externo
                   contenidoPrincipal = HtmlChartViewer(htmlContent: res['datos']);
                }
                else {
                  // Por defecto es tabla
                  contenidoPrincipal = DataGrid(data: res['datos']);
                }

                // Extracción del reporte estadístico (texto)
                String? reporteStat;
                if (res['datos'] is Map && res['datos'].containsKey('reporte_stat')) {
                  reporteStat = res['datos']['reporte_stat'];
                }

                return Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // CABECERA CON BOTÓN DE DESCARGA
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(res['titulo'] ?? "Resultado", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          // BOTÓN IA
                               IconButton(
                                icon: const Icon(Icons.auto_awesome, color: Colors.purple),
                                tooltip: "Interpretar con IA",
                                onPressed: () {
                                  if (onInterpretar != null) {
                                    // Enviamos los datos crudos de este resultado específico
                                    onInterpretar!("Explícame detalladamente estos resultados estadísticos. Interpreta los valores significativos, coeficientes y métricas.", res['datos']);
                                  }
                                },
                              ),
                              const SizedBox(width: 8),
                          // BOTÓN VERDE DE DESCARGA (Solo si hay datos tabulares)
                          // Funciona para tablas puras y gráficos híbridos que traen datos
                          if (tipo == 'tabla' || tipo == 'grafico_hibrido')
                            IconButton(
                              icon: const Icon(Icons.download, color: Colors.green),
                              tooltip: "Descargar Tabla a CSV",
                              onPressed: () => _guardarResultadoCSV(context, res['datos'], res['titulo'] ?? "resultado"),
                            )
                        ],
                      ),
                      
                      const Divider(),

                      // PANEL DE CONCLUSIONES
                      if (reporteStat != null && reporteStat.isNotEmpty)
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            border: Border.all(color: Colors.blue.shade200),
                            borderRadius: BorderRadius.circular(5)
                          ),
                          child: Text(reporteStat, style: const TextStyle(fontFamily: 'Courier New', fontSize: 13)),
                        ),

                      // CONTENIDO (Tabla o Gráfico)
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
