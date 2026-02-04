import 'package:flutter/material.dart';
import '../config/ml_params_config.dart';

class DynamicParamsForm extends StatefulWidget {
  final String algoritmo;
  final Function(Map<String, dynamic>) onParamsChanged;

  const DynamicParamsForm({super.key, required this.algoritmo, required this.onParamsChanged});

  @override
  State<DynamicParamsForm> createState() => _DynamicParamsFormState();
}

class _DynamicParamsFormState extends State<DynamicParamsForm> {
  final Map<String, dynamic> _valores = {};
  // Controladores para inputs de texto
  final Map<String, TextEditingController> _ctrls = {};

  @override
  void initState() {
    super.initState();
    _initVals();
  }

  @override
  void didUpdateWidget(DynamicParamsForm old) {
    super.didUpdateWidget(old);
    if (old.algoritmo != widget.algoritmo) _initVals();
  }

  void _initVals() {
    _valores.clear();
    _ctrls.clear();
    List<ModelParam> params = mlParamsConfig[widget.algoritmo] ?? [];
    for (var p in params) {
      _valores[p.key] = p.defaultValue;
      if (p.type != 'select') {
        _ctrls[p.key] = TextEditingController(text: p.defaultValue.toString());
      }
    }
    widget.onParamsChanged(_valores); // Reportar valores iniciales
  }

  @override
  Widget build(BuildContext context) {
    List<ModelParam> params = mlParamsConfig[widget.algoritmo] ?? [];
    if (params.isEmpty) return const SizedBox.shrink();

    return Column(
      children: params.map((p) {
        if (p.type == 'select') {
          return DropdownButtonFormField<String>(
            value: _valores[p.key],
            decoration: InputDecoration(labelText: p.label, isDense: true),
            items: p.options!.map((o) => DropdownMenuItem(value: o, child: Text(o))).toList(),
            onChanged: (v) {
              setState(() => _valores[p.key] = v);
              widget.onParamsChanged(_valores);
            },
          );
        } else {
          return TextField(
            controller: _ctrls[p.key],
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(labelText: p.label, isDense: true),
            onChanged: (v) {
              _valores[p.key] = v; // Guardamos lo que escriba
              widget.onParamsChanged(_valores);
            },
          );
        }
      }).toList(),
    );
  }
}
