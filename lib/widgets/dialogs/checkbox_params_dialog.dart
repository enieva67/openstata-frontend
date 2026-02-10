import 'package:flutter/material.dart';

class CheckboxParamsDialog extends StatefulWidget {
  final String titulo;
  final List<String> columnas;
  final String labelParametro; 
  final int valorDefecto;
  final bool showInput; 
  
  // 1. MODIFICACIÓN: Agregamos 'bool guardar' a la función callback
  final Function(List<String> vars, int param, bool guardar) onEjecutar;

  const CheckboxParamsDialog({
    super.key,
    required this.titulo,
    required this.columnas,
    this.labelParametro = "Parámetro",
    this.valorDefecto = 0,
    this.showInput = true, 
    required this.onEjecutar,
  });

  @override
  State<CheckboxParamsDialog> createState() => _CheckboxParamsDialogState();
}

class _CheckboxParamsDialogState extends State<CheckboxParamsDialog> {
  final List<String> seleccionadas = [];
  late TextEditingController _paramController;
  
  // 2. MODIFICACIÓN: Variable de estado para el checkbox
  bool guardarResultado = false;

  @override
  void initState() {
    super.initState();
    _paramController = TextEditingController(text: widget.valorDefecto.toString());
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.hub, color: Colors.purple),
          const SizedBox(width: 10),
          Text(widget.titulo, style: const TextStyle(fontSize: 16)),
        ],
      ),
      content: SizedBox(
        width: 350,
        height: 550, // Aumentamos un poco la altura para que quepa el checkbox
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. CONFIGURACIÓN DEL PARÁMETRO
            if (widget.showInput) ...[
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(5)),
                child: TextField(
                  controller: _paramController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: widget.labelParametro,
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.tune),
                  ),
                ),
              ),
              const SizedBox(height: 15),
            ],

            // 2. SELECCIÓN DE VARIABLES
            const Text("Selecciona Variables (Numéricas):", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            Expanded(
              child: Container(
                decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300)),
                child: ListView.builder(
                  itemCount: widget.columnas.length,
                  itemBuilder: (context, index) {
                    final col = widget.columnas[index];
                    return CheckboxListTile(
                      title: Text(col),
                      value: seleccionadas.contains(col),
                      dense: true,
                      onChanged: (val) {
                        setState(() {
                          if (val == true) {
                            seleccionadas.add(col);
                          } else {
                            seleccionadas.remove(col);
                          }
                        });
                      },
                    );
                  },
                ),
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.only(top: 5, bottom: 10),
              child: Text("${seleccionadas.length} seleccionadas", style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ),

            // 3. MODIFICACIÓN: EL NUEVO CHECKBOX
            // Solo lo mostramos si es un análisis que genera datos nuevos (PCA/KMeans)
            // Asumimos que si hay input numérico (showInput=true), es PCA/Kmeans. 
            // Si es Heatmap (showInput=false), no tiene sentido guardar dataset.
            if (widget.showInput) 
              Container(
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(color: Colors.green.withOpacity(0.3))
                ),
                child: CheckboxListTile(
                  title: const Text("Guardar como Dataset", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.green)),
                  subtitle: const Text("Crea una nueva tabla en memoria con los resultados.", style: TextStyle(fontSize: 11)),
                  value: guardarResultado,
                  onChanged: (v) => setState(() => guardarResultado = v!),
                  dense: true,
                  activeColor: Colors.green,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
        
        ElevatedButton(
          onPressed: seleccionadas.length >= 2 ? () {
            int param = 0;
            
            if (widget.showInput) {
               int? p = int.tryParse(_paramController.text);
               if (p == null || p <= 0) return; 
               param = p;
            } else {
               param = widget.valorDefecto;
            }

            // 4. MODIFICACIÓN: Pasamos el booleano 'guardarResultado' al callback
            widget.onEjecutar(seleccionadas, param, guardarResultado);
            Navigator.pop(context);
          } : null,
          child: const Text("Ejecutar"),
        )
      ],
    );
  }
}