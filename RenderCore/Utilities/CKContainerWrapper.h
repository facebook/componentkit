#import <RenderCore/CKDefines.h>

#if CK_NOT_SWIFT

#pragma once

#include <initializer_list>
#include <vector>
#include <unordered_map>

/**
 * Helper class that's useful for function parameters that's likely to take
 * initializer lists as input. It prevents inlined vector construction.
 *
 * For a function of the form: `foo(const std::vector<int> &)`,
 *   invoked with an initializer list: `foo({1,2,3})`,
 *   code is generated to construct and destroy a vector from that initializer
 *   list, usually inlined into the body of the function.
 * For a function of the form: `foo(CKContainerWrapper<std::vector<int>> &&)`,
 *   invoked with an initializer list: `foo({1,2,3})`,
 *   the vector constructor and destructor are not inlined. This lack of
 *   inlining helps reduce the size of the compiled output.
 *
 * Additionally, this type allows vector to be moved in, as if the parameter
 *   has a rvalue-reference overload (e.g. `foo(std::vector<int> &&)`). In ObjC++
 *   methods, where overloads are not allowed, this gives the benefit of a
 *   rvalue-reference overload at the cost of an additional move operation.
 */
template<class Container>
class CKContainerWrapper {
public:
  CKContainerWrapper() {}
  CKContainerWrapper(std::initializer_list<typename Container::value_type> items) : _container(items) {}
  CKContainerWrapper(Container &&container) : _container(std::move(container)) {}
  CKContainerWrapper(const Container &container) : _container(container) {}
  CKContainerWrapper(const CKContainerWrapper<Container> &) = delete;
  CKContainerWrapper(CKContainerWrapper<Container> &&) = default;
  ~CKContainerWrapper() = default;

  Container take() { return std::move(_container); }

private:
  Container _container;
};

#endif
