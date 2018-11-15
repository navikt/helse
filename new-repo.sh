#!/bin/bash
set -eu

GITHUB_ORG=navikt
REPO_PREFIX=helse-
GRADLE_VERSION=4.10.2

if [ $# -lt 2 ];
then
    >&2 echo "Usage: $0 APP_NAME DST_PATH [DOCKER_IMG_NAME]"
    >&2 echo 
    >&2 echo "Example: $0 my-cool-app ."
    >&2 echo "Will create $PWD/${REPO_PREFIX}my-cool-app and init a git project with"
    >&2 echo "remote set to https://github.com/$GITHUB_ORG/${REPO_PREFIX}my-cool-app.git"
    exit 1
fi

APP_NAME="$1"
DOCKER_IMG_NAME="$APP_NAME"
REPO_NAME="$REPO_PREFIX$APP_NAME"
DST_PATH="$2"

if [ $# -eq 3 ];
then
    DOCKER_IMG_NAME="$3"
fi

function replaceInFile {
    sed -i.old "s/$1/$2/g" "$3"
    rm "$3.old"
}
function replacePlaceholders {
    replaceInFile '{{REPO_NAME}}' "$REPO_NAME" "$1"
    replaceInFile '{{APP_NAME}}' "$APP_NAME" "$1"
    replaceInFile '{{DOCKER_IMG_NAME}}' "$DOCKER_IMG_NAME" "$1"
}

ORIGIN=https://github.com/$GITHUB_ORG/$REPO_NAME.git
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"

cp -r "$DIR/.new-repo-template" "$DST_PATH/$REPO_NAME"

pushd "$DST_PATH/$REPO_NAME"

replacePlaceholders README.md
replacePlaceholders Dockerfile
replacePlaceholders Makefile
replacePlaceholders naiserator.yaml
replacePlaceholders build.gradle.kts
replacePlaceholders settings.gradle.kts

git init
git remote add origin $ORIGIN

git add .

gradle wrapper --gradle-version $GRADLE_VERSION --distribution-type bin

git add gradle/wrapper/gradle-wrapper.jar gradle/wrapper/gradle-wrapper.properties gradlew gradlew.bat


# TODO: add travis secret envvars + private key file for github app

popd
