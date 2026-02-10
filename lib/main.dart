import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:frontend/widgets/dialogs/prophet_dialog.dart';
import 'widgets/ai_chat_panel.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'widgets/dialogs/ml_training_dialog.dart';
import 'widgets/dialogs/doe_dialog.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart'; 
import 'widgets/dialogs/three_vars_dialog.dart';
import 'widgets/dialogs/arima_dialog.dart';
import 'widgets/dialogs/date_features_dialog.dart';
import 'widgets/dialogs/merge_dialog.dart';
import 'widgets/dialogs/reco_dialog.dart'; 
import 'widgets/dialogs/sql_table_dialog.dart';
import 'widgets/dialogs/concat_dialog.dart';
import 'widgets/dialogs/filter_dialog.dart';

// --- IMPORTS DE TUS SERVICIOS Y WIDGETS ---
import 'services/pdf_service.dart';
import 'services/logger_service.dart';
import 'services/process_service.dart'; 

import 'widgets/sidebar.dart';
import 'widgets/console.dart';
import 'widgets/datagrid.dart';
import 'widgets/results_viewer.dart';

import 'widgets/dialogs/cleaning_dialog.dart';
import 'widgets/dialogs/checkbox_params_dialog.dart';
import 'widgets/dialogs/multi_variable_dialog.dart';
import 'widgets/dialogs/hierarchical_dialog.dart';
import 'widgets/dialogs/graphic_config_dialog.dart'; // Importante para la config de gráficos
import 'widgets/dialogs/feature_engineering_dialog.dart';

// Función global para decodificar JSON en background (evita congelar UI)
Map<String, dynamic> _decodificarEnBackground(String mensaje) {
  return jsonDecode(mensaje);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 1. Iniciar el sistema de Logs (Vital para depurar el .exe)
  await LogService.init();
  
  // 2. Arrancar el Backend Python (Solo funciona en modo Release/Empaquetado)
  // En modo Debug (IDE), esta función no hace nada y te deja correr Python manual.
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
    // Aseguramos matar el proceso de Python al cerrar la ventana
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
  List<String> _listaDatasets = [];
  String? _datasetActivo;
  
  // --- ESTADO IA ---
  final List<Map<String, String>> _chatHistory = [];
  bool _iaPensando = false;
  bool _mostrarPanelIA = false; // <--- NUEVA VARIABLE DE CONTROL VISUAL

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
    // Iniciamos el intento de conexión persistente
    _conectarConReintentos();
  }

  // --- LÓGICA DE CONEXIÓN RESILIENTE ---
  void _conectarConReintentos() {
    if (_conectado) return;

    // Usamos LogService en lugar de print para ver esto en el archivo .log
    LogService.info("Intentando conectar al WebSocket (ws://127.0.0.1:8000/ws)...");

    try {
      _canal = WebSocketChannel.connect(Uri.parse('ws://127.0.0.1:8000/ws'));
      
      // *** EL SECRETO DEL ÉXITO ***
      // Enviamos "diagnostico" inmediatamente. 
      // Si Python está listo, responderá y activará el 'listen'.
      // Si no, el error disparará el reintento.
      _canal!.sink.add("diagnostico"); 

      _canal!.stream.listen(
        (mensaje) {
          // Si recibimos CUALQUIER mensaje, es que estamos dentro
          if (!_conectado) {
            setState(() => _conectado = true);
            LogService.info("✅ Conexión establecida con el motor Python.");
            _agregarLog("Motor estadístico conectado.");
          }
          _procesarMensaje(mensaje);
        },
        onError: (error) {
          // Si falla, es normal durante los primeros segundos de arranque
          LogService.info("Fallo de conexión (Python aun cargando...): $error");
          setState(() => _conectado = false);
          _reintentarLuego();
        },
        onDone: () {
          LogService.info("El servidor cerró la conexión.");
          setState(() => _conectado = false);
          _reintentarLuego();
        },
      );
    } catch (e) {
      LogService.error("Error crítico creando canal WebSocket", e);
      _reintentarLuego();
    }
  }
void _cambiarDatasetActivo(String nombreId) {
  // Optimismo UI
  setState(() => _datasetActivo = nombreId);
  
  var orden = {
    "comando": "gestion_datasets",
    "accion": "cambiar",
    "nombre": nombreId
  };
  _enviarAlBackend(jsonEncode(orden));
  _agregarLog("Cambiando a $nombreId...");
}
  void _reintentarLuego() {
    if (_timerReconexion != null && _timerReconexion!.isActive) return;
    
    // Reintentar cada 2 segundos permite que Python tenga tiempo de cargar Pandas
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
        const SnackBar(content: Text("Esperando conexión con el motor..."))
      );
    }
  }
Future<void> _enviarConsultaIA(String pregunta, {String? apiKeyOverride, Map<String, dynamic>? datosEspecificos}) async {
    // 1. Validar Key (Igual que antes)
    String? key = apiKeyOverride;
    if (key == null || key.isEmpty) {
      final prefs = await SharedPreferences.getInstance();
      key = prefs.getString('gemini_api_key');
    }
    
    // Si no hay key, forzamos abrir el panel para que el usuario la ponga
    if (key == null || key.isEmpty) {
       setState(() => _mostrarPanelIA = true); // <--- ABRIMOS EL PANEL
       if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Configura tu API Key en el panel lateral.")));
       return;
    }

    setState(() {
      _chatHistory.add({"role": "user", "content": pregunta});
      _iaPensando = true;
    });
    
    // --- OPTIMIZACIÓN: LIMPIEZA EN EL FRONTEND ---
    // Creamos una copia de los datos para no modificar lo que se ve en pantalla,
    // y le quitamos las imágenes y HTML pesados antes de enviar.
    Map<String, dynamic>? datosLigeros;
    
    if (datosEspecificos != null) {
      // 'Map.from' crea una copia nueva
      datosLigeros = Map<String, dynamic>.from(datosEspecificos);
      
      // Borramos lo que la IA no necesita y pesa mucho
      datosLigeros.remove('imagen');
      datosLigeros.remove('html_extra');
      datosLigeros.remove('df_nuevo'); 
    }
    // ---------------------------------------------

    var orden = {
      "comando": "consulta_ia",
      "api_key": key,
      "mensaje": pregunta,
      "analisis_puntual": datosLigeros // Enviamos la versión "Light"
    };
    
    _enviarAlBackend(jsonEncode(orden));
  }

  // --- PROCESAMIENTO DE MENSAJES ---
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
        else if (tipo == 'respuesta_ia') {
       setState(() {
         _iaPensando = false;
         _chatHistory.add({"role": "ai", "content": contenido});
       });
    }
    else if (tipo == 'error_ia') {
       setState(() {
         _iaPensando = false;
         _chatHistory.add({"role": "ai", "content": "⚠️ Error: $contenido"});
       });
    }
        else if (tipo == 'tabla_datos') {
          _datasetRaw = contenido;
          _columnasDisponibles = List<String>.from(contenido['columns']);
          
          if (contenido.containsKey('total_rows')) _totalFilas = contenido['total_rows'];
          if (contenido.containsKey('offset')) _offsetActual = contenido['offset'];
          
          if (_offsetActual == 0) _tabController.animateTo(1); 
        } 
        else if (tipo == 'sql_tablas') {
             // contenido trae: {'tablas': ['t1', 't2'], 'ruta_temp': '/path/file.db'}
             List<String> tablas = List<String>.from(contenido['tablas']);
             String rutaDb = contenido['ruta_temp'];

             showDialog(
               context: context,
               builder: (ctx) => SqlTableDialog(
                 tablas: tablas,
                 onSeleccionar: (tabla) {
                   // Pedimos cargar la tabla específica
                   var orden = {
                     "comando": "sql",
                     "accion": "cargar_tabla",
                     "ruta": rutaDb,
                     "tabla": tabla
                   };
                   _enviarAlBackend(jsonEncode(orden));
                   _agregarLog("Cargando tabla '$tabla'...");
                   setState(() => _cargando = true);
                 },
               )
             );
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
        else if (tipo == 'lista_datasets') {
         // contenido trae {lista_datasets: [...], active_id: "..."}
         setState(() {
           _listaDatasets = List<String>.from(contenido['lista_datasets']);
           _datasetActivo = contenido['active_id'];
         });
    }
        else if (tipo == 'html') {
             Map<String, dynamic> res = {
               'titulo': "Interactivo #${_historialResultados.length + 1}",
               'subtitulo': "Plotly Web Engine",
               'tipo': 'html', // Marcamos como html
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
        else if (tipo == 'grafico_hibrido') {
             // contenido trae {imagen: 'base64', html_extra: '<html>'}
             Map<String, dynamic> res = {
               'titulo': "Gráfico #${_historialResultados.length + 1}",
               'subtitulo': "Imagen Estática + Interactivo",
               'tipo': 'grafico_hibrido', 
               'datos': contenido
             };
             _historialResultados.add(res);
             _irAResultados();
        }
      });
    } catch (e) {
      LogService.error("Error procesando mensaje del backend", e);
      _agregarLog("Error de procesamiento interno.", esError: true);
    }
  }

  void _irAResultados() {
    Future.delayed(const Duration(milliseconds: 100), () {
       if(mounted) _tabController.animateTo(2);
    });
  }
  
  void _agregarLog(String texto, {bool esError = false}) {
    if (_logs.length > 200) _logs.removeAt(0);
    if (mounted) {
      setState(() {
         _logs.add(esError ? "🛑 $texto" : "PY > $texto");
      });
    }
  }

  // --- ACCIONES UI ---
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
Future<void> _exportarWorkspaceExcel() async {
    String? ruta = await FilePicker.platform.saveFile(
      dialogTitle: 'Guardar Workspace Completo',
      fileName: 'proyecto_completo.xlsx',
      allowedExtensions: ['xlsx'],
      type: FileType.custom,
    );
    if (ruta != null) {
      if (!ruta.endsWith('.xlsx')) ruta += ".xlsx";
      _enviarAlBackend(jsonEncode({"comando": "exportar_workspace", "ruta": ruta.replaceAll(r'\', r'/')}));
    }
  }
  Future<void> _cargarArchivo() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom, 
      // Agregamos db y sqlite a la lista permitida
      allowedExtensions: ['csv', 'xlsx', 'xls', 'sav', 'dta', 'parquet', 'db', 'sqlite'],
    );
    
    if (result != null) {
      String ruta = result.files.single.path!.replaceAll(r'\', r'/');
      String ext = ruta.split('.').last.toLowerCase();

      // SI ES SQL, INICIAMOS EL FLUJO DE CONEXIÓN
      if (ext == 'db' || ext == 'sqlite') {
        var orden = {
          "comando": "sql",
          "accion": "conectar",
          "ruta": ruta
        };
        _enviarAlBackend(jsonEncode(orden));
        _agregarLog("Conectando a base de datos...");
      } 
      // SI ES ARCHIVO NORMAL
      else {
        setState(() => _cargando = true);
        _enviarAlBackend("cargar $ruta");
      }
    }
  }

  Future<void> _exportarDataset() async {
    String? ruta = await FilePicker.platform.saveFile(
      dialogTitle: 'Guardar Dataset Limpio',
      fileName: 'dataset_limpio.csv',
      allowedExtensions: ['csv'],
      type: FileType.custom,
    );
    if (ruta != null) {
      if (!ruta.endsWith('.csv')) ruta += ".csv";
      _enviarAlBackend(jsonEncode({"comando": "exportar_dataset", "ruta": ruta.replaceAll(r'\', r'/')}));
    }
  }

  Future<void> _exportarReportePDF() async {
    if (_historialResultados.isEmpty) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("No hay resultados para exportar.")));
      return;
    }
    String? ruta = await FilePicker.platform.saveFile(
      dialogTitle: 'Exportar Reporte PDF',
      fileName: 'reporte_analisis.pdf',
      allowedExtensions: ['pdf'],
      type: FileType.custom,
    );
    if (ruta != null) {
      if (!ruta.endsWith('.pdf')) ruta += ".pdf";
      _agregarLog("Generando PDF...");
      try {
        await PdfService.generarReporte(ruta, _historialResultados);
        _agregarLog("✅ PDF guardado: $ruta");
      } catch (e) {
        _agregarLog("Error PDF: $e", esError: true);
      }
    }
  }

  void _manejarClickMenu(String nombre, String comando) {
    
    // ---------------------------------------------------------
    // GRUPO 1: COMANDOS QUE CARGAN DATOS (No requieren chequeo previo)
    // ---------------------------------------------------------
    if (comando == "ejemplo_california") {
       _enviarAlBackend(jsonEncode({"comando": "cargar_ejemplo", "nombre": "california"}));
       _agregarLog("Solicitando California Housing...");
       return; 
    }
    
    if (comando == "ejemplo_cancer") {
       _enviarAlBackend(jsonEncode({"comando": "cargar_ejemplo", "nombre": "cancer"}));
       _agregarLog("Solicitando Breast Cancer...");
       return; 
    }

    // ---------------------------------------------------------
    // BARRERA DE SEGURIDAD (Si no hay datos, no dejar pasar)
    // ---------------------------------------------------------
    if (_columnasDisponibles.isEmpty) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Carga un CSV primero.")));
      return;
    }

    // ---------------------------------------------------------
    // GRUPO 2: GESTIÓN DE DATOS Y MERGE
    // ---------------------------------------------------------
    
    // --- AQUÍ ESTÁ EL MERGE QUE FALTABA ---
    if (comando == "merge") {
       showDialog(
         context: context,
         builder: (ctx) => MergeDialog(
           datasetsDisponibles: _listaDatasets, // Pasamos la lista que tiene el main
           datasetActivo: _datasetActivo ?? "Desconocido",
           onEjecutar: (datasetB, colA, colB, tipo) {
             var orden = {
               "comando": "gestion_datasets", // O "ingenieria" segun tu backend
               "accion": "merge",
               "dataset_B": datasetB,
               "col_A": colA,
               "col_B": colB,
               "tipo_join": tipo
             };
             _enviarAlBackend(jsonEncode(orden));
             _agregarLog("Fusionando con $datasetB ($tipo)...");
           }
         )
       );
    }
    else if (comando == "crear_variable") {
       showDialog(
         context: context,
         builder: (ctx) => FeatureEngineeringDialog(
           columnas: _columnasDisponibles,
           onEjecutar: (params) {
             var orden = {"comando": "transformacion", "accion": "crear_variable", ...params};
             _enviarAlBackend(jsonEncode(orden));
             _agregarLog("Calculando variable...");
           }
         )
       );
    }
    else if (comando == "concat") {
       showDialog(
         context: context,
         builder: (ctx) => ConcatDialog(
           datasetsDisponibles: _listaDatasets,
           datasetActivo: _datasetActivo ?? "",
           onEjecutar: (dsB, eje) {
             var orden = {"comando": "gestion_datasets", "accion": "concat", "dataset_B": dsB, "eje": eje};
             _enviarAlBackend(jsonEncode(orden));
             _agregarLog("Concatenando...");
           }
         )
       );
    }
    else if (comando == "subset_cols") {
       // Reusamos CheckboxParamsDialog sin input numérico
       showDialog(
        context: context,
        builder: (ctx) => CheckboxParamsDialog(
          titulo: "Seleccionar Columnas a Mantener",
          columnas: _columnasDisponibles,
          showInput: false, 
          onEjecutar: (varsSel, _, __) { 
            var orden = {"comando": "gestion_datasets", "accion": "subset_cols", "variables": varsSel};
            _enviarAlBackend(jsonEncode(orden));
            _agregarLog("Extrayendo sub-dataset...");
          },
        ),
      );
    }
    else if (comando == "filtrar") {
       showDialog(
         context: context,
         builder: (ctx) => FilterDialog(
           onEjecutar: (consulta) {
             var orden = {"comando": "gestion_datasets", "accion": "filtrar", "consulta": consulta};
             _enviarAlBackend(jsonEncode(orden));
             _agregarLog("Filtrando filas...");
           }
         )
       );
    }
    else if (comando == "limpieza_datos") {
       _enviarAlBackend(jsonEncode({"comando": "transformacion", "accion": "info_columnas"}));
       _agregarLog("Analizando salud del dataset...");
    }
    else if (comando == "extraer_fecha") {
       showDialog(
         context: context,
         builder: (ctx) => DateFeaturesDialog(
           columnas: _columnasDisponibles,
           onEjecutar: (col) {
             var orden = {"comando": "transformacion", "accion": "extraer_fecha", "columna": col};
             _enviarAlBackend(jsonEncode(orden));
             _agregarLog("Generando variables temporales...");
           }
         )
       );
    }

    // ---------------------------------------------------------
    // GRUPO 3: MACHINE LEARNING (Con los 9 parámetros correctos)
    // ---------------------------------------------------------
    else if (comando == "ml_training") {
       showDialog(
         context: context,
         builder: (ctx) => MLTrainingDialog(
           columnas: _columnasDisponibles,
           onEjecutar: (y, xList, algo, val, k, explicar, tipoProb, hp, split) {
             var orden = {
               "comando": "analisis",
               "tipo_analisis": "ml_training",
               "y": y, "x": xList, "algoritmo": algo,
               "validacion": val, "k_folds": k,
               "explicar": explicar, "tipo_problema": tipoProb,
               "hyperparams": hp, "train_split": split
             };
             _enviarAlBackend(jsonEncode(orden));
             if (explicar) {
               _agregarLog("Entrenando con SHAP... (Lento)");
             } else {
               _agregarLog("Entrenando modelo...");
             }
           }
         )
       );
    }

    // ---------------------------------------------------------
    // GRUPO 4: SERIES DE TIEMPO
    // ---------------------------------------------------------
    else if (comando == "prophet") {
       showDialog(
         context: context,
         builder: (ctx) => ProphetDialog(
           columnas: _columnasDisponibles,
           onEjecutar: (f, v, pasos, freq) {
             var orden = {"comando": "analisis", "tipo_analisis": "prophet", "variables": [f, v], "pasos": pasos, "freq": freq};
             _enviarAlBackend(jsonEncode(orden));
             _agregarLog("Ejecutando Prophet...");
           }
         )
       );
    }
    else if (comando == "arima") {
       showDialog(
         context: context,
         builder: (ctx) => ArimaDialog(
           columnas: _columnasDisponibles,
           onEjecutar: (f, v, p, d, q, P, D, Q, m, pasos) {
             var orden = {
               "comando": "analisis", "tipo_analisis": "arima", 
               "variables": [f, v], 
               "p": p, "d": d, "q": q, "P": P, "D": D, "Q": Q, "m": m, "pasos": pasos
             };
             _enviarAlBackend(jsonEncode(orden));
             _agregarLog("Ajustando SARIMA...");
           }
         )
       );
    }

    // ---------------------------------------------------------
    // GRUPO 5: ANÁLISIS VARIOS Y GRÁFICOS
    // ---------------------------------------------------------
    
    else if (comando == "resumen") {
      _enviarAlBackend(jsonEncode({"comando": "analisis", "tipo_analisis": "resumen"}));
    } 
    else if (comando == "histograma") {
      _mostrarDialogoVariablesGenerico(nombre, comando, numVariables: 1);
    }
    else if (comando == "scatter" || comando == "boxplot" || comando == "scatter_web") {
      _mostrarDialogoVariablesGenerico(nombre, comando, numVariables: 2);
    }
    else if (["pca", "kmeans", "elbow", "tsne"].contains(comando)) {
       _mostrarDialogoParams(nombre, comando);
    }
    else if (comando == "svd" || comando == "apriori") {
       showDialog(
         context: context,
         builder: (ctx) => RecoDialog(
           columnas: _columnasDisponibles,
           tipo: comando,
           onEjecutar: (vars, param) {
             var orden = {"comando": "analisis", "tipo_analisis": comando, "variables": vars, "parametro_float": param};
             _enviarAlBackend(jsonEncode(orden));
           }
         )
       );
    }
    else if (comando == "jerarquico") {
       showDialog(
         context: context,
         builder: (ctx) => HierarchicalDialog(
           columnas: _columnasDisponibles,
           onEjecutar: (vars, metodo, k) {
             var orden = {"comando": "analisis", "tipo_analisis": "jerarquico", "variables": vars, "metodo": metodo, "parametro": k};
             _enviarAlBackend(jsonEncode(orden));
           }
         )
       );
    }
    else if (["ols_multiple", "logit", "roc_analysis"].contains(comando)) {
       _mostrarDialogoMultiVariable(nombre, comando);
    } 
    else if (comando == "heatmap" || comando == "spearman") {
       showDialog(
        context: context,
        builder: (ctx) => CheckboxParamsDialog(
          titulo: nombre, columnas: _columnasDisponibles, showInput: false, 
          onEjecutar: (varsSel, _, __) { 
            var orden = {"comando": "analisis", "tipo_analisis": comando, "variables": varsSel};
            _enviarAlBackend(jsonEncode(orden));
          },
        ),
      );
    }
    else if (comando == "config_graficos") {
       showDialog(
         context: context,
         builder: (ctx) => GraphicConfigDialog(
           onAplicar: (s, p, c) {
             var orden = {"comando": "config_graficos", "estilo": s, "paleta": p, "contexto": c};
             _enviarAlBackend(jsonEncode(orden));
           }
         )
       );
    }
    else if (comando == "anova_2way") {
       showDialog(
         context: context,
         builder: (ctx) => DoeDialog(
           columnas: _columnasDisponibles,
           onEjecutar: (respuesta, factorA, factorB) {
             var orden = {"comando": "analisis", "tipo_analisis": "anova_2way", "variables": [respuesta, factorA, factorB]};
             _enviarAlBackend(jsonEncode(orden));
           }
         )
       );
    }
    else if (comando == "scatter_3d" || comando == "granger" || comando == "kaplan_meier") {
       showDialog(
         context: context,
         builder: (ctx) => ThreeVarsDialog(
           columnas: _columnasDisponibles,
           onEjecutar: (x, y, z, color) {
             List<String> vars = [x, y, z];
             if (color != null && comando == "scatter_3d") vars.add(color);
             _enviarAlBackend(jsonEncode({"comando": "analisis", "tipo_analisis": comando, "variables": vars}));
           }
         )
       );
    }
    else if (["acf_pacf", "periodograma", "adf_test", "descomposicion"].contains(comando)) {
       _mostrarDialogoVariablesSimple("Configuración (Var 1=Fecha, Var 2=Serie)", comando);
    }
    
    // --- DEFAULT ---
    else {
      _mostrarDialogoVariablesSimple(nombre, comando);
    }
  }

  // --- HELPERS PARA ABRIR DIÁLOGOS ---

  void _abrirDialogoLimpieza(List<dynamic> info) {
     showDialog(
       context: context,
       builder: (ctx) => CleaningDialog(
         infoColumnas: info,
         onImputar: (col, metodo) => _enviarAlBackend(jsonEncode({"comando": "transformacion", "accion": "imputar", "columna": col, "metodo": metodo})),
         onCodificar: (col, mantener) { 
           var orden = {"comando": "transformacion", "accion": "dummies", "columna": col, "mantener_original": mantener};
           _enviarAlBackend(jsonEncode(orden));
         },
       ),
     );
  }

  void _mostrarDialogoParams(String nombre, String comando) {
     String labelParam = "Parámetro";
     int valDefecto = 2;
     bool inputVisible = true;

     if (comando == "pca") { labelParam = "Componentes (N)"; valDefecto = 2; }
     if (comando == "kmeans") { labelParam = "Clusters (k)"; valDefecto = 3; }
     if (comando == "elbow") { labelParam = "Max K"; valDefecto = 10; }

    if (comando == "tsne") { 
         labelParam = "Perplejidad (5-50)"; 
         valDefecto = 30; }
         
     showDialog(
      context: context,
      builder: (ctx) => CheckboxParamsDialog(
        titulo: "Configurar $nombre",
        columnas: _columnasDisponibles,
        labelParametro: labelParam,
        valorDefecto: valDefecto,
        showInput: inputVisible,
        
        // --- AQUÍ ESTÁ EL CAMBIO EN EL MAIN ---
        // Ahora recibimos 3 variables: varsSel, param, guardar
        onEjecutar: (varsSel, param, guardar) {
          var orden = {
            "comando": "analisis",
            "tipo_analisis": comando,
            "variables": varsSel,
            "parametro": param,
            "guardar": guardar // <--- Enviamos esto al backend
          };
          _enviarAlBackend(jsonEncode(orden));
          _agregarLog("Ejecutando $nombre...");
        },
        // --------------------------------------
      ),
    );
  }

  void _mostrarDialogoMultiVariable(String nombre, String comando) {
    showDialog(
      context: context,
      builder: (ctx) => MultiVariableDialog(
        titulo: nombre,
        columnas: _columnasDisponibles,
        onEjecutar: (y, xList) {
          var orden = {"comando": "analisis", "tipo_analisis": comando, "y": y, "x": xList};
          _enviarAlBackend(jsonEncode(orden));
        },
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
            const Text("OpenStata", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(width: 10),
            
            // Indicador de conexión
            Tooltip(
              message: _conectado ? "Conectado" : "Buscando...",
              child: Container(width: 10, height: 10, decoration: BoxDecoration(shape: BoxShape.circle, color: _conectado ? Colors.green : Colors.redAccent))
            ),

            const SizedBox(width: 20), // Separador

            // --- NUEVO: SELECTOR DE DATASETS ---
            // Solo se muestra si hay datasets cargados
            if (_listaDatasets.isNotEmpty)
              Container(
                height: 35, // Altura compacta
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(20), // Bordes redondeados
                  border: Border.all(color: Colors.grey.shade300)
                ),
                child: DropdownButtonHideUnderline( // Quita la línea fea de abajo
                  child: DropdownButton<String>(
                    value: _datasetActivo,
                    icon: const Icon(Icons.arrow_drop_down, color: Colors.blueAccent),
                    style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w500, fontSize: 13),
                    // Mapeamos la lista de strings a items del menú
                    items: _listaDatasets.map((ds) {
                      // Cortamos el nombre si es muy largo para que no rompa la barra
                      String nombreCorto = ds.length > 25 ? "${ds.substring(0, 22)}..." : ds;
                      return DropdownMenuItem(
                        value: ds,
                        child: Text(nombreCorto),
                      );
                    }).toList(),
                    onChanged: (nuevoDs) {
                      if (nuevoDs != null && nuevoDs != _datasetActivo) {
                        _cambiarDatasetActivo(nuevoDs);
                      }
                    },
                  ),
                ),
              ),
            // ------------------------------------
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        actions: [
          // BOTONES DE ACCIÓN (Igual que antes)
          IconButton(icon: const Icon(Icons.save_alt, color: Colors.green), onPressed: _exportarDataset, tooltip: "Guardar CSV"),
          IconButton(icon: const Icon(Icons.picture_as_pdf, color: Colors.redAccent), onPressed: _exportarReportePDF, tooltip: "Guardar PDF"),
          const SizedBox(width: 10),
          
          // BOTÓN DE IA
          IconButton(
            icon: Icon(Icons.auto_awesome, color: _mostrarPanelIA ? Colors.purple : Colors.grey),
            tooltip: "Asistente IA",
            onPressed: () => setState(() => _mostrarPanelIA = !_mostrarPanelIA),
          ),
          
          const SizedBox(width: 10),
          IconButton(icon: const Icon(Icons.folder_open, color: Colors.blueAccent), onPressed: _cargarArchivo, tooltip: "Abrir CSV"),
          const SizedBox(width: 15),
           IconButton(
            icon: const Icon(Icons.table_view, color: Colors.greenAccent), 
            tooltip: "Guardar Workspace (Excel Multi-hoja)",
            onPressed: _exportarWorkspaceExcel,
          ),
         
        ],
      ),
      
      // EL BODY AHORA TIENE 3 COLUMNAS SI EL CHAT ESTÁ ACTIVO
      body: _conectado 
        ? Row(
            children: [
              // COLUMNA 1: MENÚ LATERAL (Izquierda)
              SidebarMenu(onOpcionSeleccionada: _manejarClickMenu),

              // COLUMNA 2: ÁREA DE TRABAJO (Centro - Se expande)
              Expanded(
                flex: 7, // Ocupa el 70% del espacio disponible (o más si no hay chat)
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
                          ResultsViewer(
                            listaResultados: _historialResultados,
                            // Callback del botón "Interpretar"
                            onInterpretar: (prompt, datosJson) {
                              // Ya no necesitamos abrir drawer manual, la función lo hace
                              _enviarConsultaIA(prompt, datosEspecificos: datosJson);
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // COLUMNA 3: PANEL IA (Derecha - Condicional)
              if (_mostrarPanelIA) 
                Expanded(
                  flex: 3, // Ocupa el 30% del espacio (aprox 400px en monitores grandes)
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border(left: BorderSide(color: Colors.grey.shade300, width: 1)),
                      boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5, offset: const Offset(-2, 0))]
                    ),
                    child: AIChatPanel(
                      historial: _chatHistory,
                      cargando: _iaPensando,
                      // Pasamos la key como parámetro opcional si la tuviéramos
                      onEnviarConsulta: (msg, key) => _enviarConsultaIA(msg, apiKeyOverride: key),
                    ),
                  ),
                ),

            ],
          )
        : const Center(
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [CircularProgressIndicator(), SizedBox(height: 20), Text("Iniciando motor estadístico...")]),
          ),
    );
  }
}