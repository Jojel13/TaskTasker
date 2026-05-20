// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'xp_event.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetXPEventCollection on Isar {
  IsarCollection<XPEvent> get xPEvents => this.collection();
}

const XPEventSchema = CollectionSchema(
  name: r'XPEvent',
  id: 2340325949008956080,
  properties: {
    r'amount': PropertySchema(
      id: 0,
      name: r'amount',
      type: IsarType.long,
    ),
    r'description': PropertySchema(
      id: 1,
      name: r'description',
      type: IsarType.string,
    ),
    r'earnedAt': PropertySchema(
      id: 2,
      name: r'earnedAt',
      type: IsarType.dateTime,
    )
  },
  estimateSize: _xPEventEstimateSize,
  serialize: _xPEventSerialize,
  deserialize: _xPEventDeserialize,
  deserializeProp: _xPEventDeserializeProp,
  idName: r'id',
  indexes: {
    r'earnedAt': IndexSchema(
      id: -8281250366239188956,
      name: r'earnedAt',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'earnedAt',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _xPEventGetId,
  getLinks: _xPEventGetLinks,
  attach: _xPEventAttach,
  version: '3.1.0+1',
);

int _xPEventEstimateSize(
  XPEvent object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.description.length * 3;
  return bytesCount;
}

void _xPEventSerialize(
  XPEvent object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeLong(offsets[0], object.amount);
  writer.writeString(offsets[1], object.description);
  writer.writeDateTime(offsets[2], object.earnedAt);
}

XPEvent _xPEventDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = XPEvent();
  object.amount = reader.readLong(offsets[0]);
  object.description = reader.readString(offsets[1]);
  object.earnedAt = reader.readDateTime(offsets[2]);
  object.id = id;
  return object;
}

P _xPEventDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readLong(offset)) as P;
    case 1:
      return (reader.readString(offset)) as P;
    case 2:
      return (reader.readDateTime(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _xPEventGetId(XPEvent object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _xPEventGetLinks(XPEvent object) {
  return [];
}

void _xPEventAttach(IsarCollection<dynamic> col, Id id, XPEvent object) {
  object.id = id;
}

extension XPEventQueryWhereSort on QueryBuilder<XPEvent, XPEvent, QWhere> {
  QueryBuilder<XPEvent, XPEvent, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<XPEvent, XPEvent, QAfterWhere> anyEarnedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'earnedAt'),
      );
    });
  }
}

extension XPEventQueryWhere on QueryBuilder<XPEvent, XPEvent, QWhereClause> {
  QueryBuilder<XPEvent, XPEvent, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<XPEvent, XPEvent, QAfterWhereClause> idNotEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<XPEvent, XPEvent, QAfterWhereClause> idGreaterThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<XPEvent, XPEvent, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<XPEvent, XPEvent, QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerId,
        includeLower: includeLower,
        upper: upperId,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<XPEvent, XPEvent, QAfterWhereClause> earnedAtEqualTo(
      DateTime earnedAt) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'earnedAt',
        value: [earnedAt],
      ));
    });
  }

  QueryBuilder<XPEvent, XPEvent, QAfterWhereClause> earnedAtNotEqualTo(
      DateTime earnedAt) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'earnedAt',
              lower: [],
              upper: [earnedAt],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'earnedAt',
              lower: [earnedAt],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'earnedAt',
              lower: [earnedAt],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'earnedAt',
              lower: [],
              upper: [earnedAt],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<XPEvent, XPEvent, QAfterWhereClause> earnedAtGreaterThan(
    DateTime earnedAt, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'earnedAt',
        lower: [earnedAt],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<XPEvent, XPEvent, QAfterWhereClause> earnedAtLessThan(
    DateTime earnedAt, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'earnedAt',
        lower: [],
        upper: [earnedAt],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<XPEvent, XPEvent, QAfterWhereClause> earnedAtBetween(
    DateTime lowerEarnedAt,
    DateTime upperEarnedAt, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'earnedAt',
        lower: [lowerEarnedAt],
        includeLower: includeLower,
        upper: [upperEarnedAt],
        includeUpper: includeUpper,
      ));
    });
  }
}

extension XPEventQueryFilter
    on QueryBuilder<XPEvent, XPEvent, QFilterCondition> {
  QueryBuilder<XPEvent, XPEvent, QAfterFilterCondition> amountEqualTo(
      int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'amount',
        value: value,
      ));
    });
  }

  QueryBuilder<XPEvent, XPEvent, QAfterFilterCondition> amountGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'amount',
        value: value,
      ));
    });
  }

  QueryBuilder<XPEvent, XPEvent, QAfterFilterCondition> amountLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'amount',
        value: value,
      ));
    });
  }

  QueryBuilder<XPEvent, XPEvent, QAfterFilterCondition> amountBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'amount',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<XPEvent, XPEvent, QAfterFilterCondition> descriptionEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<XPEvent, XPEvent, QAfterFilterCondition> descriptionGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<XPEvent, XPEvent, QAfterFilterCondition> descriptionLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<XPEvent, XPEvent, QAfterFilterCondition> descriptionBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'description',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<XPEvent, XPEvent, QAfterFilterCondition> descriptionStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<XPEvent, XPEvent, QAfterFilterCondition> descriptionEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<XPEvent, XPEvent, QAfterFilterCondition> descriptionContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<XPEvent, XPEvent, QAfterFilterCondition> descriptionMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'description',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<XPEvent, XPEvent, QAfterFilterCondition> descriptionIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'description',
        value: '',
      ));
    });
  }

  QueryBuilder<XPEvent, XPEvent, QAfterFilterCondition>
      descriptionIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'description',
        value: '',
      ));
    });
  }

  QueryBuilder<XPEvent, XPEvent, QAfterFilterCondition> earnedAtEqualTo(
      DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'earnedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<XPEvent, XPEvent, QAfterFilterCondition> earnedAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'earnedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<XPEvent, XPEvent, QAfterFilterCondition> earnedAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'earnedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<XPEvent, XPEvent, QAfterFilterCondition> earnedAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'earnedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<XPEvent, XPEvent, QAfterFilterCondition> idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<XPEvent, XPEvent, QAfterFilterCondition> idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<XPEvent, XPEvent, QAfterFilterCondition> idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<XPEvent, XPEvent, QAfterFilterCondition> idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension XPEventQueryObject
    on QueryBuilder<XPEvent, XPEvent, QFilterCondition> {}

extension XPEventQueryLinks
    on QueryBuilder<XPEvent, XPEvent, QFilterCondition> {}

extension XPEventQuerySortBy on QueryBuilder<XPEvent, XPEvent, QSortBy> {
  QueryBuilder<XPEvent, XPEvent, QAfterSortBy> sortByAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'amount', Sort.asc);
    });
  }

  QueryBuilder<XPEvent, XPEvent, QAfterSortBy> sortByAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'amount', Sort.desc);
    });
  }

  QueryBuilder<XPEvent, XPEvent, QAfterSortBy> sortByDescription() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.asc);
    });
  }

  QueryBuilder<XPEvent, XPEvent, QAfterSortBy> sortByDescriptionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.desc);
    });
  }

  QueryBuilder<XPEvent, XPEvent, QAfterSortBy> sortByEarnedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'earnedAt', Sort.asc);
    });
  }

  QueryBuilder<XPEvent, XPEvent, QAfterSortBy> sortByEarnedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'earnedAt', Sort.desc);
    });
  }
}

extension XPEventQuerySortThenBy
    on QueryBuilder<XPEvent, XPEvent, QSortThenBy> {
  QueryBuilder<XPEvent, XPEvent, QAfterSortBy> thenByAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'amount', Sort.asc);
    });
  }

  QueryBuilder<XPEvent, XPEvent, QAfterSortBy> thenByAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'amount', Sort.desc);
    });
  }

  QueryBuilder<XPEvent, XPEvent, QAfterSortBy> thenByDescription() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.asc);
    });
  }

  QueryBuilder<XPEvent, XPEvent, QAfterSortBy> thenByDescriptionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.desc);
    });
  }

  QueryBuilder<XPEvent, XPEvent, QAfterSortBy> thenByEarnedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'earnedAt', Sort.asc);
    });
  }

  QueryBuilder<XPEvent, XPEvent, QAfterSortBy> thenByEarnedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'earnedAt', Sort.desc);
    });
  }

  QueryBuilder<XPEvent, XPEvent, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<XPEvent, XPEvent, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }
}

extension XPEventQueryWhereDistinct
    on QueryBuilder<XPEvent, XPEvent, QDistinct> {
  QueryBuilder<XPEvent, XPEvent, QDistinct> distinctByAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'amount');
    });
  }

  QueryBuilder<XPEvent, XPEvent, QDistinct> distinctByDescription(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'description', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<XPEvent, XPEvent, QDistinct> distinctByEarnedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'earnedAt');
    });
  }
}

extension XPEventQueryProperty
    on QueryBuilder<XPEvent, XPEvent, QQueryProperty> {
  QueryBuilder<XPEvent, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<XPEvent, int, QQueryOperations> amountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'amount');
    });
  }

  QueryBuilder<XPEvent, String, QQueryOperations> descriptionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'description');
    });
  }

  QueryBuilder<XPEvent, DateTime, QQueryOperations> earnedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'earnedAt');
    });
  }
}
