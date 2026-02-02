import 'dart:io';
import 'dart:convert';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class PdfService {
  
  static Future<void> generarReporte(String rutaDestino, List<Map<String, dynamic>> resultados) async {
    final pdf = pw.Document();

    // 1. PORTADA
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Center(
            child: pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                pw.Container(
                  height: 80, width: 80,
                  decoration: const pw.BoxDecoration(color: PdfColors.blue800, shape: pw.BoxShape.circle),
                  child: pw.Center(child: pw.Text("OS", style: pw.TextStyle(color: PdfColors.white, fontSize: 30, fontWeight: pw.FontWeight.bold))),
                ),
                pw.SizedBox(height: 30),
                pw.Text("OpenStata Evolution", style: pw.TextStyle(fontSize: 36, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                pw.SizedBox(height: 10),
                pw.Text("Reporte de Análisis Estadístico", style: pw.TextStyle(fontSize: 20, color: PdfColors.grey700)),
                pw.SizedBox(height: 40),
                pw.Divider(thickness: 2, color: PdfColors.blue200),
                pw.SizedBox(height: 10),
                pw.Text("Generado el: ${DateTime.now().toString().split('.')[0]}", style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey600)),
              ],
            ),
          );
        },
      ),
    );

    // 2. PÁGINAS DE RESULTADOS
    for (var res in resultados) {
      String titulo = res['titulo'];
      String subtitulo = res['subtitulo'] ?? "";
      String tipo = res['tipo'] ?? 'tabla';
      
      var contenidoDatos = res['datos'];

      // --- EXTRACCIÓN SEGURA DEL REPORTE ESTADÍSTICO ---
      String? reporteStat;
      if (contenidoDatos is Map && contenidoDatos.containsKey('reporte_stat')) {
        reporteStat = contenidoDatos['reporte_stat'];
      }
      // ------------------------------------------------

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4.landscape, 
          margin: const pw.EdgeInsets.all(40),
          
          header: (pw.Context context) {
            return pw.Container(
              alignment: pw.Alignment.centerRight,
              margin: const pw.EdgeInsets.only(bottom: 20),
              child: pw.Text("OpenStata Report | Pág. ${context.pageNumber}", 
                  style: const pw.TextStyle(color: PdfColors.grey400, fontSize: 8)),
            );
          },

          build: (pw.Context context) {
            return [
              // Encabezado
              pw.Container(
                decoration: const pw.BoxDecoration(
                  border: pw.Border(left: pw.BorderSide(color: PdfColors.blue800, width: 5))
                ),
                padding: const pw.EdgeInsets.only(left: 10),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(titulo, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
                    if (subtitulo.isNotEmpty)
                      pw.Text(subtitulo, style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey600)),
                  ]
                )
              ),
              
              pw.SizedBox(height: 15),

              // --- NUEVO: RECUADRO DE ESTADÍSTICAS EN EL PDF ---
              if (reporteStat != null && reporteStat.isNotEmpty)
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.blue50,
                    border: pw.Border.all(color: PdfColors.blue200),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5))
                  ),
                  margin: const pw.EdgeInsets.only(bottom: 15),
                  child: pw.Text(reporteStat, style: pw.TextStyle(fontSize: 10, font: pw.Font.courier())),
                ),
              // --------------------------------------------------

              // Selector de Contenido Visual
              if (tipo == 'grafico_hibrido') 
                 // Si es híbrido, 'contenidoDatos' es un Map con 'imagen'
                 _construirImagenPdf(contenidoDatos['imagen'])
              else if (tipo == 'imagen') 
                 _construirImagenPdf(contenidoDatos)
              else if (tipo == 'html') 
                 _construirPlaceholderWeb()
              else 
                 _construirTablaPdf(contenidoDatos), // Aquí estaba el error antes
            ];
          },
        ),
      );
    }

    final file = File(rutaDestino);
    await file.writeAsBytes(await pdf.save());
  }

  static pw.Widget _construirPlaceholderWeb() {
    return pw.Container(
      width: double.infinity,
      height: 300,
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10))
      ),
      child: pw.Center(
        child: pw.Column(
          mainAxisSize: pw.MainAxisSize.min,
          children: [
            pw.Text("Visualización Interactiva Externa", style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
            pw.Text("(Consulte la aplicación)", style: const pw.TextStyle(color: PdfColors.grey600)),
          ]
        )
      )
    );
  }

  static pw.Widget _construirImagenPdf(dynamic datosImagen) {
    try {
      // Si recibimos el string directo o dentro de un mapa, lo manejamos
      String base64String = "";
      if (datosImagen is String) {
        base64String = datosImagen;
      } else if (datosImagen is Map && datosImagen.containsKey('imagen')) {
        base64String = datosImagen['imagen'];
      } else {
        return pw.Text("Formato de imagen no reconocido");
      }

      final imageBytes = base64Decode(base64String.replaceAll('\n', ''));
      return pw.Center(
        child: pw.Image(
          pw.MemoryImage(imageBytes),
          fit: pw.BoxFit.contain,
          height: 350, 
        ),
      );
    } catch (e) {
      return pw.Text("Error renderizando imagen: $e", style: const pw.TextStyle(color: PdfColors.red));
    }
  }

  // --- AQUÍ ESTABA EL ERROR: AHORA ES DEFENSIVO ---
  static pw.Widget _construirTablaPdf(dynamic dataJson) {
    // 1. Verificamos que sea un Mapa
    if (dataJson == null || dataJson is! Map) {
      // Si no es mapa (ej: es null), devolvemos texto vacío
      return pw.Text("Sin datos tabulares.");
    }

    // 2. Extraemos con valores por defecto (?? [])
    // Esto evita el error "Null is not a subtype of List"
    List<dynamic> cols = dataJson['columns'] ?? [];
    List<dynamic> rows = dataJson['data'] ?? [];

    if (cols.isEmpty) return pw.Text("Tabla vacía.");

    List<List<dynamic>> datosTabla = rows.map((fila) {
      // Protección extra por si una fila no es lista
      if (fila is! List) return <dynamic>[];
      
      return fila.map((celda) {
        if (celda is double) {
          if (celda != 0 && celda.abs() < 0.0001) return celda.toStringAsExponential(2);
          if (celda == celda.toInt()) return celda.toInt();
          return celda.toStringAsFixed(4);
        }
        return celda;
      }).toList();
    }).toList();

    return pw.TableHelper.fromTextArray(
      headers: cols.map((c) => c.toString().toUpperCase()).toList(),
      data: datosTabla,
      headerStyle: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
      cellStyle: const pw.TextStyle(fontSize: 8),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.blue900),
      rowDecoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5))),
      cellAlignment: pw.Alignment.centerLeft,
      headerAlignment: pw.Alignment.centerLeft,
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
    );
  }
}
