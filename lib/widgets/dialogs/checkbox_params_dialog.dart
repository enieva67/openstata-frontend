import 'package:flutter/material.dart';

class CheckboxParamsDialog extends StatefulWidget {
  final String titulo;
  final List<String> columnas;
  final String labelParametro; // Ej: "Número de Clusters (k)"
  final int valorDefecto;
  final Function(List<String> vars, int param) onEjecutar;

  const CheckboxParamsDialog({
    super.key,
    required this.titulo,
    required this.columnas,
    required this.labelParametro,
    required this.valorDefecto,
    required this.onEjecutar,
  });

  @override
  State<CheckboxParamsDialog> createState() => _CheckboxParamsDialogState();
}

class _CheckboxParamsDialogState extends State<CheckboxParamsDialog> {
  final List<String> seleccionadas = [];
  late TextEditingController _paramController;

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
        height: 500,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. CONFIGURACIÓN DEL PARÁMETRO
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
                          if (val == true) seleccionadas.add(col);
                          else seleccionadas.remove(col);
                        });
                      },
                    );
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 5),
              child: Text("${seleccionadas.length} seleccionadas", style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
        ElevatedButton(
          onPressed: seleccionadas.length >= 2 ? () {
            int? param = int.tryParse(_paramController.text);
            if (param != null && param > 0) {
              widget.onEjecutar(seleccionadas, param);
              Navigator.pop(context);
            }
          } : null,
          child: const Text("Ejecutar"),
        )
      ],
    );
  }
}
