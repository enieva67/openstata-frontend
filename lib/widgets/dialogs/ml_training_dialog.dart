import 'package:flutter/material.dart';

class MLTrainingDialog extends StatefulWidget {
  final List<String> columnas;
  final Function(String y, List<String> x, String algoritmo) onEjecutar;

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
  String algoritmo = "rf"; // Default Random Forest

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(children: [Icon(Icons.rocket_launch, color: Colors.orange), SizedBox(width: 10), Text("Entrenar Modelo ML")]),
      content: SizedBox(
        width: 400,
        height: 550,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. SELECCIÓN DE ALGORITMO
            const Text("1. Algoritmo:", style: TextStyle(fontWeight: FontWeight.bold)),
            DropdownButtonFormField<String>(
              value: algoritmo,
              decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 10)),
              items: const [
                DropdownMenuItem(value: "rf", child: Text("Random Forest (Bosques Aleatorios)")),
                DropdownMenuItem(value: "xgb", child: Text("XGBoost (Gradient Boosting)")),
                DropdownMenuItem(value: "gb", child: Text("Gradient Boosting (Sklearn)")),
                DropdownMenuItem(value: "logit", child: Text("Regresión Logística (Baseline)")),
              ],
              onChanged: (val) => setState(() => algoritmo = val!),
            ),
            const SizedBox(height: 15),

            // 2. VARIABLE OBJETIVO (Y)
            const Text("2. Objetivo (Binaria):", style: TextStyle(fontWeight: FontWeight.bold)),
            DropdownButtonFormField<String>(
              isExpanded: true,
              value: variableY,
              items: widget.columnas.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (val) => setState(() {
                variableY = val;
                variablesX.remove(val);
              }),
              decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 10)),
            ),
            const SizedBox(height: 15),

            // 3. PREDICTORES (X)
            const Text("3. Predictores (X):", style: TextStyle(fontWeight: FontWeight.bold)),
            Expanded(
              child: Container(
                decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300)),
                child: ListView.builder(
                  itemCount: widget.columnas.length,
                  itemBuilder: (context, index) {
                    final col = widget.columnas[index];
                    final esLaY = (col == variableY);
                    return CheckboxListTile(
                      title: Text(col, style: TextStyle(color: esLaY ? Colors.grey : Colors.black)),
                      value: variablesX.contains(col),
                      onChanged: esLaY ? null : (val) {
                        setState(() {
                          if (val == true) {
                            variablesX.add(col);
                          } else {
                            variablesX.remove(col);
                          }
                        });
                      },
                      dense: true,
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
        ElevatedButton.icon(
          icon: const Icon(Icons.play_circle_fill),
          label: const Text("Entrenar"),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
          onPressed: (variableY != null && variablesX.isNotEmpty) 
            ? () {
                widget.onEjecutar(variableY!, variablesX, algoritmo);
                Navigator.pop(context);
              } 
            : null,
        )
      ],
    );
  }
}
