import 'package:flutter/material.dart';

class HierarchicalDialog extends StatefulWidget {
  final List<String> columnas;
  final Function(List<String> vars, String metodo, int k) onEjecutar;

  const HierarchicalDialog({
    super.key,
    required this.columnas,
    required this.onEjecutar,
  });

  @override
  State<HierarchicalDialog> createState() => _HierarchicalDialogState();
}

class _HierarchicalDialogState extends State<HierarchicalDialog> {
  final List<String> seleccionadas = [];
  String metodo = "ward";
  final TextEditingController _kController = TextEditingController(text: "3");

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.account_tree, color: Colors.teal),
          SizedBox(width: 10),
          Text("Cluster Jerárquico"),
        ],
      ),
      content: SizedBox(
        width: 350,
        height: 550,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. CONFIGURACIÓN DEL MÉTODO
            const Text("Método de Agrupación (Linkage):", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            DropdownButtonFormField<String>(
              initialValue: metodo,
              decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 10)),
              items: const [
                DropdownMenuItem(value: "ward", child: Text("Ward (Varianza mínima)")),
                DropdownMenuItem(value: "complete", child: Text("Complete (Máxima distancia)")),
                DropdownMenuItem(value: "average", child: Text("Average (Promedio)")),
                DropdownMenuItem(value: "single", child: Text("Single (Mínima distancia)")),
              ],
              onChanged: (val) => setState(() => metodo = val!),
            ),
            const SizedBox(height: 15),

            // 2. CONFIGURACIÓN DEL CORTE
            const Text("Número de Clusters (Corte):", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            TextField(
              controller: _kController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 10),
                hintText: "Ej: 3"
              ),
            ),
            const SizedBox(height: 15),

            // 3. SELECCIÓN DE VARIABLES
            const Text("Variables:", style: TextStyle(fontWeight: FontWeight.bold)),
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
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
        ElevatedButton(
          onPressed: seleccionadas.length >= 2 ? () {
            int? k = int.tryParse(_kController.text);
            if (k != null && k > 1) {
              widget.onEjecutar(seleccionadas, metodo, k);
              Navigator.pop(context);
            }
          } : null,
          child: const Text("Ejecutar"),
        )
      ],
    );
  }
}
