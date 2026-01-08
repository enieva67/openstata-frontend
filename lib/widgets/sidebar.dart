import 'package:flutter/material.dart';

class SidebarMenu extends StatelessWidget {
  final Function(String nombre, String comando) onOpcionSeleccionada;

  const SidebarMenu({super.key, required this.onOpcionSeleccionada});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: Colors.grey.shade300)),
      ),
      child: ListView(
        padding: const EdgeInsets.all(10),
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 10),
            child: Text("ANÁLISIS ESTADÍSTICO", 
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          ),

          _crearAcordeon("Gráficos", Icons.pie_chart, [
            _crearOpcion("Histograma", "histograma"),
            _crearOpcion("Scatter Plot (Dispersión)", "scatter"),
            _crearOpcion("Boxplot (Cajas)", "boxplot"),
          ]),

          _crearAcordeon("Gestión de Datos", Icons.build, [
            _crearOpcion("Limpieza Inteligente", "limpieza_datos"),
                  ]),
          
          _crearAcordeon("Estadística Descriptiva", Icons.analytics, [
            _crearOpcion("Resumen General", "resumen"),
            _crearOpcion("Matriz de Correlación", "correlacion"),
          ]),

          _crearAcordeon("Pruebas Paramétricas", Icons.show_chart, [
            _crearOpcion("Prueba T (1 muestra)", "ttest_1samp"),
            _crearOpcion("Prueba T (Indep.)", "ttest_ind"),
            _crearOpcion("ANOVA", "anova"),
          ]),

          _crearAcordeon("No Paramétricas", Icons.graphic_eq, [
            _crearOpcion("Mann-Whitney U", "mannwhitney"),
            _crearOpcion("Kruskal-Wallis", "kruskal"),
          ]),

          _crearAcordeon("Modelos Lineales", Icons.trending_up, [
            _crearOpcion("Regresión Lineal Simple", "ols_simple"),
            _crearOpcion("Regresión Múltiple", "ols_multiple"), // Preparando terreno
            _crearOpcion("Regresión Logística", "logit"),
            _crearOpcion("GLM", "glm"),
          ]),
        ],
      ),
    );
  }

  Widget _crearAcordeon(String titulo, IconData icono, List<Widget> hijos) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 5),
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ExpansionTile(
        leading: Icon(icono, color: Colors.blueAccent, size: 20),
        title: Text(titulo, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        childrenPadding: const EdgeInsets.only(left: 10, bottom: 5),
        children: hijos,
      ),
    );
  }

  Widget _crearOpcion(String texto, String comandoInterno) {
    return ListTile(
      title: Text(texto, style: const TextStyle(fontSize: 13)),
      dense: true,
      visualDensity: VisualDensity.compact,
      trailing: const Icon(Icons.arrow_right, size: 16, color: Colors.grey),
      onTap: () => onOpcionSeleccionada(texto, comandoInterno),
    );
  }
}