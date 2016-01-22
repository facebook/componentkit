/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import <ComponentKit/CKArrayControllerChangeset.h>

#import <algorithm>
#import <map>

#import <ComponentKit/CKArgumentPrecondition.h>

using namespace CK::ArrayController;

// Explicit destructor to prevent non-trivial destructor inlining.
Sections::~Sections() {}
Input::Items::~Items() {}
Input::Changeset::~Changeset() {}

void Sections::insert(NSInteger index)
{
  CKInternalConsistencyCheckIf(_insertions.find(index) == _insertions.end(),
                               ([NSString stringWithFormat:@"%zd already exists in insertion commands", index]));
  _insertions.insert(index);
}

void Sections::remove(NSInteger index)
{
  CKInternalConsistencyCheckIf(_removals.find(index) == _removals.end(),
                               ([NSString stringWithFormat:@"%zd already exists in removal commands", index]));
  _removals.insert(index);
}

void Sections::move(NSInteger fromIndex, NSInteger toIndex)
{
  auto move = std::make_pair(fromIndex, toIndex);
  CKInternalConsistencyCheckIf(_moves.find(move) == _moves.end(),
                               ([NSString stringWithFormat:@"%zd already exists in move commands", index]));
  _moves.insert(move);
}

const std::set<NSInteger> &Sections::insertions() const
{
  return _insertions;
}

const std::set<NSInteger> &Sections::removals() const
{
  return _removals;
}

const std::set<std::pair<NSInteger, NSInteger>> &Sections::moves() const
{
  return _moves;
}

bool Sections::operator==(const Sections &other) const
{
  return _insertions == other._insertions && _removals == other._removals && _moves == other._moves;
}

size_t Sections::size() const noexcept
{
  return _insertions.size() + _removals.size() + _moves.size();
}

Sections Sections::mapIndex(Sections::Mapper mapper) const
{
  __block Sections mappedSections = {};
  void (^map)(std::set<NSInteger>, CKArrayControllerChangeType) = ^(std::set<NSInteger> indexes, CKArrayControllerChangeType type) {
    for (auto index : indexes) {
      NSInteger newIndex = mapper(index, type);
      if (type == CKArrayControllerChangeTypeInsert) {
        mappedSections.insert(newIndex);
      } else if (type == CKArrayControllerChangeTypeDelete) {
        mappedSections.remove(newIndex);
      }
    }
  };
  map(_insertions, CKArrayControllerChangeTypeInsert);
  map(_removals, CKArrayControllerChangeTypeDelete);
  return mappedSections;
}

/**
 Updates and removals operate in the same index path space, but insertions operate post-application of updates and
 removals. Therefore insertions index paths can alse appear in the commands for removals and updates and vice versa,
 but updates and removals are mututally exclusive.

 Obviously we also check that the same index path does not show up in the same command list. No double insertion of same
 index path, for example.
 */
bool Input::Items::commandExistsForIndexPath(const IndexPath &indexPath,
                                             const std::vector<ItemsBucketizedBySection> &bucketsToCheck) const
{
  bool (^test)(const ItemsBucketizedBySection&) = ^bool(const ItemsBucketizedBySection &sectionMap) {
    auto sectionIt = sectionMap.find(indexPath.section);
    if (sectionIt != sectionMap.end()) { // Section key is in map
      auto &itemMap = sectionIt->second;
      auto itemIt = itemMap.find(indexPath.item);
      return (itemIt != itemMap.end());
    }
    return false;
  };

  for (auto &bucket : bucketsToCheck) {
    if (test(bucket)) {
      return YES;
    }
  }
  return NO;
}

/**
 Inserts the object into `sectionMap`, which ends up looking like this:
 {
  {section0: {item0: object}, {item1: object}},
  {section1: {item0: object}, {item1: object}}
 }
 */
void Input::Items::bucketizeObjectBySection(ItemsBucketizedBySection &sectionMap,
                                            const IndexPath &indexPath,
                                            id<NSObject> object)
{
  const NSInteger section = indexPath.section;
  auto sectionMapIt = sectionMap.find(section);
  if (sectionMapIt == sectionMap.end()) { // Section key not in the map, make a new bucket for the section.
    sectionMap[section] = {
      {indexPath.item, object}
    };
  } else { // Section exists, add the item
    auto &itemMap = sectionMapIt->second;
    itemMap[indexPath.item] = object;
  }
}

void Input::Items::update(const IndexPath &indexPath, id<NSObject> object)
{
  CKInternalConsistencyCheckIf(!commandExistsForIndexPath(indexPath, {_updates, _removals}),
                               ([NSString stringWithFormat:@"{item:%zd, section:%zd} already exists in commands",
                                indexPath.item, indexPath.section]));

  bucketizeObjectBySection(_updates, indexPath, object);
}

void Input::Items::remove(const IndexPath &indexPath)
{
  CKInternalConsistencyCheckIf(!commandExistsForIndexPath(indexPath, {_updates, _removals}),
                               ([NSString stringWithFormat:@"{item:%zd, section:%zd} already exists in commands",
                                indexPath.item, indexPath.section]));

  // We can insert nil in a std::map.
  bucketizeObjectBySection(_removals, indexPath, nil);
}

void Input::Items::insert(const IndexPath &indexPath, id<NSObject> object)
{
  CKInternalConsistencyCheckIf(!commandExistsForIndexPath(indexPath, {_insertions}),
                               ([NSString stringWithFormat:@"{item:%zd, section:%zd} already exists in commands",
                                indexPath.item, indexPath.section]));

  bucketizeObjectBySection(_insertions, indexPath, object);
}

void Input::Items::move(const CKArrayControllerIndexPath &fromIndexPath, const CKArrayControllerIndexPath &toIndexPath)
{
  CKInternalConsistencyCheckIf(!commandExistsForIndexPath(fromIndexPath, {_moves}),
                               ([NSString stringWithFormat:@"{item:%zd, section:%zd} already exists in commands",
                                fromIndexPath.item, fromIndexPath.section]));
  bucketizeObjectBySection(_moves, fromIndexPath, toIndexPath.toNSIndexPath());
}

typedef void (^EnumerationAdapter)(NSInteger section, NSInteger index, id<NSObject> object, BOOL *stop);
static void _iterate(CK::ArrayController::Input::Items::ItemsBucketizedBySection items, EnumerationAdapter ea)
{
  BOOL stop = NO;
  for (const auto &itemsInSection : items) {
    for (const auto &item : itemsInSection.second) {
      ea(itemsInSection.first, item.first, item.second, &stop);
      if (stop) {
        break;
      }
    }
    if (stop) {
      break;
    }
  }
}

void Input::Items::enumerateItems(UpdatesEnumerator updatesEnumerator, RemovalsEnumerator removalsEnumerator, InsertionsEnumerator insertionsEnumerator, MovesEnumerator movesEnumerator) const
{
  if (updatesEnumerator) {
    _iterate(_updates, ^(NSInteger section, NSInteger index, id<NSObject> object, BOOL *stop){
      updatesEnumerator(section, index, object, stop);
    });
  }
  if (removalsEnumerator) {
    _iterate(_removals, ^(NSInteger section, NSInteger index, id<NSObject> object, BOOL *stop){
      removalsEnumerator(section, index, stop);
    });
  }
  if (insertionsEnumerator) {
    _iterate(_insertions, ^(NSInteger section, NSInteger index, id<NSObject> object, BOOL *stop){
      insertionsEnumerator(section, index, object, stop);
    });
  }
  if (movesEnumerator) {
    _iterate(_moves, ^(NSInteger section, NSInteger index, id<NSObject> object, BOOL *stop){
      movesEnumerator({section, index}, (NSIndexPath *)object, stop);
    });
  }
}


size_t Input::Items::size() const noexcept
{
  return _updates.size() + _removals.size() + _insertions.size() + _moves.size();
}

bool Input::Items::operator==(const Items &other) const
{
  return _updates == other._updates && _removals == other._removals && _insertions == other._insertions && _moves == other._moves;
}

bool Input::Changeset::operator==(const Changeset &other) const
{
  return sections == other.sections && items == other.items;
}

void Output::Items::insert(const CKArrayControllerIndexPath &indexPath, id<NSObject> object)
{
  _insertions.push_back({{}, indexPath, nil, object});
}

void Output::Items::remove(const CKArrayControllerIndexPath &indexPath, id<NSObject> object)
{
  _removals.push_back({indexPath, {}, object, nil});
}

void Output::Items::update(const CKArrayControllerIndexPath &indexPath, id<NSObject> oldObject, id<NSObject> newObject)
{
  _updates.push_back({indexPath, {}, oldObject, newObject});
}

void Output::Items::move(const CKArrayControllerIndexPath &fromIndexPath, const CKArrayControllerIndexPath &toIndexPath, id<NSObject> object) {
  _moves.push_back({fromIndexPath, toIndexPath, object, object});
}

bool Output::Items::operator==(const Items &other) const
{
  return _updates == other._updates && _removals == other._removals && _insertions == other._insertions && _moves == other._moves;
}

void Output::Changeset::enumerate(Sections::Enumerator sectionEnumerator,
                                  Items::Enumerator itemEnumerator) const
{
  __block BOOL stop = NO;

  void (^emitSectionChanges)(const std::set<NSInteger>&, CKArrayControllerChangeType) =
  (!sectionEnumerator) ? (void(^)(const std::set<NSInteger>&, CKArrayControllerChangeType))nil :
  ^(const std::set<NSInteger> &s, CKArrayControllerChangeType t){
    if (!s.empty()) {
      NSMutableIndexSet *indexes = [[NSMutableIndexSet alloc] init];
      for (auto section : s) {
        [indexes addIndex:section];
      }
      sectionEnumerator((t == CKArrayControllerChangeTypeDelete ? indexes : nil), (t == CKArrayControllerChangeTypeInsert ? indexes : nil), t, &stop);
    }
  };

  void (^emitSectionMoves)(const std::set<std::pair<NSInteger, NSInteger>>&) =
  (!sectionEnumerator) ? (void(^)(const std::set<std::pair<NSInteger, NSInteger>>&))nil :
  ^(const std::set<std::pair<NSInteger, NSInteger>> &s){
    if (!s.empty()) {
      for (auto move : s) {
        sectionEnumerator([NSIndexSet indexSetWithIndex:move.first], [NSIndexSet indexSetWithIndex:move.second], CKArrayControllerChangeTypeMove, &stop);
      }
    }
  };

  void (^emitItemChanges)(const std::vector<Change>&, CKArrayControllerChangeType) =
  (!itemEnumerator) ? (void(^)(const std::vector<Change>&, CKArrayControllerChangeType))nil :
  ^(const std::vector<Change> &v, CKArrayControllerChangeType t) {
    for (auto change : v) {
      itemEnumerator(change, t, &stop);
      if (stop) { break; }
    }
  };

  if (emitItemChanges) {
    emitItemChanges(_items._updates, CKArrayControllerChangeTypeUpdate);
  }

  if (!stop && emitItemChanges) {
    emitItemChanges(_items._removals, CKArrayControllerChangeTypeDelete);
  }

  if (!stop && emitSectionChanges) {
    emitSectionChanges(_sections.removals(), CKArrayControllerChangeTypeDelete);
  }

  if (!stop && emitSectionChanges) {
    emitSectionChanges(_sections.insertions(), CKArrayControllerChangeTypeInsert);
  }

  if (!stop && emitSectionMoves) {
    emitSectionMoves(_sections.moves());
  }

  if (!stop && emitItemChanges) {
    emitItemChanges(_items._insertions, CKArrayControllerChangeTypeInsert);
  }

  if (!stop && emitItemChanges) {
    emitItemChanges(_items._moves, CKArrayControllerChangeTypeMove);
  }
}

/**
 Clients of Output::Changeset::map() may return invalid pairs. For example {nil, <object>} for a deletion, instead of
 {<object>, nil}.
 */
NS_INLINE void _validateBeforeAfterPair(Output::Changeset::BeforeAfterPair pair, IndexPath sourceIndexPath, IndexPath destinationIndexPath, CKArrayControllerChangeType changeType)
{
  if (changeType == CKArrayControllerChangeTypeUpdate) {
    CKInternalConsistencyCheckIf(pair.first != nil, ([NSString stringWithFormat:@"update {%zd, %zd}: before MUST NOT be nil.", sourceIndexPath.item, sourceIndexPath.section]));
    CKInternalConsistencyCheckIf(pair.second != nil, ([NSString stringWithFormat:@"update {%zd, %zd}: after MUST NOT be nil.", sourceIndexPath.item, sourceIndexPath.section]));
    CKInternalConsistencyCheckIf(!(sourceIndexPath == IndexPath(NSNotFound, NSNotFound)), ([NSString stringWithFormat:@"update MUST have sourceIndexPath"]));
    CKInternalConsistencyCheckIf((destinationIndexPath == IndexPath(NSNotFound, NSNotFound)), ([NSString stringWithFormat:@"update MUST NOT have destinationIndexPath"]));
  } else if (changeType == CKArrayControllerChangeTypeDelete) {
    CKInternalConsistencyCheckIf(pair.first != nil, ([NSString stringWithFormat:@"remove {%zd, %zd}: before MUST NOT be nil.", sourceIndexPath.item, sourceIndexPath.section]));
    CKInternalConsistencyCheckIf(pair.second == nil, ([NSString stringWithFormat:@"remove {%zd, %zd}: after MUST be nil.", sourceIndexPath.item, sourceIndexPath.section]));
    CKInternalConsistencyCheckIf(!(sourceIndexPath == IndexPath(NSNotFound, NSNotFound)), ([NSString stringWithFormat:@"remove MUST have sourceIndexPath"]));
    CKInternalConsistencyCheckIf((destinationIndexPath == IndexPath(NSNotFound, NSNotFound)), ([NSString stringWithFormat:@"remove MUST NOT have destinationIndexPath"]));
  } else if (changeType == CKArrayControllerChangeTypeInsert) {
    CKInternalConsistencyCheckIf(pair.first == nil, ([NSString stringWithFormat:@"insert {%zd, %zd}: before MUST be nil.", destinationIndexPath.item, destinationIndexPath.section]));
    CKInternalConsistencyCheckIf(pair.second != nil, ([NSString stringWithFormat:@"insert {%zd, %zd}: after MUST NOT be nil.", destinationIndexPath.item, destinationIndexPath.section]));
    CKInternalConsistencyCheckIf((sourceIndexPath == IndexPath(NSNotFound, NSNotFound)), ([NSString stringWithFormat:@"insert MUST NOT have sourceIndexPath"]));
    CKInternalConsistencyCheckIf(!(destinationIndexPath == IndexPath(NSNotFound, NSNotFound)), ([NSString stringWithFormat:@"insert MUST have destinationIndexPath"]));
  }
}

Output::Changeset Output::Changeset::map(Mapper mapper) const
{
  if (!mapper) {
    return *this;
  }

  __block BOOL stop = NO;
  __block Output::Items mappedItems;

  void(^map)(const std::vector<Change>&, CKArrayControllerChangeType) =
  ^(const std::vector<Change> &changes, CKArrayControllerChangeType t) {
    for (const auto &change : changes) {
      auto mappedPair = mapper(change, t, &stop);

      _validateBeforeAfterPair(mappedPair, change.sourceIndexPath, change.destinationIndexPath, t);

      if (t == CKArrayControllerChangeTypeUpdate) {
        mappedItems.update(change.sourceIndexPath, mappedPair.first, mappedPair.second);
      }
      if (t == CKArrayControllerChangeTypeDelete) {
        mappedItems.remove(change.sourceIndexPath, mappedPair.first);
      }
      if (t == CKArrayControllerChangeTypeInsert) {
        mappedItems.insert(change.destinationIndexPath, mappedPair.second);
      }
      if (t == CKArrayControllerChangeTypeMove) {
        mappedItems.move(change.sourceIndexPath, change.destinationIndexPath, mappedPair.second);
      }
      if (stop) {
        break;
      }
    }
  };

  map(_items._removals, CKArrayControllerChangeTypeDelete);
  if (!stop) {
    map(_items._updates, CKArrayControllerChangeTypeUpdate);
  }
  if (!stop) {
    map(_items._insertions, CKArrayControllerChangeTypeInsert);
  }
  if (!stop) {
    map(_items._moves, CKArrayControllerChangeTypeMove);
  }

  return {_sections, mappedItems};
}

bool Output::Changeset::operator==(const Changeset &other) const
{
  return _sections == other._sections && _items == other._items;
}

const Sections &Output::Changeset::getSections(void) const
{
  return _sections;
}

#pragma mark - Descriptions

NS_INLINE NSString *indexSetDebugString(NSIndexSet *indexSet)
{
  NSMutableString *debugString = [NSMutableString stringWithCapacity:2*indexSet.count-1];
  NSUInteger firstIndex = [indexSet firstIndex];
  [indexSet enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
    if (idx == firstIndex) {
      [debugString appendFormat:@"%tu", idx];
    } else {
      [debugString appendFormat:@",%tu", idx];
    }
  }];
  return debugString;
}

NS_INLINE NSString *changeTypeDescriptionString(CKArrayControllerChangeType type)
{
  switch (type) {
  case CKArrayControllerChangeTypeDelete:
    return @"delete";
  case CKArrayControllerChangeTypeInsert:
    return @"insert";
  case CKArrayControllerChangeTypeUpdate:
    return @"update";
  case CKArrayControllerChangeTypeMove:
    return @"move";
  case CKArrayControllerChangeTypeUnknown:
    return @"unknown_operation";
  }
}

NSString *Output::Changeset::description() const
{
  NSMutableString *debugString = [NSMutableString string];

  Sections::Enumerator sectionsEnumerator = ^(NSIndexSet *sourceIndexes, NSIndexSet *destinationIndexes, CKArrayControllerChangeType type, BOOL *stop) {
    [debugString appendFormat:@"%@_sections => %@%@\n", changeTypeDescriptionString(type), indexSetDebugString(sourceIndexes), indexSetDebugString(destinationIndexes)];
  };

  Output::Items::Enumerator itemsEnumerator =
  ^(const Output::Change &change, CKArrayControllerChangeType type, BOOL *stop) {
    return [debugString appendFormat:@"%@_item => %@\n", changeTypeDescriptionString(type), change.description()];
  };

  this->enumerate(sectionsEnumerator, itemsEnumerator);

  return debugString;
}
