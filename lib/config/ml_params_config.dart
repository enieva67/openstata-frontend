class ModelParam {
  final String key;
  final String label;
  final String type; // 'int', 'float', 'select'
  final dynamic defaultValue;
  final List<String>? options;

  ModelParam({required this.key, required this.label, required this.type, required this.defaultValue, this.options});
}

final Map<String, List<ModelParam>> mlParamsConfig = {
  // RANDOM FOREST
  'rf': [
    ModelParam(key: 'n_estimators', label: 'N° Árboles', type: 'int', defaultValue: 100),
    ModelParam(key: 'max_depth', label: 'Profundidad Máx (0=Auto)', type: 'int', defaultValue: 0),
  ],
  // XGBOOST
  'xgb': [
    ModelParam(key: 'n_estimators', label: 'Rondas Boosting', type: 'int', defaultValue: 100),
    ModelParam(key: 'learning_rate', label: 'Tasa Aprendizaje', type: 'float', defaultValue: 0.1),
  ],
  // SVM
  'svm': [
    ModelParam(key: 'C', label: 'Regularización (C)', type: 'float', defaultValue: 1.0),
    ModelParam(key: 'kernel', label: 'Kernel', type: 'select', defaultValue: 'rbf', options: ['linear', 'poly', 'rbf', 'sigmoid']),
  ],
  // KNN
  'knn': [
    ModelParam(key: 'n_neighbors', label: 'Vecinos (k)', type: 'int', defaultValue: 5),
  ],
  // LASSO / RIDGE
  'lasso': [ ModelParam(key: 'alpha', label: 'Penalización (Alpha)', type: 'float', defaultValue: 1.0) ],
  'ridge': [ ModelParam(key: 'alpha', label: 'Penalización (Alpha)', type: 'float', defaultValue: 1.0) ],
};
