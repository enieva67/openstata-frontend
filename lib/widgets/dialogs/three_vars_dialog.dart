import 'package:flutter/material.dart';

class ThreeVarsDialog extends StatefulWidget {
  final List<String> columnas;
  final Function(String x, String y, String z, String? color) onEjecutar;

  const ThreeVarsDialog({super.key, required this.columnas, required this.onEjecutar});

  @override
  State<ThreeVarsDialog> createState() => _ThreeVarsDialogState();
}

class _ThreeVarsDialogState extends State<ThreeVarsDialog> {
  String? x, y, z, color;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(children: [Icon(Icons.view_in_ar, color: Colors.deepOrange), SizedBox(width: 10), Text("Configurar 3D")]),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _crearDropdown("Eje X", (v) => x = v),
            const SizedBox(height: 10),
            _crearDropdown("Eje Y", (v) => y = v),
            const SizedBox(height: 10),
            _crearDropdown("Eje Z (Profundidad)", (v) => z = v),
            const Divider(),
            _crearDropdown("Color (Opcional)", (v) => color = v, opcional: true),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
        ElevatedButton(
          onPressed: () {
            if (x != null && y != null && z != null) {
              widget.onEjecutar(x!, y!, z!, color);
              Navigator.pop(context);
            }
          },
          child: const Text("Renderizar 3D"),
        )
      ],
    );
  }

  Widget _crearDropdown(String label, Function(String?) onChange, {bool opcional = false}) {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(labelText: label, border: const OutlineInputBorder(), contentPadding: const EdgeInsets.symmetric(horizontal: 10)),
      items: [
        if (opcional) const DropdownMenuItem(value: null, child: Text("--- Nada ---")),
        ...widget.columnas.map((c) => DropdownMenuItem(value: c, child: Text(c)))
      ],
      onChanged: (val) => setState(() => onChange(val)),
    );
  }
}
