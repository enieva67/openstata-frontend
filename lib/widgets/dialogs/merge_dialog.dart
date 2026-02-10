import 'package:flutter/material.dart';

class MergeDialog extends StatefulWidget {
  final List<String> datasetsDisponibles;
  final String datasetActivo;
  final Function(String datasetB, String colA, String colB, String tipo) onEjecutar;

  const MergeDialog({super.key, required this.datasetsDisponibles, required this.datasetActivo, required this.onEjecutar});

  @override
  State<MergeDialog> createState() => _MergeDialogState();
}

class _MergeDialogState extends State<MergeDialog> {
  String? datasetB;
  String tipoJoin = "inner";
  final _colA = TextEditingController(text: "id");
  final _colB = TextEditingController(text: "id");

  @override
  Widget build(BuildContext context) {
    // Filtramos para no mergear con uno mismo
    var listaB = widget.datasetsDisponibles.where((d) => d != widget.datasetActivo).toList();

    return AlertDialog(
      title: const Text("Unir Datasets (Merge/Join)"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text("Dataset A (Activo): ${widget.datasetActivo}", style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(labelText: "Dataset B (A unir)", border: OutlineInputBorder()),
            items: listaB.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
            onChanged: (v) => setState(() => datasetB = v),
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(child: TextField(controller: _colA, decoration: const InputDecoration(labelText: "Columna Llave A", border: OutlineInputBorder()))),
              const SizedBox(width: 10),
              const Icon(Icons.link),
              const SizedBox(width: 10),
              Expanded(child: TextField(controller: _colB, decoration: const InputDecoration(labelText: "Columna Llave B", border: OutlineInputBorder()))),
            ],
          ),
          const SizedBox(height: 15),
          DropdownButtonFormField<String>(
            value: tipoJoin,
            decoration: const InputDecoration(labelText: "Tipo de Unión", border: OutlineInputBorder()),
            items: const [
              DropdownMenuItem(value: "inner", child: Text("Inner (Solo coincidencias)")),
              DropdownMenuItem(value: "left", child: Text("Left (Mantener A)")),
              DropdownMenuItem(value: "right", child: Text("Right (Mantener B)")),
              DropdownMenuItem(value: "outer", child: Text("Outer (Todo)")),
            ],
            onChanged: (v) => setState(() => tipoJoin = v!),
          ),
        ],
      ),
      actions: [
        ElevatedButton(
          onPressed: datasetB != null ? () {
            widget.onEjecutar(datasetB!, _colA.text, _colB.text, tipoJoin);
            Navigator.pop(context);
          } : null,
          child: const Text("Unir"),
        )
      ],
    );
  }
}