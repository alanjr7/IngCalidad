import 'package:drift/drift.dart';

/// Fallback para plataformas sin conexión disponible.
QueryExecutor openConnection() => throw UnsupportedError(
      'Plataforma no soportada para la base de datos local',
    );
