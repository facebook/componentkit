/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import <stdlib.h>
#import <pthread.h>

#import <libkern/OSAtomic.h>

#import <ComponentKit/CKAssert.h>

#if defined (__GNUC__)
# define CK_NOTHROW __attribute__ ((nothrow))
#else
# define CK_NOTHROW
#endif

/**
 For use with CK::StaticMutex only.
 */
#define CK_MUTEX_INITIALIZER {PTHREAD_MUTEX_INITIALIZER}
#define CK_MUTEX_RECURSIVE_INITIALIZER {PTHREAD_RECURSIVE_MUTEX_INITIALIZER}

// This MUST always execute, even when assertions are disabled. Otherwise all lock operations become no-ops!
// (To be explicit, do not turn this into an CKAssert, NSAssert, assert(), or any other kind of statement where the
// evaluation of x_ can be compiled out.)
#define CK_THREAD_ASSERT_ON_ERROR(x_) do { \
  _Pragma("clang diagnostic push"); \
  _Pragma("clang diagnostic ignored \"-Wunused-variable\""); \
  volatile int res = (x_); \
  CKCAssert(res == 0, @" %@ returned %d", @#x_, res); \
  _Pragma("clang diagnostic pop"); \
} while (0)


namespace CK {

  template<class T>
  class Locker
  {
    T &_l;

  public:
    Locker (T &l) CK_NOTHROW : _l (l) {
      _l.lock ();
    }

    ~Locker () {
      _l.unlock ();
    }

    // non-copyable.
    Locker(const Locker<T>&) = delete;
    Locker &operator=(const Locker<T>&) = delete;
  };

  struct Mutex
  {
    /// Constructs a non-recursive mutex (the default).
    Mutex () : Mutex (false) {}

    ~Mutex () {
      CK_THREAD_ASSERT_ON_ERROR(pthread_mutex_destroy (&_m));
    }

    Mutex (const Mutex&) = delete;
    Mutex &operator=(const Mutex&) = delete;

    void lock () {
      CK_THREAD_ASSERT_ON_ERROR(pthread_mutex_lock (this->mutex()));
    }

    void unlock () {
      CK_THREAD_ASSERT_ON_ERROR(pthread_mutex_unlock (this->mutex()));
    }

    pthread_mutex_t *mutex () { return &_m; }

  protected:
    explicit Mutex (bool recursive) {
      if (!recursive) {
        CK_THREAD_ASSERT_ON_ERROR(pthread_mutex_init (&_m, NULL));
      } else {
        pthread_mutexattr_t attr;
        CK_THREAD_ASSERT_ON_ERROR(pthread_mutexattr_init (&attr));
        CK_THREAD_ASSERT_ON_ERROR(pthread_mutexattr_settype (&attr, PTHREAD_MUTEX_RECURSIVE));
        CK_THREAD_ASSERT_ON_ERROR(pthread_mutex_init (&_m, &attr));
        CK_THREAD_ASSERT_ON_ERROR(pthread_mutexattr_destroy (&attr));
      }
    }

  private:
    pthread_mutex_t _m;
  };

  typedef Locker<Mutex> MutexLocker;

  /**
   If you are creating a static mutex, use StaticMutex and specify its default value as one of CK_MUTEX_INITIALIZER or
   CK_MUTEX_RECURSIVE_INITIALIZER. This avoids expensive constructor overhead at startup (or worse, ordering issues
   between different static objects). It also avoids running a destructor on app exit time (needless expense).

   Note that you can, but should not, use StaticMutex for non-static objects. It will leak its mutex on destruction,
   so avoid that!

   If you fail to specify a default value (like CK_MUTEX_INITIALIZER) an assert will be thrown when you attempt to lock.
   */
  struct StaticMutex
  {
    pthread_mutex_t _m; // public so it can be provided by CK_MUTEX_INITIALIZER and friends

    void lock () {
      CK_THREAD_ASSERT_ON_ERROR(pthread_mutex_lock (this->mutex()));
    }

    void unlock () {
      CK_THREAD_ASSERT_ON_ERROR(pthread_mutex_unlock (this->mutex()));
    }

    pthread_mutex_t *mutex () { return &_m; }

    StaticMutex(const StaticMutex&) = delete;
    StaticMutex &operator=(const StaticMutex&) = delete;
  };

  typedef Locker<StaticMutex> StaticMutexLocker;

} // namespace CK
