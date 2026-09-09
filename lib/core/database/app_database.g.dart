// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $TasksTable extends Tasks with TableInfo<$TasksTable, Task> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TasksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 140),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _isCompletedMeta =
      const VerificationMeta('isCompleted');
  @override
  late final GeneratedColumn<bool> isCompleted = GeneratedColumn<bool>(
      'is_completed', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("is_completed" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _isArchivedMeta =
      const VerificationMeta('isArchived');
  @override
  late final GeneratedColumn<bool> isArchived = GeneratedColumn<bool>(
      'is_archived', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_archived" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _sortOrderMeta =
      const VerificationMeta('sortOrder');
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
      'sort_order', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _completedAtMeta =
      const VerificationMeta('completedAt');
  @override
  late final GeneratedColumn<DateTime> completedAt = GeneratedColumn<DateTime>(
      'completed_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns =>
      [id, title, isCompleted, isArchived, sortOrder, createdAt, completedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tasks';
  @override
  VerificationContext validateIntegrity(Insertable<Task> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('is_completed')) {
      context.handle(
          _isCompletedMeta,
          isCompleted.isAcceptableOrUnknown(
              data['is_completed']!, _isCompletedMeta));
    }
    if (data.containsKey('is_archived')) {
      context.handle(
          _isArchivedMeta,
          isArchived.isAcceptableOrUnknown(
              data['is_archived']!, _isArchivedMeta));
    }
    if (data.containsKey('sort_order')) {
      context.handle(_sortOrderMeta,
          sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('completed_at')) {
      context.handle(
          _completedAtMeta,
          completedAt.isAcceptableOrUnknown(
              data['completed_at']!, _completedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Task map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Task(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      isCompleted: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_completed'])!,
      isArchived: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_archived'])!,
      sortOrder: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}sort_order'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      completedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}completed_at']),
    );
  }

  @override
  $TasksTable createAlias(String alias) {
    return $TasksTable(attachedDatabase, alias);
  }
}

class Task extends DataClass implements Insertable<Task> {
  final int id;
  final String title;
  final bool isCompleted;
  final bool isArchived;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime? completedAt;
  const Task(
      {required this.id,
      required this.title,
      required this.isCompleted,
      required this.isArchived,
      required this.sortOrder,
      required this.createdAt,
      this.completedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['title'] = Variable<String>(title);
    map['is_completed'] = Variable<bool>(isCompleted);
    map['is_archived'] = Variable<bool>(isArchived);
    map['sort_order'] = Variable<int>(sortOrder);
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || completedAt != null) {
      map['completed_at'] = Variable<DateTime>(completedAt);
    }
    return map;
  }

  TasksCompanion toCompanion(bool nullToAbsent) {
    return TasksCompanion(
      id: Value(id),
      title: Value(title),
      isCompleted: Value(isCompleted),
      isArchived: Value(isArchived),
      sortOrder: Value(sortOrder),
      createdAt: Value(createdAt),
      completedAt: completedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(completedAt),
    );
  }

  factory Task.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Task(
      id: serializer.fromJson<int>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      isCompleted: serializer.fromJson<bool>(json['isCompleted']),
      isArchived: serializer.fromJson<bool>(json['isArchived']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      completedAt: serializer.fromJson<DateTime?>(json['completedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'title': serializer.toJson<String>(title),
      'isCompleted': serializer.toJson<bool>(isCompleted),
      'isArchived': serializer.toJson<bool>(isArchived),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'completedAt': serializer.toJson<DateTime?>(completedAt),
    };
  }

  Task copyWith(
          {int? id,
          String? title,
          bool? isCompleted,
          bool? isArchived,
          int? sortOrder,
          DateTime? createdAt,
          Value<DateTime?> completedAt = const Value.absent()}) =>
      Task(
        id: id ?? this.id,
        title: title ?? this.title,
        isCompleted: isCompleted ?? this.isCompleted,
        isArchived: isArchived ?? this.isArchived,
        sortOrder: sortOrder ?? this.sortOrder,
        createdAt: createdAt ?? this.createdAt,
        completedAt: completedAt.present ? completedAt.value : this.completedAt,
      );
  Task copyWithCompanion(TasksCompanion data) {
    return Task(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      isCompleted:
          data.isCompleted.present ? data.isCompleted.value : this.isCompleted,
      isArchived:
          data.isArchived.present ? data.isArchived.value : this.isArchived,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      completedAt:
          data.completedAt.present ? data.completedAt.value : this.completedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Task(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('isCompleted: $isCompleted, ')
          ..write('isArchived: $isArchived, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt, ')
          ..write('completedAt: $completedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, title, isCompleted, isArchived, sortOrder, createdAt, completedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Task &&
          other.id == this.id &&
          other.title == this.title &&
          other.isCompleted == this.isCompleted &&
          other.isArchived == this.isArchived &&
          other.sortOrder == this.sortOrder &&
          other.createdAt == this.createdAt &&
          other.completedAt == this.completedAt);
}

class TasksCompanion extends UpdateCompanion<Task> {
  final Value<int> id;
  final Value<String> title;
  final Value<bool> isCompleted;
  final Value<bool> isArchived;
  final Value<int> sortOrder;
  final Value<DateTime> createdAt;
  final Value<DateTime?> completedAt;
  const TasksCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.isCompleted = const Value.absent(),
    this.isArchived = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.completedAt = const Value.absent(),
  });
  TasksCompanion.insert({
    this.id = const Value.absent(),
    required String title,
    this.isCompleted = const Value.absent(),
    this.isArchived = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.completedAt = const Value.absent(),
  }) : title = Value(title);
  static Insertable<Task> custom({
    Expression<int>? id,
    Expression<String>? title,
    Expression<bool>? isCompleted,
    Expression<bool>? isArchived,
    Expression<int>? sortOrder,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? completedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (isCompleted != null) 'is_completed': isCompleted,
      if (isArchived != null) 'is_archived': isArchived,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (createdAt != null) 'created_at': createdAt,
      if (completedAt != null) 'completed_at': completedAt,
    });
  }

  TasksCompanion copyWith(
      {Value<int>? id,
      Value<String>? title,
      Value<bool>? isCompleted,
      Value<bool>? isArchived,
      Value<int>? sortOrder,
      Value<DateTime>? createdAt,
      Value<DateTime?>? completedAt}) {
    return TasksCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
      isArchived: isArchived ?? this.isArchived,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (isCompleted.present) {
      map['is_completed'] = Variable<bool>(isCompleted.value);
    }
    if (isArchived.present) {
      map['is_archived'] = Variable<bool>(isArchived.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<DateTime>(completedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TasksCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('isCompleted: $isCompleted, ')
          ..write('isArchived: $isArchived, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt, ')
          ..write('completedAt: $completedAt')
          ..write(')'))
        .toString();
  }
}

class $TimerSessionsTable extends TimerSessions
    with TableInfo<$TimerSessionsTable, TimerSession> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TimerSessionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _targetMinutesMeta =
      const VerificationMeta('targetMinutes');
  @override
  late final GeneratedColumn<int> targetMinutes = GeneratedColumn<int>(
      'target_minutes', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _elapsedSecondsMeta =
      const VerificationMeta('elapsedSeconds');
  @override
  late final GeneratedColumn<int> elapsedSeconds = GeneratedColumn<int>(
      'elapsed_seconds', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _isFinishedMeta =
      const VerificationMeta('isFinished');
  @override
  late final GeneratedColumn<bool> isFinished = GeneratedColumn<bool>(
      'is_finished', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_finished" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _startedAtMeta =
      const VerificationMeta('startedAt');
  @override
  late final GeneratedColumn<DateTime> startedAt = GeneratedColumn<DateTime>(
      'started_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _finishedAtMeta =
      const VerificationMeta('finishedAt');
  @override
  late final GeneratedColumn<DateTime> finishedAt = GeneratedColumn<DateTime>(
      'finished_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns =>
      [id, targetMinutes, elapsedSeconds, isFinished, startedAt, finishedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'timer_sessions';
  @override
  VerificationContext validateIntegrity(Insertable<TimerSession> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('target_minutes')) {
      context.handle(
          _targetMinutesMeta,
          targetMinutes.isAcceptableOrUnknown(
              data['target_minutes']!, _targetMinutesMeta));
    } else if (isInserting) {
      context.missing(_targetMinutesMeta);
    }
    if (data.containsKey('elapsed_seconds')) {
      context.handle(
          _elapsedSecondsMeta,
          elapsedSeconds.isAcceptableOrUnknown(
              data['elapsed_seconds']!, _elapsedSecondsMeta));
    } else if (isInserting) {
      context.missing(_elapsedSecondsMeta);
    }
    if (data.containsKey('is_finished')) {
      context.handle(
          _isFinishedMeta,
          isFinished.isAcceptableOrUnknown(
              data['is_finished']!, _isFinishedMeta));
    }
    if (data.containsKey('started_at')) {
      context.handle(_startedAtMeta,
          startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta));
    }
    if (data.containsKey('finished_at')) {
      context.handle(
          _finishedAtMeta,
          finishedAt.isAcceptableOrUnknown(
              data['finished_at']!, _finishedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TimerSession map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TimerSession(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      targetMinutes: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}target_minutes'])!,
      elapsedSeconds: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}elapsed_seconds'])!,
      isFinished: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_finished'])!,
      startedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}started_at'])!,
      finishedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}finished_at']),
    );
  }

  @override
  $TimerSessionsTable createAlias(String alias) {
    return $TimerSessionsTable(attachedDatabase, alias);
  }
}

class TimerSession extends DataClass implements Insertable<TimerSession> {
  final int id;
  final int targetMinutes;
  final int elapsedSeconds;
  final bool isFinished;
  final DateTime startedAt;
  final DateTime? finishedAt;
  const TimerSession(
      {required this.id,
      required this.targetMinutes,
      required this.elapsedSeconds,
      required this.isFinished,
      required this.startedAt,
      this.finishedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['target_minutes'] = Variable<int>(targetMinutes);
    map['elapsed_seconds'] = Variable<int>(elapsedSeconds);
    map['is_finished'] = Variable<bool>(isFinished);
    map['started_at'] = Variable<DateTime>(startedAt);
    if (!nullToAbsent || finishedAt != null) {
      map['finished_at'] = Variable<DateTime>(finishedAt);
    }
    return map;
  }

  TimerSessionsCompanion toCompanion(bool nullToAbsent) {
    return TimerSessionsCompanion(
      id: Value(id),
      targetMinutes: Value(targetMinutes),
      elapsedSeconds: Value(elapsedSeconds),
      isFinished: Value(isFinished),
      startedAt: Value(startedAt),
      finishedAt: finishedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(finishedAt),
    );
  }

  factory TimerSession.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TimerSession(
      id: serializer.fromJson<int>(json['id']),
      targetMinutes: serializer.fromJson<int>(json['targetMinutes']),
      elapsedSeconds: serializer.fromJson<int>(json['elapsedSeconds']),
      isFinished: serializer.fromJson<bool>(json['isFinished']),
      startedAt: serializer.fromJson<DateTime>(json['startedAt']),
      finishedAt: serializer.fromJson<DateTime?>(json['finishedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'targetMinutes': serializer.toJson<int>(targetMinutes),
      'elapsedSeconds': serializer.toJson<int>(elapsedSeconds),
      'isFinished': serializer.toJson<bool>(isFinished),
      'startedAt': serializer.toJson<DateTime>(startedAt),
      'finishedAt': serializer.toJson<DateTime?>(finishedAt),
    };
  }

  TimerSession copyWith(
          {int? id,
          int? targetMinutes,
          int? elapsedSeconds,
          bool? isFinished,
          DateTime? startedAt,
          Value<DateTime?> finishedAt = const Value.absent()}) =>
      TimerSession(
        id: id ?? this.id,
        targetMinutes: targetMinutes ?? this.targetMinutes,
        elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
        isFinished: isFinished ?? this.isFinished,
        startedAt: startedAt ?? this.startedAt,
        finishedAt: finishedAt.present ? finishedAt.value : this.finishedAt,
      );
  TimerSession copyWithCompanion(TimerSessionsCompanion data) {
    return TimerSession(
      id: data.id.present ? data.id.value : this.id,
      targetMinutes: data.targetMinutes.present
          ? data.targetMinutes.value
          : this.targetMinutes,
      elapsedSeconds: data.elapsedSeconds.present
          ? data.elapsedSeconds.value
          : this.elapsedSeconds,
      isFinished:
          data.isFinished.present ? data.isFinished.value : this.isFinished,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      finishedAt:
          data.finishedAt.present ? data.finishedAt.value : this.finishedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TimerSession(')
          ..write('id: $id, ')
          ..write('targetMinutes: $targetMinutes, ')
          ..write('elapsedSeconds: $elapsedSeconds, ')
          ..write('isFinished: $isFinished, ')
          ..write('startedAt: $startedAt, ')
          ..write('finishedAt: $finishedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, targetMinutes, elapsedSeconds, isFinished, startedAt, finishedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TimerSession &&
          other.id == this.id &&
          other.targetMinutes == this.targetMinutes &&
          other.elapsedSeconds == this.elapsedSeconds &&
          other.isFinished == this.isFinished &&
          other.startedAt == this.startedAt &&
          other.finishedAt == this.finishedAt);
}

class TimerSessionsCompanion extends UpdateCompanion<TimerSession> {
  final Value<int> id;
  final Value<int> targetMinutes;
  final Value<int> elapsedSeconds;
  final Value<bool> isFinished;
  final Value<DateTime> startedAt;
  final Value<DateTime?> finishedAt;
  const TimerSessionsCompanion({
    this.id = const Value.absent(),
    this.targetMinutes = const Value.absent(),
    this.elapsedSeconds = const Value.absent(),
    this.isFinished = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.finishedAt = const Value.absent(),
  });
  TimerSessionsCompanion.insert({
    this.id = const Value.absent(),
    required int targetMinutes,
    required int elapsedSeconds,
    this.isFinished = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.finishedAt = const Value.absent(),
  })  : targetMinutes = Value(targetMinutes),
        elapsedSeconds = Value(elapsedSeconds);
  static Insertable<TimerSession> custom({
    Expression<int>? id,
    Expression<int>? targetMinutes,
    Expression<int>? elapsedSeconds,
    Expression<bool>? isFinished,
    Expression<DateTime>? startedAt,
    Expression<DateTime>? finishedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (targetMinutes != null) 'target_minutes': targetMinutes,
      if (elapsedSeconds != null) 'elapsed_seconds': elapsedSeconds,
      if (isFinished != null) 'is_finished': isFinished,
      if (startedAt != null) 'started_at': startedAt,
      if (finishedAt != null) 'finished_at': finishedAt,
    });
  }

  TimerSessionsCompanion copyWith(
      {Value<int>? id,
      Value<int>? targetMinutes,
      Value<int>? elapsedSeconds,
      Value<bool>? isFinished,
      Value<DateTime>? startedAt,
      Value<DateTime?>? finishedAt}) {
    return TimerSessionsCompanion(
      id: id ?? this.id,
      targetMinutes: targetMinutes ?? this.targetMinutes,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      isFinished: isFinished ?? this.isFinished,
      startedAt: startedAt ?? this.startedAt,
      finishedAt: finishedAt ?? this.finishedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (targetMinutes.present) {
      map['target_minutes'] = Variable<int>(targetMinutes.value);
    }
    if (elapsedSeconds.present) {
      map['elapsed_seconds'] = Variable<int>(elapsedSeconds.value);
    }
    if (isFinished.present) {
      map['is_finished'] = Variable<bool>(isFinished.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (finishedAt.present) {
      map['finished_at'] = Variable<DateTime>(finishedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TimerSessionsCompanion(')
          ..write('id: $id, ')
          ..write('targetMinutes: $targetMinutes, ')
          ..write('elapsedSeconds: $elapsedSeconds, ')
          ..write('isFinished: $isFinished, ')
          ..write('startedAt: $startedAt, ')
          ..write('finishedAt: $finishedAt')
          ..write(')'))
        .toString();
  }
}

class $DeskPreferencesTable extends DeskPreferences
    with TableInfo<$DeskPreferencesTable, DeskPreference> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DeskPreferencesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _soundVolumeMeta =
      const VerificationMeta('soundVolume');
  @override
  late final GeneratedColumn<double> soundVolume = GeneratedColumn<double>(
      'sound_volume', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0.8));
  static const VerificationMeta _parallaxEnabledMeta =
      const VerificationMeta('parallaxEnabled');
  @override
  late final GeneratedColumn<bool> parallaxEnabled = GeneratedColumn<bool>(
      'parallax_enabled', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("parallax_enabled" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _activeAmbientTrackIndexMeta =
      const VerificationMeta('activeAmbientTrackIndex');
  @override
  late final GeneratedColumn<int> activeAmbientTrackIndex =
      GeneratedColumn<int>('active_ambient_track_index', aliasedName, false,
          type: DriftSqlType.int,
          requiredDuringInsert: false,
          defaultValue: const Constant(0));
  static const VerificationMeta _foleyEnabledMeta =
      const VerificationMeta('foleyEnabled');
  @override
  late final GeneratedColumn<bool> foleyEnabled = GeneratedColumn<bool>(
      'foley_enabled', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("foley_enabled" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _hapticsEnabledMeta =
      const VerificationMeta('hapticsEnabled');
  @override
  late final GeneratedColumn<bool> hapticsEnabled = GeneratedColumn<bool>(
      'haptics_enabled', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("haptics_enabled" IN (0, 1))'),
      defaultValue: const Constant(true));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        soundVolume,
        parallaxEnabled,
        activeAmbientTrackIndex,
        foleyEnabled,
        hapticsEnabled
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'desk_preferences';
  @override
  VerificationContext validateIntegrity(Insertable<DeskPreference> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('sound_volume')) {
      context.handle(
          _soundVolumeMeta,
          soundVolume.isAcceptableOrUnknown(
              data['sound_volume']!, _soundVolumeMeta));
    }
    if (data.containsKey('parallax_enabled')) {
      context.handle(
          _parallaxEnabledMeta,
          parallaxEnabled.isAcceptableOrUnknown(
              data['parallax_enabled']!, _parallaxEnabledMeta));
    }
    if (data.containsKey('active_ambient_track_index')) {
      context.handle(
          _activeAmbientTrackIndexMeta,
          activeAmbientTrackIndex.isAcceptableOrUnknown(
              data['active_ambient_track_index']!,
              _activeAmbientTrackIndexMeta));
    }
    if (data.containsKey('foley_enabled')) {
      context.handle(
          _foleyEnabledMeta,
          foleyEnabled.isAcceptableOrUnknown(
              data['foley_enabled']!, _foleyEnabledMeta));
    }
    if (data.containsKey('haptics_enabled')) {
      context.handle(
          _hapticsEnabledMeta,
          hapticsEnabled.isAcceptableOrUnknown(
              data['haptics_enabled']!, _hapticsEnabledMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DeskPreference map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DeskPreference(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      soundVolume: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}sound_volume'])!,
      parallaxEnabled: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}parallax_enabled'])!,
      activeAmbientTrackIndex: attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}active_ambient_track_index'])!,
      foleyEnabled: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}foley_enabled'])!,
      hapticsEnabled: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}haptics_enabled'])!,
    );
  }

  @override
  $DeskPreferencesTable createAlias(String alias) {
    return $DeskPreferencesTable(attachedDatabase, alias);
  }
}

class DeskPreference extends DataClass implements Insertable<DeskPreference> {
  final int id;
  final double soundVolume;
  final bool parallaxEnabled;
  final int activeAmbientTrackIndex;
  final bool foleyEnabled;
  final bool hapticsEnabled;
  const DeskPreference(
      {required this.id,
      required this.soundVolume,
      required this.parallaxEnabled,
      required this.activeAmbientTrackIndex,
      required this.foleyEnabled,
      required this.hapticsEnabled});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['sound_volume'] = Variable<double>(soundVolume);
    map['parallax_enabled'] = Variable<bool>(parallaxEnabled);
    map['active_ambient_track_index'] = Variable<int>(activeAmbientTrackIndex);
    map['foley_enabled'] = Variable<bool>(foleyEnabled);
    map['haptics_enabled'] = Variable<bool>(hapticsEnabled);
    return map;
  }

  DeskPreferencesCompanion toCompanion(bool nullToAbsent) {
    return DeskPreferencesCompanion(
      id: Value(id),
      soundVolume: Value(soundVolume),
      parallaxEnabled: Value(parallaxEnabled),
      activeAmbientTrackIndex: Value(activeAmbientTrackIndex),
      foleyEnabled: Value(foleyEnabled),
      hapticsEnabled: Value(hapticsEnabled),
    );
  }

  factory DeskPreference.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DeskPreference(
      id: serializer.fromJson<int>(json['id']),
      soundVolume: serializer.fromJson<double>(json['soundVolume']),
      parallaxEnabled: serializer.fromJson<bool>(json['parallaxEnabled']),
      activeAmbientTrackIndex:
          serializer.fromJson<int>(json['activeAmbientTrackIndex']),
      foleyEnabled: serializer.fromJson<bool>(json['foleyEnabled']),
      hapticsEnabled: serializer.fromJson<bool>(json['hapticsEnabled']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'soundVolume': serializer.toJson<double>(soundVolume),
      'parallaxEnabled': serializer.toJson<bool>(parallaxEnabled),
      'activeAmbientTrackIndex':
          serializer.toJson<int>(activeAmbientTrackIndex),
      'foleyEnabled': serializer.toJson<bool>(foleyEnabled),
      'hapticsEnabled': serializer.toJson<bool>(hapticsEnabled),
    };
  }

  DeskPreference copyWith(
          {int? id,
          double? soundVolume,
          bool? parallaxEnabled,
          int? activeAmbientTrackIndex,
          bool? foleyEnabled,
          bool? hapticsEnabled}) =>
      DeskPreference(
        id: id ?? this.id,
        soundVolume: soundVolume ?? this.soundVolume,
        parallaxEnabled: parallaxEnabled ?? this.parallaxEnabled,
        activeAmbientTrackIndex:
            activeAmbientTrackIndex ?? this.activeAmbientTrackIndex,
        foleyEnabled: foleyEnabled ?? this.foleyEnabled,
        hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
      );
  DeskPreference copyWithCompanion(DeskPreferencesCompanion data) {
    return DeskPreference(
      id: data.id.present ? data.id.value : this.id,
      soundVolume:
          data.soundVolume.present ? data.soundVolume.value : this.soundVolume,
      parallaxEnabled: data.parallaxEnabled.present
          ? data.parallaxEnabled.value
          : this.parallaxEnabled,
      activeAmbientTrackIndex: data.activeAmbientTrackIndex.present
          ? data.activeAmbientTrackIndex.value
          : this.activeAmbientTrackIndex,
      foleyEnabled: data.foleyEnabled.present
          ? data.foleyEnabled.value
          : this.foleyEnabled,
      hapticsEnabled: data.hapticsEnabled.present
          ? data.hapticsEnabled.value
          : this.hapticsEnabled,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DeskPreference(')
          ..write('id: $id, ')
          ..write('soundVolume: $soundVolume, ')
          ..write('parallaxEnabled: $parallaxEnabled, ')
          ..write('activeAmbientTrackIndex: $activeAmbientTrackIndex, ')
          ..write('foleyEnabled: $foleyEnabled, ')
          ..write('hapticsEnabled: $hapticsEnabled')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, soundVolume, parallaxEnabled,
      activeAmbientTrackIndex, foleyEnabled, hapticsEnabled);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DeskPreference &&
          other.id == this.id &&
          other.soundVolume == this.soundVolume &&
          other.parallaxEnabled == this.parallaxEnabled &&
          other.activeAmbientTrackIndex == this.activeAmbientTrackIndex &&
          other.foleyEnabled == this.foleyEnabled &&
          other.hapticsEnabled == this.hapticsEnabled);
}

class DeskPreferencesCompanion extends UpdateCompanion<DeskPreference> {
  final Value<int> id;
  final Value<double> soundVolume;
  final Value<bool> parallaxEnabled;
  final Value<int> activeAmbientTrackIndex;
  final Value<bool> foleyEnabled;
  final Value<bool> hapticsEnabled;
  const DeskPreferencesCompanion({
    this.id = const Value.absent(),
    this.soundVolume = const Value.absent(),
    this.parallaxEnabled = const Value.absent(),
    this.activeAmbientTrackIndex = const Value.absent(),
    this.foleyEnabled = const Value.absent(),
    this.hapticsEnabled = const Value.absent(),
  });
  DeskPreferencesCompanion.insert({
    this.id = const Value.absent(),
    this.soundVolume = const Value.absent(),
    this.parallaxEnabled = const Value.absent(),
    this.activeAmbientTrackIndex = const Value.absent(),
    this.foleyEnabled = const Value.absent(),
    this.hapticsEnabled = const Value.absent(),
  });
  static Insertable<DeskPreference> custom({
    Expression<int>? id,
    Expression<double>? soundVolume,
    Expression<bool>? parallaxEnabled,
    Expression<int>? activeAmbientTrackIndex,
    Expression<bool>? foleyEnabled,
    Expression<bool>? hapticsEnabled,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (soundVolume != null) 'sound_volume': soundVolume,
      if (parallaxEnabled != null) 'parallax_enabled': parallaxEnabled,
      if (activeAmbientTrackIndex != null)
        'active_ambient_track_index': activeAmbientTrackIndex,
      if (foleyEnabled != null) 'foley_enabled': foleyEnabled,
      if (hapticsEnabled != null) 'haptics_enabled': hapticsEnabled,
    });
  }

  DeskPreferencesCompanion copyWith(
      {Value<int>? id,
      Value<double>? soundVolume,
      Value<bool>? parallaxEnabled,
      Value<int>? activeAmbientTrackIndex,
      Value<bool>? foleyEnabled,
      Value<bool>? hapticsEnabled}) {
    return DeskPreferencesCompanion(
      id: id ?? this.id,
      soundVolume: soundVolume ?? this.soundVolume,
      parallaxEnabled: parallaxEnabled ?? this.parallaxEnabled,
      activeAmbientTrackIndex:
          activeAmbientTrackIndex ?? this.activeAmbientTrackIndex,
      foleyEnabled: foleyEnabled ?? this.foleyEnabled,
      hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (soundVolume.present) {
      map['sound_volume'] = Variable<double>(soundVolume.value);
    }
    if (parallaxEnabled.present) {
      map['parallax_enabled'] = Variable<bool>(parallaxEnabled.value);
    }
    if (activeAmbientTrackIndex.present) {
      map['active_ambient_track_index'] =
          Variable<int>(activeAmbientTrackIndex.value);
    }
    if (foleyEnabled.present) {
      map['foley_enabled'] = Variable<bool>(foleyEnabled.value);
    }
    if (hapticsEnabled.present) {
      map['haptics_enabled'] = Variable<bool>(hapticsEnabled.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DeskPreferencesCompanion(')
          ..write('id: $id, ')
          ..write('soundVolume: $soundVolume, ')
          ..write('parallaxEnabled: $parallaxEnabled, ')
          ..write('activeAmbientTrackIndex: $activeAmbientTrackIndex, ')
          ..write('foleyEnabled: $foleyEnabled, ')
          ..write('hapticsEnabled: $hapticsEnabled')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $TasksTable tasks = $TasksTable(this);
  late final $TimerSessionsTable timerSessions = $TimerSessionsTable(this);
  late final $DeskPreferencesTable deskPreferences =
      $DeskPreferencesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities =>
      [tasks, timerSessions, deskPreferences];
}

typedef $$TasksTableCreateCompanionBuilder = TasksCompanion Function({
  Value<int> id,
  required String title,
  Value<bool> isCompleted,
  Value<bool> isArchived,
  Value<int> sortOrder,
  Value<DateTime> createdAt,
  Value<DateTime?> completedAt,
});
typedef $$TasksTableUpdateCompanionBuilder = TasksCompanion Function({
  Value<int> id,
  Value<String> title,
  Value<bool> isCompleted,
  Value<bool> isArchived,
  Value<int> sortOrder,
  Value<DateTime> createdAt,
  Value<DateTime?> completedAt,
});

class $$TasksTableFilterComposer extends Composer<_$AppDatabase, $TasksTable> {
  $$TasksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isCompleted => $composableBuilder(
      column: $table.isCompleted, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isArchived => $composableBuilder(
      column: $table.isArchived, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get sortOrder => $composableBuilder(
      column: $table.sortOrder, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get completedAt => $composableBuilder(
      column: $table.completedAt, builder: (column) => ColumnFilters(column));
}

class $$TasksTableOrderingComposer
    extends Composer<_$AppDatabase, $TasksTable> {
  $$TasksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isCompleted => $composableBuilder(
      column: $table.isCompleted, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isArchived => $composableBuilder(
      column: $table.isArchived, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get sortOrder => $composableBuilder(
      column: $table.sortOrder, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get completedAt => $composableBuilder(
      column: $table.completedAt, builder: (column) => ColumnOrderings(column));
}

class $$TasksTableAnnotationComposer
    extends Composer<_$AppDatabase, $TasksTable> {
  $$TasksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<bool> get isCompleted => $composableBuilder(
      column: $table.isCompleted, builder: (column) => column);

  GeneratedColumn<bool> get isArchived => $composableBuilder(
      column: $table.isArchived, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get completedAt => $composableBuilder(
      column: $table.completedAt, builder: (column) => column);
}

class $$TasksTableTableManager extends RootTableManager<
    _$AppDatabase,
    $TasksTable,
    Task,
    $$TasksTableFilterComposer,
    $$TasksTableOrderingComposer,
    $$TasksTableAnnotationComposer,
    $$TasksTableCreateCompanionBuilder,
    $$TasksTableUpdateCompanionBuilder,
    (Task, BaseReferences<_$AppDatabase, $TasksTable, Task>),
    Task,
    PrefetchHooks Function()> {
  $$TasksTableTableManager(_$AppDatabase db, $TasksTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TasksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TasksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TasksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<bool> isCompleted = const Value.absent(),
            Value<bool> isArchived = const Value.absent(),
            Value<int> sortOrder = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime?> completedAt = const Value.absent(),
          }) =>
              TasksCompanion(
            id: id,
            title: title,
            isCompleted: isCompleted,
            isArchived: isArchived,
            sortOrder: sortOrder,
            createdAt: createdAt,
            completedAt: completedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String title,
            Value<bool> isCompleted = const Value.absent(),
            Value<bool> isArchived = const Value.absent(),
            Value<int> sortOrder = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime?> completedAt = const Value.absent(),
          }) =>
              TasksCompanion.insert(
            id: id,
            title: title,
            isCompleted: isCompleted,
            isArchived: isArchived,
            sortOrder: sortOrder,
            createdAt: createdAt,
            completedAt: completedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$TasksTable, Task>(table),
                    BaseReferences<_$AppDatabase, $TasksTable, Task>(
                        db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$TasksTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $TasksTable,
    Task,
    $$TasksTableFilterComposer,
    $$TasksTableOrderingComposer,
    $$TasksTableAnnotationComposer,
    $$TasksTableCreateCompanionBuilder,
    $$TasksTableUpdateCompanionBuilder,
    (Task, BaseReferences<_$AppDatabase, $TasksTable, Task>),
    Task,
    PrefetchHooks Function()>;
typedef $$TimerSessionsTableCreateCompanionBuilder = TimerSessionsCompanion
    Function({
  Value<int> id,
  required int targetMinutes,
  required int elapsedSeconds,
  Value<bool> isFinished,
  Value<DateTime> startedAt,
  Value<DateTime?> finishedAt,
});
typedef $$TimerSessionsTableUpdateCompanionBuilder = TimerSessionsCompanion
    Function({
  Value<int> id,
  Value<int> targetMinutes,
  Value<int> elapsedSeconds,
  Value<bool> isFinished,
  Value<DateTime> startedAt,
  Value<DateTime?> finishedAt,
});

class $$TimerSessionsTableFilterComposer
    extends Composer<_$AppDatabase, $TimerSessionsTable> {
  $$TimerSessionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get targetMinutes => $composableBuilder(
      column: $table.targetMinutes, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get elapsedSeconds => $composableBuilder(
      column: $table.elapsedSeconds,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isFinished => $composableBuilder(
      column: $table.isFinished, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get startedAt => $composableBuilder(
      column: $table.startedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get finishedAt => $composableBuilder(
      column: $table.finishedAt, builder: (column) => ColumnFilters(column));
}

class $$TimerSessionsTableOrderingComposer
    extends Composer<_$AppDatabase, $TimerSessionsTable> {
  $$TimerSessionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get targetMinutes => $composableBuilder(
      column: $table.targetMinutes,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get elapsedSeconds => $composableBuilder(
      column: $table.elapsedSeconds,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isFinished => $composableBuilder(
      column: $table.isFinished, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get startedAt => $composableBuilder(
      column: $table.startedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get finishedAt => $composableBuilder(
      column: $table.finishedAt, builder: (column) => ColumnOrderings(column));
}

class $$TimerSessionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TimerSessionsTable> {
  $$TimerSessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get targetMinutes => $composableBuilder(
      column: $table.targetMinutes, builder: (column) => column);

  GeneratedColumn<int> get elapsedSeconds => $composableBuilder(
      column: $table.elapsedSeconds, builder: (column) => column);

  GeneratedColumn<bool> get isFinished => $composableBuilder(
      column: $table.isFinished, builder: (column) => column);

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get finishedAt => $composableBuilder(
      column: $table.finishedAt, builder: (column) => column);
}

class $$TimerSessionsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $TimerSessionsTable,
    TimerSession,
    $$TimerSessionsTableFilterComposer,
    $$TimerSessionsTableOrderingComposer,
    $$TimerSessionsTableAnnotationComposer,
    $$TimerSessionsTableCreateCompanionBuilder,
    $$TimerSessionsTableUpdateCompanionBuilder,
    (
      TimerSession,
      BaseReferences<_$AppDatabase, $TimerSessionsTable, TimerSession>
    ),
    TimerSession,
    PrefetchHooks Function()> {
  $$TimerSessionsTableTableManager(_$AppDatabase db, $TimerSessionsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TimerSessionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TimerSessionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TimerSessionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> targetMinutes = const Value.absent(),
            Value<int> elapsedSeconds = const Value.absent(),
            Value<bool> isFinished = const Value.absent(),
            Value<DateTime> startedAt = const Value.absent(),
            Value<DateTime?> finishedAt = const Value.absent(),
          }) =>
              TimerSessionsCompanion(
            id: id,
            targetMinutes: targetMinutes,
            elapsedSeconds: elapsedSeconds,
            isFinished: isFinished,
            startedAt: startedAt,
            finishedAt: finishedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int targetMinutes,
            required int elapsedSeconds,
            Value<bool> isFinished = const Value.absent(),
            Value<DateTime> startedAt = const Value.absent(),
            Value<DateTime?> finishedAt = const Value.absent(),
          }) =>
              TimerSessionsCompanion.insert(
            id: id,
            targetMinutes: targetMinutes,
            elapsedSeconds: elapsedSeconds,
            isFinished: isFinished,
            startedAt: startedAt,
            finishedAt: finishedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$TimerSessionsTable, TimerSession>(table),
                    BaseReferences<_$AppDatabase, $TimerSessionsTable,
                        TimerSession>(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$TimerSessionsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $TimerSessionsTable,
    TimerSession,
    $$TimerSessionsTableFilterComposer,
    $$TimerSessionsTableOrderingComposer,
    $$TimerSessionsTableAnnotationComposer,
    $$TimerSessionsTableCreateCompanionBuilder,
    $$TimerSessionsTableUpdateCompanionBuilder,
    (
      TimerSession,
      BaseReferences<_$AppDatabase, $TimerSessionsTable, TimerSession>
    ),
    TimerSession,
    PrefetchHooks Function()>;
typedef $$DeskPreferencesTableCreateCompanionBuilder = DeskPreferencesCompanion
    Function({
  Value<int> id,
  Value<double> soundVolume,
  Value<bool> parallaxEnabled,
  Value<int> activeAmbientTrackIndex,
  Value<bool> foleyEnabled,
  Value<bool> hapticsEnabled,
});
typedef $$DeskPreferencesTableUpdateCompanionBuilder = DeskPreferencesCompanion
    Function({
  Value<int> id,
  Value<double> soundVolume,
  Value<bool> parallaxEnabled,
  Value<int> activeAmbientTrackIndex,
  Value<bool> foleyEnabled,
  Value<bool> hapticsEnabled,
});

class $$DeskPreferencesTableFilterComposer
    extends Composer<_$AppDatabase, $DeskPreferencesTable> {
  $$DeskPreferencesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get soundVolume => $composableBuilder(
      column: $table.soundVolume, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get parallaxEnabled => $composableBuilder(
      column: $table.parallaxEnabled,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get activeAmbientTrackIndex => $composableBuilder(
      column: $table.activeAmbientTrackIndex,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get foleyEnabled => $composableBuilder(
      column: $table.foleyEnabled, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get hapticsEnabled => $composableBuilder(
      column: $table.hapticsEnabled,
      builder: (column) => ColumnFilters(column));
}

class $$DeskPreferencesTableOrderingComposer
    extends Composer<_$AppDatabase, $DeskPreferencesTable> {
  $$DeskPreferencesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get soundVolume => $composableBuilder(
      column: $table.soundVolume, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get parallaxEnabled => $composableBuilder(
      column: $table.parallaxEnabled,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get activeAmbientTrackIndex => $composableBuilder(
      column: $table.activeAmbientTrackIndex,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get foleyEnabled => $composableBuilder(
      column: $table.foleyEnabled,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get hapticsEnabled => $composableBuilder(
      column: $table.hapticsEnabled,
      builder: (column) => ColumnOrderings(column));
}

class $$DeskPreferencesTableAnnotationComposer
    extends Composer<_$AppDatabase, $DeskPreferencesTable> {
  $$DeskPreferencesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<double> get soundVolume => $composableBuilder(
      column: $table.soundVolume, builder: (column) => column);

  GeneratedColumn<bool> get parallaxEnabled => $composableBuilder(
      column: $table.parallaxEnabled, builder: (column) => column);

  GeneratedColumn<int> get activeAmbientTrackIndex => $composableBuilder(
      column: $table.activeAmbientTrackIndex, builder: (column) => column);

  GeneratedColumn<bool> get foleyEnabled => $composableBuilder(
      column: $table.foleyEnabled, builder: (column) => column);

  GeneratedColumn<bool> get hapticsEnabled => $composableBuilder(
      column: $table.hapticsEnabled, builder: (column) => column);
}

class $$DeskPreferencesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $DeskPreferencesTable,
    DeskPreference,
    $$DeskPreferencesTableFilterComposer,
    $$DeskPreferencesTableOrderingComposer,
    $$DeskPreferencesTableAnnotationComposer,
    $$DeskPreferencesTableCreateCompanionBuilder,
    $$DeskPreferencesTableUpdateCompanionBuilder,
    (
      DeskPreference,
      BaseReferences<_$AppDatabase, $DeskPreferencesTable, DeskPreference>
    ),
    DeskPreference,
    PrefetchHooks Function()> {
  $$DeskPreferencesTableTableManager(
      _$AppDatabase db, $DeskPreferencesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DeskPreferencesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DeskPreferencesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DeskPreferencesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<double> soundVolume = const Value.absent(),
            Value<bool> parallaxEnabled = const Value.absent(),
            Value<int> activeAmbientTrackIndex = const Value.absent(),
            Value<bool> foleyEnabled = const Value.absent(),
            Value<bool> hapticsEnabled = const Value.absent(),
          }) =>
              DeskPreferencesCompanion(
            id: id,
            soundVolume: soundVolume,
            parallaxEnabled: parallaxEnabled,
            activeAmbientTrackIndex: activeAmbientTrackIndex,
            foleyEnabled: foleyEnabled,
            hapticsEnabled: hapticsEnabled,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<double> soundVolume = const Value.absent(),
            Value<bool> parallaxEnabled = const Value.absent(),
            Value<int> activeAmbientTrackIndex = const Value.absent(),
            Value<bool> foleyEnabled = const Value.absent(),
            Value<bool> hapticsEnabled = const Value.absent(),
          }) =>
              DeskPreferencesCompanion.insert(
            id: id,
            soundVolume: soundVolume,
            parallaxEnabled: parallaxEnabled,
            activeAmbientTrackIndex: activeAmbientTrackIndex,
            foleyEnabled: foleyEnabled,
            hapticsEnabled: hapticsEnabled,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$DeskPreferencesTable, DeskPreference>(table),
                    BaseReferences<_$AppDatabase, $DeskPreferencesTable,
                        DeskPreference>(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$DeskPreferencesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $DeskPreferencesTable,
    DeskPreference,
    $$DeskPreferencesTableFilterComposer,
    $$DeskPreferencesTableOrderingComposer,
    $$DeskPreferencesTableAnnotationComposer,
    $$DeskPreferencesTableCreateCompanionBuilder,
    $$DeskPreferencesTableUpdateCompanionBuilder,
    (
      DeskPreference,
      BaseReferences<_$AppDatabase, $DeskPreferencesTable, DeskPreference>
    ),
    DeskPreference,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$TasksTableTableManager get tasks =>
      $$TasksTableTableManager(_db, _db.tasks);
  $$TimerSessionsTableTableManager get timerSessions =>
      $$TimerSessionsTableTableManager(_db, _db.timerSessions);
  $$DeskPreferencesTableTableManager get deskPreferences =>
      $$DeskPreferencesTableTableManager(_db, _db.deskPreferences);
}
