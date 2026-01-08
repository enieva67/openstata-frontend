import 'package:flutter/material.dart';
import 'datagrid.dart';
import 'dart:convert';

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
            
            // Lógica de decisión: ¿Es Tabla o Imagen?
            Widget contenidoPrincipal;
            
            if (res['tipo'] == 'imagen') {
              // Decodificamos Base64 a Bytes
              var imagenBytes = base64Decode(res['datos']);
              contenidoPrincipal = Center(
                child: InteractiveViewer( // Permite hacer Zoom con el mouse/dedos
                  panEnabled: true,
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: Image.memory(imagenBytes, fit: BoxFit.contain),
                ),
              );
            } else {
              // Es una tabla normal
              contenidoPrincipal = DataGrid(data: res['datos']);
            }

            return Padding(
              padding: const EdgeInsets.all(15.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(res['titulo'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const Divider(),
                  Expanded(
                    child: contenidoPrincipal, // Aquí va la tabla o la imagen
                  ),
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