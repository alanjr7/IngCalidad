// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'local_history_service.dart';

// ignore_for_file: type=lint
class $AnalysisEntriesTable extends AnalysisEntries
    with TableInfo<$AnalysisEntriesTable, AnalysisEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AnalysisEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      clientDefault: () => DateTime.now().millisecondsSinceEpoch.toString());
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
      'type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _riskLevelMeta =
      const VerificationMeta('riskLevel');
  @override
  late final GeneratedColumn<String> riskLevel = GeneratedColumn<String>(
      'risk_level', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _riskScoreMeta =
      const VerificationMeta('riskScore');
  @override
  late final GeneratedColumn<double> riskScore = GeneratedColumn<double>(
      'risk_score', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _patternsJsonMeta =
      const VerificationMeta('patternsJson');
  @override
  late final GeneratedColumn<String> patternsJson = GeneratedColumn<String>(
      'patterns_json', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _contentPreviewMeta =
      const VerificationMeta('contentPreview');
  @override
  late final GeneratedColumn<String> contentPreview = GeneratedColumn<String>(
      'content_preview', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _processingMsMeta =
      const VerificationMeta('processingMs');
  @override
  late final GeneratedColumn<int> processingMs = GeneratedColumn<int>(
      'processing_ms', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        type,
        riskLevel,
        riskScore,
        patternsJson,
        contentPreview,
        processingMs,
        createdAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'analysis_entries';
  @override
  VerificationContext validateIntegrity(Insertable<AnalysisEntry> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('type')) {
      context.handle(
          _typeMeta, type.isAcceptableOrUnknown(data['type']!, _typeMeta));
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('risk_level')) {
      context.handle(_riskLevelMeta,
          riskLevel.isAcceptableOrUnknown(data['risk_level']!, _riskLevelMeta));
    } else if (isInserting) {
      context.missing(_riskLevelMeta);
    }
    if (data.containsKey('risk_score')) {
      context.handle(_riskScoreMeta,
          riskScore.isAcceptableOrUnknown(data['risk_score']!, _riskScoreMeta));
    } else if (isInserting) {
      context.missing(_riskScoreMeta);
    }
    if (data.containsKey('patterns_json')) {
      context.handle(
          _patternsJsonMeta,
          patternsJson.isAcceptableOrUnknown(
              data['patterns_json']!, _patternsJsonMeta));
    } else if (isInserting) {
      context.missing(_patternsJsonMeta);
    }
    if (data.containsKey('content_preview')) {
      context.handle(
          _contentPreviewMeta,
          contentPreview.isAcceptableOrUnknown(
              data['content_preview']!, _contentPreviewMeta));
    }
    if (data.containsKey('processing_ms')) {
      context.handle(
          _processingMsMeta,
          processingMs.isAcceptableOrUnknown(
              data['processing_ms']!, _processingMsMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AnalysisEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AnalysisEntry(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      type: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}type'])!,
      riskLevel: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}risk_level'])!,
      riskScore: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}risk_score'])!,
      patternsJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}patterns_json'])!,
      contentPreview: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}content_preview']),
      processingMs: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}processing_ms']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $AnalysisEntriesTable createAlias(String alias) {
    return $AnalysisEntriesTable(attachedDatabase, alias);
  }
}

class AnalysisEntry extends DataClass implements Insertable<AnalysisEntry> {
  final String id;
  final String type;
  final String riskLevel;
  final double riskScore;
  final String patternsJson;
  final String? contentPreview;
  final int? processingMs;
  final DateTime createdAt;
  const AnalysisEntry(
      {required this.id,
      required this.type,
      required this.riskLevel,
      required this.riskScore,
      required this.patternsJson,
      this.contentPreview,
      this.processingMs,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['type'] = Variable<String>(type);
    map['risk_level'] = Variable<String>(riskLevel);
    map['risk_score'] = Variable<double>(riskScore);
    map['patterns_json'] = Variable<String>(patternsJson);
    if (!nullToAbsent || contentPreview != null) {
      map['content_preview'] = Variable<String>(contentPreview);
    }
    if (!nullToAbsent || processingMs != null) {
      map['processing_ms'] = Variable<int>(processingMs);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  AnalysisEntriesCompanion toCompanion(bool nullToAbsent) {
    return AnalysisEntriesCompanion(
      id: Value(id),
      type: Value(type),
      riskLevel: Value(riskLevel),
      riskScore: Value(riskScore),
      patternsJson: Value(patternsJson),
      contentPreview: contentPreview == null && nullToAbsent
          ? const Value.absent()
          : Value(contentPreview),
      processingMs: processingMs == null && nullToAbsent
          ? const Value.absent()
          : Value(processingMs),
      createdAt: Value(createdAt),
    );
  }

  factory AnalysisEntry.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AnalysisEntry(
      id: serializer.fromJson<String>(json['id']),
      type: serializer.fromJson<String>(json['type']),
      riskLevel: serializer.fromJson<String>(json['riskLevel']),
      riskScore: serializer.fromJson<double>(json['riskScore']),
      patternsJson: serializer.fromJson<String>(json['patternsJson']),
      contentPreview: serializer.fromJson<String?>(json['contentPreview']),
      processingMs: serializer.fromJson<int?>(json['processingMs']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'type': serializer.toJson<String>(type),
      'riskLevel': serializer.toJson<String>(riskLevel),
      'riskScore': serializer.toJson<double>(riskScore),
      'patternsJson': serializer.toJson<String>(patternsJson),
      'contentPreview': serializer.toJson<String?>(contentPreview),
      'processingMs': serializer.toJson<int?>(processingMs),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  AnalysisEntry copyWith(
          {String? id,
          String? type,
          String? riskLevel,
          double? riskScore,
          String? patternsJson,
          Value<String?> contentPreview = const Value.absent(),
          Value<int?> processingMs = const Value.absent(),
          DateTime? createdAt}) =>
      AnalysisEntry(
        id: id ?? this.id,
        type: type ?? this.type,
        riskLevel: riskLevel ?? this.riskLevel,
        riskScore: riskScore ?? this.riskScore,
        patternsJson: patternsJson ?? this.patternsJson,
        contentPreview:
            contentPreview.present ? contentPreview.value : this.contentPreview,
        processingMs:
            processingMs.present ? processingMs.value : this.processingMs,
        createdAt: createdAt ?? this.createdAt,
      );
  AnalysisEntry copyWithCompanion(AnalysisEntriesCompanion data) {
    return AnalysisEntry(
      id: data.id.present ? data.id.value : this.id,
      type: data.type.present ? data.type.value : this.type,
      riskLevel: data.riskLevel.present ? data.riskLevel.value : this.riskLevel,
      riskScore: data.riskScore.present ? data.riskScore.value : this.riskScore,
      patternsJson: data.patternsJson.present
          ? data.patternsJson.value
          : this.patternsJson,
      contentPreview: data.contentPreview.present
          ? data.contentPreview.value
          : this.contentPreview,
      processingMs: data.processingMs.present
          ? data.processingMs.value
          : this.processingMs,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AnalysisEntry(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('riskLevel: $riskLevel, ')
          ..write('riskScore: $riskScore, ')
          ..write('patternsJson: $patternsJson, ')
          ..write('contentPreview: $contentPreview, ')
          ..write('processingMs: $processingMs, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, type, riskLevel, riskScore, patternsJson,
      contentPreview, processingMs, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AnalysisEntry &&
          other.id == this.id &&
          other.type == this.type &&
          other.riskLevel == this.riskLevel &&
          other.riskScore == this.riskScore &&
          other.patternsJson == this.patternsJson &&
          other.contentPreview == this.contentPreview &&
          other.processingMs == this.processingMs &&
          other.createdAt == this.createdAt);
}

class AnalysisEntriesCompanion extends UpdateCompanion<AnalysisEntry> {
  final Value<String> id;
  final Value<String> type;
  final Value<String> riskLevel;
  final Value<double> riskScore;
  final Value<String> patternsJson;
  final Value<String?> contentPreview;
  final Value<int?> processingMs;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const AnalysisEntriesCompanion({
    this.id = const Value.absent(),
    this.type = const Value.absent(),
    this.riskLevel = const Value.absent(),
    this.riskScore = const Value.absent(),
    this.patternsJson = const Value.absent(),
    this.contentPreview = const Value.absent(),
    this.processingMs = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AnalysisEntriesCompanion.insert({
    this.id = const Value.absent(),
    required String type,
    required String riskLevel,
    required double riskScore,
    required String patternsJson,
    this.contentPreview = const Value.absent(),
    this.processingMs = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  })  : type = Value(type),
        riskLevel = Value(riskLevel),
        riskScore = Value(riskScore),
        patternsJson = Value(patternsJson),
        createdAt = Value(createdAt);
  static Insertable<AnalysisEntry> custom({
    Expression<String>? id,
    Expression<String>? type,
    Expression<String>? riskLevel,
    Expression<double>? riskScore,
    Expression<String>? patternsJson,
    Expression<String>? contentPreview,
    Expression<int>? processingMs,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (type != null) 'type': type,
      if (riskLevel != null) 'risk_level': riskLevel,
      if (riskScore != null) 'risk_score': riskScore,
      if (patternsJson != null) 'patterns_json': patternsJson,
      if (contentPreview != null) 'content_preview': contentPreview,
      if (processingMs != null) 'processing_ms': processingMs,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AnalysisEntriesCompanion copyWith(
      {Value<String>? id,
      Value<String>? type,
      Value<String>? riskLevel,
      Value<double>? riskScore,
      Value<String>? patternsJson,
      Value<String?>? contentPreview,
      Value<int?>? processingMs,
      Value<DateTime>? createdAt,
      Value<int>? rowid}) {
    return AnalysisEntriesCompanion(
      id: id ?? this.id,
      type: type ?? this.type,
      riskLevel: riskLevel ?? this.riskLevel,
      riskScore: riskScore ?? this.riskScore,
      patternsJson: patternsJson ?? this.patternsJson,
      contentPreview: contentPreview ?? this.contentPreview,
      processingMs: processingMs ?? this.processingMs,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (riskLevel.present) {
      map['risk_level'] = Variable<String>(riskLevel.value);
    }
    if (riskScore.present) {
      map['risk_score'] = Variable<double>(riskScore.value);
    }
    if (patternsJson.present) {
      map['patterns_json'] = Variable<String>(patternsJson.value);
    }
    if (contentPreview.present) {
      map['content_preview'] = Variable<String>(contentPreview.value);
    }
    if (processingMs.present) {
      map['processing_ms'] = Variable<int>(processingMs.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AnalysisEntriesCompanion(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('riskLevel: $riskLevel, ')
          ..write('riskScore: $riskScore, ')
          ..write('patternsJson: $patternsJson, ')
          ..write('contentPreview: $contentPreview, ')
          ..write('processingMs: $processingMs, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$LocalDatabase extends GeneratedDatabase {
  _$LocalDatabase(QueryExecutor e) : super(e);
  $LocalDatabaseManager get managers => $LocalDatabaseManager(this);
  late final $AnalysisEntriesTable analysisEntries =
      $AnalysisEntriesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [analysisEntries];
}

typedef $$AnalysisEntriesTableCreateCompanionBuilder = AnalysisEntriesCompanion
    Function({
  Value<String> id,
  required String type,
  required String riskLevel,
  required double riskScore,
  required String patternsJson,
  Value<String?> contentPreview,
  Value<int?> processingMs,
  required DateTime createdAt,
  Value<int> rowid,
});
typedef $$AnalysisEntriesTableUpdateCompanionBuilder = AnalysisEntriesCompanion
    Function({
  Value<String> id,
  Value<String> type,
  Value<String> riskLevel,
  Value<double> riskScore,
  Value<String> patternsJson,
  Value<String?> contentPreview,
  Value<int?> processingMs,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

class $$AnalysisEntriesTableTableManager extends RootTableManager<
    _$LocalDatabase,
    $AnalysisEntriesTable,
    AnalysisEntry,
    $$AnalysisEntriesTableFilterComposer,
    $$AnalysisEntriesTableOrderingComposer,
    $$AnalysisEntriesTableCreateCompanionBuilder,
    $$AnalysisEntriesTableUpdateCompanionBuilder> {
  $$AnalysisEntriesTableTableManager(
      _$LocalDatabase db, $AnalysisEntriesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$AnalysisEntriesTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$AnalysisEntriesTableOrderingComposer(ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> type = const Value.absent(),
            Value<String> riskLevel = const Value.absent(),
            Value<double> riskScore = const Value.absent(),
            Value<String> patternsJson = const Value.absent(),
            Value<String?> contentPreview = const Value.absent(),
            Value<int?> processingMs = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              AnalysisEntriesCompanion(
            id: id,
            type: type,
            riskLevel: riskLevel,
            riskScore: riskScore,
            patternsJson: patternsJson,
            contentPreview: contentPreview,
            processingMs: processingMs,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            Value<String> id = const Value.absent(),
            required String type,
            required String riskLevel,
            required double riskScore,
            required String patternsJson,
            Value<String?> contentPreview = const Value.absent(),
            Value<int?> processingMs = const Value.absent(),
            required DateTime createdAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              AnalysisEntriesCompanion.insert(
            id: id,
            type: type,
            riskLevel: riskLevel,
            riskScore: riskScore,
            patternsJson: patternsJson,
            contentPreview: contentPreview,
            processingMs: processingMs,
            createdAt: createdAt,
            rowid: rowid,
          ),
        ));
}

class $$AnalysisEntriesTableFilterComposer
    extends FilterComposer<_$LocalDatabase, $AnalysisEntriesTable> {
  $$AnalysisEntriesTableFilterComposer(super.$state);
  ColumnFilters<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get type => $state.composableBuilder(
      column: $state.table.type,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get riskLevel => $state.composableBuilder(
      column: $state.table.riskLevel,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get riskScore => $state.composableBuilder(
      column: $state.table.riskScore,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get patternsJson => $state.composableBuilder(
      column: $state.table.patternsJson,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get contentPreview => $state.composableBuilder(
      column: $state.table.contentPreview,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get processingMs => $state.composableBuilder(
      column: $state.table.processingMs,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));
}

class $$AnalysisEntriesTableOrderingComposer
    extends OrderingComposer<_$LocalDatabase, $AnalysisEntriesTable> {
  $$AnalysisEntriesTableOrderingComposer(super.$state);
  ColumnOrderings<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get type => $state.composableBuilder(
      column: $state.table.type,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get riskLevel => $state.composableBuilder(
      column: $state.table.riskLevel,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get riskScore => $state.composableBuilder(
      column: $state.table.riskScore,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get patternsJson => $state.composableBuilder(
      column: $state.table.patternsJson,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get contentPreview => $state.composableBuilder(
      column: $state.table.contentPreview,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get processingMs => $state.composableBuilder(
      column: $state.table.processingMs,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

class $LocalDatabaseManager {
  final _$LocalDatabase _db;
  $LocalDatabaseManager(this._db);
  $$AnalysisEntriesTableTableManager get analysisEntries =>
      $$AnalysisEntriesTableTableManager(_db, _db.analysisEntries);
}
