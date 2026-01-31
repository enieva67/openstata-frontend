import 'package:flutter/material.dart';

class FeatureEngineeringDialog extends StatefulWidget {
  final List<String> columnas;
  final Function(Map<String, dynamic> params) onEjecutar;

  const FeatureEngineeringDialog({
    super.key,
    required this.columnas,
    required this.onEjecutar,
  });

  @override
  State<FeatureEngineeringDialog> createState() => _FeatureEngineeringDialogState();
}

class _FeatureEngineeringDialogState extends State<FeatureEngineeringDialog> {
  String operacion = "formula"; // Por defecto, el modo avanzado
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _formulaController = TextEditingController();
  final TextEditingController _escalarController = TextEditingController(text: "2");
  
  // Foco para saber dónde insertar el texto
  final FocusNode _formulaFocus = FocusNode();

  String? col1;
  String? col2;

  final Map<String, String> opcionesSimples = {
    "formula": "✨ Editor de Fórmulas (Avanzado)",
    "log": "Rápido: Logaritmo (ln)",
    "cuadrado": "Rápido: Cuadrado (x²)",
    "suma": "Rápido: Suma (A + B)",
    "resta": "Rápido: Resta (A - B)",
    "division": "Rápido: División (A / B)",
  };

  @override
  void initState() {
    super.initState();
    _nombreController.text = "nueva_var";
    if (widget.columnas.isNotEmpty) col1 = widget.columnas.first;
  }

  // --- LÓGICA DEL "EDITOR CIENTÍFICO" ---
  
  void _insertarTexto(String texto) {
    // Esta función inserta texto exactamente donde está el cursor
    final text = _formulaController.text;
    final selection = _formulaController.selection;
    
    // Si no hay selección válida, agregamos al final
    if (selection.start == -1) {
      _formulaController.text = text + texto;
      return;
    }

    final newText = text.replaceRange(selection.start, selection.end, texto);
    final newSelectionIndex = selection.start + texto.length;

    _formulaController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newSelectionIndex),
    );
    
    // Mantenemos el foco para seguir escribiendo
    _formulaFocus.requestFocus();
  }

  Widget _botonFuncion(String label, String valorInsercion, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.all(2.0),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color ?? Colors.grey[200],
          foregroundColor: color != null ? Colors.white : Colors.black87,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          minimumSize: const Size(40, 35),
          elevation: 1,
        ),
        onPressed: () => _insertarTexto(valorInsercion),
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool esFormula = operacion == "formula";
    
    // Lógica para modo simple
    bool necesitaCol1 = !esFormula;
    bool necesitaCol2 = ["suma", "resta", "multiplicacion", "division"].contains(operacion);

    return AlertDialog(
      title: const Row(children: [Icon(Icons.functions, color: Colors.teal), SizedBox(width: 10), Text("Ingeniería de Variables")]),
      content: SizedBox(
        width: 600, // Más ancho para el editor
        height: 600,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. NOMBRE DE LA NUEVA VARIABLE
              const Text("1. Nombre de la nueva variable:", style: TextStyle(fontWeight: FontWeight.bold)),
              TextField(
                controller: _nombreController,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.label_outline), 
                  hintText: "Ej: Ingreso_Real",
                  border: OutlineInputBorder()
                ),
              ),
              const SizedBox(height: 20),

              // 2. MODO DE OPERACIÓN
              const Text("2. Método de Construcción:", style: TextStyle(fontWeight: FontWeight.bold)),
              DropdownButtonFormField<String>(
                value: operacion,
                isExpanded: true,
                items: opcionesSimples.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
                onChanged: (val) => setState(() => operacion = val!),
                decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 10)),
              ),
              const SizedBox(height: 15),

              // --- UI DEL EDITOR AVANZADO ---
              if (esFormula) ...[
                const Text("Editor de Fórmulas:", style: TextStyle(color: Colors.teal, fontWeight: FontWeight.bold)),
                
                // PANTALLA
                TextField(
                  controller: _formulaController,
                  focusNode: _formulaFocus,
                  maxLines: 3,
                  style: const TextStyle(fontFamily: 'Courier New', fontSize: 16),
                  decoration: const InputDecoration(
                    hintText: "Selecciona variables y funciones abajo...",
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Color(0xFFFAFAFA),
                  ),
                ),
                const SizedBox(height: 10),

                // TECLADO MATEMÁTICO
                const Text("Operadores y Funciones:", style: TextStyle(fontSize: 12, color: Colors.grey)),
                Wrap(
                  spacing: 4,
                  children: [
                    _botonFuncion("+", " + ", color: Colors.orange[300]),
                    _botonFuncion("-", " - ", color: Colors.orange[300]),
                    _botonFuncion("*", " * ", color: Colors.orange[300]),
                    _botonFuncion("/", " / ", color: Colors.orange[300]),
                    _botonFuncion("(", "("),
                    _botonFuncion(")", ")"),
                    _botonFuncion("^n", "**", color: Colors.purple[200]), // Potencia Python
                    _botonFuncion("Log", "log(", color: Colors.blue[200]),
                    _botonFuncion("Exp", "exp(", color: Colors.blue[200]),
                    _botonFuncion("√", "sqrt(", color: Colors.blue[200]),
                    _botonFuncion("Abs", "abs(", color: Colors.blue[200]),
                  ],
                ),
                const SizedBox(height: 10),

                // SELECTOR DE VARIABLES
                const Text("Variables Disponibles (Clic para insertar):", style: TextStyle(fontSize: 12, color: Colors.grey)),
                Container(
                  height: 150,
                  width: double.infinity,
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(5)),
                  child: SingleChildScrollView(
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: widget.columnas.map((col) {
                        return ActionChip(
                          label: Text(col),
                          backgroundColor: Colors.teal.shade50,
                          labelStyle: const TextStyle(color: Colors.teal, fontSize: 11),
                          onPressed: () => _insertarTexto(col), // Inserta el nombre tal cual
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ] 
              
              // --- UI DEL MODO SIMPLE (DROPDOWNS) ---
              else ...[
                if (necesitaCol1) 
                  DropdownButtonFormField<String>(
                    value: col1,
                    decoration: const InputDecoration(labelText: "Variable A", border: OutlineInputBorder()),
                    items: widget.columnas.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                    onChanged: (val) => setState(() => col1 = val),
                  ),
                
                const SizedBox(height: 10),
                
                if (necesitaCol2) 
                  DropdownButtonFormField<String>(
                    value: col2,
                    decoration: const InputDecoration(labelText: "Variable B", border: OutlineInputBorder()),
                    items: widget.columnas.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                    onChanged: (val) => setState(() => col2 = val),
                  ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
        ElevatedButton.icon(
          icon: const Icon(Icons.calculate),
          label: const Text("Calcular"),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
          onPressed: () {
            if (_nombreController.text.isEmpty) return;

            widget.onEjecutar({
              "tipo_operacion": operacion,
              "nombre_nuevo": _nombreController.text,
              "col1": col1,
              "col2": col2,
              "formula": _formulaController.text, // Enviamos lo que haya escrito
            });
            Navigator.pop(context);
          },
        )
      ],
    );
  }
}
