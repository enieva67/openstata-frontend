import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart'; // Para leer bonito
import 'package:shared_preferences/shared_preferences.dart';

class AIChatPanel extends StatefulWidget {
  final Function(String mensaje, String apiKey) onEnviarConsulta;
  final bool cargando;
  final List<Map<String, String>> historial; // [{role: 'user', content: 'hola'}, ...]

  const AIChatPanel({
    super.key,
    required this.onEnviarConsulta,
    required this.cargando,
    required this.historial,
  });

  @override
  State<AIChatPanel> createState() => _AIChatPanelState();
}

class _AIChatPanelState extends State<AIChatPanel> {
  final TextEditingController _msgController = TextEditingController();
  final TextEditingController _apiController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  String? _apiKeyGuardada;
  bool _configurandoKey = false;

  @override
  void initState() {
    super.initState();
    _cargarApiKey();
  }

  // Cargar Key del disco
  Future<void> _cargarApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _apiKeyGuardada = prefs.getString('gemini_api_key');
      if (_apiKeyGuardada != null) _apiController.text = _apiKeyGuardada!;
    });
  }

  // Guardar Key en disco
  Future<void> _guardarApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('gemini_api_key', _apiController.text.trim());
    setState(() {
      _apiKeyGuardada = _apiController.text.trim();
      _configurandoKey = false;
    });
  }

  void _enviar() {
    if (_msgController.text.isEmpty) return;
    if (_apiKeyGuardada == null || _apiKeyGuardada!.isEmpty) {
      setState(() => _configurandoKey = true);
      return;
    }
    
    widget.onEnviarConsulta(_msgController.text, _apiKeyGuardada!);
    _msgController.clear();
    
    // Auto-scroll al fondo
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 400, // Ancho del panel lateral
      color: Colors.white,
      child: Column(
        children: [
          // CABECERA
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
            color: Colors.blueAccent,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.auto_awesome, color: Colors.white),
                    SizedBox(width: 10),
                    Text("Copiloto IA", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.settings, color: Colors.white70),
                  tooltip: "Configurar API Key",
                  onPressed: () => setState(() => _configurandoKey = !_configurandoKey),
                )
              ],
            ),
          ),

          // CONFIGURACIÓN API KEY (Se muestra si no hay key o si se pide)
          if (_apiKeyGuardada == null || _configurandoKey)
            Container(
              padding: const EdgeInsets.all(15),
              color: Colors.yellow.shade50,
              child: Column(
                children: [
                  const Text("Se requiere una API Key de Google Gemini", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 5),
                  TextField(
                    controller: _apiController,
                    decoration: const InputDecoration(
                      labelText: "Pegar API Key aquí (AI Studio)",
                      border: OutlineInputBorder(),
                      isDense: true
                    ),
                    obscureText: true,
                  ),
                  const SizedBox(height: 5),
                  ElevatedButton(onPressed: _guardarApiKey, child: const Text("Guardar Key"))
                ],
              ),
            ),

          // LISTA DE MENSAJES
          Expanded(
            child: widget.historial.isEmpty 
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(30.0),
                    child: Text(
                      "👋 Hola, soy tu asistente estadístico.\n\nPuedo analizar tus datos, explicar resultados o sugerir modelos.\n\n¡Pregúntame algo!",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                )
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(10),
                  itemCount: widget.historial.length,
                  itemBuilder: (context, index) {
                    final msg = widget.historial[index];
                    final esUsuario = msg['role'] == 'user';
                    
                    return Align(
                      alignment: esUsuario ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 5),
                        padding: const EdgeInsets.all(12),
                        constraints: const BoxConstraints(maxWidth: 300),
                        decoration: BoxDecoration(
                          color: esUsuario ? Colors.blue.shade100 : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(10).copyWith(
                            bottomRight: esUsuario ? const Radius.circular(0) : null,
                            bottomLeft: !esUsuario ? const Radius.circular(0) : null
                          )
                        ),
                        // Usamos Markdown para que la IA pueda escribir negritas y listas
                        child: MarkdownBody(
                          data: msg['content']!,
                          selectable: true,
                          styleSheet: MarkdownStyleSheet(
                            p: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ),
                    );
                  },
                ),
          ),

          // INPUT DE TEXTO
          if (widget.cargando)
             const Padding(
               padding: EdgeInsets.all(10.0),
               child: LinearProgressIndicator(),
             )
          else
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(border: Border(top: BorderSide(color: Colors.grey.shade300))),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _msgController,
                      decoration: const InputDecoration(
                        hintText: "Escribe tu pregunta...",
                        border: InputBorder.none
                      ),
                      onSubmitted: (_) => _enviar(),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send, color: Colors.blueAccent),
                    onPressed: _enviar,
                  )
                ],
              ),
            )
        ],
      ),
    );
  }
}