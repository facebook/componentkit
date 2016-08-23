#!/bin/sh

if [ -z $1 ]; then
  echo "usage: build.sh <subcommand>"
  echo "available subcommands:"
  echo "  ci"
  echo "  docs"
  exit
fi

BUILDOUTPUTFILTER="tee" # handle xcpretty not being installed, tee will act like a noop
if type xcpretty > /dev/null 2>&1; then
  BUILDOUTPUTFILTER="xcpretty"
fi

set -eu

MODE=$1

function ci() {
  xcodebuild \
    -project $1.xcodeproj \
    -scheme $2 \
    -sdk $3 \
    -destination "$4" \
    $5 \
    | $BUILDOUTPUTFILTER \
    && exit ${PIPESTATUS[0]}
}

function ios_ci() {
  ci $1 $1 iphonesimulator9.3 "platform=iOS Simulator,OS=9.3,name=iPhone 5" $2
}

function tvos_ci() {
  ci $1 $1AppleTV appletvsimulator "platform=tvOS Simulator,OS=9.2,name=Apple TV 1080p" $2
}

if [ "$MODE" = "ci" ]; then
  brew install carthage
  carthage update

  ios_ci ComponentKit test
  tvos_ci ComponentKit test

  pushd Examples/WildeGuess
  ios_ci WildeGuess build
  popd

fi

if [ "$MODE" = "docs" ]; then
  HEADERS=`ls ComponentKit/**/*.h ComponentTextKit/**/*.h`
  rm -rf appledoc

  appledoc \
    --no-create-docset \
    --create-html \
    --exit-threshold 2 \
    --no-repeat-first-par \
    --no-merge-categories \
    --explicit-crossref \
    --warn-missing-output-path \
    --warn-missing-company-id \
    --warn-undocumented-object \
    --warn-undocumented-member \
    --warn-empty-description \
    --warn-unknown-directive \
    --warn-invalid-crossref \
    --warn-missing-arg \
    --project-name ComponentKit \
    --project-company Facebook \
    --company-id "org.componentkit" \
    --output appledoc \
    $HEADERS
fi
