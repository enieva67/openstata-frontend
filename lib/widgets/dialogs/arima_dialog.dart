import 'package:flutter/material.dart';

class ArimaDialog extends StatefulWidget {
  final List<String> columnas;
  final Function(String f, String v, int p, int d, int q, int P, int D, int Q, int m, int pasos) onEjecutar;

  const ArimaDialog({super.key, required this.columnas, required this.onEjecutar});

  @override
  State<ArimaDialog> createState() => _ArimaDialogState();
}

class _ArimaDialogState extends State<ArimaDialog> {
  String? fecha;
  String? valor;
  
  // ARIMA
  final _p = TextEditingController(text: "1");
  final _d = TextEditingController(text: "1");
  final _q = TextEditingController(text: "1");
  
  // ESTACIONALIDAD
  bool _esEstacional = false;
  final _P = TextEditingController(text: "1");
  final _D = TextEditingController(text: "1");
  final _Q = TextEditingController(text: "1");
  final _m = TextEditingController(text: "7"); 
  
  final _pasos = TextEditingController(text: "12");

  @override
  void dispose() {
    _p.dispose(); _d.dispose(); _q.dispose();
    _P.dispose(); _D.dispose(); _Q.dispose(); _m.dispose();
    _pasos.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(children: [Icon(Icons.timeline, color: Colors.blueAccent), SizedBox(width: 10), Text("Modelo SARIMA")]),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 400,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _dropdown("1. Fecha (Índice)", (v) => fecha = v),
              const SizedBox(height: 10),
              _dropdown("2. Valor a Predecir", (v) => valor = v),
              
              const Divider(),
              const Text("Orden No Estacional (p, d, q):", style: TextStyle(fontWeight: FontWeight.bold)),
              Row(
                children: [
                  // AQUÍ SÍ USAMOS EXPANDED (Porque están en fila)
                  Expanded(child: _inputBase("p", _p)),
                  const SizedBox(width: 5),
                  Expanded(child: _inputBase("d", _d)),
                  const SizedBox(width: 5),
                  Expanded(child: _inputBase("q", _q)),
                ],
              ),
              
              const SizedBox(height: 10),
              
              Container(
                decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(5)),
                child: CheckboxListTile(
                  title: const Text("Activar Estacionalidad (S)", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                  value: _esEstacional,
                  onChanged: (v) => setState(() => _esEstacional = v!),
                  dense: true,
                ),
              ),
              
              if (_esEstacional) ...[
                const SizedBox(height: 10),
                const Text("Orden Estacional (P, D, Q) [m]:", style: TextStyle(fontWeight: FontWeight.bold)),
                Row(
                  children: [
                    Expanded(child: _inputBase("P", _P)),
                    const SizedBox(width: 5),
                    Expanded(child: _inputBase("D", _D)),
                    const SizedBox(width: 5),
                    Expanded(child: _inputBase("Q", _Q)),
                    const SizedBox(width: 5),
                    Expanded(child: _inputBase("m (Per.)", _m, color: Colors.blue[50])),
                  ],
                ),
              ],

              const Divider(),
              
              // AQUÍ ESTABA EL ERROR ANTES:
              // Antes usábamos Expanded directo en la Columna (CRASH).
              // Ahora usamos el input base sin expandir.
              const Text("Proyección a Futuro (Pasos):", style: TextStyle(fontWeight: FontWeight.bold)),
              _inputBase("Ej: 12 meses", _pasos),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
        ElevatedButton(
          onPressed: () {
            if (fecha != null && valor != null) {
              widget.onEjecutar(
                fecha!, valor!,
                int.parse(_p.text), int.parse(_d.text), int.parse(_q.text),
                _esEstacional ? int.parse(_P.text) : 0,
                _esEstacional ? int.parse(_D.text) : 0,
                _esEstacional ? int.parse(_Q.text) : 0,
                _esEstacional ? int.parse(_m.text) : 0,
                int.parse(_pasos.text)
              );
              Navigator.pop(context);
            }
          },
          child: const Text("Calcular"),
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

  // CORRECCIÓN: Esta función ya NO devuelve Expanded, solo el TextField
  Widget _inputBase(String label, TextEditingController ctrl, {Color? color}) {
    return TextField(
      controller: ctrl, 
      keyboardType: TextInputType.number, 
      decoration: InputDecoration(
        labelText: label, 
        border: const OutlineInputBorder(), 
        filled: color != null, 
        fillColor: color,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0)
      ),
    );
  }
}
