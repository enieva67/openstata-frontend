import 'package:flutter/material.dart';

class MultiVariableDialog extends StatefulWidget {
  final List<String> columnas;
  final String titulo;
  final Function(String y, List<String> x) onEjecutar;

  const MultiVariableDialog({
    super.key,
    required this.columnas,
    required this.titulo,
    required this.onEjecutar,
  });

  @override
  State<MultiVariableDialog> createState() => _MultiVariableDialogState();
}

class _MultiVariableDialogState extends State<MultiVariableDialog> {
  String? variableY; // La Dependiente
  final List<String> variablesX = []; // Las Independientes (Lista dinámica)

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.titulo, style: const TextStyle(color: Colors.blueAccent)),
      content: SizedBox(
        width: 350, // Un poco más ancho para que quepa bien
        height: 400, // Altura fija para que el scroll funcione
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. SELECCIÓN DE Y (DEPENDIENTE)
            const Text("1. Variable Dependiente (Y):", 
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            DropdownButtonFormField<String>(
              isExpanded: true,
              initialValue: variableY,
              items: widget.columnas.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (val) {
                setState(() {
                  variableY = val;
                  // Si seleccionas una Y que ya estaba en X, la sacamos de X
                  variablesX.remove(val);
                });
              },
              decoration: const InputDecoration(
                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                border: OutlineInputBorder(),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // 2. SELECCIÓN DE X (INDEPENDIENTES)
            const Text("2. Variables Independientes (X):", 
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 5),
            
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(5)
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: widget.columnas.length,
                  itemBuilder: (context, index) {
                    final col = widget.columnas[index];
                    
                    // No permitimos seleccionar la misma variable para Y y X
                    final esLaY = (col == variableY);
                    
                    return CheckboxListTile(
                      title: Text(col, style: TextStyle(
                        color: esLaY ? Colors.grey : Colors.black,
                        decoration: esLaY ? TextDecoration.lineThrough : null
                      )),
                      value: variablesX.contains(col),
                      onChanged: esLaY ? null : (bool? marcado) {
                        setState(() {
                          if (marcado == true) {
                            variablesX.add(col);
                          } else {
                            variablesX.remove(col);
                          }
                        });
                      },
                      dense: true,
                      controlAffinity: ListTileControlAffinity.leading,
                    );
                  },
                ),
              ),
            ),
            
            // Contador
            Padding(
              padding: const EdgeInsets.only(top: 5),
              child: Text("${variablesX.length} variables seleccionadas", 
                style: const TextStyle(fontSize: 11, color: Colors.grey)),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancelar"),
        ),
        ElevatedButton.icon(
          icon: const Icon(Icons.play_arrow),
          label: const Text("Ejecutar Modelo"),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueAccent,
            foregroundColor: Colors.white,
          ),
          // Solo habilitamos si hay Y seleccionada y al menos una X
          onPressed: (variableY != null && variablesX.isNotEmpty) 
            ? () {
                widget.onEjecutar(variableY!, variablesX);
                Navigator.pop(context);
              } 
            : null,
        ),
      ],
    );
  }
}
