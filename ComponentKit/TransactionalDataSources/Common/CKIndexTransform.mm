// Copyright 2004-present Facebook. All Rights Reserved.

#import "CKIndexTransform.h"

#import <algorithm>

auto CK::IndexTransform::applyOffsetToIndex(NSInteger index) const -> NSInteger
{
  const auto maybeRangeOffsetForIdx = std::find_if(_rangeOffsets.begin(), _rangeOffsets.end(), [=](auto r) {
    return NSLocationInRange(index, r.range);
  });
  if (maybeRangeOffsetForIdx != _rangeOffsets.end() && (*maybeRangeOffsetForIdx).offset != NSNotFound) {
    return index + (*maybeRangeOffsetForIdx).offset;
  } else {
    return NSNotFound;
  }
}

auto CK::IndexTransform::findRangeAndApplyOffsetToIndex(NSInteger index) const -> NSInteger
{
  auto nonRemovedIdx = 0;
  for (const auto rangeOffset : _rangeOffsets) {
    if (rangeOffset.offset == NSNotFound) { continue; }

    const auto r = rangeOffset.range;
    for (NSInteger i = r.location; i < NSMaxRange(r); i++) {
      if (index == nonRemovedIdx) {
        return index - rangeOffset.offset;
      }
      nonRemovedIdx += 1;
    }
  }
  return NSNotFound;
}

CK::IndexTransform::IndexTransform(NSIndexSet *const indexes)
{
  if (indexes.count == 0) {
    _rangeOffsets = {{NSMakeRange(0, NSIntegerMax), 0}};
    return;
  }

  __block auto numberOfIndexesRemovedSoFar = 0;
  __block auto lastNonRemovedIdx = 1;
  __block auto isFirstRange = true;
  __block std::vector<RangeOffset> rangeOffsets;
  rangeOffsets.reserve(indexes.count);
  [indexes enumerateRangesUsingBlock:^(NSRange range, BOOL *_Nonnull) {
    if (isFirstRange) {
      isFirstRange = false;
      if (range.location > 0) {
        const auto unaffectedRange = NSMakeRange(0, range.location);
        rangeOffsets.push_back({unaffectedRange, 0});
      }
      rangeOffsets.push_back({range, NSNotFound});
    } else {
      const auto nonRemovedRange = NSMakeRange(lastNonRemovedIdx, range.location - lastNonRemovedIdx);
      rangeOffsets.push_back({nonRemovedRange, -numberOfIndexesRemovedSoFar});
      rangeOffsets.push_back({range, NSNotFound});
    }
    numberOfIndexesRemovedSoFar += range.length;
    lastNonRemovedIdx = static_cast<int>(NSMaxRange(range));
  }];
  const auto lastRange = NSMakeRange(lastNonRemovedIdx, NSIntegerMax);
  rangeOffsets.push_back({lastRange, -numberOfIndexesRemovedSoFar});
  _rangeOffsets = rangeOffsets;
}
