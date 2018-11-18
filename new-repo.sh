#!/bin/bash
set -eu

SCRIPT_NAME=$0

GITHUB_ORG=navikt
REPO_PREFIX=helse-
GRADLE_VERSION=4.10.2

APP_NAME=
DOCKER_IMG_NAME=
REPO_NAME=
PRIVATE_KEY=

function usage {
    >&2 echo "Usage: $SCRIPT_NAME --app APP_NAME [OPTIONS] DST_PATH"
    >&2 echo
    >&2 echo "Options"
    >&2 echo "    --private-key PRIVATE_KEY         Path to GitHub App private key. Repo must exist on GitHub, or else Travis will fail."
    >&2 echo "    --docker-image DOCKER_IMG_NAME    Sets alternate docker image name, defaults to '\$appname'"
    >&2 echo "    --repo REPO_NAME                  Sets alternate repo name, defaults to '${REPO_PREFIX}\$appname'"
    >&2 echo
    >&2 echo "Example: $SCRIPT_NAME --app my-cool-app ."
    >&2 echo "Will create $PWD/${REPO_PREFIX}my-cool-app and init a git project with"
    >&2 echo "remote set to https://github.com/$GITHUB_ORG/${REPO_PREFIX}my-cool-app.git"
    exit 1
}

if [ $# -lt 3 ];
then
    usage
fi

for i in "$@"
do
case $i in
    --private-key)
    PRIVATE_KEY="$2"
    shift
    shift
    ;;
    --app)
    APP_NAME="$2"
    shift
    shift
    ;;
    --docker-image)
    DOCKER_IMG_NAME="$2"
    shift
    shift
    ;;
    --repo)
    REPO_NAME="$2"
    shift
    shift
    ;;
    -h|--help)
    usage
    ;;
esac
done

if [ -z "$APP_NAME" ];
then
    usage
fi

if [ -z "$DOCKER_IMG_NAME" ];
then
    DOCKER_IMG_NAME="$APP_NAME"
fi

if [ -z "$REPO_NAME" ];
then
    REPO_NAME="$REPO_PREFIX$APP_NAME"
fi

DST_PATH="$1"

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

if [ -f "$PRIVATE_KEY" ];
then
    cp "$PRIVATE_KEY" "$DST_PATH/$REPO_NAME/travis/github-app.private-key.pem"
fi

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

if [ -f "./travis/github-app.private-key.pem" ];
then
    travis encrypt-file ./travis/github-app.private-key.pem ./travis/github-app.private-key.pem.enc --add --com --repo "$GITHUB_ORG/$REPO_NAME"
    rm ./travis/github-app.private-key.pem

    git add .travis.yml ./travis/github-app.private-key.pem.enc
fi

# TODO: add travis secret envvars

popd
