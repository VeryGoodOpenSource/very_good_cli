#!/bin/bash

# Ensures that the package is ready for a release.
# 
# Will update the version.dart file and update the CHANGELOG.md.
#
# Set it up for a new version:
# `./release_ready.sh <version>

# Check if current directory is usable for this script, if so we assume it is correctly set up.
if [ ! -f "pubspec.yaml" ] && [ ! -f "brick.yaml" ] && [ ! -f "package.json" ]; then
  echo "$(pwd) is not a valid (dart/npm) package or brick."
  exit 1
fi

currentBranch=$(git symbolic-ref --short -q HEAD)
if [[ ! $currentBranch == "main" ]]; then
 echo "Releasing is only supported on the main branch."
 exit 1
fi

# Get information
old_version=""
if [ -f "pubspec.yaml" ]; then
  old_version=$(dart pub deps --json | pcregrep -o1 -i '"version": "(.*?)"' | head -1)
elif [ -f "brick.yaml" ]; then
  old_version=$(cat brick.yaml | pcregrep 'version: (.*?)' | tr " " "\n" | tail -1)
elif [ -f "package.json" ]; then
  old_version=$(cat package.json | pcregrep -o1 -i '"version": "(.*?)"' | head -1)
fi

if [ -z "$old_version" ]; then
  echo "Current version was not resolved."
  exit 1
fi

# Get new version
new_version="$1";

if [[ "$new_version" == "" ]]; then 
  echo "No new version supplied, please provide one"
  exit 1
fi

if [[ "$new_version" == "$old_version" ]]; then
  echo "Current version is $old_version, can't update."
  exit 1
fi

# Retrieving all the commits in the current directory since the last tag.
previousTag="v${old_version}"
raw_commits="$(git log --pretty=format:"%s" --no-merges --reverse $previousTag..HEAD -- .)"
markdown_commits=$(echo "$raw_commits" | sed -En "s/\(#([0-9]+)\)/([#\1](https:\/\/github.com\/VeryGoodOpenSource\/very_good_cli\/pull\/\1))/p")

if [[ "$markdown_commits" == "" ]]; then
  echo "No commits since last tag, can't update."
  exit 0
fi
commits=$(echo "$markdown_commits" | sed -En "s/^/- /p")

echo "Updating version to $new_version"
if [ -f "pubspec.yaml" ]; then
  sed -i '' "s/version: $old_version/version: $new_version/g" pubspec.yaml
elif [ -f "brick.yaml" ]; then
  sed -i '' "s/version: $old_version/version: $new_version/g" brick.yaml
elif [ -f "package.json" ]; then
  sed -i '' "s/\"version\": \"$old_version\"/\"version\": \"$new_version\"/g" package.json
  npm i
fi

# Update dart file with new version.
dart run build_runner build --delete-conflicting-outputs > /dev/null

if grep -q v$new_version "CHANGELOG.md"; then
  echo "CHANGELOG already contains version $new_version."
  exit 1
fi

# Add a new version entry with the found commits to the CHANGELOG.md.
echo "# ${new_version} \n\n ${commits}\n\n$(cat CHANGELOG.md)" > CHANGELOG.md
echo "CHANGELOG generated, validate entries here: $(pwd)/CHANGELOG.md"

echo "Creating git branch for ver_good_cli@$new_version"
git checkout -b "chore/$new_version" > /dev/null

git add pubspec.yaml CHANGELOG.md 
if [ -f lib/src/version.dart ]; then
  git add lib/src/version.dart
fi

echo ""
echo "Run the following command if you wish to commit the changes:"
echo "git commit -m \"chore: v$new_version\""