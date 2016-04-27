#!/bin/sh

if [ -z $1 ]; then
  echo "usage: build.sh <subcommand>"
  echo "available subcommands:"
  echo "  ci"
  echo "  docs"
  exit
fi

set -eu

MODE=$1

function ci() {
  xcodebuild \
      -project $1.xcodeproj \
      -scheme $1 \
      -sdk iphonesimulator9.3 \
      -destination "platform=iOS Simulator,OS=8.1,name=iPhone 5" \
      $2
}

if [ "$MODE" = "ci" ]; then
  ci ComponentKit test

  pushd Examples/WildeGuess
  ci WildeGuess build
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
