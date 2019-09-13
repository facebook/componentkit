/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#pragma once

#include <type_traits>

namespace CK {
namespace BuilderDetails {
namespace PropBitmap {
template <typename PropId, typename RawType = std::underlying_type_t<PropId>>
static constexpr auto isSet(RawType bitmap, PropId prop) -> bool
{
  return (bitmap & static_cast<RawType>(prop)) != 0;
}

template <typename PropId, typename RawType = std::underlying_type_t<PropId>>
static constexpr auto set(RawType bitmap, PropId prop) -> RawType
{
  return (bitmap | static_cast<RawType>(prop));
}

template <typename PropId> static constexpr auto withIds(PropId propId)
{
  return static_cast<std::underlying_type_t<PropId>>(propId);
}

template <typename PropId, typename... Rest> static constexpr auto withIds(PropId propId, Rest... propIds)
{
  return static_cast<std::underlying_type_t<PropId>>(propId) | withIds(propIds...);
}
}  // namespace PropBitmap
}  // namespace BuilderDetails
}  // namespace CK
