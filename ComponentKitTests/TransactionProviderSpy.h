/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#ifndef TransactionProviderSpy_h
#define TransactionProviderSpy_h

#include <vector>

struct TransactionProviderSpy {
  using TransactionBlock = void (^)(void);
  using CompletionBlock = void (^)(void);

  auto inTransaction(TransactionBlock t, CompletionBlock c)
  {
    _transactions.push_back(t);
    _completions.push_back(c);
  }

  auto runAllTransactions() const
  {
    for (const auto &t : _transactions) {
      t();
    }
  }

  auto runAllCompletions() const
  {
    for (const auto &c : _completions) {
      c();
    }
  }

  const auto &transactions() const { return _transactions; }
  const auto &completions() const { return _completions; };

private:
  std::vector<TransactionBlock> _transactions;
  std::vector<CompletionBlock> _completions;
};

#endif /* TransactionProviderSpy_h */
