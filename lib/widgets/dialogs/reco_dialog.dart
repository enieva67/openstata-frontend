import 'package:flutter/material.dart';

class RecoDialog extends StatefulWidget {
  final List<String> columnas;
  final String tipo; // 'svd' o 'apriori'
  final Function(List<String> vars, double param) onEjecutar;

  const RecoDialog({super.key, required this.columnas, required this.tipo, required this.onEjecutar});

  @override
  State<RecoDialog> createState() => _RecoDialogState();
}

class _RecoDialogState extends State<RecoDialog> {
  String? var1;
  String? var2;
  String? var3;
  final _paramCtrl = TextEditingController(text: "0.01"); // Soporte default

  @override
  Widget build(BuildContext context) {
    bool esSVD = widget.tipo == 'svd';
    
    return AlertDialog(
      title: Row(children: [Icon(esSVD ? Icons.people : Icons.shopping_cart, color: Colors.purple), const SizedBox(width: 10), Text(esSVD ? "Filtrado Colaborativo (SVD)" : "Reglas de Asociación")]),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _dropdown(esSVD ? "Columna Usuario (ID)" : "ID Transacción / Ticket", (v) => var1 = v),
            const SizedBox(height: 10),
            _dropdown(esSVD ? "Columna Item (Producto/Peli)" : "Columna Item (Producto)", (v) => var2 = v),
            
            if (esSVD) ...[
              const SizedBox(height: 10),
              _dropdown("Columna Rating (Calificación)", (v) => var3 = v),
            ],

            if (!esSVD) ...[
              const SizedBox(height: 20),
              const Text("Soporte Mínimo (0.01 - 1.0):", style: TextStyle(fontWeight: FontWeight.bold)),
              TextField(controller: _paramCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(border: OutlineInputBorder(), hintText: "0.01")),
            ]
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
        ElevatedButton(
          onPressed: () {
            if (var1 != null && var2 != null && (!esSVD || var3 != null)) {
              List<String> vars = [var1!, var2!];
              if (esSVD) vars.add(var3!);
              
              double p = double.tryParse(_paramCtrl.text) ?? 0.01;
              widget.onEjecutar(vars, p);
              Navigator.pop(context);
            }
          },
          child: const Text("Analizar"),
        )
      ],
    );
  }

  Widget _dropdown(String label, Function(String?) onChange) {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(labelText: label, border: const OutlineInputBorder(), contentPadding: const EdgeInsets.symmetric(horizontal: 10)),
      items: widget.columnas.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
      onChanged: (val) => setState(() => onChange(val)),
    );
  }
}
