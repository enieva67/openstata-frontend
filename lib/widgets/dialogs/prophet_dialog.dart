import 'package:flutter/material.dart';

class ProphetDialog extends StatefulWidget {
  final List<String> columnas;
  final Function(String fecha, String valor, int pasos, String freq) onEjecutar;

  const ProphetDialog({super.key, required this.columnas, required this.onEjecutar});

  @override
  State<ProphetDialog> createState() => _ProphetDialogState();
}

class _ProphetDialogState extends State<ProphetDialog> {
  String? fecha;
  String? valor;
  final _pasos = TextEditingController(text: "30");
  String frecuencia = "D"; // D, M, Y

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(children: [Icon(Icons.auto_graph, color: Colors.purple), SizedBox(width: 10), Text("Facebook Prophet")]),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Predicción automática con estacionalidad múltiple.", style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 15),
            
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: "Columna Fecha", border: OutlineInputBorder()),
              items: widget.columnas.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (v) => setState(() => fecha = v),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: "Variable a Predecir", border: OutlineInputBorder()),
              items: widget.columnas.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (v) => setState(() => valor = v),
            ),
            const SizedBox(height: 15),
            
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _pasos, 
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: "Pasos a Futuro", border: OutlineInputBorder()),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: frecuencia,
                    decoration: const InputDecoration(labelText: "Unidad", border: OutlineInputBorder()),
                    items: const [
                      DropdownMenuItem(value: "D", child: Text("Días")),
                      DropdownMenuItem(value: "W", child: Text("Semanas")),
                      DropdownMenuItem(value: "M", child: Text("Meses")),
                      DropdownMenuItem(value: "Y", child: Text("Años")),
                    ],
                    onChanged: (v) => setState(() => frecuencia = v!),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
        ElevatedButton(
          onPressed: (fecha != null && valor != null) 
            ? () {
                widget.onEjecutar(fecha!, valor!, int.parse(_pasos.text), frecuencia);
                Navigator.pop(context);
              } 
            : null,
          child: const Text("Ejecutar Prophet"),
        )
      ],
    );
  }
}
