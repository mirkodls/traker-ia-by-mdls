// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $LettureTable extends Letture with TableInfo<$LettureTable, RigaLettura> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LettureTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _oraMeta = const VerificationMeta('ora');
  @override
  late final GeneratedColumn<String> ora = GeneratedColumn<String>(
    'ora',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _settMeta = const VerificationMeta('sett');
  @override
  late final GeneratedColumn<double> sett = GeneratedColumn<double>(
    'sett',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sessMeta = const VerificationMeta('sess');
  @override
  late final GeneratedColumn<double> sess = GeneratedColumn<double>(
    'sess',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fonteMeta = const VerificationMeta('fonte');
  @override
  late final GeneratedColumn<String> fonte = GeneratedColumn<String>(
    'fonte',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant<String>('auto'),
  );
  static const VerificationMeta _alPcMeta = const VerificationMeta('alPc');
  @override
  late final GeneratedColumn<bool> alPc = GeneratedColumn<bool>(
    'al_pc',
    aliasedName,
    true,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("al_pc" IN (0, 1))',
    ),
  );
  static const VerificationMeta _lavoroMeta = const VerificationMeta('lavoro');
  @override
  late final GeneratedColumn<bool> lavoro = GeneratedColumn<bool>(
    'lavoro',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("lavoro" IN (0, 1))',
    ),
    defaultValue: const Constant<bool>(false),
  );
  static const VerificationMeta _modelliMeta = const VerificationMeta(
    'modelli',
  );
  @override
  late final GeneratedColumn<String> modelli = GeneratedColumn<String>(
    'modelli',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant<String>(''),
  );
  static const VerificationMeta _skillMeta = const VerificationMeta('skill');
  @override
  late final GeneratedColumn<String> skill = GeneratedColumn<String>(
    'skill',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant<String>(''),
  );
  static const VerificationMeta _gestoreMeta = const VerificationMeta(
    'gestore',
  );
  @override
  late final GeneratedColumn<String> gestore = GeneratedColumn<String>(
    'gestore',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    ora,
    sett,
    sess,
    fonte,
    alPc,
    lavoro,
    modelli,
    skill,
    gestore,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'letture';
  @override
  VerificationContext validateIntegrity(
    Insertable<RigaLettura> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('ora')) {
      context.handle(
        _oraMeta,
        ora.isAcceptableOrUnknown(data['ora']!, _oraMeta),
      );
    } else if (isInserting) {
      context.missing(_oraMeta);
    }
    if (data.containsKey('sett')) {
      context.handle(
        _settMeta,
        sett.isAcceptableOrUnknown(data['sett']!, _settMeta),
      );
    }
    if (data.containsKey('sess')) {
      context.handle(
        _sessMeta,
        sess.isAcceptableOrUnknown(data['sess']!, _sessMeta),
      );
    }
    if (data.containsKey('fonte')) {
      context.handle(
        _fonteMeta,
        fonte.isAcceptableOrUnknown(data['fonte']!, _fonteMeta),
      );
    }
    if (data.containsKey('al_pc')) {
      context.handle(
        _alPcMeta,
        alPc.isAcceptableOrUnknown(data['al_pc']!, _alPcMeta),
      );
    }
    if (data.containsKey('lavoro')) {
      context.handle(
        _lavoroMeta,
        lavoro.isAcceptableOrUnknown(data['lavoro']!, _lavoroMeta),
      );
    }
    if (data.containsKey('modelli')) {
      context.handle(
        _modelliMeta,
        modelli.isAcceptableOrUnknown(data['modelli']!, _modelliMeta),
      );
    }
    if (data.containsKey('skill')) {
      context.handle(
        _skillMeta,
        skill.isAcceptableOrUnknown(data['skill']!, _skillMeta),
      );
    }
    if (data.containsKey('gestore')) {
      context.handle(
        _gestoreMeta,
        gestore.isAcceptableOrUnknown(data['gestore']!, _gestoreMeta),
      );
    } else if (isInserting) {
      context.missing(_gestoreMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RigaLettura map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RigaLettura(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      ora: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ora'],
      )!,
      sett: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}sett'],
      ),
      sess: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}sess'],
      ),
      fonte: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}fonte'],
      )!,
      alPc: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}al_pc'],
      ),
      lavoro: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}lavoro'],
      )!,
      modelli: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}modelli'],
      )!,
      skill: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}skill'],
      )!,
      gestore: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}gestore'],
      )!,
    );
  }

  @override
  $LettureTable createAlias(String alias) {
    return $LettureTable(attachedDatabase, alias);
  }
}

class RigaLettura extends DataClass implements Insertable<RigaLettura> {
  /// Id automatico (ordine di arrivo).
  final int id;

  /// Ora 'aaaa-mm-gg hh:mm', ora locale (stesso formato dei CSV).
  final String ora;

  /// % settimanale.
  final double? sett;

  /// % sessione 5 ore.
  final double? sess;

  /// Origine: auto | manuale | iniziale.
  final String fonte;

  /// Input tastiera/mouse nell'intervallo (null = non noto).
  final bool? alPc;

  /// Periodo di lavoro attivo.
  final bool lavoro;

  /// Modelli accesi, separati da '|'.
  final String modelli;

  /// Skill accese, separate da '|'.
  final String skill;

  /// Gestore IA (es. 'anthropic').
  final String gestore;
  const RigaLettura({
    required this.id,
    required this.ora,
    this.sett,
    this.sess,
    required this.fonte,
    this.alPc,
    required this.lavoro,
    required this.modelli,
    required this.skill,
    required this.gestore,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['ora'] = Variable<String>(ora);
    if (!nullToAbsent || sett != null) {
      map['sett'] = Variable<double>(sett);
    }
    if (!nullToAbsent || sess != null) {
      map['sess'] = Variable<double>(sess);
    }
    map['fonte'] = Variable<String>(fonte);
    if (!nullToAbsent || alPc != null) {
      map['al_pc'] = Variable<bool>(alPc);
    }
    map['lavoro'] = Variable<bool>(lavoro);
    map['modelli'] = Variable<String>(modelli);
    map['skill'] = Variable<String>(skill);
    map['gestore'] = Variable<String>(gestore);
    return map;
  }

  LettureCompanion toCompanion(bool nullToAbsent) {
    return LettureCompanion(
      id: Value(id),
      ora: Value(ora),
      sett: sett == null && nullToAbsent ? const Value.absent() : Value(sett),
      sess: sess == null && nullToAbsent ? const Value.absent() : Value(sess),
      fonte: Value(fonte),
      alPc: alPc == null && nullToAbsent ? const Value.absent() : Value(alPc),
      lavoro: Value(lavoro),
      modelli: Value(modelli),
      skill: Value(skill),
      gestore: Value(gestore),
    );
  }

  factory RigaLettura.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RigaLettura(
      id: serializer.fromJson<int>(json['id']),
      ora: serializer.fromJson<String>(json['ora']),
      sett: serializer.fromJson<double?>(json['sett']),
      sess: serializer.fromJson<double?>(json['sess']),
      fonte: serializer.fromJson<String>(json['fonte']),
      alPc: serializer.fromJson<bool?>(json['alPc']),
      lavoro: serializer.fromJson<bool>(json['lavoro']),
      modelli: serializer.fromJson<String>(json['modelli']),
      skill: serializer.fromJson<String>(json['skill']),
      gestore: serializer.fromJson<String>(json['gestore']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'ora': serializer.toJson<String>(ora),
      'sett': serializer.toJson<double?>(sett),
      'sess': serializer.toJson<double?>(sess),
      'fonte': serializer.toJson<String>(fonte),
      'alPc': serializer.toJson<bool?>(alPc),
      'lavoro': serializer.toJson<bool>(lavoro),
      'modelli': serializer.toJson<String>(modelli),
      'skill': serializer.toJson<String>(skill),
      'gestore': serializer.toJson<String>(gestore),
    };
  }

  RigaLettura copyWith({
    int? id,
    String? ora,
    Value<double?> sett = const Value.absent(),
    Value<double?> sess = const Value.absent(),
    String? fonte,
    Value<bool?> alPc = const Value.absent(),
    bool? lavoro,
    String? modelli,
    String? skill,
    String? gestore,
  }) => RigaLettura(
    id: id ?? this.id,
    ora: ora ?? this.ora,
    sett: sett.present ? sett.value : this.sett,
    sess: sess.present ? sess.value : this.sess,
    fonte: fonte ?? this.fonte,
    alPc: alPc.present ? alPc.value : this.alPc,
    lavoro: lavoro ?? this.lavoro,
    modelli: modelli ?? this.modelli,
    skill: skill ?? this.skill,
    gestore: gestore ?? this.gestore,
  );
  RigaLettura copyWithCompanion(LettureCompanion data) {
    return RigaLettura(
      id: data.id.present ? data.id.value : this.id,
      ora: data.ora.present ? data.ora.value : this.ora,
      sett: data.sett.present ? data.sett.value : this.sett,
      sess: data.sess.present ? data.sess.value : this.sess,
      fonte: data.fonte.present ? data.fonte.value : this.fonte,
      alPc: data.alPc.present ? data.alPc.value : this.alPc,
      lavoro: data.lavoro.present ? data.lavoro.value : this.lavoro,
      modelli: data.modelli.present ? data.modelli.value : this.modelli,
      skill: data.skill.present ? data.skill.value : this.skill,
      gestore: data.gestore.present ? data.gestore.value : this.gestore,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RigaLettura(')
          ..write('id: $id, ')
          ..write('ora: $ora, ')
          ..write('sett: $sett, ')
          ..write('sess: $sess, ')
          ..write('fonte: $fonte, ')
          ..write('alPc: $alPc, ')
          ..write('lavoro: $lavoro, ')
          ..write('modelli: $modelli, ')
          ..write('skill: $skill, ')
          ..write('gestore: $gestore')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    ora,
    sett,
    sess,
    fonte,
    alPc,
    lavoro,
    modelli,
    skill,
    gestore,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RigaLettura &&
          other.id == this.id &&
          other.ora == this.ora &&
          other.sett == this.sett &&
          other.sess == this.sess &&
          other.fonte == this.fonte &&
          other.alPc == this.alPc &&
          other.lavoro == this.lavoro &&
          other.modelli == this.modelli &&
          other.skill == this.skill &&
          other.gestore == this.gestore);
}

class LettureCompanion extends UpdateCompanion<RigaLettura> {
  final Value<int> id;
  final Value<String> ora;
  final Value<double?> sett;
  final Value<double?> sess;
  final Value<String> fonte;
  final Value<bool?> alPc;
  final Value<bool> lavoro;
  final Value<String> modelli;
  final Value<String> skill;
  final Value<String> gestore;
  const LettureCompanion({
    this.id = const Value.absent(),
    this.ora = const Value.absent(),
    this.sett = const Value.absent(),
    this.sess = const Value.absent(),
    this.fonte = const Value.absent(),
    this.alPc = const Value.absent(),
    this.lavoro = const Value.absent(),
    this.modelli = const Value.absent(),
    this.skill = const Value.absent(),
    this.gestore = const Value.absent(),
  });
  LettureCompanion.insert({
    this.id = const Value.absent(),
    required String ora,
    this.sett = const Value.absent(),
    this.sess = const Value.absent(),
    this.fonte = const Value.absent(),
    this.alPc = const Value.absent(),
    this.lavoro = const Value.absent(),
    this.modelli = const Value.absent(),
    this.skill = const Value.absent(),
    required String gestore,
  }) : ora = Value(ora),
       gestore = Value(gestore);
  static Insertable<RigaLettura> custom({
    Expression<int>? id,
    Expression<String>? ora,
    Expression<double>? sett,
    Expression<double>? sess,
    Expression<String>? fonte,
    Expression<bool>? alPc,
    Expression<bool>? lavoro,
    Expression<String>? modelli,
    Expression<String>? skill,
    Expression<String>? gestore,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (ora != null) 'ora': ora,
      if (sett != null) 'sett': sett,
      if (sess != null) 'sess': sess,
      if (fonte != null) 'fonte': fonte,
      if (alPc != null) 'al_pc': alPc,
      if (lavoro != null) 'lavoro': lavoro,
      if (modelli != null) 'modelli': modelli,
      if (skill != null) 'skill': skill,
      if (gestore != null) 'gestore': gestore,
    });
  }

  LettureCompanion copyWith({
    Value<int>? id,
    Value<String>? ora,
    Value<double?>? sett,
    Value<double?>? sess,
    Value<String>? fonte,
    Value<bool?>? alPc,
    Value<bool>? lavoro,
    Value<String>? modelli,
    Value<String>? skill,
    Value<String>? gestore,
  }) {
    return LettureCompanion(
      id: id ?? this.id,
      ora: ora ?? this.ora,
      sett: sett ?? this.sett,
      sess: sess ?? this.sess,
      fonte: fonte ?? this.fonte,
      alPc: alPc ?? this.alPc,
      lavoro: lavoro ?? this.lavoro,
      modelli: modelli ?? this.modelli,
      skill: skill ?? this.skill,
      gestore: gestore ?? this.gestore,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (ora.present) {
      map['ora'] = Variable<String>(ora.value);
    }
    if (sett.present) {
      map['sett'] = Variable<double>(sett.value);
    }
    if (sess.present) {
      map['sess'] = Variable<double>(sess.value);
    }
    if (fonte.present) {
      map['fonte'] = Variable<String>(fonte.value);
    }
    if (alPc.present) {
      map['al_pc'] = Variable<bool>(alPc.value);
    }
    if (lavoro.present) {
      map['lavoro'] = Variable<bool>(lavoro.value);
    }
    if (modelli.present) {
      map['modelli'] = Variable<String>(modelli.value);
    }
    if (skill.present) {
      map['skill'] = Variable<String>(skill.value);
    }
    if (gestore.present) {
      map['gestore'] = Variable<String>(gestore.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LettureCompanion(')
          ..write('id: $id, ')
          ..write('ora: $ora, ')
          ..write('sett: $sett, ')
          ..write('sess: $sess, ')
          ..write('fonte: $fonte, ')
          ..write('alPc: $alPc, ')
          ..write('lavoro: $lavoro, ')
          ..write('modelli: $modelli, ')
          ..write('skill: $skill, ')
          ..write('gestore: $gestore')
          ..write(')'))
        .toString();
  }
}

class $EventiTable extends Eventi with TableInfo<$EventiTable, RigaEvento> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EventiTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _oraMeta = const VerificationMeta('ora');
  @override
  late final GeneratedColumn<String> ora = GeneratedColumn<String>(
    'ora',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tipoMeta = const VerificationMeta('tipo');
  @override
  late final GeneratedColumn<String> tipo = GeneratedColumn<String>(
    'tipo',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _testoMeta = const VerificationMeta('testo');
  @override
  late final GeneratedColumn<String> testo = GeneratedColumn<String>(
    'testo',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant<String>(''),
  );
  @override
  List<GeneratedColumn> get $columns => [id, ora, tipo, testo];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'eventi';
  @override
  VerificationContext validateIntegrity(
    Insertable<RigaEvento> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('ora')) {
      context.handle(
        _oraMeta,
        ora.isAcceptableOrUnknown(data['ora']!, _oraMeta),
      );
    } else if (isInserting) {
      context.missing(_oraMeta);
    }
    if (data.containsKey('tipo')) {
      context.handle(
        _tipoMeta,
        tipo.isAcceptableOrUnknown(data['tipo']!, _tipoMeta),
      );
    } else if (isInserting) {
      context.missing(_tipoMeta);
    }
    if (data.containsKey('testo')) {
      context.handle(
        _testoMeta,
        testo.isAcceptableOrUnknown(data['testo']!, _testoMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RigaEvento map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RigaEvento(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      ora: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ora'],
      )!,
      tipo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tipo'],
      )!,
      testo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}testo'],
      )!,
    );
  }

  @override
  $EventiTable createAlias(String alias) {
    return $EventiTable(attachedDatabase, alias);
  }
}

class RigaEvento extends DataClass implements Insertable<RigaEvento> {
  /// Id automatico (ordine di arrivo).
  final int id;

  /// Ora 'aaaa-mm-gg hh:mm', ora locale.
  final String ora;

  /// Tipo: nota | inizio | fine | reset.
  final String tipo;

  /// Testo libero.
  final String testo;
  const RigaEvento({
    required this.id,
    required this.ora,
    required this.tipo,
    required this.testo,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['ora'] = Variable<String>(ora);
    map['tipo'] = Variable<String>(tipo);
    map['testo'] = Variable<String>(testo);
    return map;
  }

  EventiCompanion toCompanion(bool nullToAbsent) {
    return EventiCompanion(
      id: Value(id),
      ora: Value(ora),
      tipo: Value(tipo),
      testo: Value(testo),
    );
  }

  factory RigaEvento.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RigaEvento(
      id: serializer.fromJson<int>(json['id']),
      ora: serializer.fromJson<String>(json['ora']),
      tipo: serializer.fromJson<String>(json['tipo']),
      testo: serializer.fromJson<String>(json['testo']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'ora': serializer.toJson<String>(ora),
      'tipo': serializer.toJson<String>(tipo),
      'testo': serializer.toJson<String>(testo),
    };
  }

  RigaEvento copyWith({int? id, String? ora, String? tipo, String? testo}) =>
      RigaEvento(
        id: id ?? this.id,
        ora: ora ?? this.ora,
        tipo: tipo ?? this.tipo,
        testo: testo ?? this.testo,
      );
  RigaEvento copyWithCompanion(EventiCompanion data) {
    return RigaEvento(
      id: data.id.present ? data.id.value : this.id,
      ora: data.ora.present ? data.ora.value : this.ora,
      tipo: data.tipo.present ? data.tipo.value : this.tipo,
      testo: data.testo.present ? data.testo.value : this.testo,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RigaEvento(')
          ..write('id: $id, ')
          ..write('ora: $ora, ')
          ..write('tipo: $tipo, ')
          ..write('testo: $testo')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, ora, tipo, testo);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RigaEvento &&
          other.id == this.id &&
          other.ora == this.ora &&
          other.tipo == this.tipo &&
          other.testo == this.testo);
}

class EventiCompanion extends UpdateCompanion<RigaEvento> {
  final Value<int> id;
  final Value<String> ora;
  final Value<String> tipo;
  final Value<String> testo;
  const EventiCompanion({
    this.id = const Value.absent(),
    this.ora = const Value.absent(),
    this.tipo = const Value.absent(),
    this.testo = const Value.absent(),
  });
  EventiCompanion.insert({
    this.id = const Value.absent(),
    required String ora,
    required String tipo,
    this.testo = const Value.absent(),
  }) : ora = Value(ora),
       tipo = Value(tipo);
  static Insertable<RigaEvento> custom({
    Expression<int>? id,
    Expression<String>? ora,
    Expression<String>? tipo,
    Expression<String>? testo,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (ora != null) 'ora': ora,
      if (tipo != null) 'tipo': tipo,
      if (testo != null) 'testo': testo,
    });
  }

  EventiCompanion copyWith({
    Value<int>? id,
    Value<String>? ora,
    Value<String>? tipo,
    Value<String>? testo,
  }) {
    return EventiCompanion(
      id: id ?? this.id,
      ora: ora ?? this.ora,
      tipo: tipo ?? this.tipo,
      testo: testo ?? this.testo,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (ora.present) {
      map['ora'] = Variable<String>(ora.value);
    }
    if (tipo.present) {
      map['tipo'] = Variable<String>(tipo.value);
    }
    if (testo.present) {
      map['testo'] = Variable<String>(testo.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EventiCompanion(')
          ..write('id: $id, ')
          ..write('ora: $ora, ')
          ..write('tipo: $tipo, ')
          ..write('testo: $testo')
          ..write(')'))
        .toString();
  }
}

class $ImpostazioniTable extends Impostazioni
    with TableInfo<$ImpostazioniTable, RigaImpostazione> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ImpostazioniTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _chiaveMeta = const VerificationMeta('chiave');
  @override
  late final GeneratedColumn<String> chiave = GeneratedColumn<String>(
    'chiave',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valoreMeta = const VerificationMeta('valore');
  @override
  late final GeneratedColumn<String> valore = GeneratedColumn<String>(
    'valore',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [chiave, valore];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'impostazioni';
  @override
  VerificationContext validateIntegrity(
    Insertable<RigaImpostazione> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('chiave')) {
      context.handle(
        _chiaveMeta,
        chiave.isAcceptableOrUnknown(data['chiave']!, _chiaveMeta),
      );
    } else if (isInserting) {
      context.missing(_chiaveMeta);
    }
    if (data.containsKey('valore')) {
      context.handle(
        _valoreMeta,
        valore.isAcceptableOrUnknown(data['valore']!, _valoreMeta),
      );
    } else if (isInserting) {
      context.missing(_valoreMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {chiave};
  @override
  RigaImpostazione map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RigaImpostazione(
      chiave: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}chiave'],
      )!,
      valore: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}valore'],
      )!,
    );
  }

  @override
  $ImpostazioniTable createAlias(String alias) {
    return $ImpostazioniTable(attachedDatabase, alias);
  }
}

class RigaImpostazione extends DataClass
    implements Insertable<RigaImpostazione> {
  /// Nome dell'impostazione.
  final String chiave;

  /// Valore (testo o JSON).
  final String valore;
  const RigaImpostazione({required this.chiave, required this.valore});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['chiave'] = Variable<String>(chiave);
    map['valore'] = Variable<String>(valore);
    return map;
  }

  ImpostazioniCompanion toCompanion(bool nullToAbsent) {
    return ImpostazioniCompanion(chiave: Value(chiave), valore: Value(valore));
  }

  factory RigaImpostazione.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RigaImpostazione(
      chiave: serializer.fromJson<String>(json['chiave']),
      valore: serializer.fromJson<String>(json['valore']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'chiave': serializer.toJson<String>(chiave),
      'valore': serializer.toJson<String>(valore),
    };
  }

  RigaImpostazione copyWith({String? chiave, String? valore}) =>
      RigaImpostazione(
        chiave: chiave ?? this.chiave,
        valore: valore ?? this.valore,
      );
  RigaImpostazione copyWithCompanion(ImpostazioniCompanion data) {
    return RigaImpostazione(
      chiave: data.chiave.present ? data.chiave.value : this.chiave,
      valore: data.valore.present ? data.valore.value : this.valore,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RigaImpostazione(')
          ..write('chiave: $chiave, ')
          ..write('valore: $valore')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(chiave, valore);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RigaImpostazione &&
          other.chiave == this.chiave &&
          other.valore == this.valore);
}

class ImpostazioniCompanion extends UpdateCompanion<RigaImpostazione> {
  final Value<String> chiave;
  final Value<String> valore;
  final Value<int> rowid;
  const ImpostazioniCompanion({
    this.chiave = const Value.absent(),
    this.valore = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ImpostazioniCompanion.insert({
    required String chiave,
    required String valore,
    this.rowid = const Value.absent(),
  }) : chiave = Value(chiave),
       valore = Value(valore);
  static Insertable<RigaImpostazione> custom({
    Expression<String>? chiave,
    Expression<String>? valore,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (chiave != null) 'chiave': chiave,
      if (valore != null) 'valore': valore,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ImpostazioniCompanion copyWith({
    Value<String>? chiave,
    Value<String>? valore,
    Value<int>? rowid,
  }) {
    return ImpostazioniCompanion(
      chiave: chiave ?? this.chiave,
      valore: valore ?? this.valore,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (chiave.present) {
      map['chiave'] = Variable<String>(chiave.value);
    }
    if (valore.present) {
      map['valore'] = Variable<String>(valore.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ImpostazioniCompanion(')
          ..write('chiave: $chiave, ')
          ..write('valore: $valore, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PianiTable extends Piani with TableInfo<$PianiTable, RigaPiano> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PianiTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nomeMeta = const VerificationMeta('nome');
  @override
  late final GeneratedColumn<String> nome = GeneratedColumn<String>(
    'nome',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _giorniMaskMeta = const VerificationMeta(
    'giorniMask',
  );
  @override
  late final GeneratedColumn<int> giorniMask = GeneratedColumn<int>(
    'giorni_mask',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _targetPctMeta = const VerificationMeta(
    'targetPct',
  );
  @override
  late final GeneratedColumn<double> targetPct = GeneratedColumn<double>(
    'target_pct',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant<double>(99),
  );
  static const VerificationMeta _confineMeta = const VerificationMeta(
    'confine',
  );
  @override
  late final GeneratedColumn<String> confine = GeneratedColumn<String>(
    'confine',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant<String>('reset24h'),
  );
  static const VerificationMeta _inizioMeta = const VerificationMeta('inizio');
  @override
  late final GeneratedColumn<String> inizio = GeneratedColumn<String>(
    'inizio',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fineMeta = const VerificationMeta('fine');
  @override
  late final GeneratedColumn<String> fine = GeneratedColumn<String>(
    'fine',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    nome,
    giorniMask,
    targetPct,
    confine,
    inizio,
    fine,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'piani';
  @override
  VerificationContext validateIntegrity(
    Insertable<RigaPiano> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('nome')) {
      context.handle(
        _nomeMeta,
        nome.isAcceptableOrUnknown(data['nome']!, _nomeMeta),
      );
    } else if (isInserting) {
      context.missing(_nomeMeta);
    }
    if (data.containsKey('giorni_mask')) {
      context.handle(
        _giorniMaskMeta,
        giorniMask.isAcceptableOrUnknown(data['giorni_mask']!, _giorniMaskMeta),
      );
    } else if (isInserting) {
      context.missing(_giorniMaskMeta);
    }
    if (data.containsKey('target_pct')) {
      context.handle(
        _targetPctMeta,
        targetPct.isAcceptableOrUnknown(data['target_pct']!, _targetPctMeta),
      );
    }
    if (data.containsKey('confine')) {
      context.handle(
        _confineMeta,
        confine.isAcceptableOrUnknown(data['confine']!, _confineMeta),
      );
    }
    if (data.containsKey('inizio')) {
      context.handle(
        _inizioMeta,
        inizio.isAcceptableOrUnknown(data['inizio']!, _inizioMeta),
      );
    } else if (isInserting) {
      context.missing(_inizioMeta);
    }
    if (data.containsKey('fine')) {
      context.handle(
        _fineMeta,
        fine.isAcceptableOrUnknown(data['fine']!, _fineMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RigaPiano map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RigaPiano(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      nome: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nome'],
      )!,
      giorniMask: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}giorni_mask'],
      )!,
      targetPct: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}target_pct'],
      )!,
      confine: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}confine'],
      )!,
      inizio: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}inizio'],
      )!,
      fine: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}fine'],
      ),
    );
  }

  @override
  $PianiTable createAlias(String alias) {
    return $PianiTable(attachedDatabase, alias);
  }
}

class RigaPiano extends DataClass implements Insertable<RigaPiano> {
  /// Id automatico.
  final int id;

  /// Nome del piano.
  final String nome;

  /// Giorni di lavoro: bit 0 = lunedì ... bit 6 = domenica.
  final int giorniMask;

  /// % settimanale da raggiungere a fine piano.
  final double targetPct;

  /// Confine del giorno ('reset24h' = 24 h dal reset settimanale).
  final String confine;

  /// Inizio validità 'aaaa-mm-gg hh:mm'.
  final String inizio;

  /// Fine validità 'aaaa-mm-gg hh:mm' (null = ancora valido).
  final String? fine;
  const RigaPiano({
    required this.id,
    required this.nome,
    required this.giorniMask,
    required this.targetPct,
    required this.confine,
    required this.inizio,
    this.fine,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['nome'] = Variable<String>(nome);
    map['giorni_mask'] = Variable<int>(giorniMask);
    map['target_pct'] = Variable<double>(targetPct);
    map['confine'] = Variable<String>(confine);
    map['inizio'] = Variable<String>(inizio);
    if (!nullToAbsent || fine != null) {
      map['fine'] = Variable<String>(fine);
    }
    return map;
  }

  PianiCompanion toCompanion(bool nullToAbsent) {
    return PianiCompanion(
      id: Value(id),
      nome: Value(nome),
      giorniMask: Value(giorniMask),
      targetPct: Value(targetPct),
      confine: Value(confine),
      inizio: Value(inizio),
      fine: fine == null && nullToAbsent ? const Value.absent() : Value(fine),
    );
  }

  factory RigaPiano.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RigaPiano(
      id: serializer.fromJson<int>(json['id']),
      nome: serializer.fromJson<String>(json['nome']),
      giorniMask: serializer.fromJson<int>(json['giorniMask']),
      targetPct: serializer.fromJson<double>(json['targetPct']),
      confine: serializer.fromJson<String>(json['confine']),
      inizio: serializer.fromJson<String>(json['inizio']),
      fine: serializer.fromJson<String?>(json['fine']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'nome': serializer.toJson<String>(nome),
      'giorniMask': serializer.toJson<int>(giorniMask),
      'targetPct': serializer.toJson<double>(targetPct),
      'confine': serializer.toJson<String>(confine),
      'inizio': serializer.toJson<String>(inizio),
      'fine': serializer.toJson<String?>(fine),
    };
  }

  RigaPiano copyWith({
    int? id,
    String? nome,
    int? giorniMask,
    double? targetPct,
    String? confine,
    String? inizio,
    Value<String?> fine = const Value.absent(),
  }) => RigaPiano(
    id: id ?? this.id,
    nome: nome ?? this.nome,
    giorniMask: giorniMask ?? this.giorniMask,
    targetPct: targetPct ?? this.targetPct,
    confine: confine ?? this.confine,
    inizio: inizio ?? this.inizio,
    fine: fine.present ? fine.value : this.fine,
  );
  RigaPiano copyWithCompanion(PianiCompanion data) {
    return RigaPiano(
      id: data.id.present ? data.id.value : this.id,
      nome: data.nome.present ? data.nome.value : this.nome,
      giorniMask: data.giorniMask.present
          ? data.giorniMask.value
          : this.giorniMask,
      targetPct: data.targetPct.present ? data.targetPct.value : this.targetPct,
      confine: data.confine.present ? data.confine.value : this.confine,
      inizio: data.inizio.present ? data.inizio.value : this.inizio,
      fine: data.fine.present ? data.fine.value : this.fine,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RigaPiano(')
          ..write('id: $id, ')
          ..write('nome: $nome, ')
          ..write('giorniMask: $giorniMask, ')
          ..write('targetPct: $targetPct, ')
          ..write('confine: $confine, ')
          ..write('inizio: $inizio, ')
          ..write('fine: $fine')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, nome, giorniMask, targetPct, confine, inizio, fine);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RigaPiano &&
          other.id == this.id &&
          other.nome == this.nome &&
          other.giorniMask == this.giorniMask &&
          other.targetPct == this.targetPct &&
          other.confine == this.confine &&
          other.inizio == this.inizio &&
          other.fine == this.fine);
}

class PianiCompanion extends UpdateCompanion<RigaPiano> {
  final Value<int> id;
  final Value<String> nome;
  final Value<int> giorniMask;
  final Value<double> targetPct;
  final Value<String> confine;
  final Value<String> inizio;
  final Value<String?> fine;
  const PianiCompanion({
    this.id = const Value.absent(),
    this.nome = const Value.absent(),
    this.giorniMask = const Value.absent(),
    this.targetPct = const Value.absent(),
    this.confine = const Value.absent(),
    this.inizio = const Value.absent(),
    this.fine = const Value.absent(),
  });
  PianiCompanion.insert({
    this.id = const Value.absent(),
    required String nome,
    required int giorniMask,
    this.targetPct = const Value.absent(),
    this.confine = const Value.absent(),
    required String inizio,
    this.fine = const Value.absent(),
  }) : nome = Value(nome),
       giorniMask = Value(giorniMask),
       inizio = Value(inizio);
  static Insertable<RigaPiano> custom({
    Expression<int>? id,
    Expression<String>? nome,
    Expression<int>? giorniMask,
    Expression<double>? targetPct,
    Expression<String>? confine,
    Expression<String>? inizio,
    Expression<String>? fine,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (nome != null) 'nome': nome,
      if (giorniMask != null) 'giorni_mask': giorniMask,
      if (targetPct != null) 'target_pct': targetPct,
      if (confine != null) 'confine': confine,
      if (inizio != null) 'inizio': inizio,
      if (fine != null) 'fine': fine,
    });
  }

  PianiCompanion copyWith({
    Value<int>? id,
    Value<String>? nome,
    Value<int>? giorniMask,
    Value<double>? targetPct,
    Value<String>? confine,
    Value<String>? inizio,
    Value<String?>? fine,
  }) {
    return PianiCompanion(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      giorniMask: giorniMask ?? this.giorniMask,
      targetPct: targetPct ?? this.targetPct,
      confine: confine ?? this.confine,
      inizio: inizio ?? this.inizio,
      fine: fine ?? this.fine,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (nome.present) {
      map['nome'] = Variable<String>(nome.value);
    }
    if (giorniMask.present) {
      map['giorni_mask'] = Variable<int>(giorniMask.value);
    }
    if (targetPct.present) {
      map['target_pct'] = Variable<double>(targetPct.value);
    }
    if (confine.present) {
      map['confine'] = Variable<String>(confine.value);
    }
    if (inizio.present) {
      map['inizio'] = Variable<String>(inizio.value);
    }
    if (fine.present) {
      map['fine'] = Variable<String>(fine.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PianiCompanion(')
          ..write('id: $id, ')
          ..write('nome: $nome, ')
          ..write('giorniMask: $giorniMask, ')
          ..write('targetPct: $targetPct, ')
          ..write('confine: $confine, ')
          ..write('inizio: $inizio, ')
          ..write('fine: $fine')
          ..write(')'))
        .toString();
  }
}

class $ProgettiTable extends Progetti
    with TableInfo<$ProgettiTable, RigaProgetto> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProgettiTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nomeMeta = const VerificationMeta('nome');
  @override
  late final GeneratedColumn<String> nome = GeneratedColumn<String>(
    'nome',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _coloreMeta = const VerificationMeta('colore');
  @override
  late final GeneratedColumn<int> colore = GeneratedColumn<int>(
    'colore',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant<int>(0),
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant<String>(''),
  );
  @override
  List<GeneratedColumn> get $columns => [id, nome, colore, note];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'progetti';
  @override
  VerificationContext validateIntegrity(
    Insertable<RigaProgetto> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('nome')) {
      context.handle(
        _nomeMeta,
        nome.isAcceptableOrUnknown(data['nome']!, _nomeMeta),
      );
    } else if (isInserting) {
      context.missing(_nomeMeta);
    }
    if (data.containsKey('colore')) {
      context.handle(
        _coloreMeta,
        colore.isAcceptableOrUnknown(data['colore']!, _coloreMeta),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RigaProgetto map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RigaProgetto(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      nome: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nome'],
      )!,
      colore: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}colore'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      )!,
    );
  }

  @override
  $ProgettiTable createAlias(String alias) {
    return $ProgettiTable(attachedDatabase, alias);
  }
}

class RigaProgetto extends DataClass implements Insertable<RigaProgetto> {
  /// Id automatico.
  final int id;

  /// Nome del progetto.
  final String nome;

  /// Colore ARGB (0xAARRGGBB).
  final int colore;

  /// Note libere.
  final String note;
  const RigaProgetto({
    required this.id,
    required this.nome,
    required this.colore,
    required this.note,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['nome'] = Variable<String>(nome);
    map['colore'] = Variable<int>(colore);
    map['note'] = Variable<String>(note);
    return map;
  }

  ProgettiCompanion toCompanion(bool nullToAbsent) {
    return ProgettiCompanion(
      id: Value(id),
      nome: Value(nome),
      colore: Value(colore),
      note: Value(note),
    );
  }

  factory RigaProgetto.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RigaProgetto(
      id: serializer.fromJson<int>(json['id']),
      nome: serializer.fromJson<String>(json['nome']),
      colore: serializer.fromJson<int>(json['colore']),
      note: serializer.fromJson<String>(json['note']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'nome': serializer.toJson<String>(nome),
      'colore': serializer.toJson<int>(colore),
      'note': serializer.toJson<String>(note),
    };
  }

  RigaProgetto copyWith({int? id, String? nome, int? colore, String? note}) =>
      RigaProgetto(
        id: id ?? this.id,
        nome: nome ?? this.nome,
        colore: colore ?? this.colore,
        note: note ?? this.note,
      );
  RigaProgetto copyWithCompanion(ProgettiCompanion data) {
    return RigaProgetto(
      id: data.id.present ? data.id.value : this.id,
      nome: data.nome.present ? data.nome.value : this.nome,
      colore: data.colore.present ? data.colore.value : this.colore,
      note: data.note.present ? data.note.value : this.note,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RigaProgetto(')
          ..write('id: $id, ')
          ..write('nome: $nome, ')
          ..write('colore: $colore, ')
          ..write('note: $note')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, nome, colore, note);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RigaProgetto &&
          other.id == this.id &&
          other.nome == this.nome &&
          other.colore == this.colore &&
          other.note == this.note);
}

class ProgettiCompanion extends UpdateCompanion<RigaProgetto> {
  final Value<int> id;
  final Value<String> nome;
  final Value<int> colore;
  final Value<String> note;
  const ProgettiCompanion({
    this.id = const Value.absent(),
    this.nome = const Value.absent(),
    this.colore = const Value.absent(),
    this.note = const Value.absent(),
  });
  ProgettiCompanion.insert({
    this.id = const Value.absent(),
    required String nome,
    this.colore = const Value.absent(),
    this.note = const Value.absent(),
  }) : nome = Value(nome);
  static Insertable<RigaProgetto> custom({
    Expression<int>? id,
    Expression<String>? nome,
    Expression<int>? colore,
    Expression<String>? note,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (nome != null) 'nome': nome,
      if (colore != null) 'colore': colore,
      if (note != null) 'note': note,
    });
  }

  ProgettiCompanion copyWith({
    Value<int>? id,
    Value<String>? nome,
    Value<int>? colore,
    Value<String>? note,
  }) {
    return ProgettiCompanion(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      colore: colore ?? this.colore,
      note: note ?? this.note,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (nome.present) {
      map['nome'] = Variable<String>(nome.value);
    }
    if (colore.present) {
      map['colore'] = Variable<int>(colore.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProgettiCompanion(')
          ..write('id: $id, ')
          ..write('nome: $nome, ')
          ..write('colore: $colore, ')
          ..write('note: $note')
          ..write(')'))
        .toString();
  }
}

class $ProgettoSettimaneTable extends ProgettoSettimane
    with TableInfo<$ProgettoSettimaneTable, RigaProgettoSettimana> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProgettoSettimaneTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _progettoIdMeta = const VerificationMeta(
    'progettoId',
  );
  @override
  late final GeneratedColumn<int> progettoId = GeneratedColumn<int>(
    'progetto_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _settInizioMeta = const VerificationMeta(
    'settInizio',
  );
  @override
  late final GeneratedColumn<String> settInizio = GeneratedColumn<String>(
    'sett_inizio',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _settFineMeta = const VerificationMeta(
    'settFine',
  );
  @override
  late final GeneratedColumn<String> settFine = GeneratedColumn<String>(
    'sett_fine',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _snapshotJsonMeta = const VerificationMeta(
    'snapshotJson',
  );
  @override
  late final GeneratedColumn<String> snapshotJson = GeneratedColumn<String>(
    'snapshot_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant<String>('{}'),
  );
  static const VerificationMeta _logTestoMeta = const VerificationMeta(
    'logTesto',
  );
  @override
  late final GeneratedColumn<String> logTesto = GeneratedColumn<String>(
    'log_testo',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant<String>(''),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    progettoId,
    settInizio,
    settFine,
    snapshotJson,
    logTesto,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'progetto_settimane';
  @override
  VerificationContext validateIntegrity(
    Insertable<RigaProgettoSettimana> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('progetto_id')) {
      context.handle(
        _progettoIdMeta,
        progettoId.isAcceptableOrUnknown(data['progetto_id']!, _progettoIdMeta),
      );
    } else if (isInserting) {
      context.missing(_progettoIdMeta);
    }
    if (data.containsKey('sett_inizio')) {
      context.handle(
        _settInizioMeta,
        settInizio.isAcceptableOrUnknown(data['sett_inizio']!, _settInizioMeta),
      );
    } else if (isInserting) {
      context.missing(_settInizioMeta);
    }
    if (data.containsKey('sett_fine')) {
      context.handle(
        _settFineMeta,
        settFine.isAcceptableOrUnknown(data['sett_fine']!, _settFineMeta),
      );
    }
    if (data.containsKey('snapshot_json')) {
      context.handle(
        _snapshotJsonMeta,
        snapshotJson.isAcceptableOrUnknown(
          data['snapshot_json']!,
          _snapshotJsonMeta,
        ),
      );
    }
    if (data.containsKey('log_testo')) {
      context.handle(
        _logTestoMeta,
        logTesto.isAcceptableOrUnknown(data['log_testo']!, _logTestoMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RigaProgettoSettimana map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RigaProgettoSettimana(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      progettoId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}progetto_id'],
      )!,
      settInizio: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sett_inizio'],
      )!,
      settFine: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sett_fine'],
      ),
      snapshotJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}snapshot_json'],
      )!,
      logTesto: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}log_testo'],
      )!,
    );
  }

  @override
  $ProgettoSettimaneTable createAlias(String alias) {
    return $ProgettoSettimaneTable(attachedDatabase, alias);
  }
}

class RigaProgettoSettimana extends DataClass
    implements Insertable<RigaProgettoSettimana> {
  /// Id automatico.
  final int id;

  /// Id del progetto.
  final int progettoId;

  /// Inizio settimana 'aaaa-mm-gg hh:mm'.
  final String settInizio;

  /// Fine settimana 'aaaa-mm-gg hh:mm' (null = in corso).
  final String? settFine;

  /// Istantanea dei numeri (JSON).
  final String snapshotJson;

  /// Log testuale della settimana.
  final String logTesto;
  const RigaProgettoSettimana({
    required this.id,
    required this.progettoId,
    required this.settInizio,
    this.settFine,
    required this.snapshotJson,
    required this.logTesto,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['progetto_id'] = Variable<int>(progettoId);
    map['sett_inizio'] = Variable<String>(settInizio);
    if (!nullToAbsent || settFine != null) {
      map['sett_fine'] = Variable<String>(settFine);
    }
    map['snapshot_json'] = Variable<String>(snapshotJson);
    map['log_testo'] = Variable<String>(logTesto);
    return map;
  }

  ProgettoSettimaneCompanion toCompanion(bool nullToAbsent) {
    return ProgettoSettimaneCompanion(
      id: Value(id),
      progettoId: Value(progettoId),
      settInizio: Value(settInizio),
      settFine: settFine == null && nullToAbsent
          ? const Value.absent()
          : Value(settFine),
      snapshotJson: Value(snapshotJson),
      logTesto: Value(logTesto),
    );
  }

  factory RigaProgettoSettimana.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RigaProgettoSettimana(
      id: serializer.fromJson<int>(json['id']),
      progettoId: serializer.fromJson<int>(json['progettoId']),
      settInizio: serializer.fromJson<String>(json['settInizio']),
      settFine: serializer.fromJson<String?>(json['settFine']),
      snapshotJson: serializer.fromJson<String>(json['snapshotJson']),
      logTesto: serializer.fromJson<String>(json['logTesto']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'progettoId': serializer.toJson<int>(progettoId),
      'settInizio': serializer.toJson<String>(settInizio),
      'settFine': serializer.toJson<String?>(settFine),
      'snapshotJson': serializer.toJson<String>(snapshotJson),
      'logTesto': serializer.toJson<String>(logTesto),
    };
  }

  RigaProgettoSettimana copyWith({
    int? id,
    int? progettoId,
    String? settInizio,
    Value<String?> settFine = const Value.absent(),
    String? snapshotJson,
    String? logTesto,
  }) => RigaProgettoSettimana(
    id: id ?? this.id,
    progettoId: progettoId ?? this.progettoId,
    settInizio: settInizio ?? this.settInizio,
    settFine: settFine.present ? settFine.value : this.settFine,
    snapshotJson: snapshotJson ?? this.snapshotJson,
    logTesto: logTesto ?? this.logTesto,
  );
  RigaProgettoSettimana copyWithCompanion(ProgettoSettimaneCompanion data) {
    return RigaProgettoSettimana(
      id: data.id.present ? data.id.value : this.id,
      progettoId: data.progettoId.present
          ? data.progettoId.value
          : this.progettoId,
      settInizio: data.settInizio.present
          ? data.settInizio.value
          : this.settInizio,
      settFine: data.settFine.present ? data.settFine.value : this.settFine,
      snapshotJson: data.snapshotJson.present
          ? data.snapshotJson.value
          : this.snapshotJson,
      logTesto: data.logTesto.present ? data.logTesto.value : this.logTesto,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RigaProgettoSettimana(')
          ..write('id: $id, ')
          ..write('progettoId: $progettoId, ')
          ..write('settInizio: $settInizio, ')
          ..write('settFine: $settFine, ')
          ..write('snapshotJson: $snapshotJson, ')
          ..write('logTesto: $logTesto')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, progettoId, settInizio, settFine, snapshotJson, logTesto);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RigaProgettoSettimana &&
          other.id == this.id &&
          other.progettoId == this.progettoId &&
          other.settInizio == this.settInizio &&
          other.settFine == this.settFine &&
          other.snapshotJson == this.snapshotJson &&
          other.logTesto == this.logTesto);
}

class ProgettoSettimaneCompanion
    extends UpdateCompanion<RigaProgettoSettimana> {
  final Value<int> id;
  final Value<int> progettoId;
  final Value<String> settInizio;
  final Value<String?> settFine;
  final Value<String> snapshotJson;
  final Value<String> logTesto;
  const ProgettoSettimaneCompanion({
    this.id = const Value.absent(),
    this.progettoId = const Value.absent(),
    this.settInizio = const Value.absent(),
    this.settFine = const Value.absent(),
    this.snapshotJson = const Value.absent(),
    this.logTesto = const Value.absent(),
  });
  ProgettoSettimaneCompanion.insert({
    this.id = const Value.absent(),
    required int progettoId,
    required String settInizio,
    this.settFine = const Value.absent(),
    this.snapshotJson = const Value.absent(),
    this.logTesto = const Value.absent(),
  }) : progettoId = Value(progettoId),
       settInizio = Value(settInizio);
  static Insertable<RigaProgettoSettimana> custom({
    Expression<int>? id,
    Expression<int>? progettoId,
    Expression<String>? settInizio,
    Expression<String>? settFine,
    Expression<String>? snapshotJson,
    Expression<String>? logTesto,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (progettoId != null) 'progetto_id': progettoId,
      if (settInizio != null) 'sett_inizio': settInizio,
      if (settFine != null) 'sett_fine': settFine,
      if (snapshotJson != null) 'snapshot_json': snapshotJson,
      if (logTesto != null) 'log_testo': logTesto,
    });
  }

  ProgettoSettimaneCompanion copyWith({
    Value<int>? id,
    Value<int>? progettoId,
    Value<String>? settInizio,
    Value<String?>? settFine,
    Value<String>? snapshotJson,
    Value<String>? logTesto,
  }) {
    return ProgettoSettimaneCompanion(
      id: id ?? this.id,
      progettoId: progettoId ?? this.progettoId,
      settInizio: settInizio ?? this.settInizio,
      settFine: settFine ?? this.settFine,
      snapshotJson: snapshotJson ?? this.snapshotJson,
      logTesto: logTesto ?? this.logTesto,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (progettoId.present) {
      map['progetto_id'] = Variable<int>(progettoId.value);
    }
    if (settInizio.present) {
      map['sett_inizio'] = Variable<String>(settInizio.value);
    }
    if (settFine.present) {
      map['sett_fine'] = Variable<String>(settFine.value);
    }
    if (snapshotJson.present) {
      map['snapshot_json'] = Variable<String>(snapshotJson.value);
    }
    if (logTesto.present) {
      map['log_testo'] = Variable<String>(logTesto.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProgettoSettimaneCompanion(')
          ..write('id: $id, ')
          ..write('progettoId: $progettoId, ')
          ..write('settInizio: $settInizio, ')
          ..write('settFine: $settFine, ')
          ..write('snapshotJson: $snapshotJson, ')
          ..write('logTesto: $logTesto')
          ..write(')'))
        .toString();
  }
}

abstract class _$DatabaseTraker extends GeneratedDatabase {
  _$DatabaseTraker(QueryExecutor e) : super(e);
  $DatabaseTrakerManager get managers => $DatabaseTrakerManager(this);
  late final $LettureTable letture = $LettureTable(this);
  late final $EventiTable eventi = $EventiTable(this);
  late final $ImpostazioniTable impostazioni = $ImpostazioniTable(this);
  late final $PianiTable piani = $PianiTable(this);
  late final $ProgettiTable progetti = $ProgettiTable(this);
  late final $ProgettoSettimaneTable progettoSettimane =
      $ProgettoSettimaneTable(this);
  late final Index lettureOra = Index(
    'letture_ora',
    'CREATE INDEX letture_ora ON letture (ora)',
  );
  late final Index eventiOra = Index(
    'eventi_ora',
    'CREATE INDEX eventi_ora ON eventi (ora)',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    letture,
    eventi,
    impostazioni,
    piani,
    progetti,
    progettoSettimane,
    lettureOra,
    eventiOra,
  ];
}

typedef $$LettureTableCreateCompanionBuilder = LettureCompanion Function({
  Value<int> id,
  required String ora,
  Value<double?> sett,
  Value<double?> sess,
  Value<String> fonte,
  Value<bool?> alPc,
  Value<bool> lavoro,
  Value<String> modelli,
  Value<String> skill,
  required String gestore,
});
typedef $$LettureTableUpdateCompanionBuilder = LettureCompanion Function({
  Value<int> id,
  Value<String> ora,
  Value<double?> sett,
  Value<double?> sess,
  Value<String> fonte,
  Value<bool?> alPc,
  Value<bool> lavoro,
  Value<String> modelli,
  Value<String> skill,
  Value<String> gestore,
});

class $$LettureTableFilterComposer
    extends Composer<_$DatabaseTraker, $LettureTable> {
  $$LettureTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ora => $composableBuilder(
    column: $table.ora,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get sett => $composableBuilder(
    column: $table.sett,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get sess => $composableBuilder(
    column: $table.sess,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fonte => $composableBuilder(
    column: $table.fonte,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get alPc => $composableBuilder(
    column: $table.alPc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get lavoro => $composableBuilder(
    column: $table.lavoro,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get modelli => $composableBuilder(
    column: $table.modelli,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get skill => $composableBuilder(
    column: $table.skill,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get gestore => $composableBuilder(
    column: $table.gestore,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LettureTableOrderingComposer
    extends Composer<_$DatabaseTraker, $LettureTable> {
  $$LettureTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ora => $composableBuilder(
    column: $table.ora,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get sett => $composableBuilder(
    column: $table.sett,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get sess => $composableBuilder(
    column: $table.sess,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fonte => $composableBuilder(
    column: $table.fonte,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get alPc => $composableBuilder(
    column: $table.alPc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get lavoro => $composableBuilder(
    column: $table.lavoro,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get modelli => $composableBuilder(
    column: $table.modelli,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get skill => $composableBuilder(
    column: $table.skill,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get gestore => $composableBuilder(
    column: $table.gestore,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LettureTableAnnotationComposer
    extends Composer<_$DatabaseTraker, $LettureTable> {
  $$LettureTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get ora =>
      $composableBuilder(column: $table.ora, builder: (column) => column);

  GeneratedColumn<double> get sett =>
      $composableBuilder(column: $table.sett, builder: (column) => column);

  GeneratedColumn<double> get sess =>
      $composableBuilder(column: $table.sess, builder: (column) => column);

  GeneratedColumn<String> get fonte =>
      $composableBuilder(column: $table.fonte, builder: (column) => column);

  GeneratedColumn<bool> get alPc =>
      $composableBuilder(column: $table.alPc, builder: (column) => column);

  GeneratedColumn<bool> get lavoro =>
      $composableBuilder(column: $table.lavoro, builder: (column) => column);

  GeneratedColumn<String> get modelli =>
      $composableBuilder(column: $table.modelli, builder: (column) => column);

  GeneratedColumn<String> get skill =>
      $composableBuilder(column: $table.skill, builder: (column) => column);

  GeneratedColumn<String> get gestore =>
      $composableBuilder(column: $table.gestore, builder: (column) => column);
}

class $$LettureTableTableManager
    extends
        RootTableManager<
          _$DatabaseTraker,
          $LettureTable,
          RigaLettura,
          $$LettureTableFilterComposer,
          $$LettureTableOrderingComposer,
          $$LettureTableAnnotationComposer,
          $$LettureTableCreateCompanionBuilder,
          $$LettureTableUpdateCompanionBuilder,
          (
            RigaLettura,
            BaseReferences<_$DatabaseTraker, $LettureTable, RigaLettura>,
          ),
          RigaLettura,
          PrefetchHooks Function()
        > {
  $$LettureTableTableManager(_$DatabaseTraker db, $LettureTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LettureTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LettureTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LettureTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> ora = const Value.absent(),
                Value<double?> sett = const Value.absent(),
                Value<double?> sess = const Value.absent(),
                Value<String> fonte = const Value.absent(),
                Value<bool?> alPc = const Value.absent(),
                Value<bool> lavoro = const Value.absent(),
                Value<String> modelli = const Value.absent(),
                Value<String> skill = const Value.absent(),
                Value<String> gestore = const Value.absent(),
              }) => LettureCompanion(
                id: id,
                ora: ora,
                sett: sett,
                sess: sess,
                fonte: fonte,
                alPc: alPc,
                lavoro: lavoro,
                modelli: modelli,
                skill: skill,
                gestore: gestore,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String ora,
                Value<double?> sett = const Value.absent(),
                Value<double?> sess = const Value.absent(),
                Value<String> fonte = const Value.absent(),
                Value<bool?> alPc = const Value.absent(),
                Value<bool> lavoro = const Value.absent(),
                Value<String> modelli = const Value.absent(),
                Value<String> skill = const Value.absent(),
                required String gestore,
              }) => LettureCompanion.insert(
                id: id,
                ora: ora,
                sett: sett,
                sess: sess,
                fonte: fonte,
                alPc: alPc,
                lavoro: lavoro,
                modelli: modelli,
                skill: skill,
                gestore: gestore,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LettureTable, RigaLettura>(table),
                  BaseReferences<_$DatabaseTraker, $LettureTable, RigaLettura>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LettureTableProcessedTableManager =
    ProcessedTableManager<
      _$DatabaseTraker,
      $LettureTable,
      RigaLettura,
      $$LettureTableFilterComposer,
      $$LettureTableOrderingComposer,
      $$LettureTableAnnotationComposer,
      $$LettureTableCreateCompanionBuilder,
      $$LettureTableUpdateCompanionBuilder,
      (
        RigaLettura,
        BaseReferences<_$DatabaseTraker, $LettureTable, RigaLettura>,
      ),
      RigaLettura,
      PrefetchHooks Function()
    >;
typedef $$EventiTableCreateCompanionBuilder = EventiCompanion Function({
  Value<int> id,
  required String ora,
  required String tipo,
  Value<String> testo,
});
typedef $$EventiTableUpdateCompanionBuilder = EventiCompanion Function({
  Value<int> id,
  Value<String> ora,
  Value<String> tipo,
  Value<String> testo,
});

class $$EventiTableFilterComposer
    extends Composer<_$DatabaseTraker, $EventiTable> {
  $$EventiTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ora => $composableBuilder(
    column: $table.ora,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tipo => $composableBuilder(
    column: $table.tipo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get testo => $composableBuilder(
    column: $table.testo,
    builder: (column) => ColumnFilters(column),
  );
}

class $$EventiTableOrderingComposer
    extends Composer<_$DatabaseTraker, $EventiTable> {
  $$EventiTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ora => $composableBuilder(
    column: $table.ora,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tipo => $composableBuilder(
    column: $table.tipo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get testo => $composableBuilder(
    column: $table.testo,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$EventiTableAnnotationComposer
    extends Composer<_$DatabaseTraker, $EventiTable> {
  $$EventiTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get ora =>
      $composableBuilder(column: $table.ora, builder: (column) => column);

  GeneratedColumn<String> get tipo =>
      $composableBuilder(column: $table.tipo, builder: (column) => column);

  GeneratedColumn<String> get testo =>
      $composableBuilder(column: $table.testo, builder: (column) => column);
}

class $$EventiTableTableManager
    extends
        RootTableManager<
          _$DatabaseTraker,
          $EventiTable,
          RigaEvento,
          $$EventiTableFilterComposer,
          $$EventiTableOrderingComposer,
          $$EventiTableAnnotationComposer,
          $$EventiTableCreateCompanionBuilder,
          $$EventiTableUpdateCompanionBuilder,
          (
            RigaEvento,
            BaseReferences<_$DatabaseTraker, $EventiTable, RigaEvento>,
          ),
          RigaEvento,
          PrefetchHooks Function()
        > {
  $$EventiTableTableManager(_$DatabaseTraker db, $EventiTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EventiTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EventiTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EventiTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> ora = const Value.absent(),
            Value<String> tipo = const Value.absent(),
            Value<String> testo = const Value.absent(),
          }) => EventiCompanion(id: id, ora: ora, tipo: tipo, testo: testo),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String ora,
                required String tipo,
                Value<String> testo = const Value.absent(),
              }) => EventiCompanion.insert(
                id: id,
                ora: ora,
                tipo: tipo,
                testo: testo,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$EventiTable, RigaEvento>(table),
                  BaseReferences<_$DatabaseTraker, $EventiTable, RigaEvento>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$EventiTableProcessedTableManager =
    ProcessedTableManager<
      _$DatabaseTraker,
      $EventiTable,
      RigaEvento,
      $$EventiTableFilterComposer,
      $$EventiTableOrderingComposer,
      $$EventiTableAnnotationComposer,
      $$EventiTableCreateCompanionBuilder,
      $$EventiTableUpdateCompanionBuilder,
      (RigaEvento, BaseReferences<_$DatabaseTraker, $EventiTable, RigaEvento>),
      RigaEvento,
      PrefetchHooks Function()
    >;
typedef $$ImpostazioniTableCreateCompanionBuilder =
    ImpostazioniCompanion Function({
      required String chiave,
      required String valore,
      Value<int> rowid,
    });
typedef $$ImpostazioniTableUpdateCompanionBuilder =
    ImpostazioniCompanion Function({
      Value<String> chiave,
      Value<String> valore,
      Value<int> rowid,
    });

class $$ImpostazioniTableFilterComposer
    extends Composer<_$DatabaseTraker, $ImpostazioniTable> {
  $$ImpostazioniTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get chiave => $composableBuilder(
    column: $table.chiave,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get valore => $composableBuilder(
    column: $table.valore,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ImpostazioniTableOrderingComposer
    extends Composer<_$DatabaseTraker, $ImpostazioniTable> {
  $$ImpostazioniTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get chiave => $composableBuilder(
    column: $table.chiave,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get valore => $composableBuilder(
    column: $table.valore,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ImpostazioniTableAnnotationComposer
    extends Composer<_$DatabaseTraker, $ImpostazioniTable> {
  $$ImpostazioniTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get chiave =>
      $composableBuilder(column: $table.chiave, builder: (column) => column);

  GeneratedColumn<String> get valore =>
      $composableBuilder(column: $table.valore, builder: (column) => column);
}

class $$ImpostazioniTableTableManager
    extends
        RootTableManager<
          _$DatabaseTraker,
          $ImpostazioniTable,
          RigaImpostazione,
          $$ImpostazioniTableFilterComposer,
          $$ImpostazioniTableOrderingComposer,
          $$ImpostazioniTableAnnotationComposer,
          $$ImpostazioniTableCreateCompanionBuilder,
          $$ImpostazioniTableUpdateCompanionBuilder,
          (
            RigaImpostazione,
            BaseReferences<
              _$DatabaseTraker,
              $ImpostazioniTable,
              RigaImpostazione
            >,
          ),
          RigaImpostazione,
          PrefetchHooks Function()
        > {
  $$ImpostazioniTableTableManager(_$DatabaseTraker db, $ImpostazioniTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ImpostazioniTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ImpostazioniTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ImpostazioniTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> chiave = const Value.absent(),
                Value<String> valore = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ImpostazioniCompanion(
                chiave: chiave,
                valore: valore,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String chiave,
                required String valore,
                Value<int> rowid = const Value.absent(),
              }) => ImpostazioniCompanion.insert(
                chiave: chiave,
                valore: valore,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ImpostazioniTable, RigaImpostazione>(table),
                  BaseReferences<
                    _$DatabaseTraker,
                    $ImpostazioniTable,
                    RigaImpostazione
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ImpostazioniTableProcessedTableManager =
    ProcessedTableManager<
      _$DatabaseTraker,
      $ImpostazioniTable,
      RigaImpostazione,
      $$ImpostazioniTableFilterComposer,
      $$ImpostazioniTableOrderingComposer,
      $$ImpostazioniTableAnnotationComposer,
      $$ImpostazioniTableCreateCompanionBuilder,
      $$ImpostazioniTableUpdateCompanionBuilder,
      (
        RigaImpostazione,
        BaseReferences<_$DatabaseTraker, $ImpostazioniTable, RigaImpostazione>,
      ),
      RigaImpostazione,
      PrefetchHooks Function()
    >;
typedef $$PianiTableCreateCompanionBuilder = PianiCompanion Function({
  Value<int> id,
  required String nome,
  required int giorniMask,
  Value<double> targetPct,
  Value<String> confine,
  required String inizio,
  Value<String?> fine,
});
typedef $$PianiTableUpdateCompanionBuilder = PianiCompanion Function({
  Value<int> id,
  Value<String> nome,
  Value<int> giorniMask,
  Value<double> targetPct,
  Value<String> confine,
  Value<String> inizio,
  Value<String?> fine,
});

class $$PianiTableFilterComposer
    extends Composer<_$DatabaseTraker, $PianiTable> {
  $$PianiTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nome => $composableBuilder(
    column: $table.nome,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get giorniMask => $composableBuilder(
    column: $table.giorniMask,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get targetPct => $composableBuilder(
    column: $table.targetPct,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get confine => $composableBuilder(
    column: $table.confine,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get inizio => $composableBuilder(
    column: $table.inizio,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fine => $composableBuilder(
    column: $table.fine,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PianiTableOrderingComposer
    extends Composer<_$DatabaseTraker, $PianiTable> {
  $$PianiTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nome => $composableBuilder(
    column: $table.nome,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get giorniMask => $composableBuilder(
    column: $table.giorniMask,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get targetPct => $composableBuilder(
    column: $table.targetPct,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get confine => $composableBuilder(
    column: $table.confine,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get inizio => $composableBuilder(
    column: $table.inizio,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fine => $composableBuilder(
    column: $table.fine,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PianiTableAnnotationComposer
    extends Composer<_$DatabaseTraker, $PianiTable> {
  $$PianiTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get nome =>
      $composableBuilder(column: $table.nome, builder: (column) => column);

  GeneratedColumn<int> get giorniMask => $composableBuilder(
    column: $table.giorniMask,
    builder: (column) => column,
  );

  GeneratedColumn<double> get targetPct =>
      $composableBuilder(column: $table.targetPct, builder: (column) => column);

  GeneratedColumn<String> get confine =>
      $composableBuilder(column: $table.confine, builder: (column) => column);

  GeneratedColumn<String> get inizio =>
      $composableBuilder(column: $table.inizio, builder: (column) => column);

  GeneratedColumn<String> get fine =>
      $composableBuilder(column: $table.fine, builder: (column) => column);
}

class $$PianiTableTableManager
    extends
        RootTableManager<
          _$DatabaseTraker,
          $PianiTable,
          RigaPiano,
          $$PianiTableFilterComposer,
          $$PianiTableOrderingComposer,
          $$PianiTableAnnotationComposer,
          $$PianiTableCreateCompanionBuilder,
          $$PianiTableUpdateCompanionBuilder,
          (RigaPiano, BaseReferences<_$DatabaseTraker, $PianiTable, RigaPiano>),
          RigaPiano,
          PrefetchHooks Function()
        > {
  $$PianiTableTableManager(_$DatabaseTraker db, $PianiTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PianiTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PianiTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PianiTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> nome = const Value.absent(),
                Value<int> giorniMask = const Value.absent(),
                Value<double> targetPct = const Value.absent(),
                Value<String> confine = const Value.absent(),
                Value<String> inizio = const Value.absent(),
                Value<String?> fine = const Value.absent(),
              }) => PianiCompanion(
                id: id,
                nome: nome,
                giorniMask: giorniMask,
                targetPct: targetPct,
                confine: confine,
                inizio: inizio,
                fine: fine,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String nome,
                required int giorniMask,
                Value<double> targetPct = const Value.absent(),
                Value<String> confine = const Value.absent(),
                required String inizio,
                Value<String?> fine = const Value.absent(),
              }) => PianiCompanion.insert(
                id: id,
                nome: nome,
                giorniMask: giorniMask,
                targetPct: targetPct,
                confine: confine,
                inizio: inizio,
                fine: fine,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PianiTable, RigaPiano>(table),
                  BaseReferences<_$DatabaseTraker, $PianiTable, RigaPiano>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PianiTableProcessedTableManager =
    ProcessedTableManager<
      _$DatabaseTraker,
      $PianiTable,
      RigaPiano,
      $$PianiTableFilterComposer,
      $$PianiTableOrderingComposer,
      $$PianiTableAnnotationComposer,
      $$PianiTableCreateCompanionBuilder,
      $$PianiTableUpdateCompanionBuilder,
      (RigaPiano, BaseReferences<_$DatabaseTraker, $PianiTable, RigaPiano>),
      RigaPiano,
      PrefetchHooks Function()
    >;
typedef $$ProgettiTableCreateCompanionBuilder = ProgettiCompanion Function({
  Value<int> id,
  required String nome,
  Value<int> colore,
  Value<String> note,
});
typedef $$ProgettiTableUpdateCompanionBuilder = ProgettiCompanion Function({
  Value<int> id,
  Value<String> nome,
  Value<int> colore,
  Value<String> note,
});

class $$ProgettiTableFilterComposer
    extends Composer<_$DatabaseTraker, $ProgettiTable> {
  $$ProgettiTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nome => $composableBuilder(
    column: $table.nome,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get colore => $composableBuilder(
    column: $table.colore,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ProgettiTableOrderingComposer
    extends Composer<_$DatabaseTraker, $ProgettiTable> {
  $$ProgettiTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nome => $composableBuilder(
    column: $table.nome,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get colore => $composableBuilder(
    column: $table.colore,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ProgettiTableAnnotationComposer
    extends Composer<_$DatabaseTraker, $ProgettiTable> {
  $$ProgettiTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get nome =>
      $composableBuilder(column: $table.nome, builder: (column) => column);

  GeneratedColumn<int> get colore =>
      $composableBuilder(column: $table.colore, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);
}

class $$ProgettiTableTableManager
    extends
        RootTableManager<
          _$DatabaseTraker,
          $ProgettiTable,
          RigaProgetto,
          $$ProgettiTableFilterComposer,
          $$ProgettiTableOrderingComposer,
          $$ProgettiTableAnnotationComposer,
          $$ProgettiTableCreateCompanionBuilder,
          $$ProgettiTableUpdateCompanionBuilder,
          (
            RigaProgetto,
            BaseReferences<_$DatabaseTraker, $ProgettiTable, RigaProgetto>,
          ),
          RigaProgetto,
          PrefetchHooks Function()
        > {
  $$ProgettiTableTableManager(_$DatabaseTraker db, $ProgettiTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProgettiTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProgettiTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProgettiTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> nome = const Value.absent(),
                Value<int> colore = const Value.absent(),
                Value<String> note = const Value.absent(),
              }) => ProgettiCompanion(
                id: id,
                nome: nome,
                colore: colore,
                note: note,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String nome,
                Value<int> colore = const Value.absent(),
                Value<String> note = const Value.absent(),
              }) => ProgettiCompanion.insert(
                id: id,
                nome: nome,
                colore: colore,
                note: note,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ProgettiTable, RigaProgetto>(table),
                  BaseReferences<
                    _$DatabaseTraker,
                    $ProgettiTable,
                    RigaProgetto
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ProgettiTableProcessedTableManager =
    ProcessedTableManager<
      _$DatabaseTraker,
      $ProgettiTable,
      RigaProgetto,
      $$ProgettiTableFilterComposer,
      $$ProgettiTableOrderingComposer,
      $$ProgettiTableAnnotationComposer,
      $$ProgettiTableCreateCompanionBuilder,
      $$ProgettiTableUpdateCompanionBuilder,
      (
        RigaProgetto,
        BaseReferences<_$DatabaseTraker, $ProgettiTable, RigaProgetto>,
      ),
      RigaProgetto,
      PrefetchHooks Function()
    >;
typedef $$ProgettoSettimaneTableCreateCompanionBuilder =
    ProgettoSettimaneCompanion Function({
      Value<int> id,
      required int progettoId,
      required String settInizio,
      Value<String?> settFine,
      Value<String> snapshotJson,
      Value<String> logTesto,
    });
typedef $$ProgettoSettimaneTableUpdateCompanionBuilder =
    ProgettoSettimaneCompanion Function({
      Value<int> id,
      Value<int> progettoId,
      Value<String> settInizio,
      Value<String?> settFine,
      Value<String> snapshotJson,
      Value<String> logTesto,
    });

class $$ProgettoSettimaneTableFilterComposer
    extends Composer<_$DatabaseTraker, $ProgettoSettimaneTable> {
  $$ProgettoSettimaneTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get progettoId => $composableBuilder(
    column: $table.progettoId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get settInizio => $composableBuilder(
    column: $table.settInizio,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get settFine => $composableBuilder(
    column: $table.settFine,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get snapshotJson => $composableBuilder(
    column: $table.snapshotJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get logTesto => $composableBuilder(
    column: $table.logTesto,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ProgettoSettimaneTableOrderingComposer
    extends Composer<_$DatabaseTraker, $ProgettoSettimaneTable> {
  $$ProgettoSettimaneTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get progettoId => $composableBuilder(
    column: $table.progettoId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get settInizio => $composableBuilder(
    column: $table.settInizio,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get settFine => $composableBuilder(
    column: $table.settFine,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get snapshotJson => $composableBuilder(
    column: $table.snapshotJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get logTesto => $composableBuilder(
    column: $table.logTesto,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ProgettoSettimaneTableAnnotationComposer
    extends Composer<_$DatabaseTraker, $ProgettoSettimaneTable> {
  $$ProgettoSettimaneTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get progettoId => $composableBuilder(
    column: $table.progettoId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get settInizio => $composableBuilder(
    column: $table.settInizio,
    builder: (column) => column,
  );

  GeneratedColumn<String> get settFine =>
      $composableBuilder(column: $table.settFine, builder: (column) => column);

  GeneratedColumn<String> get snapshotJson => $composableBuilder(
    column: $table.snapshotJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get logTesto =>
      $composableBuilder(column: $table.logTesto, builder: (column) => column);
}

class $$ProgettoSettimaneTableTableManager
    extends
        RootTableManager<
          _$DatabaseTraker,
          $ProgettoSettimaneTable,
          RigaProgettoSettimana,
          $$ProgettoSettimaneTableFilterComposer,
          $$ProgettoSettimaneTableOrderingComposer,
          $$ProgettoSettimaneTableAnnotationComposer,
          $$ProgettoSettimaneTableCreateCompanionBuilder,
          $$ProgettoSettimaneTableUpdateCompanionBuilder,
          (
            RigaProgettoSettimana,
            BaseReferences<
              _$DatabaseTraker,
              $ProgettoSettimaneTable,
              RigaProgettoSettimana
            >,
          ),
          RigaProgettoSettimana,
          PrefetchHooks Function()
        > {
  $$ProgettoSettimaneTableTableManager(
    _$DatabaseTraker db,
    $ProgettoSettimaneTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProgettoSettimaneTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProgettoSettimaneTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProgettoSettimaneTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> progettoId = const Value.absent(),
                Value<String> settInizio = const Value.absent(),
                Value<String?> settFine = const Value.absent(),
                Value<String> snapshotJson = const Value.absent(),
                Value<String> logTesto = const Value.absent(),
              }) => ProgettoSettimaneCompanion(
                id: id,
                progettoId: progettoId,
                settInizio: settInizio,
                settFine: settFine,
                snapshotJson: snapshotJson,
                logTesto: logTesto,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int progettoId,
                required String settInizio,
                Value<String?> settFine = const Value.absent(),
                Value<String> snapshotJson = const Value.absent(),
                Value<String> logTesto = const Value.absent(),
              }) => ProgettoSettimaneCompanion.insert(
                id: id,
                progettoId: progettoId,
                settInizio: settInizio,
                settFine: settFine,
                snapshotJson: snapshotJson,
                logTesto: logTesto,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ProgettoSettimaneTable, RigaProgettoSettimana>(
                    table,
                  ),
                  BaseReferences<
                    _$DatabaseTraker,
                    $ProgettoSettimaneTable,
                    RigaProgettoSettimana
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ProgettoSettimaneTableProcessedTableManager =
    ProcessedTableManager<
      _$DatabaseTraker,
      $ProgettoSettimaneTable,
      RigaProgettoSettimana,
      $$ProgettoSettimaneTableFilterComposer,
      $$ProgettoSettimaneTableOrderingComposer,
      $$ProgettoSettimaneTableAnnotationComposer,
      $$ProgettoSettimaneTableCreateCompanionBuilder,
      $$ProgettoSettimaneTableUpdateCompanionBuilder,
      (
        RigaProgettoSettimana,
        BaseReferences<
          _$DatabaseTraker,
          $ProgettoSettimaneTable,
          RigaProgettoSettimana
        >,
      ),
      RigaProgettoSettimana,
      PrefetchHooks Function()
    >;

class $DatabaseTrakerManager {
  final _$DatabaseTraker _db;
  $DatabaseTrakerManager(this._db);
  $$LettureTableTableManager get letture =>
      $$LettureTableTableManager(_db, _db.letture);
  $$EventiTableTableManager get eventi =>
      $$EventiTableTableManager(_db, _db.eventi);
  $$ImpostazioniTableTableManager get impostazioni =>
      $$ImpostazioniTableTableManager(_db, _db.impostazioni);
  $$PianiTableTableManager get piani =>
      $$PianiTableTableManager(_db, _db.piani);
  $$ProgettiTableTableManager get progetti =>
      $$ProgettiTableTableManager(_db, _db.progetti);
  $$ProgettoSettimaneTableTableManager get progettoSettimane =>
      $$ProgettoSettimaneTableTableManager(_db, _db.progettoSettimane);
}
