import 'package:flutter/material.dart';

class MLTrainingDialog extends StatefulWidget {
  final List<String> columnas;
  final Function(String y, List<String> x, String algoritmo, String validacion, int k, bool explicar) onEjecutar;

  const MLTrainingDialog({
    super.key,
    required this.columnas,
    required this.onEjecutar,
  });

  @override
  State<MLTrainingDialog> createState() => _MLTrainingDialogState();
}

class _MLTrainingDialogState extends State<MLTrainingDialog> {
  String? variableY;
  final List<String> variablesX = [];
  String algoritmo = "rf";
  
  bool explicarShap = false;
  // Variables de Validación
  String metodoValidacion = "simple"; 
  final TextEditingController _kController = TextEditingController(text: "5");  

  @override
  void dispose() {
    _kController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(children: [Icon(Icons.rocket_launch, color: Colors.orange), SizedBox(width: 10), Text("Entrenar Modelo ML")]),
      content: SizedBox(
        width: 400,
        height: 600, // Altura aumentada para que quepa todo
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. SELECCIÓN DE ALGORITMO
              const Text("1. Algoritmo:", style: TextStyle(fontWeight: FontWeight.bold)),
              DropdownButtonFormField<String>(
                value: algoritmo, // Usamos value, no initialValue, para controlar el estado
                decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 10)),
                items: const [
                  DropdownMenuItem(value: "rf", child: Text("Random Forest")),
                  DropdownMenuItem(value: "xgb", child: Text("XGBoost")),
                  DropdownMenuItem(value: "gb", child: Text("Gradient Boosting")),
                  DropdownMenuItem(value: "logit", child: Text("Regresión Logística")),
                ],
                onChanged: (val) => setState(() => algoritmo = val!),
              ),
              const SizedBox(height: 15),

              // --- NUEVO: ESTRATEGIA DE VALIDACIÓN (Faltaba esto) ---
              const Text("2. Estrategia de Validación:", style: TextStyle(fontWeight: FontWeight.bold)),
              DropdownButtonFormField<String>(
                value: metodoValidacion,
                decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 10)),
                items: const [
                  DropdownMenuItem(value: "simple", child: Text("Simple Split (Train/Test)")),
                  DropdownMenuItem(value: "cv", child: Text("Cross-Validation (K-Fold)")),
                ],
                onChanged: (val) => setState(() => metodoValidacion = val!),
              ),
              
              // Campo K (Solo si es CV)
              if (metodoValidacion == "cv")
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: TextField(
                    controller: _kController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "Número de Folds (k)",
                      border: OutlineInputBorder()
                    ),
                  ),
                ),
              // -----------------------------------------------------

              const SizedBox(height: 15),

              // 3. VARIABLE OBJETIVO (Y)
              const Text("3. Objetivo (Binaria):", style: TextStyle(fontWeight: FontWeight.bold)),
              DropdownButtonFormField<String>(
                isExpanded: true,
                value: variableY, // Usamos value
                items: widget.columnas.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (val) => setState(() {
                  variableY = val;
                  variablesX.remove(val);
                }),
                decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 10)),
              ),
              const SizedBox(height: 15),

              // 4. PREDICTORES (X)
              const Text("4. Predictores (X):", style: TextStyle(fontWeight: FontWeight.bold)),
              Container(
                height: 150, // Altura fija para scroll
                decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300)),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: widget.columnas.length,
                  itemBuilder: (context, index) {
                    final col = widget.columnas[index];
                    final esLaY = (col == variableY);
                    return CheckboxListTile(
                      title: Text(col, style: TextStyle(color: esLaY ? Colors.grey : Colors.black)),
                      value: variablesX.contains(col),
                      dense: true,
                      onChanged: esLaY ? null : (val) {
                        setState(() {
                          if (val == true) {
                            variablesX.add(col);
                          } else {
                            variablesX.remove(col);
                          }
                        });
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              
              // CHECKBOX SHAP
              Container(
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.purple.withOpacity(0.3))
                ),
                child: CheckboxListTile(
                  title: const Text("Generar Explicación (SHAP)", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.purple)),
                  subtitle: const Text("Crea gráficos interactivos de importancia de variables. (Más lento)", style: TextStyle(fontSize: 11)),
                  value: explicarShap,
                  onChanged: (val) => setState(() => explicarShap = val!),
                  activeColor: Colors.purple,
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context), 
          child: const Text("Cancelar")
        ),
        ElevatedButton.icon(
          icon: const Icon(Icons.play_circle_fill),
          label: const Text("Entrenar"),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
          
          onPressed: (variableY != null && variablesX.isNotEmpty) 
            ? () {
                int k = int.tryParse(_kController.text) ?? 5;
                // Enviamos los 5 argumentos
                widget.onEjecutar(variableY!, variablesX, algoritmo, metodoValidacion, k, explicarShap);
                Navigator.pop(context);
              } 
            : null,
        )
      ],
    );
  }
}
