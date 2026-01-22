import 'package:flutter/material.dart';

class CleaningDialog extends StatefulWidget {
  final List<dynamic> infoColumnas;
  final Function(String col, String metodo) onImputar;
  
  // CORRECCIÓN: Ahora aceptamos String Y Bool
  final Function(String col, bool mantenerOriginal) onCodificar; 

  const CleaningDialog({
    super.key,
    required this.infoColumnas,
    required this.onImputar,
    required this.onCodificar,
  });

  @override
  State<CleaningDialog> createState() => _CleaningDialogState();
}

class _CleaningDialogState extends State<CleaningDialog> {
  bool conservarOriginal = false;
  String? columnaSeleccionada;
  String metodoImputacion = "media"; // Default

  @override
  Widget build(BuildContext context) {
    // Filtramos la info de la columna seleccionada
    Map<String, dynamic>? infoSel;
    if (columnaSeleccionada != null) {
      infoSel = widget.infoColumnas.firstWhere((e) => e['columna'] == columnaSeleccionada);
    }

    bool tieneNulos = infoSel != null && infoSel['nulos'] > 0;
    bool esNumerica = infoSel != null && infoSel['es_numerica'] == true;
    bool esTexto = infoSel != null && !esNumerica;

    return AlertDialog(
      title: const Row(children: [Icon(Icons.cleaning_services, color: Colors.orange), SizedBox(width: 10), Text("Limpieza de Datos")]),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("1. Selecciona Variable a Tratar:"),
            DropdownButtonFormField<String>(
              isExpanded: true,
              initialValue: columnaSeleccionada,
              items: widget.infoColumnas.map<DropdownMenuItem<String>>((info) {
                // Si tiene nulos, le ponemos un icono de advertencia
                int nulos = info['nulos'];
                return DropdownMenuItem(
                  value: info['columna'],
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(info['columna']),
                      if (nulos > 0) 
                        Text("($nulos nulos)", style: const TextStyle(color: Colors.red, fontSize: 12))
                      else if (!info['es_numerica'])
                        const Text("(ABC)", style: TextStyle(color: Colors.blue, fontSize: 12))
                    ],
                  ),
                );
              }).toList(),
              onChanged: (val) => setState(() => columnaSeleccionada = val),
            ),
            
            const SizedBox(height: 20),
            
            if (columnaSeleccionada != null) ...[
              // PANEL DE ACCIONES
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Tipo detectado: ${infoSel!['tipo']}", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    const SizedBox(height: 10),
                    
                    // OPCIÓN A: IMPUTAR NULOS
                    if (tieneNulos) ...[
                      const Text("⚠️ Se detectaron valores perdidos", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 5),
                      DropdownButtonFormField<String>(
                        initialValue: metodoImputacion,
                        decoration: const InputDecoration(labelText: "Método de Relleno"),
                        items: const [
                          DropdownMenuItem(value: "media", child: Text("Rellenar con Media (Promedio)")),
                          DropdownMenuItem(value: "mediana", child: Text("Rellenar con Mediana (Central)")),
                          DropdownMenuItem(value: "moda", child: Text("Rellenar con Moda (Más frecuente)")),
                          DropdownMenuItem(value: "eliminar_filas", child: Text("ELIMINAR filas vacías (Drástico)")),
                        ],
                        onChanged: (val) => setState(() => metodoImputacion = val!),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.build),
                          label: const Text("Aplicar Imputación"),
                          onPressed: () {
                            widget.onImputar(columnaSeleccionada!, metodoImputacion);
                            Navigator.pop(context);
                          },
                        ),
                      )
                    ] else ...[
                      const Row(children: [Icon(Icons.check_circle, color: Colors.green, size: 16), SizedBox(width: 5), Text("Sin valores nulos.")])
                    ],

                    const Divider(),

                    // OPCIÓN B: CODIFICAR (Si es texto)
                    if (esTexto) ...[
                      const Text("🔤 Variable Categórica Detectada", style: TextStyle(fontWeight: FontWeight.bold)),
                      // NUEVO CHECKBOX
                      CheckboxListTile(
                        title: const Text("Conservar variable original"),
                        subtitle: const Text("Útil para comparar, pero cuidado con duplicados."),
                        value: conservarOriginal,
                        onChanged: (val) => setState(() => conservarOriginal = val!),
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                      ),
                      const Text("Necesaria para regresiones.", style: TextStyle(fontSize: 12)),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
                          icon: const Icon(Icons.code),
                          label: const Text("Convertir a Dummies (0/1)"),
                          onPressed: () {
                            // Pasamos el booleano al callback (tendrás que actualizar la firma del callback arriba)
                            widget.onCodificar(columnaSeleccionada!, conservarOriginal);
                            Navigator.pop(context);
                          },
                        ),
                      )
                    ]
                  ],
                ),
              )
            ]
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cerrar")),
      ],
    );
  }
}