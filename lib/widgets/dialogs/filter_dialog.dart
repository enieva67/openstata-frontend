import 'package:flutter/material.dart';

class FilterDialog extends StatelessWidget {
  final Function(String consulta) onEjecutar;
  final TextEditingController _ctrl = TextEditingController();

  FilterDialog({super.key, required this.onEjecutar});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(children: [Icon(Icons.filter_alt, color: Colors.blue), SizedBox(width: 10), Text("Filtrar Filas")]),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Escribe una condición lógica (Pandas Query):"),
          const SizedBox(height: 5),
          TextField(
            controller: _ctrl,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: "Ej: Age > 30 and Sex == 'female'"
            ),
          ),
          const SizedBox(height: 10),
          const Text("Ejemplos:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          const Text("- Precio > 1000\n- Grupo == 'A'\n- Edad >= 18 and Edad <= 65", style: TextStyle(fontSize: 11, color: Colors.grey)),
        ],
      ),
      actions: [
        ElevatedButton(
          onPressed: () {
            if (_ctrl.text.isNotEmpty) {
              onEjecutar(_ctrl.text);
              Navigator.pop(context);
            }
          },
          child: const Text("Aplicar Filtro"),
        )
      ],
    );
  }
}