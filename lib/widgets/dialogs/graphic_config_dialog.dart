import 'package:flutter/material.dart';

class GraphicConfigDialog extends StatefulWidget {
  final Function(String style, String palette, String context) onAplicar;

  const GraphicConfigDialog({super.key, required this.onAplicar});

  @override
  State<GraphicConfigDialog> createState() => _GraphicConfigDialogState();
}

class _GraphicConfigDialogState extends State<GraphicConfigDialog> {
  String style = "whitegrid";
  String palette = "deep";
  String contextPlot = "notebook";

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(children: [Icon(Icons.palette), SizedBox(width: 10), Text("Estilo de Gráficos")]),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<String>(
            initialValue: style,
            decoration: const InputDecoration(labelText: "Fondo (Grid)"),
            items: const [
              DropdownMenuItem(value: "whitegrid", child: Text("Blanco con Rejilla (Standard)")),
              DropdownMenuItem(value: "darkgrid", child: Text("Gris con Rejilla")),
              DropdownMenuItem(value: "white", child: Text("Blanco Limpio")),
              DropdownMenuItem(value: "dark", child: Text("Oscuro")),
              DropdownMenuItem(value: "ticks", child: Text("Solo Marcas (Minimal)")),
            ],
            onChanged: (v) => setState(() => style = v!),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            initialValue: palette,
            decoration: const InputDecoration(labelText: "Paleta de Colores"),
            items: const [
              DropdownMenuItem(value: "deep", child: Text("Deep (Profesional)")),
              DropdownMenuItem(value: "muted", child: Text("Muted (Suave)")),
              DropdownMenuItem(value: "bright", child: Text("Bright (Vibrante)")),
              DropdownMenuItem(value: "pastel", child: Text("Pastel")),
              DropdownMenuItem(value: "viridis", child: Text("Viridis (Científico)")),
              DropdownMenuItem(value: "magma", child: Text("Magma (Cálido)")),
            ],
            onChanged: (v) => setState(() => palette = v!),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            value: contextPlot,
            decoration: const InputDecoration(labelText: "Escala / Tamaño"),
            items: const [
              DropdownMenuItem(value: "paper", child: Text("Paper (Pequeño - Reportes)")),
              DropdownMenuItem(value: "notebook", child: Text("Notebook (Normal - Pantalla)")),
              DropdownMenuItem(value: "talk", child: Text("Talk (Grande - Presentación)")),
            ],
            onChanged: (v) => setState(() => contextPlot = v!),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
        ElevatedButton(
          onPressed: () {
            widget.onAplicar(style, palette, contextPlot);
            Navigator.pop(context);
          },
          child: const Text("Aplicar Globalmente"),
        )
      ],
    );
  }
}
