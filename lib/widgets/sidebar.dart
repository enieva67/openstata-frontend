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
            _crearOpcion("Mapa de Calor (Heatmap)", "heatmap"),
            _crearOpcion("Scatter Plot (Dispersión)", "scatter"),
            _crearOpcion("Boxplot (Cajas)", "boxplot"),
            _crearOpcion("Configurar Estilos Gráficos", "config_graficos")
          ]),
          _crearAcordeon("Gráficos Interactivos (Plotly)", Icons.touch_app, [
            _crearOpcion("Scatter 3D (Rotable)", "scatter_3d"),
            _crearOpcion("Scatter 2D (Web)", "scatter_web"),]),
          _crearAcordeon("Gestión de Datos", Icons.build, [
            _crearOpcion("Crear / Transformar Variables", "crear_variable"), // NUEVO
            _crearOpcion("Limpieza Inteligente", "limpieza_datos"),
            _crearOpcion("Descomponer Fechas (Time Features)", "extraer_fecha"), // NUEVO
                  ]),
          
          _crearAcordeon("Estadística Descriptiva", Icons.analytics, [
            _crearOpcion("Resumen General", "resumen"),
            _crearOpcion("Matriz de Correlación", "correlacion"),
          ]),

          _crearAcordeon("Pruebas Paramétricas", Icons.show_chart, [
            _crearOpcion("Prueba T (1 muestra)", "ttest_1samp"),
            _crearOpcion("Prueba T (Indep.)", "ttest_ind"),
            _crearOpcion("ANOVA", "anova"),
            _crearOpcion("Prueba T (Pareada)", "ttest_rel"), // NUEVO
            _crearOpcion("ANOVA (1 Factor)", "anova"),       // NUEVO
          ]),
          _crearAcordeon("Machine Learning Pro", Icons.psychology, [
            _crearOpcion("Entrenar Modelo (RF/XGB)", "ml_training"),
          ]),
          _crearAcordeon("Sistemas de Recomendación", Icons.shopping_bag, [
        _crearOpcion("Colaborativo (SVD)", "svd"),
        _crearOpcion("Market Basket (Apriori)", "apriori"),]),
      _crearAcordeon("Multivariado / ML", Icons.hub, [
        _crearOpcion("PCA (Biplot)", "pca"),
        _crearOpcion("K-Means Clustering", "kmeans"),
        _crearOpcion("t-SNE (Manifold Learning)", "tsne"),
         _crearOpcion("PCA (Componentes Princ.)", "pca"),
        _crearOpcion("Método del Codo (Elbow)", "elbow"),
        _crearOpcion("Cluster Jerárquico", "jerarquico"),
      ]),
      _crearAcordeon("Series de Tiempo (Econometría)", Icons.trending_up, [
        _crearOpcion("Descomposición Estacional", "descomposicion"),
        _crearOpcion("Diagnóstico (ACF / PACF)", "acf_pacf"),
        _crearOpcion("Periodograma (Fourier)", "periodograma"),
        _crearOpcion("Causalidad de Granger", "granger"),
         _crearOpcion("Facebook Prophet (Auto)", "prophet"),
        _crearOpcion("Test Estacionariedad (ADF)", "adf_test"),
        _crearOpcion("Modelo ARIMA", "arima"),

      ]),
          // Crea un NUEVO acordeón:
          _crearAcordeon("Tablas y Proporciones", Icons.grid_on, [
            _crearOpcion("Chi-Cuadrado (Independencia)", "chi2"),
            _crearOpcion("Test Exacto de Fisher", "fisher"),
          ]),
          _crearAcordeon("Supuestos y Diagnóstico", Icons.check_circle_outline, [
            _crearOpcion("Normalidad (Shapiro/QQ)", "normalidad"),
            _crearOpcion("Homocedasticidad (Levene)", "levene"),
            _crearOpcion("Post-Hoc Tukey (ANOVA)", "tukey"),
          ]),
          _crearAcordeon("Datasets de Prueba", Icons.science, [
            _crearOpcion("California Housing (Difícil)", "ejemplo_california"),
            _crearOpcion("Breast Cancer (Clásico)", "ejemplo_cancer"),
          ]),
             _crearAcordeon("No Paramétricas", Icons.graphic_eq, [
            _crearOpcion("Mann-Whitney U", "mannwhitney"),
            _crearOpcion("Kruskal-Wallis", "kruskal"),

            _crearOpcion("Wilcoxon (Pareada)", "wilcoxon"), // NUEVO
            _crearOpcion("Correlación Spearman", "spearman"), // NUEVO
          ]),                         
           _crearAcordeon("Diseño Experimental (DoE)", Icons.science_outlined, [
            _crearOpcion("ANOVA Factorial (2 Factores)", "anova_2way"),
          ]),
          _crearAcordeon("Modelos Lineales", Icons.trending_up, [
            _crearOpcion("Análisis ROC & Métricas", "roc_analysis"),
            _crearOpcion("Regresión Lineal Simple", "ols_simple"),
            _crearOpcion("Regresión Múltiple", "ols_multiple"), // Preparando terreno
            _crearOpcion("Regresión Logística", "logit"),
            _crearOpcion("GLM", "glm"),
          ]),
          _crearAcordeon("Análisis de Supervivencia", Icons.medical_services, [
            _crearOpcion("Curvas Kaplan-Meier", "kaplan_meier"),
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