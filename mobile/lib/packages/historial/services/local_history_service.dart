import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'connection/connection.dart';
import '../models/analysis_result.dart';
import '../../../core/constants/risk_level.dart';

part 'local_history_service.g.dart';

// ── Tabla Drift ───────────────────────────────────────────────

class AnalysisEntries extends Table {
  TextColumn get id => text().clientDefault(() =>
      DateTime.now().millisecondsSinceEpoch.toString())();
  TextColumn get type => text()();
  TextColumn get riskLevel => text()();
  RealColumn get riskScore => real()();
  TextColumn get patternsJson => text()();  // JSON string
  TextColumn get contentPreview => text().nullable()();
  IntColumn get processingMs => integer().nullable()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

// ── Database ──────────────────────────────────────────────────

@DriftDatabase(tables: [AnalysisEntries])
class LocalDatabase extends _$LocalDatabase {
  LocalDatabase() : super(openConnection());

  @override
  int get schemaVersion => 1;
}

// ── Service ───────────────────────────────────────────────────

final localHistoryServiceProvider = Provider<LocalHistoryService>((ref) {
  return LocalHistoryService(LocalDatabase());
});

class LocalHistoryService {
  final LocalDatabase _db;

  LocalHistoryService(this._db);

  Future<void> save(AnalysisResult result) async {
    await _db.into(_db.analysisEntries).insert(
          AnalysisEntriesCompanion.insert(
            type: result.type,
            riskLevel: result.riskLevel.name,
            riskScore: result.riskScore,
            patternsJson: result.patternsFound.join('||'),
            contentPreview: Value(result.contentPreview),
            processingMs: Value(result.processingMs),
            createdAt: result.createdAt,
          ),
        );
  }

  Future<List<AnalysisResult>> getAll({int limit = 100}) async {
    final rows = await (_db.select(_db.analysisEntries)
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
          ..limit(limit))
        .get();
    return rows.map(_rowToResult).toList();
  }

  Future<void> delete(String id) async {
    await (_db.delete(_db.analysisEntries)
          ..where((t) => t.id.equals(id)))
        .go();
  }

  Future<void> clearAll() async {
    await _db.delete(_db.analysisEntries).go();
  }

  AnalysisResult _rowToResult(AnalysisEntry row) => AnalysisResult(
        id: row.id,
        type: row.type,
        riskLevel: RiskLevel.fromString(row.riskLevel),
        riskScore: row.riskScore,
        patternsFound: row.patternsJson.isEmpty
            ? []
            : row.patternsJson.split('||'),
        contentPreview: row.contentPreview,
        processingMs: row.processingMs,
        createdAt: row.createdAt,
      );
}
