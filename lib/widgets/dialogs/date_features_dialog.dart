import 'package:flutter/material.dart';

class DateFeaturesDialog extends StatefulWidget {
  final List<String> columnas;
  final Function(String columna) onEjecutar;

  const DateFeaturesDialog({super.key, required this.columnas, required this.onEjecutar});

  @override
  State<DateFeaturesDialog> createState() => _DateFeaturesDialogState();
}

class _DateFeaturesDialogState extends State<DateFeaturesDialog> {
  String? columnaSeleccionada;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [Icon(Icons.calendar_month, color: Colors.blueGrey), SizedBox(width: 10), Text("Ingeniería de Fechas")],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Se crearán automáticamente variables numéricas para:\n- Año, Mes, Día\n- Día de la Semana (0-6)\n- Fin de Semana (0/1)\n- Día del Año (1-365)",
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 20),
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(labelText: "Selecciona la Columna Fecha", border: OutlineInputBorder()),
            items: widget.columnas.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
            onChanged: (val) => setState(() => columnaSeleccionada = val),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
        ElevatedButton(
          onPressed: columnaSeleccionada != null 
            ? () {
                widget.onEjecutar(columnaSeleccionada!);
                Navigator.pop(context);
              } 
            : null,
          child: const Text("Generar Variables"),
        )
      ],
    );
  }
}
