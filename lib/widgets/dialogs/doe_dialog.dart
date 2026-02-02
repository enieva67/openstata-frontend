import 'package:flutter/material.dart';

class DoeDialog extends StatefulWidget {
  final List<String> columnas;
  // Callback: Devuelve (Respuesta, Factor 1, Factor 2)
  final Function(String respuesta, String factorA, String factorB) onEjecutar;

  const DoeDialog({
    super.key,
    required this.columnas,
    required this.onEjecutar,
  });

  @override
  State<DoeDialog> createState() => _DoeDialogState();
}

class _DoeDialogState extends State<DoeDialog> {
  String? respuesta; // Variable Dependiente (Numérica)
  String? factorA;   // Variable Independiente 1 (Categórica)
  String? factorB;   // Variable Independiente 2 (Categórica)

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.science_outlined, color: Colors.teal),
          SizedBox(width: 10),
          Text("Diseño Experimental (DoE)"),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Configurar ANOVA de 2 Vías",
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey),
            ),
            const SizedBox(height: 20),

            // 1. VARIABLE RESPUESTA
            _crearDropdown(
              label: "Variable Respuesta (Numérica)",
              icon: Icons.numbers,
              valorActual: respuesta,
              onChange: (v) => respuesta = v,
            ),
            
            const SizedBox(height: 15),

            // 2. FACTOR A
            _crearDropdown(
              label: "Factor A (Grupo/Categórica)",
              icon: Icons.category,
              valorActual: factorA,
              onChange: (v) => factorA = v,
            ),

            const SizedBox(height: 15),

            // 3. FACTOR B
            _crearDropdown(
              label: "Factor B (Grupo/Categórica)",
              icon: Icons.category_outlined,
              valorActual: factorB,
              onChange: (v) => factorB = v,
            ),
            
            const SizedBox(height: 10),
            const Text(
              "Nota: Se calculará la interacción (A*B).",
              style: TextStyle(fontSize: 11, color: Colors.grey, fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context), 
          child: const Text("Cancelar")
        ),
        ElevatedButton.icon(
          icon: const Icon(Icons.play_circle_filled),
          label: const Text("Calcular ANOVA"),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.teal,
            foregroundColor: Colors.white,
          ),
          // Solo habilitamos si los 3 campos están seleccionados
          onPressed: (respuesta != null && factorA != null && factorB != null) 
            ? () {
                widget.onEjecutar(respuesta!, factorA!, factorB!);
                Navigator.pop(context);
              } 
            : null,
        )
      ],
    );
  }

  // Helper para no repetir código visual
  Widget _crearDropdown({
    required String label, 
    required IconData icon, 
    required String? valorActual,
    required Function(String?) onChange
  }) {
    return DropdownButtonFormField<String>(
      value: valorActual,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        prefixIcon: Icon(icon, color: Colors.teal[300]),
        contentPadding: const EdgeInsets.symmetric(horizontal: 10),
      ),
      items: widget.columnas.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
      onChanged: (val) => setState(() => onChange(val)),
    );
  }
}
