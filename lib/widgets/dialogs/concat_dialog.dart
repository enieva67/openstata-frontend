import 'package:flutter/material.dart';

class ConcatDialog extends StatefulWidget {
  final List<String> datasetsDisponibles;
  final String datasetActivo;
  final Function(String datasetB, String eje) onEjecutar;

  const ConcatDialog({super.key, required this.datasetsDisponibles, required this.datasetActivo, required this.onEjecutar});

  @override
  State<ConcatDialog> createState() => _ConcatDialogState();
}

class _ConcatDialogState extends State<ConcatDialog> {
  String? datasetB;
  String eje = "filas";

  @override
  Widget build(BuildContext context) {
    var listaB = widget.datasetsDisponibles.where((d) => d != widget.datasetActivo).toList();

    return AlertDialog(
      title: const Text("Concatenar Datasets"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text("Dataset Base: ${widget.datasetActivo}", style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(labelText: "Dataset a Anexar", border: OutlineInputBorder()),
            items: listaB.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
            onChanged: (v) => setState(() => datasetB = v),
          ),
          const SizedBox(height: 15),
          DropdownButtonFormField<String>(
            value: eje,
            decoration: const InputDecoration(labelText: "Dirección de Unión", border: OutlineInputBorder()),
            items: const [
              DropdownMenuItem(value: "filas", child: Text("Vertical (Agregar Filas)")),
              DropdownMenuItem(value: "columnas", child: Text("Horizontal (Agregar Columnas)")),
            ],
            onChanged: (v) => setState(() => eje = v!),
          ),
        ],
      ),
      actions: [
        ElevatedButton(
          onPressed: datasetB != null ? () {
            widget.onEjecutar(datasetB!, eje);
            Navigator.pop(context);
          } : null,
          child: const Text("Concatenar"),
        )
      ],
    );
  }
}