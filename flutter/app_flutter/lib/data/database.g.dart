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

abstract class _$DatabaseTraker extends GeneratedDatabase {
  _$DatabaseTraker(QueryExecutor e) : super(e);
  $DatabaseTrakerManager get managers => $DatabaseTrakerManager(this);
  late final $LettureTable letture = $LettureTable(this);
  late final $EventiTable eventi = $EventiTable(this);
  late final $ImpostazioniTable impostazioni = $ImpostazioniTable(this);
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

class $DatabaseTrakerManager {
  final _$DatabaseTraker _db;
  $DatabaseTrakerManager(this._db);
  $$LettureTableTableManager get letture =>
      $$LettureTableTableManager(_db, _db.letture);
  $$EventiTableTableManager get eventi =>
      $$EventiTableTableManager(_db, _db.eventi);
  $$ImpostazioniTableTableManager get impostazioni =>
      $$ImpostazioniTableTableManager(_db, _db.impostazioni);
}
