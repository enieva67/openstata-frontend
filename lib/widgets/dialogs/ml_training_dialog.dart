import 'package:flutter/material.dart';

import '../dynamic_params_form.dart'; // Asegúrate de tener este archivo creado

class MLTrainingDialog extends StatefulWidget {
  final List<String> columnas;
  
  // FIRMA ACTUALIZADA CON 9 PARÁMETROS
  final Function(
    String y, 
    List<String> x, 
    String algoritmo, 
    String validacion, 
    int k, 
    bool explicar, 
    String tipoProblema,
    Map<String, dynamic> hyperparams, // <--- NUEVO
    double trainSplit                 // <--- NUEVO
  ) onEjecutar;

  const MLTrainingDialog({
    super.key,
    required this.columnas,
    required this.onEjecutar,
  });

  @override
  State<MLTrainingDialog> createState() => _MLTrainingDialogState();
}

class _MLTrainingDialogState extends State<MLTrainingDialog> {
  // Estado de Selección
  String? variableY;
  final List<String> variablesX = [];
  
  // Estado de Configuración
  String algoritmo = "rf";
  bool explicarShap = false;
  String tipoProblema = "clasificacion"; 
  String metodoValidacion = "simple"; 
  final TextEditingController _kController = TextEditingController(text: "5");

  // NUEVO ESTADO PARA AVANZADO
  Map<String, dynamic> hyperparams = {};
  double trainSplit = 0.7; // 70% por defecto

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
        width: 450, // Un poco más ancho para que quepan sliders
        height: 650, // Más alto para el acordeón
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 0. TIPO DE PROBLEMA
              const Text("0. Tipo de Problema:", style: TextStyle(fontWeight: FontWeight.bold)),
              DropdownButtonFormField<String>(
                value: tipoProblema,
                decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 10)),
                items: const [
                  DropdownMenuItem(value: "clasificacion", child: Text("Clasificación (Binaria 0/1)")),
                  DropdownMenuItem(value: "regresion", child: Text("Regresión (Numérica Continua)")),
                ],
                onChanged: (val) => setState(() => tipoProblema = val!),
              ),
              const SizedBox(height: 15),

              // 1. SELECCIÓN DE ALGORITMO
              const Text("1. Algoritmo:", style: TextStyle(fontWeight: FontWeight.bold)),
              DropdownButtonFormField<String>(
                value: algoritmo, 
                decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 10)),
                items: const [
                  DropdownMenuItem(value: "rf", child: Text("Random Forest (Arboles)")),
                  DropdownMenuItem(value: "xgb", child: Text("XGBoost (Boosting)")),
                  DropdownMenuItem(value: "gb", child: Text("Gradient Boosting (Sklearn)")),
                  DropdownMenuItem(value: "svm", child: Text("Support Vector Machines (SVM)")),
                  DropdownMenuItem(value: "knn", child: Text("K-Nearest Neighbors (KNN)")),
                  DropdownMenuItem(value: "ridge", child: Text("Ridge (Regresión L2)")),
                  DropdownMenuItem(value: "lasso", child: Text("Lasso (Regresión L1)")),
                  DropdownMenuItem(value: "logit", child: Text("Lineal / Logística (Base)")),
                ],
                onChanged: (val) => setState(() => algoritmo = val!),
              ),
              const SizedBox(height: 15),

              // 2. VALIDACIÓN
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
              
              if (metodoValidacion == "cv")
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: TextField(
                    controller: _kController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: "Número de Folds (k)", border: OutlineInputBorder()),
                  ),
                ),
              const SizedBox(height: 15),

              // --- NUEVO ACORDEÓN: CONFIGURACIÓN AVANZADA ---
              Card(
                elevation: 0,
                color: Colors.blue.withOpacity(0.05),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: Colors.blue.shade100)),
                child: ExpansionTile(
                  title: const Text("⚙️ Configuración Avanzada", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.blue)),
                  childrenPadding: const EdgeInsets.all(10),
                  children: [
                    // 1. Slider de Train/Test Split (Solo si es validación Simple)
                    if (metodoValidacion == "simple") ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Entrenamiento %:", style: TextStyle(fontSize: 12)),
                          Text("${(trainSplit * 100).toInt()}%", style: const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Slider(
                        value: trainSplit,
                        min: 0.5,
                        max: 0.9,
                        divisions: 4, 
                        label: "${(trainSplit * 100).toInt()}%",
                        onChanged: (v) => setState(() => trainSplit = v),
                      ),
                      const Divider(),
                    ],

                    // 2. Formulario Dinámico de Hiperparámetros
                    DynamicParamsForm(
                      algoritmo: algoritmo,
                      onParamsChanged: (params) {
                        // Actualizamos el estado con lo que viene del formulario hijo
                        hyperparams = params;
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 15),

              // 3. VARIABLE OBJETIVO (Y)
              const Text("3. Objetivo (Y):", style: TextStyle(fontWeight: FontWeight.bold)),
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

              // 4. PREDICTORES (X)
              const Text("4. Predictores (X):", style: TextStyle(fontWeight: FontWeight.bold)),
              Container(
                height: 150, 
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
                  subtitle: const Text("Gráficos de importancia.", style: TextStyle(fontSize: 11)),
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
                
                // LLAMADA FINAL CON LOS 9 ARGUMENTOS
                widget.onEjecutar(
                  variableY!, 
                  variablesX, 
                  algoritmo, 
                  metodoValidacion, 
                  k, 
                  explicarShap, 
                  tipoProblema,
                  hyperparams, // <--- NUEVO
                  trainSplit   // <--- NUEVO
                );
                
                Navigator.pop(context);
              } 
            : null,
        )
      ],
    );
  }
}