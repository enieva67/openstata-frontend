import 'package:flutter/material.dart';

class DataGrid extends StatefulWidget {
  final Map<String, dynamic>? data;
  
  // Paginación (Opcional: Si es null, asumimos que es una tabla de resultados pequeña)
  final int offset;
  final int totalRows;
  final int filasPorPagina;
  final Function(int)? onPageChanged; 

  const DataGrid({
    super.key,
    required this.data,
    this.offset = 0,
    this.totalRows = 0,
    this.filasPorPagina = 100,
    this.onPageChanged,
  });

  @override
  State<DataGrid> createState() => _DataGridState();
}

class _DataGridState extends State<DataGrid> {
  final ScrollController _vertical = ScrollController();
  final ScrollController _horizontal = ScrollController();

  @override
  void dispose() {
    _vertical.dispose();
    _horizontal.dispose();
    super.dispose();
  }

  // --- LÓGICA DE REDONDEO INTELIGENTE ---
  String _formatearCelda(dynamic valor) {
    if (valor == null) return "";
    
    // Protección contra errores raros de tipos
    if (valor is! num) return valor.toString();

    try {
      // Si es entero visualmente (ej: 5.0), mostrar "5"
      if (valor == valor.toInt()) return valor.toInt().toString();
      
      // Notación científica para valores muy pequeños
      if (valor != 0 && valor.abs() < 0.0001) {
        return valor.toStringAsExponential(2);
      }
      
      // Estándar
      return valor.toStringAsFixed(4);
    } catch (e) {
      return valor.toString(); // Fallback seguro
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.data == null) {
      return const Center(child: Text("Sin datos para mostrar.", style: TextStyle(color: Colors.grey)));
    }

    List<dynamic> cols = widget.data!['columns'];
    List<dynamic> rows = widget.data!['data'];

    // Si hay paginación, calculamos los índices. Si no, mostramos "Total"
    bool usarPaginacion = widget.onPageChanged != null;
    int inicio = widget.offset + 1;
    int fin = widget.offset + rows.length;

    return Column(
      children: [
        // TABLA
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Scrollbar(
                controller: _horizontal,
                thumbVisibility: true,
                trackVisibility: true,
                child: SingleChildScrollView(
                  controller: _horizontal,
                  scrollDirection: Axis.horizontal,
                  child: SingleChildScrollView(
                    controller: _vertical,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minWidth: constraints.maxWidth),
                      child: DataTable(
                        headingRowColor: WidgetStateProperty.all(const Color(0xFFE8F0FE)),
                        dataRowMinHeight: 30, // Filas más compactas
                        dataRowMaxHeight: 40,
                        border: TableBorder.all(color: Colors.grey.shade300),
                        columns: cols.map((c) => DataColumn(
                          label: Text(c.toString().toUpperCase(), 
                              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue.shade900))
                        )).toList(),
                        rows: rows.map((r) => DataRow(
                          cells: (r as List).map((c) => DataCell(
                            // APLICAMOS EL FORMATEO AQUÍ
                            Text(_formatearCelda(c), style: const TextStyle(fontSize: 13))
                          )).toList(),
                        )).toList(),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        // FOOTER (Solo si hay paginación activada)
        if (usarPaginacion)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey.shade300)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Filas $inicio - $fin de ${widget.totalRows}",
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.first_page),
                      onPressed: widget.offset > 0 ? () => widget.onPageChanged!(0) : null,
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed: widget.offset > 0 ? () => widget.onPageChanged!(widget.offset - widget.filasPorPagina) : null,
                    ),
                    Text(" Pag ${(widget.offset / widget.filasPorPagina).floor() + 1} "),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: (widget.offset + widget.filasPorPagina) < widget.totalRows
                          ? () => widget.onPageChanged!(widget.offset + widget.filasPorPagina)
                          : null,
                    ),
                  ],
                )
              ],
            ),
          ),
      ],
    );
  }
}
