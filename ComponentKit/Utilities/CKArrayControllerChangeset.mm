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

const std::set<NSInteger> &Sections::insertions() const
{
  return _insertions;
}

const std::set<NSInteger> &Sections::removals() const
{
  return _removals;
}

bool Sections::operator==(const Sections &other) const
{
  return _insertions == other._insertions && _removals == other._removals;
}

size_t Sections::size() const noexcept
{
  return _insertions.size() + _removals.size();
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
  CKInternalConsistencyCheckIf(!commandExistsForIndexPath(indexPath, {_updates, _removals, _insertions}),
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
  CKInternalConsistencyCheckIf(!commandExistsForIndexPath(indexPath, {_insertions, _updates}),
                               ([NSString stringWithFormat:@"{item:%zd, section:%zd} already exists in commands",
                                indexPath.item, indexPath.section]));

  bucketizeObjectBySection(_insertions, indexPath, object);
}

size_t Input::Items::size() const noexcept
{
  return _updates.size() + _removals.size() + _insertions.size();
}

bool Input::Items::operator==(const Items &other) const
{
  return _updates == other._updates && _removals == other._removals && _insertions == other._insertions;
}

typedef std::pair<IndexPath, id<NSObject>> IndexPathObjectPair;

/**
 1) item updates
 2) item removals
 3) section removals
 4) section insertions
 5) item insertions
 */
void Input::Changeset::enumerate(Sections::Enumerator sectionEnumerator,
                                 Items::Enumerator itemEnumerator) const
{
  __block BOOL stop = NO;

  void (^emitSectionChanges)(const std::set<NSInteger>&, CKArrayControllerChangeType) =
  (!sectionEnumerator) ? (void(^)(const std::set<NSInteger>&, CKArrayControllerChangeType))nil :
  ^(const std::set<NSInteger> &s, CKArrayControllerChangeType t) {
    if (!s.empty()) {
      NSMutableIndexSet *indexes = [[NSMutableIndexSet alloc] init];
      for (auto section : s) {
        [indexes addIndex:section];
      }
      sectionEnumerator(indexes, t, &stop);
    }
  };

  void (^emitItemChanges)(const Items::ItemsBucketizedBySection&, CKArrayControllerChangeType) =
  (!itemEnumerator) ? (void(^)(const Items::ItemsBucketizedBySection&, CKArrayControllerChangeType))nil :
  ^(const Items::ItemsBucketizedBySection &m, CKArrayControllerChangeType t) {
    for (auto sectionToBucket : m) {
      NSMutableIndexSet *indexes = [[NSMutableIndexSet alloc] init];
      NSMutableArray *objects = (t == CKArrayControllerChangeTypeDelete) ? nil : [[NSMutableArray alloc] init];
      for (auto itemObjectPair : sectionToBucket.second) {
        [indexes addIndex:itemObjectPair.first];
        [objects addObject:itemObjectPair.second];
      }
      itemEnumerator(sectionToBucket.first, indexes, objects, t, &stop);
      if (stop) {
        break;
      }
    }
  };

  if (emitItemChanges) {
    emitItemChanges(items._updates, CKArrayControllerChangeTypeUpdate);
  }

  if (!stop && emitItemChanges) {
    emitItemChanges(items._removals, CKArrayControllerChangeTypeDelete);
  }

  if (!stop && emitSectionChanges) {
    emitSectionChanges(sections.removals(), CKArrayControllerChangeTypeDelete);
  }

  if (!stop && emitSectionChanges) {
    emitSectionChanges(sections.insertions(), CKArrayControllerChangeTypeInsert);
  }

  if (!stop && emitItemChanges) {
    emitItemChanges(items._insertions, CKArrayControllerChangeTypeInsert);
  }
}

Input::Changeset Input::Changeset::_map(Mapper objectMapper, Sections::Mapper sectionIndexMapper, ItemIndexPathMapper indexPathMapper) const
{
  if (!objectMapper && !sectionIndexMapper && !indexPathMapper) {
    return *this;
  }
  
  __block BOOL stop = NO;
  __block Input::Items mappedItems;
  
  void (^map)(const Items::ItemsBucketizedBySection&, CKArrayControllerChangeType) =
  ^(const Items::ItemsBucketizedBySection &m, CKArrayControllerChangeType t) {
    for (auto sectionToBucket : m) {
      for (auto itemObjectPair : sectionToBucket.second) {
        const IndexPath originalIndexPath = {sectionToBucket.first, itemObjectPair.first};
        id<NSObject> mappedObject = objectMapper ? objectMapper(originalIndexPath, itemObjectPair.second, t, &stop) : itemObjectPair.second;
        IndexPath mappedIndexPath = indexPathMapper ? indexPathMapper(originalIndexPath, t) : originalIndexPath;
        
        if (t != CKArrayControllerChangeTypeDelete) {
          CKInternalConsistencyCheckIf(mappedObject != nil, @"");
        }
        
        switch (t) {
          case CKArrayControllerChangeTypeInsert:
            mappedItems.insert(mappedIndexPath, mappedObject);
            break;
          case CKArrayControllerChangeTypeDelete:
            if (indexPathMapper) {
              mappedItems.remove(mappedIndexPath);
            }
            break;
          case CKArrayControllerChangeTypeUpdate:
            mappedItems.update(mappedIndexPath, mappedObject);
            break;
          case CKArrayControllerChangeTypeMove:
          case CKArrayControllerChangeTypeUnknown:
            break;
        }
      }
      if (stop) {
        break;
      }
    }
  };
  
  if (!indexPathMapper) {
    // Removals are just index paths. No need to enumerate these, just copy over.
    mappedItems._removals = items._removals;
  } else {
    map(items._removals, CKArrayControllerChangeTypeDelete);
  }
  
  map(items._updates, CKArrayControllerChangeTypeUpdate);
  if (!stop) {
    map(items._insertions, CKArrayControllerChangeTypeInsert);
  }
  
  Sections mappedSections = sectionIndexMapper ? sections.mapIndex(sectionIndexMapper) : sections;
  return {mappedSections, mappedItems};
}

Input::Changeset Input::Changeset::map(Mapper mapper) const
{
  return _map(mapper, nil, nil);
}

Input::Changeset Input::Changeset::mapIndex(Sections::Mapper sectionIndexMapper, ItemIndexPathMapper itemIndexMapper) const
{
  return _map(nil, sectionIndexMapper, itemIndexMapper);
}

bool Input::Changeset::operator==(const Changeset &other) const
{
  return sections == other.sections && items == other.items;
}

void Output::Items::insert(const Pair &insertion)
{
  _insertions.push_back({insertion.indexPath, nil, insertion.object});
}

void Output::Items::remove(const Pair &removal)
{
  _removals.push_back({removal.indexPath, removal.object, nil});
}

void Output::Items::update(const Change &update)
{
  _updates.push_back(update);
}

bool Output::Items::operator==(const Items &other) const
{
  return _updates == other._updates && _removals == other._removals && _insertions == other._insertions;
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
      sectionEnumerator(indexes, t, &stop);
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

  if (!stop && emitItemChanges) {
    emitItemChanges(_items._insertions, CKArrayControllerChangeTypeInsert);
  }
}

/**
 Clients of Output::Changeset::map() may reuturn invalid pairs. For example {nil, <object>} for a deletion, instead of
 {<object>, nil}.
 */
NS_INLINE void _validateBeforeAfterPair(Output::Changeset::BeforeAfterPair pair, IndexPath indexPath, CKArrayControllerChangeType changeType)
{
  if (changeType == CKArrayControllerChangeTypeUpdate) {
    CKInternalConsistencyCheckIf(pair.first != nil, ([NSString stringWithFormat:@"update {%zd, %zd}: before MUST NOT be nil.", indexPath.item, indexPath.section]));
    CKInternalConsistencyCheckIf(pair.second != nil, ([NSString stringWithFormat:@"update {%zd, %zd}: after MUST NOT be nil.", indexPath.item, indexPath.section]));
  } else if (changeType == CKArrayControllerChangeTypeDelete) {
    CKInternalConsistencyCheckIf(pair.first != nil, ([NSString stringWithFormat:@"remove {%zd, %zd}: before MUST NOT be nil.", indexPath.item, indexPath.section]));
    CKInternalConsistencyCheckIf(pair.second == nil, ([NSString stringWithFormat:@"remove {%zd, %zd}: after MUST be nil.", indexPath.item, indexPath.section]));
  } else if (changeType == CKArrayControllerChangeTypeInsert) {
    CKInternalConsistencyCheckIf(pair.first == nil, ([NSString stringWithFormat:@"insert {%zd, %zd}: before MUST be nil.", indexPath.item, indexPath.section]));
    CKInternalConsistencyCheckIf(pair.second != nil, ([NSString stringWithFormat:@"insert {%zd, %zd}: after MUST NOT be nil.", indexPath.item, indexPath.section]));
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

      _validateBeforeAfterPair(mappedPair, change.indexPath, t);

      if (t == CKArrayControllerChangeTypeUpdate) {
        mappedItems.update({change.indexPath, mappedPair.first, mappedPair.second});
      }
      if (t == CKArrayControllerChangeTypeDelete) {
        mappedItems.remove({change.indexPath, mappedPair.first});
      }
      if (t == CKArrayControllerChangeTypeInsert) {
        mappedItems.insert({change.indexPath, mappedPair.second});
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

  Sections::Enumerator sectionsEnumerator = ^(NSIndexSet *sectionIndexes, CKArrayControllerChangeType type, BOOL *stop) {
    [debugString appendFormat:@"%@_sections => %@\n", changeTypeDescriptionString(type), indexSetDebugString(sectionIndexes)];
  };

  Output::Items::Enumerator itemsEnumerator =
  ^(const Output::Change &change, CKArrayControllerChangeType type, BOOL *stop) {
    return [debugString appendFormat:@"%@_item => %@\n", changeTypeDescriptionString(type), change.description()];
  };

  this->enumerate(sectionsEnumerator, itemsEnumerator);

  return debugString;
}
