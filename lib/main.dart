import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:frontend/widgets/dialogs/graphic_config_dialog.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart'; 
import 'widgets/dialogs/hierarchical_dialog.dart';
// Imports de tus servicios y widgets
import 'services/pdf_service.dart';
import 'services/logger_service.dart';
import 'services/process_service.dart'; 
import 'widgets/dialogs/cleaning_dialog.dart';
import 'widgets/dialogs/checkbox_params_dialog.dart';
import 'widgets/sidebar.dart';
import 'widgets/console.dart';
import 'widgets/datagrid.dart';
import 'widgets/dialogs/multi_variable_dialog.dart';
import 'widgets/results_viewer.dart';

// Función para decodificar JSON en background
Map<String, dynamic> _decodificarEnBackground(String mensaje) {
  return jsonDecode(mensaje);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializamos servicios
  await LogService.init();
  
  // En modo Debug (IDE), esto no hará nada (y está bien, porque tú corres Python aparte)
  await ProcessService.iniciarBackend();

  runApp(const MiStataApp());
}

class MiStataApp extends StatefulWidget {
  const MiStataApp({super.key});

  @override
  State<MiStataApp> createState() => _MiStataAppState();
}

class _MiStataAppState extends State<MiStataApp> with WidgetsBindingObserver {
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached) {
      ProcessService.cerrarBackend();
    }
  }

   @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OpenStata Evolution',
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

class PantallaPrincipal extends StatefulWidget {
  const PantallaPrincipal({super.key});

  @override
  State<PantallaPrincipal> createState() => _PantallaPrincipalState();
}

class _PantallaPrincipalState extends State<PantallaPrincipal> with SingleTickerProviderStateMixin {
  
  // --- CONEXIÓN ---
  WebSocketChannel? _canal;
  bool _conectado = false;
  Timer? _timerReconexion;

  // --- ESTADO ---
  final List<String> _logs = []; 
  Map<String, dynamic>? _datasetRaw;
  List<String> _columnasDisponibles = [];
  final List<Map<String, dynamic>> _historialResultados = [];

  // Paginación
  final int _filasPorPagina = 100;
  int _offsetActual = 0;
  int _totalFilas = 0;
  bool _cargando = false;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _conectarConReintentos();
  }

  void _conectarConReintentos() {
    if (_conectado) return;

    print("Intentando conectar al WebSocket..."); // Print para ver en consola debug

    try {
      _canal = WebSocketChannel.connect(Uri.parse('ws://127.0.0.1:8000/ws'));
      
      // --- LA SOLUCIÓN AL BLOQUEO ---
      // Enviamos un mensaje INMEDIATO para "despertar" el flujo.
      // Si no hacemos esto, Python espera y nosotros esperamos -> Deadlock.
      _canal!.sink.add("diagnostico"); 
      // ------------------------------

      _canal!.stream.listen(
        (mensaje) {
          // Apenas Python responda al "diagnostico", entramos aquí
          if (!_conectado) {
            setState(() => _conectado = true);
            _agregarLog("Conectado al motor estadístico.");
          }
          _procesarMensaje(mensaje);
        },
        onError: (error) {
          if (kDebugMode) print("Error conexión: $error");
          setState(() => _conectado = false);
          _reintentarLuego();
        },
        onDone: () {
          setState(() => _conectado = false);
          _reintentarLuego();
        },
      );
    } catch (e) {
      if (kDebugMode) print("Fallo al crear canal: $e");
      _reintentarLuego();
    }
  }

  void _reintentarLuego() {
    if (_timerReconexion != null && _timerReconexion!.isActive) return;
    _timerReconexion = Timer(const Duration(seconds: 2), _conectarConReintentos);
  }

  @override
  void dispose() {
    _timerReconexion?.cancel();
    _canal?.sink.close();
    _tabController.dispose();
    super.dispose();
  }

  void _enviarAlBackend(String jsonCmd) {
    if (_canal != null && _conectado) {
      _canal!.sink.add(jsonCmd);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Esperando conexión con Python..."))
      );
    }
  }

  // --- PROCESAMIENTO ---
  Future<void> _procesarMensaje(String mensajeRaw) async {
    try {
      final datos = await compute(_decodificarEnBackground, mensajeRaw);
      
      final tipo = datos['tipo'];
      final contenido = datos['contenido'];

      if (!mounted) return;

      setState(() {
        _cargando = false;
        
        if (tipo == 'texto') {
          _agregarLog(contenido);
        } 
        else if (tipo == 'error') {
          _agregarLog(contenido, esError: true);
        } 
        else if (tipo == 'tabla_datos') {
          _datasetRaw = contenido;
          _columnasDisponibles = List<String>.from(contenido['columns']);
          if (contenido.containsKey('total_rows')) _totalFilas = contenido['total_rows'];
          if (contenido.containsKey('offset')) _offsetActual = contenido['offset'];
          
          if (_offsetActual == 0) _tabController.animateTo(1); 
        } 
        else if (tipo == 'tabla_resumen') {
             Map<String, dynamic> res = {
               'titulo': "Análisis #${_historialResultados.length + 1}",
               'subtitulo': DateTime.now().toString().split('.')[0],
               'datos': contenido
             };
             _historialResultados.add(res);
             _irAResultados();
        }
        else if (tipo == 'info_columnas') {
           _abrirDialogoLimpieza(contenido['info']);
        }
        else if (tipo == 'grafico') {
             Map<String, dynamic> res = {
               'titulo': "Gráfico #${_historialResultados.length + 1}",
               'subtitulo': "Visualización",
               'tipo': 'imagen',
               'datos': contenido
             };
             _historialResultados.add(res);
             _irAResultados();
        }
      });
    } catch (e) {
      _agregarLog("Error procesando: $e", esError: true);
    }
  }

  void _irAResultados() {
    Future.delayed(const Duration(milliseconds: 100), () {
       if(mounted) _tabController.animateTo(2);
    });
  }
  
  void _agregarLog(String texto, {bool esError = false}) {
    if (_logs.length > 200) _logs.removeAt(0);
    // Verificación de mounted para evitar errores al salir
    if (mounted) {
      setState(() {
         _logs.add(esError ? "🛑 $texto" : "PY > $texto");
      });
    }
  }

  // --- UI ACTIONS ---
  void _enviarComandoManual(String texto) {
    if (texto.trim().isEmpty) return;
    setState(() => _logs.add("YO > $texto"));
    _enviarAlBackend(texto);
  }

  void _solicitarPagina(int nuevoInicio) {
    setState(() => _cargando = true);
    var orden = {"comando": "paginacion", "inicio": nuevoInicio, "limite": _filasPorPagina};
    _enviarAlBackend(jsonEncode(orden));
  }

  Future<void> _cargarArchivo() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['csv']);
    if (result != null) {
      setState(() => _cargando = true);
      String ruta = result.files.single.path!.replaceAll(r'\', r'/'); 
      _enviarAlBackend("cargar $ruta");
    }
  }

  Future<void> _exportarDataset() async {
    String? ruta = await FilePicker.platform.saveFile(
      dialogTitle: 'Guardar Dataset', fileName: 'dataset.csv', allowedExtensions: ['csv'], type: FileType.custom
    );
    if (ruta != null) {
      if (!ruta.endsWith('.csv')) ruta += ".csv";
      _enviarAlBackend(jsonEncode({"comando": "exportar_dataset", "ruta": ruta.replaceAll(r'\', r'/')}));
    }
  }

  Future<void> _exportarReportePDF() async {
    if (_historialResultados.isEmpty) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Sin resultados.")));
      return;
    }
    String? ruta = await FilePicker.platform.saveFile(
      dialogTitle: 'Guardar PDF', fileName: 'reporte.pdf', allowedExtensions: ['pdf'], type: FileType.custom
    );
    if (ruta != null) {
      if (!ruta.endsWith('.pdf')) ruta += ".pdf";
      _agregarLog("Generando PDF...");
      await PdfService.generarReporte(ruta, _historialResultados);
      _agregarLog("✅ PDF guardado.");
    }
  }

  // --- DIÁLOGOS ---
  void _manejarClickMenu(String nombre, String comando) {
    if (_columnasDisponibles.isEmpty) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Carga un CSV primero.")));
      return;
    }

    if (comando == "resumen") {
      _enviarAlBackend(jsonEncode({"comando": "analisis", "tipo_analisis": "resumen"}));
    } 
    else if (comando == "limpieza_datos") {
       _enviarAlBackend(jsonEncode({"comando": "transformacion", "accion": "info_columnas"}));
       _agregarLog("Analizando salud...");
    }
    else if (comando == "histograma") {
      _mostrarDialogoVariablesGenerico(nombre, comando, numVariables: 1);
    }
    else if (comando == "scatter" || comando == "boxplot") {
      _mostrarDialogoVariablesGenerico(nombre, comando, numVariables: 2);
    }
    else if (["pca", "kmeans", "elbow"].contains(comando)) {
       _mostrarDialogoParams(nombre, comando);
    }
    else if (comando == "jerarquico") {
       showDialog(
         context: context,
         builder: (ctx) => HierarchicalDialog(
           columnas: _columnasDisponibles,
           onEjecutar: (vars, metodo, k) {
             var orden = {
               "comando": "analisis",
               "tipo_analisis": "jerarquico",
               "variables": vars,
               "metodo": metodo,
               "parametro": k // Usamos parametro para enviar K
             };
             _enviarAlBackend(jsonEncode(orden));
             _agregarLog("Calculando Dendrograma ($metodo)...");
           }
         )
       );
    }
    else if (["ols_multiple", "logit", "roc_analysis"].contains(comando)) {
       _mostrarDialogoMultiVariable(nombre, comando);
    } 
        // CASO HEATMAP (Matriz de correlación)
    else if (comando == "heatmap") {
       showDialog(
        context: context,
        builder: (ctx) => CheckboxParamsDialog(
          titulo: "Variables para Matriz",
          columnas: _columnasDisponibles,
          showInput: false, // <--- ¡LA SOLUCIÓN! Ocultamos el campo numérico
          onEjecutar: (varsSel, _) { // El '_' significa que ignoramos el parámetro
            var orden = {
              "comando": "analisis",
              "tipo_analisis": "heatmap",
              "variables": varsSel
            };
            _enviarAlBackend(jsonEncode(orden));
            _agregarLog("Generando Heatmap...");
          },
        ),
      );
    }
    else if (comando == "config_graficos") {
       showDialog(
         context: context,
         builder: (ctx) => GraphicConfigDialog(
           onAplicar: (s, p, c) {
             var orden = {
               "comando": "config_graficos",
               "estilo": s, "paleta": p, "contexto": c
             };
             _enviarAlBackend(jsonEncode(orden));
           }
         )
       );
    }
    else {
      _mostrarDialogoVariablesSimple(nombre, comando);
    }
  }

  void _abrirDialogoLimpieza(List<dynamic> info) {
     showDialog(
       context: context,
       builder: (ctx) => CleaningDialog(
         infoColumnas: info,
         onImputar: (col, metodo) => _enviarAlBackend(jsonEncode({"comando": "transformacion", "accion": "imputar", "columna": col, "metodo": metodo})),
         onCodificar: (col, mantener) { // Agrega 'mantener'
           var orden = {
             "comando": "transformacion", 
             "accion": "dummies", 
             "columna": col, 
             "mantener_original": mantener // Enviamos al backend
           };
           _enviarAlBackend(jsonEncode(orden));
         },
       ),
     );
  }

  void _mostrarDialogoParams(String nombre, String comando) {
     String labelParam = "Parámetro";
     int valDefecto = 2;
     bool inputVisible = true; // Por defecto visible

     if (comando == "pca") { labelParam = "Componentes (N)"; valDefecto = 2; }
     if (comando == "kmeans") { labelParam = "Clusters (k)"; valDefecto = 3; }
     if (comando == "elbow") { labelParam = "Max K"; valDefecto = 10; }
     
     // Para Jerárquico, el parámetro a veces sobra, podríamos ocultarlo también si quisieras
     if (comando == "jerarquico") { 
         // Ocultemos el input para jerarquico también, ya que el dendrograma muestra todo
         inputVisible = false; 
     }

     showDialog(
      context: context,
      builder: (ctx) => CheckboxParamsDialog(
        titulo: "Configurar $nombre",
        columnas: _columnasDisponibles,
        labelParametro: labelParam,
        valorDefecto: valDefecto,
        showInput: inputVisible, // <--- Pasamos la bandera
        onEjecutar: (varsSel, param) {
          var orden = {
            "comando": "analisis",
            "tipo_analisis": comando,
            "variables": varsSel,
            "parametro": param
          };
          _enviarAlBackend(jsonEncode(orden));
          _agregarLog("Ejecutando $nombre...");
        },
      ),
    );
  }

  void _mostrarDialogoMultiVariable(String nombre, String comando) {
    showDialog(
      context: context,
      builder: (ctx) => MultiVariableDialog(
        titulo: nombre, columnas: _columnasDisponibles,
        onEjecutar: (y, xList) => _enviarAlBackend(jsonEncode({"comando": "analisis", "tipo_analisis": comando, "y": y, "x": xList})),
      ),
    );
  }

  void _mostrarDialogoVariablesSimple(String titulo, String comando) {
    String? v1; String? v2;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateDlg) => AlertDialog(
          title: Text(titulo),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(decoration: const InputDecoration(labelText: "Variable 1"), items: _columnasDisponibles.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(), onChanged: (val) => setStateDlg(() => v1 = val)),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(decoration: const InputDecoration(labelText: "Variable 2"), items: _columnasDisponibles.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(), onChanged: (val) => setStateDlg(() => v2 = val)),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancelar")),
            ElevatedButton(
              onPressed: (v1 != null && v2 != null) ? () {
                _enviarAlBackend(jsonEncode({"comando": "analisis", "tipo_analisis": comando, "variables": [v1!, v2!]}));
                Navigator.pop(ctx);
              } : null,
              child: const Text("Ejecutar"),
            )
          ],
        ),
      ),
    );
  }

  void _mostrarDialogoVariablesGenerico(String titulo, String comando, {required int numVariables}) {
    String? v1; String? v2; String? v3;
    bool permiteColor = (comando == "scatter");

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateDlg) => AlertDialog(
          title: Row(children: [const Icon(Icons.bar_chart, color: Colors.blue), const SizedBox(width: 10), Text(titulo)]),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(decoration: InputDecoration(labelText: numVariables == 1 ? "Variable Principal" : "Eje Y"), items: _columnasDisponibles.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(), onChanged: (val) => setStateDlg(() => v1 = val)),
              const SizedBox(height: 10),
              if (numVariables >= 2)
                DropdownButtonFormField<String>(decoration: const InputDecoration(labelText: "Eje X"), items: _columnasDisponibles.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(), onChanged: (val) => setStateDlg(() => v2 = val)),
              if (permiteColor) ...[
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: "Color (Opcional)", filled: true, fillColor: Color(0xFFE3F2FD)),
                  items: [const DropdownMenuItem(value: null, child: Text("--- Sin Agrupación ---")), ..._columnasDisponibles.map((c) => DropdownMenuItem(value: c, child: Text(c)))],
                  onChanged: (val) => setStateDlg(() => v3 = val),
                ),
              ]
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancelar")),
            ElevatedButton(
              onPressed: (v1 != null && (numVariables < 2 || v2 != null)) 
                ? () {
                    List<String> vars = [v1!];
                    if (v2 != null) vars.add(v2!);
                    if (v3 != null) vars.add(v3!);
                    _enviarAlBackend(jsonEncode({"comando": "analisis", "tipo_analisis": comando, "variables": vars}));
                    Navigator.pop(ctx);
                  } 
                : null,
              child: const Text("Generar"),
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
        title: Row(
          children: [
            const Text("OpenStata Evolution"),
            const SizedBox(width: 10),
            Container(width: 10, height: 10, decoration: BoxDecoration(shape: BoxShape.circle, color: _conectado ? Colors.green : Colors.red))
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.save_alt), onPressed: _exportarDataset),
          IconButton(icon: const Icon(Icons.picture_as_pdf), onPressed: _exportarReportePDF),
          IconButton(icon: const Icon(Icons.folder_open), onPressed: _cargarArchivo),
        ],
      ),
      body: _conectado 
        ? Row(
            children: [
              SidebarMenu(onOpcionSeleccionada: _manejarClickMenu),
              Expanded(
                child: Column(
                  children: [
                    Container(
                      color: Colors.grey[200],
                      child: TabBar(controller: _tabController, labelColor: Colors.blue[800], tabs: const [Tab(text: "Consola"), Tab(text: "Datos"), Tab(text: "Resultados")]),
                    ),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          ConsoleWidget(logs: _logs, onEnviarComando: _enviarComandoManual),
                          DataGrid(data: _datasetRaw, offset: _offsetActual, totalRows: _totalFilas, filasPorPagina: _filasPorPagina, onPageChanged: _solicitarPagina),
                          ResultsViewer(listaResultados: _historialResultados),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          )
        : const Center(
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [CircularProgressIndicator(), SizedBox(height: 20), Text("Esperando al motor estadístico...")]),
          ),
    );
  }
}
