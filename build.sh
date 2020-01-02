#!/bin/sh

# Go to root directory of the script
pushd $(dirname $0)

if [ -z $1 ]; then
  echo "usage: build.sh <subcommand>"
  echo "available subcommands:"
  echo "  ci-componentkit-ios"
  echo "  ci-componentkit-tvos"
  echo "  ci-wildeguess-ios"
  echo "  docs"
  exit
fi

set -eu

MODE=$1

function project_version() {
  # get contents -> grep for project version line -> cut string with '=' delimeter, take 2nd value -> trim whitespaces.
  more ComponentKit/ComponentKit.xcconfig | grep "CURRENT_PROJECT_VERSION = [\.0-9]*" | cut -d = -f 2 | xargs echo -n
}

function ci() {
  # replace line contains s.version with a new line contains value of `project_version`.
  sed -i -e "s/s.version = \'[\.0-9]*\'/s.version = \'$(project_version)\'/g" ComponentKit.podspec

  xcodebuild \
    clean \
    -project $1 \
    -scheme $2 \
    -sdk $3 \
    -destination "$4" \
    -configuration $5 \
    $6 \
    -json \
    -UseModernBuildSystem=NO
}

function ios_ci() {
  ci $1 $2 iphonesimulator "platform=iOS Simulator,name=iPhone 8" Release $3
}

function tvos_ci() {
  ci $1 $2 appletvsimulator "platform=tvOS Simulator,name=Apple TV" Release $3
}

function carthage_bootstrap() {
  carthage bootstrap --platform iOS --no-use-binaries || true
}

carthage_bootstrap

if [ "$MODE" = "ci-componentkit-ios" ]; then
  ios_ci ComponentKit.xcodeproj ComponentKit test
fi

if [ "$MODE" = "ci-componentkit-tvos" ]; then
  tvos_ci ComponentKit.xcodeproj ComponentKitAppleTV test
fi

if [ "$MODE" = "ci-wildeguess-ios" ]; then
  ios_ci Examples/WildeGuess/WildeGuess.xcodeproj WildeGuess build
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

# Go back to the initial directory
popd
