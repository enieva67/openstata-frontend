import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'widgets/dialogs/cleaning_dialog.dart';

import 'widgets/sidebar.dart';
import 'widgets/console.dart';
import 'widgets/datagrid.dart';
import 'widgets/dialogs/multi_variable_dialog.dart';
import 'widgets/results_viewer.dart'; // NUEVO IMPORT

void main() {
  runApp(const MiStataApp());
}

class MiStataApp extends StatelessWidget {
  const MiStataApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OpenStata Doctorado',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF005EB8)),
        scaffoldBackgroundColor: const Color(0xFFF5F5F7),
      ),
      home: const PantallaPrincipal(),
    );
  }
}

Map<String, dynamic> _decodificarEnBackground(String mensaje) {
  return jsonDecode(mensaje);
}

class PantallaPrincipal extends StatefulWidget {
  const PantallaPrincipal({super.key});

  @override
  State<PantallaPrincipal> createState() => _PantallaPrincipalState();
}

class _PantallaPrincipalState extends State<PantallaPrincipal> with SingleTickerProviderStateMixin {
  final _canal = WebSocketChannel.connect(Uri.parse('ws://127.0.0.1:8000/ws'));
  
  // DATOS
  final List<String> _logs = []; 
  Map<String, dynamic>? _datasetRaw; // Solo para la pestaña "Datos"
  List<String> _columnasDisponibles = [];
  
  // RESULTADOS (Lista de análisis hechos)
  final List<Map<String, dynamic>> _historialResultados = [];

  // Paginación Dataset
  final int _filasPorPagina = 100;
  int _offsetActual = 0;
  int _totalFilas = 0;
  bool _cargando = false;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    // AHORA TENEMOS 3 PESTAÑAS: Consola, Datos, Resultados
    _tabController = TabController(length: 3, vsync: this);
    
    _canal.stream.listen((mensaje) {
      _procesarMensaje(mensaje);
    }, onError: (err) => _agregarLog("Error conexión: $err", esError: true));
  }

  @override
  void dispose() {
    _canal.sink.close();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _procesarMensaje(String mensajeRaw) async {
    final hora = DateTime.now().toString().split(' ')[1];
    print("[$hora] 1. Mensaje recibido (${mensajeRaw.length} bytes)");

    try {
      // PASO CLAVE: Usamos 'compute' para que el JSON se decodifique en otro hilo
      // Si el mensaje es gigante, esto evita que la UI se trabe.
      final datos = await compute(_decodificarEnBackground, mensajeRaw);
      
      print("[$hora] 2. JSON Decodificado en background");

      final tipo = datos['tipo'];
      final contenido = datos['contenido'];

      if (!mounted) return; // Seguridad por si el widget se cerró

      setState(() {
        print("[$hora] 3. Iniciando actualización de UI (setState)");
        _cargando = false;
        
        if (tipo == 'texto') {
          _agregarLog(contenido);
        } 
        else if (tipo == 'error') {
          _agregarLog(contenido, esError: true);
        } 
        else if (tipo == 'tabla_datos') {
          print("[$hora] 4. Procesando tabla de datos...");
          _datasetRaw = contenido;
          _columnasDisponibles = List<String>.from(contenido['columns']);
          
          if (contenido.containsKey('total_rows')) _totalFilas = contenido['total_rows'];
          if (contenido.containsKey('offset')) _offsetActual = contenido['offset'];
          
          if (_offsetActual == 0) _tabController.animateTo(1); 
        } 
        else if (tipo == 'tabla_resumen') {
             print("[$hora] 4. Procesando nuevo resultado...");
             Map<String, dynamic> nuevoResultado = {
               'titulo': "Análisis #${_historialResultados.length + 1}",
               'subtitulo': DateTime.now().toString().split('.')[0],
               'datos': contenido
             };

             // CLAVE: Usamos una lista nueva para forzar a Flutter a detectar el cambio
             _historialResultados.add(nuevoResultado);
             
             // Forzamos un pequeño delay para dejar que la UI respire antes de cambiar de tab
             Future.delayed(const Duration(milliseconds: 100), () {
               if(mounted) _tabController.animateTo(2);
             });
        }
        else if (tipo == 'info_columnas') {
         // LLEGÓ LA INFO DE SALUD -> ABRIMOS EL DIÁLOGO
         // 'contenido' es la lista de info: [{'columna': 'Age', 'nulos': 177...}, ...]
         showDialog(
           context: context,
           builder: (ctx) => CleaningDialog(
             infoColumnas: contenido['info'],
             onImputar: (col, metodo) {
               var orden = {
                 "comando": "transformacion", "accion": "imputar", "columna": col, "metodo": metodo
               };
               _canal.sink.add(jsonEncode(orden));
             },
             onCodificar: (col) {
               var orden = {
                 "comando": "transformacion", "accion": "dummies", "columna": col
               };
               _canal.sink.add(jsonEncode(orden));
             },
           ),
         );
    }
    else if (tipo == 'grafico') {
             Map<String, dynamic> nuevoResultado = {
               'titulo': "Gráfico #${_historialResultados.length + 1}",
               'subtitulo': "Visualización",
               'tipo': 'imagen', // Marcamos que es imagen
               'datos': contenido // Aquí viene el string base64 gigante
             };
             _historialResultados.add(nuevoResultado);
             
             Future.delayed(const Duration(milliseconds: 100), () {
               if(mounted) _tabController.animateTo(2);
             });
        }
        print("[$hora] 5. Fin del setState");
      });
    } catch (e, stackTrace) {
      print("[$hora] 🛑 ERROR CRÍTICO EN PROCESAMIENTO: $e");
      print(stackTrace);
      _agregarLog("Error interno de UI: $e", esError: true);
    }
  }
  
  void _agregarLog(String texto, {bool esError = false}) {
    if (_logs.length > 200) _logs.removeAt(0);
    setState(() {
       _logs.add(esError ? "🛑 $texto" : "PY > $texto");
    });
  }

  void _enviarComandoManual(String texto) {
    if (texto.trim().isEmpty) return;
    setState(() => _logs.add("YO > $texto"));
    _canal.sink.add(texto);
  }

  void _solicitarPagina(int nuevoInicio) {
    setState(() => _cargando = true);
    Map<String, dynamic> orden = {
      "comando": "paginacion",
      "inicio": nuevoInicio,
      "limite": _filasPorPagina
    };
    _canal.sink.add(jsonEncode(orden));
  }

  Future<void> _cargarArchivo() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom, allowedExtensions: ['csv'],
    );
    if (result != null) {
      setState(() => _cargando = true);
      String ruta = result.files.single.path!.replaceAll(r'\', r'/'); 
      _canal.sink.add("cargar $ruta");
    }
  }

  // Lógica de menús (Sin cambios importantes aquí)
  void _manejarClickMenu(String nombre, String comando) {
    if (_columnasDisponibles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Carga un CSV primero.")));
      return;
    }

    if (comando == "resumen") {
      _canal.sink.add(jsonEncode({"comando": "analisis", "tipo_analisis": "resumen"}));
    } else if (comando == "ols_multiple" || comando == "logit") {
       showDialog(
        context: context,
        builder: (ctx) => MultiVariableDialog(
          titulo: nombre,
          columnas: _columnasDisponibles,
          onEjecutar: (y, xList) {
            var orden = {
              "comando": "analisis", 
              "tipo_analisis": comando, // Pasamos "logit" u "ols_multiple"
              "y": y, 
              "x": xList
            };
            _canal.sink.add(jsonEncode(orden));
          },
        ),
      );
    } 
    else if (comando == "limpieza_datos") {
   // Primero pedimos la info, no abrimos el diálogo directo
   _canal.sink.add(jsonEncode({"comando": "transformacion", "accion": "info_columnas"}));
   _agregarLog("Analizando salud del dataset...");
}
 else if (comando == "histograma") {
      // Necesita 1 variable
      _mostrarDialogoVariablesGenerico(nombre, comando, numVariables: 1);
    }
    else if (comando == "scatter") {
      // Necesita 2 variables (Y vs X)
      _mostrarDialogoVariablesGenerico(nombre, comando, numVariables: 2);
    }
    else if (comando == "boxplot") {
      // Boxplot puede ser 1 o 2. Usemos el de 2 por ahora (Variable Y, Grupo X)
      _mostrarDialogoVariablesGenerico(nombre, comando, numVariables: 2);
    }
 else {
      _mostrarDialogoVariables(nombre, comando);
    }
  }
// --- FUNCIÓN INTELIGENTE PARA GRÁFICOS (1 o 2 Variables) ---
  void _mostrarDialogoVariablesGenerico(String titulo, String comando, {required int numVariables}) {
    String? v1;
    String? v2;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateDlg) => AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.bar_chart, color: Colors.blueAccent),
              const SizedBox(width: 10),
              Text(titulo),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // VARIABLE 1 (Siempre visible)
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: numVariables == 1 ? "Variable (Numérica)" : "Variable Y (Eje Vertical)",
                  border: const OutlineInputBorder(),
                ),
                items: _columnasDisponibles.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (val) => setStateDlg(() => v1 = val),
              ),
              
              const SizedBox(height: 15),

              // VARIABLE 2 (Solo visible si numVariables >= 2)
              if (numVariables >= 2)
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: "Variable X (Eje Horizontal / Grupo)",
                    border: OutlineInputBorder(),
                  ),
                  items: _columnasDisponibles.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (val) => setStateDlg(() => v2 = val),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx), 
              child: const Text("Cancelar")
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.brush),
              label: const Text("Generar Gráfico"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
              ),
              // Lógica de validación:
              // - Si pide 1 var: Solo v1 debe estar llena.
              // - Si pide 2 vars: v1 Y v2 deben estar llenas.
              onPressed: (v1 != null && (numVariables < 2 || v2 != null)) 
                ? () {
                    // Construimos la lista de variables a enviar
                    List<String> varsToSend = [v1!];
                    if (v2 != null) varsToSend.add(v2!);

                    var orden = {
                      "comando": "analisis",
                      "tipo_analisis": comando,
                      "variables": varsToSend
                    };
                    _canal.sink.add(jsonEncode(orden));
                    Navigator.pop(ctx);
                    
                    _agregarLog("Generando gráfico...");
                  } 
                : null, // Deshabilita el botón si faltan datos
            )
          ],
        ),
      ),
    );
  }

  void _mostrarDialogoVariables(String titulo, String comando) {
    String? v1;
    String? v2;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateDlg) => AlertDialog(
          title: Text(titulo),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: "Variable 1"),
                items: _columnasDisponibles.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (val) => setStateDlg(() => v1 = val),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: "Variable 2"),
                items: _columnasDisponibles.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (val) => setStateDlg(() => v2 = val),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancelar")),
            ElevatedButton(
              onPressed: (v1 != null && v2 != null) ? () {
                var orden = {"comando": "analisis", "tipo_analisis": comando, "variables": [v1, v2]};
                _canal.sink.add(jsonEncode(orden));
                Navigator.pop(ctx);
              } : null,
              child: const Text("Ejecutar"),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("OpenStata Evolution"),
        backgroundColor: Colors.white,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.folder_open, color: Colors.blueAccent),
            onPressed: _cargarArchivo,
            tooltip: "Cargar CSV",
          ),
          const SizedBox(width: 15),
        ],
      ),
      body: Row(
        children: [
          // 1. Sidebar
          SidebarMenu(onOpcionSeleccionada: _manejarClickMenu),

          // 2. Área Principal (3 PESTAÑAS)
          Expanded(
            child: _cargando 
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    Container(
                      color: Colors.grey[200],
                      child: TabBar(
                        controller: _tabController,
                        labelColor: Colors.blue[800],
                        indicatorColor: Colors.blue[800],
                        tabs: const [
                          Tab(text: "Consola"),
                          Tab(text: "Dataset (Datos)"),
                          Tab(text: "Resultados"),
                        ],
                      ),
                    ),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          // A. CONSOLA
                          ConsoleWidget(logs: _logs, onEnviarComando: _enviarComandoManual),
                          
                          // B. DATASET (RAW DATA)
                          DataGrid(
                            data: _datasetRaw,
                            offset: _offsetActual,
                            totalRows: _totalFilas,
                            filasPorPagina: _filasPorPagina,
                            onPageChanged: _solicitarPagina,
                          ),
                          
                          // C. RESULTADOS (PESTAÑAS INTERNAS)
                          ResultsViewer(listaResultados: _historialResultados),
                        ],
                      ),
                    ),
                  ],
                ),
          ),
        ],
      ),
    );
  }
}