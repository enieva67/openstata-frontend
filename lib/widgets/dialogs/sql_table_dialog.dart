import 'package:flutter/material.dart';

class SqlTableDialog extends StatefulWidget {
  final List<String> tablas;
  final Function(String tabla) onSeleccionar;

  const SqlTableDialog({super.key, required this.tablas, required this.onSeleccionar});

  @override
  State<SqlTableDialog> createState() => _SqlTableDialogState();
}

class _SqlTableDialogState extends State<SqlTableDialog> {
  String? tablaSeleccionada;

  @override
  void initState() {
    super.initState();
    if (widget.tablas.isNotEmpty) tablaSeleccionada = widget.tablas.first;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(children: [Icon(Icons.storage, color: Colors.blueGrey), SizedBox(width: 10), Text("Seleccionar Tabla SQL")]),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text("Se encontraron las siguientes tablas en el archivo:"),
          const SizedBox(height: 15),
          DropdownButtonFormField<String>(
            value: tablaSeleccionada,
            decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 10)),
            items: widget.tablas.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
            onChanged: (v) => setState(() => tablaSeleccionada = v),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
        ElevatedButton(
          onPressed: tablaSeleccionada != null 
            ? () {
                widget.onSeleccionar(tablaSeleccionada!);
                Navigator.pop(context);
              } 
            : null,
          child: const Text("Cargar Tabla"),
        )
      ],
    );
  }
}