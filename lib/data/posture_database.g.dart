// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'posture_database.dart';

// ignore_for_file: type=lint
class $MinuteStatsTable extends MinuteStats
    with TableInfo<$MinuteStatsTable, MinuteStat> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MinuteStatsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _minuteEpochMeta = const VerificationMeta(
    'minuteEpoch',
  );
  @override
  late final GeneratedColumn<int> minuteEpoch = GeneratedColumn<int>(
    'minute_epoch',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _uprightSecondsMeta = const VerificationMeta(
    'uprightSeconds',
  );
  @override
  late final GeneratedColumn<int> uprightSeconds = GeneratedColumn<int>(
    'upright_seconds',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _slouchSecondsMeta = const VerificationMeta(
    'slouchSeconds',
  );
  @override
  late final GeneratedColumn<int> slouchSeconds = GeneratedColumn<int>(
    'slouch_seconds',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _peakAngleMeta = const VerificationMeta(
    'peakAngle',
  );
  @override
  late final GeneratedColumn<int> peakAngle = GeneratedColumn<int>(
    'peak_angle',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    minuteEpoch,
    uprightSeconds,
    slouchSeconds,
    peakAngle,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'minute_stats';
  @override
  VerificationContext validateIntegrity(
    Insertable<MinuteStat> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('minute_epoch')) {
      context.handle(
        _minuteEpochMeta,
        minuteEpoch.isAcceptableOrUnknown(
          data['minute_epoch']!,
          _minuteEpochMeta,
        ),
      );
    }
    if (data.containsKey('upright_seconds')) {
      context.handle(
        _uprightSecondsMeta,
        uprightSeconds.isAcceptableOrUnknown(
          data['upright_seconds']!,
          _uprightSecondsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_uprightSecondsMeta);
    }
    if (data.containsKey('slouch_seconds')) {
      context.handle(
        _slouchSecondsMeta,
        slouchSeconds.isAcceptableOrUnknown(
          data['slouch_seconds']!,
          _slouchSecondsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_slouchSecondsMeta);
    }
    if (data.containsKey('peak_angle')) {
      context.handle(
        _peakAngleMeta,
        peakAngle.isAcceptableOrUnknown(data['peak_angle']!, _peakAngleMeta),
      );
    } else if (isInserting) {
      context.missing(_peakAngleMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {minuteEpoch};
  @override
  MinuteStat map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MinuteStat(
      minuteEpoch: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}minute_epoch'],
      )!,
      uprightSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}upright_seconds'],
      )!,
      slouchSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}slouch_seconds'],
      )!,
      peakAngle: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}peak_angle'],
      )!,
    );
  }

  @override
  $MinuteStatsTable createAlias(String alias) {
    return $MinuteStatsTable(attachedDatabase, alias);
  }
}

class MinuteStat extends DataClass implements Insertable<MinuteStat> {
  final int minuteEpoch;
  final int uprightSeconds;
  final int slouchSeconds;
  final int peakAngle;
  const MinuteStat({
    required this.minuteEpoch,
    required this.uprightSeconds,
    required this.slouchSeconds,
    required this.peakAngle,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['minute_epoch'] = Variable<int>(minuteEpoch);
    map['upright_seconds'] = Variable<int>(uprightSeconds);
    map['slouch_seconds'] = Variable<int>(slouchSeconds);
    map['peak_angle'] = Variable<int>(peakAngle);
    return map;
  }

  MinuteStatsCompanion toCompanion(bool nullToAbsent) {
    return MinuteStatsCompanion(
      minuteEpoch: Value(minuteEpoch),
      uprightSeconds: Value(uprightSeconds),
      slouchSeconds: Value(slouchSeconds),
      peakAngle: Value(peakAngle),
    );
  }

  factory MinuteStat.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MinuteStat(
      minuteEpoch: serializer.fromJson<int>(json['minuteEpoch']),
      uprightSeconds: serializer.fromJson<int>(json['uprightSeconds']),
      slouchSeconds: serializer.fromJson<int>(json['slouchSeconds']),
      peakAngle: serializer.fromJson<int>(json['peakAngle']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'minuteEpoch': serializer.toJson<int>(minuteEpoch),
      'uprightSeconds': serializer.toJson<int>(uprightSeconds),
      'slouchSeconds': serializer.toJson<int>(slouchSeconds),
      'peakAngle': serializer.toJson<int>(peakAngle),
    };
  }

  MinuteStat copyWith({
    int? minuteEpoch,
    int? uprightSeconds,
    int? slouchSeconds,
    int? peakAngle,
  }) => MinuteStat(
    minuteEpoch: minuteEpoch ?? this.minuteEpoch,
    uprightSeconds: uprightSeconds ?? this.uprightSeconds,
    slouchSeconds: slouchSeconds ?? this.slouchSeconds,
    peakAngle: peakAngle ?? this.peakAngle,
  );
  MinuteStat copyWithCompanion(MinuteStatsCompanion data) {
    return MinuteStat(
      minuteEpoch: data.minuteEpoch.present
          ? data.minuteEpoch.value
          : this.minuteEpoch,
      uprightSeconds: data.uprightSeconds.present
          ? data.uprightSeconds.value
          : this.uprightSeconds,
      slouchSeconds: data.slouchSeconds.present
          ? data.slouchSeconds.value
          : this.slouchSeconds,
      peakAngle: data.peakAngle.present ? data.peakAngle.value : this.peakAngle,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MinuteStat(')
          ..write('minuteEpoch: $minuteEpoch, ')
          ..write('uprightSeconds: $uprightSeconds, ')
          ..write('slouchSeconds: $slouchSeconds, ')
          ..write('peakAngle: $peakAngle')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(minuteEpoch, uprightSeconds, slouchSeconds, peakAngle);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MinuteStat &&
          other.minuteEpoch == this.minuteEpoch &&
          other.uprightSeconds == this.uprightSeconds &&
          other.slouchSeconds == this.slouchSeconds &&
          other.peakAngle == this.peakAngle);
}

class MinuteStatsCompanion extends UpdateCompanion<MinuteStat> {
  final Value<int> minuteEpoch;
  final Value<int> uprightSeconds;
  final Value<int> slouchSeconds;
  final Value<int> peakAngle;
  const MinuteStatsCompanion({
    this.minuteEpoch = const Value.absent(),
    this.uprightSeconds = const Value.absent(),
    this.slouchSeconds = const Value.absent(),
    this.peakAngle = const Value.absent(),
  });
  MinuteStatsCompanion.insert({
    this.minuteEpoch = const Value.absent(),
    required int uprightSeconds,
    required int slouchSeconds,
    required int peakAngle,
  }) : uprightSeconds = Value(uprightSeconds),
       slouchSeconds = Value(slouchSeconds),
       peakAngle = Value(peakAngle);
  static Insertable<MinuteStat> custom({
    Expression<int>? minuteEpoch,
    Expression<int>? uprightSeconds,
    Expression<int>? slouchSeconds,
    Expression<int>? peakAngle,
  }) {
    return RawValuesInsertable({
      if (minuteEpoch != null) 'minute_epoch': minuteEpoch,
      if (uprightSeconds != null) 'upright_seconds': uprightSeconds,
      if (slouchSeconds != null) 'slouch_seconds': slouchSeconds,
      if (peakAngle != null) 'peak_angle': peakAngle,
    });
  }

  MinuteStatsCompanion copyWith({
    Value<int>? minuteEpoch,
    Value<int>? uprightSeconds,
    Value<int>? slouchSeconds,
    Value<int>? peakAngle,
  }) {
    return MinuteStatsCompanion(
      minuteEpoch: minuteEpoch ?? this.minuteEpoch,
      uprightSeconds: uprightSeconds ?? this.uprightSeconds,
      slouchSeconds: slouchSeconds ?? this.slouchSeconds,
      peakAngle: peakAngle ?? this.peakAngle,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (minuteEpoch.present) {
      map['minute_epoch'] = Variable<int>(minuteEpoch.value);
    }
    if (uprightSeconds.present) {
      map['upright_seconds'] = Variable<int>(uprightSeconds.value);
    }
    if (slouchSeconds.present) {
      map['slouch_seconds'] = Variable<int>(slouchSeconds.value);
    }
    if (peakAngle.present) {
      map['peak_angle'] = Variable<int>(peakAngle.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MinuteStatsCompanion(')
          ..write('minuteEpoch: $minuteEpoch, ')
          ..write('uprightSeconds: $uprightSeconds, ')
          ..write('slouchSeconds: $slouchSeconds, ')
          ..write('peakAngle: $peakAngle')
          ..write(')'))
        .toString();
  }
}

class $SlouchEventsTable extends SlouchEvents
    with TableInfo<$SlouchEventsTable, SlouchEvent> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SlouchEventsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _deviceSeqMeta = const VerificationMeta(
    'deviceSeq',
  );
  @override
  late final GeneratedColumn<int> deviceSeq = GeneratedColumn<int>(
    'device_seq',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _startEpochMeta = const VerificationMeta(
    'startEpoch',
  );
  @override
  late final GeneratedColumn<int> startEpoch = GeneratedColumn<int>(
    'start_epoch',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _durationSecondsMeta = const VerificationMeta(
    'durationSeconds',
  );
  @override
  late final GeneratedColumn<int> durationSeconds = GeneratedColumn<int>(
    'duration_seconds',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _peakAngleMeta = const VerificationMeta(
    'peakAngle',
  );
  @override
  late final GeneratedColumn<int> peakAngle = GeneratedColumn<int>(
    'peak_angle',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    deviceSeq,
    startEpoch,
    durationSeconds,
    peakAngle,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'slouch_events';
  @override
  VerificationContext validateIntegrity(
    Insertable<SlouchEvent> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('device_seq')) {
      context.handle(
        _deviceSeqMeta,
        deviceSeq.isAcceptableOrUnknown(data['device_seq']!, _deviceSeqMeta),
      );
    }
    if (data.containsKey('start_epoch')) {
      context.handle(
        _startEpochMeta,
        startEpoch.isAcceptableOrUnknown(data['start_epoch']!, _startEpochMeta),
      );
    } else if (isInserting) {
      context.missing(_startEpochMeta);
    }
    if (data.containsKey('duration_seconds')) {
      context.handle(
        _durationSecondsMeta,
        durationSeconds.isAcceptableOrUnknown(
          data['duration_seconds']!,
          _durationSecondsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_durationSecondsMeta);
    }
    if (data.containsKey('peak_angle')) {
      context.handle(
        _peakAngleMeta,
        peakAngle.isAcceptableOrUnknown(data['peak_angle']!, _peakAngleMeta),
      );
    } else if (isInserting) {
      context.missing(_peakAngleMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {deviceSeq};
  @override
  SlouchEvent map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SlouchEvent(
      deviceSeq: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}device_seq'],
      )!,
      startEpoch: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}start_epoch'],
      )!,
      durationSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_seconds'],
      )!,
      peakAngle: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}peak_angle'],
      )!,
    );
  }

  @override
  $SlouchEventsTable createAlias(String alias) {
    return $SlouchEventsTable(attachedDatabase, alias);
  }
}

class SlouchEvent extends DataClass implements Insertable<SlouchEvent> {
  final int deviceSeq;
  final int startEpoch;
  final int durationSeconds;
  final int peakAngle;
  const SlouchEvent({
    required this.deviceSeq,
    required this.startEpoch,
    required this.durationSeconds,
    required this.peakAngle,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['device_seq'] = Variable<int>(deviceSeq);
    map['start_epoch'] = Variable<int>(startEpoch);
    map['duration_seconds'] = Variable<int>(durationSeconds);
    map['peak_angle'] = Variable<int>(peakAngle);
    return map;
  }

  SlouchEventsCompanion toCompanion(bool nullToAbsent) {
    return SlouchEventsCompanion(
      deviceSeq: Value(deviceSeq),
      startEpoch: Value(startEpoch),
      durationSeconds: Value(durationSeconds),
      peakAngle: Value(peakAngle),
    );
  }

  factory SlouchEvent.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SlouchEvent(
      deviceSeq: serializer.fromJson<int>(json['deviceSeq']),
      startEpoch: serializer.fromJson<int>(json['startEpoch']),
      durationSeconds: serializer.fromJson<int>(json['durationSeconds']),
      peakAngle: serializer.fromJson<int>(json['peakAngle']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'deviceSeq': serializer.toJson<int>(deviceSeq),
      'startEpoch': serializer.toJson<int>(startEpoch),
      'durationSeconds': serializer.toJson<int>(durationSeconds),
      'peakAngle': serializer.toJson<int>(peakAngle),
    };
  }

  SlouchEvent copyWith({
    int? deviceSeq,
    int? startEpoch,
    int? durationSeconds,
    int? peakAngle,
  }) => SlouchEvent(
    deviceSeq: deviceSeq ?? this.deviceSeq,
    startEpoch: startEpoch ?? this.startEpoch,
    durationSeconds: durationSeconds ?? this.durationSeconds,
    peakAngle: peakAngle ?? this.peakAngle,
  );
  SlouchEvent copyWithCompanion(SlouchEventsCompanion data) {
    return SlouchEvent(
      deviceSeq: data.deviceSeq.present ? data.deviceSeq.value : this.deviceSeq,
      startEpoch: data.startEpoch.present
          ? data.startEpoch.value
          : this.startEpoch,
      durationSeconds: data.durationSeconds.present
          ? data.durationSeconds.value
          : this.durationSeconds,
      peakAngle: data.peakAngle.present ? data.peakAngle.value : this.peakAngle,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SlouchEvent(')
          ..write('deviceSeq: $deviceSeq, ')
          ..write('startEpoch: $startEpoch, ')
          ..write('durationSeconds: $durationSeconds, ')
          ..write('peakAngle: $peakAngle')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(deviceSeq, startEpoch, durationSeconds, peakAngle);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SlouchEvent &&
          other.deviceSeq == this.deviceSeq &&
          other.startEpoch == this.startEpoch &&
          other.durationSeconds == this.durationSeconds &&
          other.peakAngle == this.peakAngle);
}

class SlouchEventsCompanion extends UpdateCompanion<SlouchEvent> {
  final Value<int> deviceSeq;
  final Value<int> startEpoch;
  final Value<int> durationSeconds;
  final Value<int> peakAngle;
  const SlouchEventsCompanion({
    this.deviceSeq = const Value.absent(),
    this.startEpoch = const Value.absent(),
    this.durationSeconds = const Value.absent(),
    this.peakAngle = const Value.absent(),
  });
  SlouchEventsCompanion.insert({
    this.deviceSeq = const Value.absent(),
    required int startEpoch,
    required int durationSeconds,
    required int peakAngle,
  }) : startEpoch = Value(startEpoch),
       durationSeconds = Value(durationSeconds),
       peakAngle = Value(peakAngle);
  static Insertable<SlouchEvent> custom({
    Expression<int>? deviceSeq,
    Expression<int>? startEpoch,
    Expression<int>? durationSeconds,
    Expression<int>? peakAngle,
  }) {
    return RawValuesInsertable({
      if (deviceSeq != null) 'device_seq': deviceSeq,
      if (startEpoch != null) 'start_epoch': startEpoch,
      if (durationSeconds != null) 'duration_seconds': durationSeconds,
      if (peakAngle != null) 'peak_angle': peakAngle,
    });
  }

  SlouchEventsCompanion copyWith({
    Value<int>? deviceSeq,
    Value<int>? startEpoch,
    Value<int>? durationSeconds,
    Value<int>? peakAngle,
  }) {
    return SlouchEventsCompanion(
      deviceSeq: deviceSeq ?? this.deviceSeq,
      startEpoch: startEpoch ?? this.startEpoch,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      peakAngle: peakAngle ?? this.peakAngle,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (deviceSeq.present) {
      map['device_seq'] = Variable<int>(deviceSeq.value);
    }
    if (startEpoch.present) {
      map['start_epoch'] = Variable<int>(startEpoch.value);
    }
    if (durationSeconds.present) {
      map['duration_seconds'] = Variable<int>(durationSeconds.value);
    }
    if (peakAngle.present) {
      map['peak_angle'] = Variable<int>(peakAngle.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SlouchEventsCompanion(')
          ..write('deviceSeq: $deviceSeq, ')
          ..write('startEpoch: $startEpoch, ')
          ..write('durationSeconds: $durationSeconds, ')
          ..write('peakAngle: $peakAngle')
          ..write(')'))
        .toString();
  }
}

abstract class _$PostureDatabase extends GeneratedDatabase {
  _$PostureDatabase(QueryExecutor e) : super(e);
  $PostureDatabaseManager get managers => $PostureDatabaseManager(this);
  late final $MinuteStatsTable minuteStats = $MinuteStatsTable(this);
  late final $SlouchEventsTable slouchEvents = $SlouchEventsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    minuteStats,
    slouchEvents,
  ];
}

typedef $$MinuteStatsTableCreateCompanionBuilder =
    MinuteStatsCompanion Function({
      Value<int> minuteEpoch,
      required int uprightSeconds,
      required int slouchSeconds,
      required int peakAngle,
    });
typedef $$MinuteStatsTableUpdateCompanionBuilder =
    MinuteStatsCompanion Function({
      Value<int> minuteEpoch,
      Value<int> uprightSeconds,
      Value<int> slouchSeconds,
      Value<int> peakAngle,
    });

class $$MinuteStatsTableFilterComposer
    extends Composer<_$PostureDatabase, $MinuteStatsTable> {
  $$MinuteStatsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get minuteEpoch => $composableBuilder(
    column: $table.minuteEpoch,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get uprightSeconds => $composableBuilder(
    column: $table.uprightSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get slouchSeconds => $composableBuilder(
    column: $table.slouchSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get peakAngle => $composableBuilder(
    column: $table.peakAngle,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MinuteStatsTableOrderingComposer
    extends Composer<_$PostureDatabase, $MinuteStatsTable> {
  $$MinuteStatsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get minuteEpoch => $composableBuilder(
    column: $table.minuteEpoch,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get uprightSeconds => $composableBuilder(
    column: $table.uprightSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get slouchSeconds => $composableBuilder(
    column: $table.slouchSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get peakAngle => $composableBuilder(
    column: $table.peakAngle,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MinuteStatsTableAnnotationComposer
    extends Composer<_$PostureDatabase, $MinuteStatsTable> {
  $$MinuteStatsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get minuteEpoch => $composableBuilder(
    column: $table.minuteEpoch,
    builder: (column) => column,
  );

  GeneratedColumn<int> get uprightSeconds => $composableBuilder(
    column: $table.uprightSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<int> get slouchSeconds => $composableBuilder(
    column: $table.slouchSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<int> get peakAngle =>
      $composableBuilder(column: $table.peakAngle, builder: (column) => column);
}

class $$MinuteStatsTableTableManager
    extends
        RootTableManager<
          _$PostureDatabase,
          $MinuteStatsTable,
          MinuteStat,
          $$MinuteStatsTableFilterComposer,
          $$MinuteStatsTableOrderingComposer,
          $$MinuteStatsTableAnnotationComposer,
          $$MinuteStatsTableCreateCompanionBuilder,
          $$MinuteStatsTableUpdateCompanionBuilder,
          (
            MinuteStat,
            BaseReferences<_$PostureDatabase, $MinuteStatsTable, MinuteStat>,
          ),
          MinuteStat,
          PrefetchHooks Function()
        > {
  $$MinuteStatsTableTableManager(_$PostureDatabase db, $MinuteStatsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MinuteStatsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MinuteStatsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MinuteStatsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> minuteEpoch = const Value.absent(),
                Value<int> uprightSeconds = const Value.absent(),
                Value<int> slouchSeconds = const Value.absent(),
                Value<int> peakAngle = const Value.absent(),
              }) => MinuteStatsCompanion(
                minuteEpoch: minuteEpoch,
                uprightSeconds: uprightSeconds,
                slouchSeconds: slouchSeconds,
                peakAngle: peakAngle,
              ),
          createCompanionCallback:
              ({
                Value<int> minuteEpoch = const Value.absent(),
                required int uprightSeconds,
                required int slouchSeconds,
                required int peakAngle,
              }) => MinuteStatsCompanion.insert(
                minuteEpoch: minuteEpoch,
                uprightSeconds: uprightSeconds,
                slouchSeconds: slouchSeconds,
                peakAngle: peakAngle,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$MinuteStatsTable, MinuteStat>(table),
                  BaseReferences<
                    _$PostureDatabase,
                    $MinuteStatsTable,
                    MinuteStat
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MinuteStatsTableProcessedTableManager =
    ProcessedTableManager<
      _$PostureDatabase,
      $MinuteStatsTable,
      MinuteStat,
      $$MinuteStatsTableFilterComposer,
      $$MinuteStatsTableOrderingComposer,
      $$MinuteStatsTableAnnotationComposer,
      $$MinuteStatsTableCreateCompanionBuilder,
      $$MinuteStatsTableUpdateCompanionBuilder,
      (
        MinuteStat,
        BaseReferences<_$PostureDatabase, $MinuteStatsTable, MinuteStat>,
      ),
      MinuteStat,
      PrefetchHooks Function()
    >;
typedef $$SlouchEventsTableCreateCompanionBuilder =
    SlouchEventsCompanion Function({
      Value<int> deviceSeq,
      required int startEpoch,
      required int durationSeconds,
      required int peakAngle,
    });
typedef $$SlouchEventsTableUpdateCompanionBuilder =
    SlouchEventsCompanion Function({
      Value<int> deviceSeq,
      Value<int> startEpoch,
      Value<int> durationSeconds,
      Value<int> peakAngle,
    });

class $$SlouchEventsTableFilterComposer
    extends Composer<_$PostureDatabase, $SlouchEventsTable> {
  $$SlouchEventsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get deviceSeq => $composableBuilder(
    column: $table.deviceSeq,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get startEpoch => $composableBuilder(
    column: $table.startEpoch,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationSeconds => $composableBuilder(
    column: $table.durationSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get peakAngle => $composableBuilder(
    column: $table.peakAngle,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SlouchEventsTableOrderingComposer
    extends Composer<_$PostureDatabase, $SlouchEventsTable> {
  $$SlouchEventsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get deviceSeq => $composableBuilder(
    column: $table.deviceSeq,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get startEpoch => $composableBuilder(
    column: $table.startEpoch,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationSeconds => $composableBuilder(
    column: $table.durationSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get peakAngle => $composableBuilder(
    column: $table.peakAngle,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SlouchEventsTableAnnotationComposer
    extends Composer<_$PostureDatabase, $SlouchEventsTable> {
  $$SlouchEventsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get deviceSeq =>
      $composableBuilder(column: $table.deviceSeq, builder: (column) => column);

  GeneratedColumn<int> get startEpoch => $composableBuilder(
    column: $table.startEpoch,
    builder: (column) => column,
  );

  GeneratedColumn<int> get durationSeconds => $composableBuilder(
    column: $table.durationSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<int> get peakAngle =>
      $composableBuilder(column: $table.peakAngle, builder: (column) => column);
}

class $$SlouchEventsTableTableManager
    extends
        RootTableManager<
          _$PostureDatabase,
          $SlouchEventsTable,
          SlouchEvent,
          $$SlouchEventsTableFilterComposer,
          $$SlouchEventsTableOrderingComposer,
          $$SlouchEventsTableAnnotationComposer,
          $$SlouchEventsTableCreateCompanionBuilder,
          $$SlouchEventsTableUpdateCompanionBuilder,
          (
            SlouchEvent,
            BaseReferences<_$PostureDatabase, $SlouchEventsTable, SlouchEvent>,
          ),
          SlouchEvent,
          PrefetchHooks Function()
        > {
  $$SlouchEventsTableTableManager(
    _$PostureDatabase db,
    $SlouchEventsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SlouchEventsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SlouchEventsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SlouchEventsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> deviceSeq = const Value.absent(),
                Value<int> startEpoch = const Value.absent(),
                Value<int> durationSeconds = const Value.absent(),
                Value<int> peakAngle = const Value.absent(),
              }) => SlouchEventsCompanion(
                deviceSeq: deviceSeq,
                startEpoch: startEpoch,
                durationSeconds: durationSeconds,
                peakAngle: peakAngle,
              ),
          createCompanionCallback:
              ({
                Value<int> deviceSeq = const Value.absent(),
                required int startEpoch,
                required int durationSeconds,
                required int peakAngle,
              }) => SlouchEventsCompanion.insert(
                deviceSeq: deviceSeq,
                startEpoch: startEpoch,
                durationSeconds: durationSeconds,
                peakAngle: peakAngle,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SlouchEventsTable, SlouchEvent>(table),
                  BaseReferences<
                    _$PostureDatabase,
                    $SlouchEventsTable,
                    SlouchEvent
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SlouchEventsTableProcessedTableManager =
    ProcessedTableManager<
      _$PostureDatabase,
      $SlouchEventsTable,
      SlouchEvent,
      $$SlouchEventsTableFilterComposer,
      $$SlouchEventsTableOrderingComposer,
      $$SlouchEventsTableAnnotationComposer,
      $$SlouchEventsTableCreateCompanionBuilder,
      $$SlouchEventsTableUpdateCompanionBuilder,
      (
        SlouchEvent,
        BaseReferences<_$PostureDatabase, $SlouchEventsTable, SlouchEvent>,
      ),
      SlouchEvent,
      PrefetchHooks Function()
    >;

class $PostureDatabaseManager {
  final _$PostureDatabase _db;
  $PostureDatabaseManager(this._db);
  $$MinuteStatsTableTableManager get minuteStats =>
      $$MinuteStatsTableTableManager(_db, _db.minuteStats);
  $$SlouchEventsTableTableManager get slouchEvents =>
      $$SlouchEventsTableTableManager(_db, _db.slouchEvents);
}
