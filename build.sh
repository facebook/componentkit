#!/bin/sh

function ci() {
  pod install
  xctool \
      -workspace $1.xcworkspace \
      -scheme $1 \
      -sdk iphonesimulator8.1 \
      -destination "platform=iOS Simulator,OS=8.1,name=iPhone 5" \
      $2
}

set -e

ci ComponentKit test

pushd Examples/WildeGuess
ci WildeGuess build
popd





