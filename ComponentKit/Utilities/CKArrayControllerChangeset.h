/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import <map>
#import <set>
#import <vector>

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import <ComponentKit/CKArrayControllerChangeType.h>
#import <ComponentKit/CKMacros.h>
#import <ComponentKit/ComponentUtilities.h>

/**
 CKSectionedArrayController is mutated via an -applyChanges: method which takes an CKArrayControllerInputChangeset
 and returns an CKArrayControllerOutputChangeset.

 The input is a list of commands to apply to the array controller: insert this section, update this object, etc. While
 the output can be enumerated such that the changes can be applied to a UITableView or UICollectionView.

 In order for changes to be "UI{Table|Collection|}View compliant" the index paths for updates and removals (of both
 sections and items) should be relative to the initial state of the array controller, while insertions should be
 relative to the state **after** removals have been applied. CKSectionedArrayController is written with the same
 constraints. In doing so we don't need to do any index-munging while were inserting or removing items or sections.
 */

namespace CK {

  namespace ArrayController {

    /**
     More concise than using NSIndexPaths all over the place, and doesn't require heap allocations.
     */
    struct IndexPath {
      NSInteger section;
      NSInteger item;

      IndexPath(void) : section(NSNotFound), item(NSNotFound) {};

      IndexPath(NSInteger s, NSInteger i) : section(s), item(i) {};

      IndexPath(NSIndexPath *indexPath) : section(indexPath ? [indexPath section] : NSNotFound), item(indexPath ? [indexPath item] : NSNotFound) {};

      NSIndexPath *toNSIndexPath(void) const NS_RETURNS_RETAINED {
        const NSUInteger indexes[] = {(NSUInteger)section, (NSUInteger)item};
        return [[NSIndexPath alloc] initWithIndexes:indexes length:CK_ARRAY_COUNT(indexes)];
      }

      bool operator==(const IndexPath &other) const {
        return section == other.section && item == other.item;
      }

      bool operator<(const IndexPath &other) const {
        if (section < other.section) {
          return true;
        }
        if (section == other.section) {
          return item < other.item;
        }
        return false;
      }
    };

    class Sections final {
    public:
      ~Sections();
      void insert(NSInteger index);
      void remove(NSInteger index);
      void move(NSInteger fromIndex, NSInteger toIndex);

      const std::set<NSInteger> &insertions(void) const;
      const std::set<NSInteger> &removals(void) const;
      const std::set<std::pair<NSInteger, NSInteger>> &moves() const;

      bool operator==(const Sections &other) const;

      size_t size() const noexcept;

      /**
       Called by Changeset::enumerate(). Note that by passing an NSIndexSet the **order** that clients have called
       Sections::insert() is irrelevant. See CKArrayControllerInputChangesetTests for an example.
       */
      typedef void(^Enumerator)(NSIndexSet *sourceIndexes,
                                NSIndexSet *destinationIndexes,
                                CKArrayControllerChangeType type,
                                BOOL *stop);

      typedef NSInteger (^Mapper)(const NSInteger sectionIndex, CKArrayControllerChangeType type);

      Sections mapIndex(Mapper mapper) const;

      NSString *description() const {
        return [NSString stringWithFormat:@"Inserted sections: %@\nRemoved sections: %@\nMoved sections: %@", stringFromSet(this->insertions()), stringFromSet(this->removals()), stringFromSet(this->moves())];
      }

    private:
      std::set<NSInteger> _insertions;
      std::set<NSInteger> _removals;
      std::set<std::pair<NSInteger, NSInteger>> _moves;

      NSString *stringFromSet(std::set<NSInteger> set) const {
        if (set.size() == 0) {
          return @"";
        }

        NSMutableString *setString = [NSMutableString new];
        for (NSInteger entry : set) {
          [setString appendString:[NSString stringWithFormat:@"%ld, ", (long)entry]];
        }
        return [setString length] > 0 ? [setString substringToIndex:([setString length] - 2)] : @"";
      }

      NSString *stringFromSet(std::set<std::pair<NSInteger, NSInteger>> set) const {
        if (set.size() == 0) {
          return @"";
        }

        NSMutableString *setString = [NSMutableString new];
        for (std::pair<NSInteger, NSInteger> entry : set) {
          [setString appendString:[NSString stringWithFormat:@"%ld->%ld, ", (long)(entry.first), (long)(entry.second)]];
        }
        return [setString substringToIndex:([setString length] - 2)];
      }
    };

  }
}

typedef CK::ArrayController::IndexPath CKArrayControllerIndexPath;
typedef CK::ArrayController::Sections CKArrayControllerSections;

namespace CK {

  namespace ArrayController {

    namespace Input {

      /**
       Describes the insertions, removal and update commands for items in an CKSectionedArrayController.
       */
      class Items final {
      public:
        ~Items();
        void update(const CKArrayControllerIndexPath &indexPath, id<NSObject> object);
        void remove(const CKArrayControllerIndexPath &indexPath);
        void insert(const CKArrayControllerIndexPath &indexPath, id<NSObject> object);
        void move(const CKArrayControllerIndexPath &fromIndexPath, const CKArrayControllerIndexPath &toIndexPath);
        typedef std::map<NSInteger, id<NSObject>> ItemIndexToObjectMap;
        typedef std::map<NSInteger, ItemIndexToObjectMap> ItemsBucketizedBySection;

        typedef void (^UpdatesEnumerator)(NSInteger section, NSInteger index, id<NSObject> object, BOOL *stop);
        typedef void (^RemovalsEnumerator)(NSInteger section, NSInteger index, BOOL *stop);
        typedef void (^InsertionsEnumerator)(NSInteger section, NSInteger index, id<NSObject> object, BOOL *stop);
        typedef void (^MovesEnumerator)(const CKArrayControllerIndexPath &fromIndexPath, const CKArrayControllerIndexPath &toIndexPath, BOOL *stop);
        /**
         Each set of items is guaranteed to be enumerated in ascending order based on index path.
         For example, following code

         Items items;
         items.remove({2,4});
         items.remove({2,3});
         items.remove({1,18});

         would result in removalsBlock being called with index paths in this order during enumeration: {1,18}, {2,3}, {2,4}.
         */
        void enumerateItems(UpdatesEnumerator updatesBlock, RemovalsEnumerator removalsBlock, InsertionsEnumerator insertionsBlock, MovesEnumerator movesBlock) const;

        size_t size() const noexcept;

        bool operator==(const Items &other) const;

        NSString *description() const {
          NSMutableString *changesetString = [NSMutableString new];

          this->enumerateItems(
                               ^(NSInteger section, NSInteger index, id<NSObject> object, BOOL *stop) {
                                 [changesetString appendString:[NSString stringWithFormat:@"Update: {%ld,%ld} -> %@\n", (long)section, (long)index, object]];
                               },
                               ^(NSInteger section, NSInteger index, BOOL *stop) {
                                 [changesetString appendString:[NSString stringWithFormat:@"Removal: {%ld,%ld}\n", (long)section, (long)index]];
                               },
                               ^(NSInteger section, NSInteger index, id<NSObject> object, BOOL *stop) {
                                 [changesetString appendString:[NSString stringWithFormat:@"Insertion: {%ld,%ld} -> %@\n", (long)section, (long)index, object]];
                               },
                               ^(const CKArrayControllerIndexPath &fromIndexPath, const CKArrayControllerIndexPath &toIndexPath, BOOL *stop) {
                                 [changesetString appendString:[NSString stringWithFormat:@"Move: {%ld,%ld} -> {%ld,%ld}\n", (long)fromIndexPath.section, (long)fromIndexPath.item, (long)toIndexPath.section, (long)toIndexPath.item]];
                               });

          return changesetString;
        }
      private:
        friend class Changeset;

        void bucketizeObjectBySection(ItemsBucketizedBySection &m, const CKArrayControllerIndexPath &indexPath, id<NSObject> object);
        bool commandExistsForIndexPath(const CKArrayControllerIndexPath &indexPath,
                                       const std::vector<ItemsBucketizedBySection> &bucketsToCheck) const;

        ItemsBucketizedBySection _updates;
        ItemsBucketizedBySection _removals;
        ItemsBucketizedBySection _insertions;
        ItemsBucketizedBySection _moves;
      };

    }
  }
}

typedef CK::ArrayController::Input::Items CKArrayControllerInputItems;

namespace CK {
  
  namespace ArrayController {
    
    namespace Input {
      
      class Changeset final {
      public:
        Changeset(const CKArrayControllerSections &s) : sections(s), items({}) {}
        Changeset(const CKArrayControllerInputItems &i) : sections({}), items(i) {}
        Changeset(const CKArrayControllerSections &s, const CKArrayControllerInputItems &i) : sections(s), items(i) {}
        ~Changeset();
        
        const CKArrayControllerSections sections;
        const CKArrayControllerInputItems items;


        bool operator==(const Changeset &other) const;

        NSString *description() const {
          return [NSString stringWithFormat:@"Sections:\n%@\n\nItems:\n%@\n", sections.description(), items.description()];
        }
      };
    }
  }
}

typedef CK::ArrayController::Input::Changeset CKArrayControllerInputChangeset;

namespace CK {

  namespace ArrayController {

    /**
     Only CKSectionedArrayController (and unit tests) should be constructing these. Client code is solely required to
     call CKArrayControllerOutputChangeset::enumerate() (see below).
     */
    namespace Output {

      struct Change {
        /** Valid for updates and removals. */
        CKArrayControllerIndexPath sourceIndexPath;
        /** Valid for insertions. */
        CKArrayControllerIndexPath destinationIndexPath;

        id<NSObject> before;
        id<NSObject> after;

        Change(const CKArrayControllerIndexPath &sIP, const CKArrayControllerIndexPath &dIP, id<NSObject> b, id<NSObject> a) : sourceIndexPath(sIP), destinationIndexPath(dIP), before(b), after(a) {};

        bool operator==(const Change &other) const {
          return sourceIndexPath == other.sourceIndexPath && destinationIndexPath == other.destinationIndexPath && CKObjectIsEqual(before, other.before) && CKObjectIsEqual(after, other.after);
        }

        NSString *description() const {
          return [NSString stringWithFormat:@"sourceIndexPath: <%zd,%zd>, destinationIndexPath: <%zd,%zd>, before: <%@>, after: <%@>",
                  sourceIndexPath.section, sourceIndexPath.item, destinationIndexPath.section, destinationIndexPath.item, before, after];
        }

      };
    }
  }
}

typedef CK::ArrayController::Output::Change CKArrayControllerOutputChange;

namespace CK {
  
  namespace ArrayController {
    
    namespace Output {

      class Items final {
      public:
        void update(const CKArrayControllerIndexPath &indexPath, id<NSObject> oldObject, id<NSObject> newObject);
        /**
         Note that we pass the removed object here, too. In doing so we can inform clients of what was removed as a
         result of an Input::Changeset
         */
        void remove(const CKArrayControllerIndexPath &indexPath, id<NSObject> object);
        void insert(const CKArrayControllerIndexPath &indexPath, id<NSObject> object);
        void move(const CKArrayControllerIndexPath &fromIndexPath, const CKArrayControllerIndexPath &toIndexPath, id<NSObject> object);

        typedef void(^Enumerator)(const CKArrayControllerOutputChange &change,
                                  CKArrayControllerChangeType type,
                                  BOOL *stop);

        bool operator==(const Items &other) const;

      private:
        friend class Changeset;

        std::vector<Change> _updates;
        std::vector<Change> _removals;
        std::vector<Change> _insertions;
        std::vector<Change> _moves;
      };

    }

  }

}

typedef CK::ArrayController::Output::Items CKArrayControllerOutputItems;

namespace CK {
  
  namespace ArrayController {
    
    namespace Output {
      
      class Changeset final {
      public:
        Changeset(const CKArrayControllerSections &s, const CKArrayControllerOutputItems &i) : _sections(s), _items(i) {};
        
        /**
         Enumerates over section and item changes such that our mutation of a table view and collection view is trivial
         to implement.
         
         We follow a callback order identical to CKArrayControllerInputChangeset::enumerate().
         */
        void enumerate(CKArrayControllerSections::Enumerator sectionsBlock,
                       CKArrayControllerOutputItems::Enumerator itemsBlock) const;
        
        typedef std::pair<id<NSObject>, id<NSObject>> BeforeAfterPair;
        typedef BeforeAfterPair (^Mapper)(const Change &change, CKArrayControllerChangeType type, BOOL *stop);
        
        /**
         Enumerates over all the Change objects in the changeset and invokes Mapper on each. Returns a new instance
         of Changeset.
         
         Returns the receiver if mapper is NULL.
         */
        Changeset map(Mapper mapper) const;
        
        bool operator==(const Changeset &other) const;
        
        const CKArrayControllerSections &getSections(void) const;
        
        NSString *description() const;
        
      private:
        Sections _sections;
        Items _items;
      };
      
    }
    
  }
  
}

typedef CK::ArrayController::Output::Changeset CKArrayControllerOutputChangeset;
