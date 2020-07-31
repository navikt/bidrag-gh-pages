#!/bin/bash
set -x

# funksjon som skriver ut hvordan bruk er
function usage() {
  echo Navngi apps som json: apps.sh '{"apps":["github project","another github project","..."]}'
}

# fuksjon som henter ut et github prosjekt for en applikasjon (github prosjekt)
function checkoutNais() {
  NAIS_APP=$(echo "$1" | sed 's/"//g')

  if [[ "$GITHUB_REF" != "refs/heads/master" ]]; then
    FEATURE_BRANCH=${GITHUB_REF#refs/heads/}
    # shellcheck disable=SC2046
    IS_POSSIBLE_API_CHANGE=$(git ls-remote --heads $(echo "https://github.com/navikt/$NAIS_APP $FEATURE_BRANCH" | sed "s/'//g") | wc -l)

    if [[ $IS_POSSIBLE_API_CHANGE -eq 1 ]]; then
      echo "Using feature branch: $FEATURE_BRANCH"
      git clone --depth 1 --branch="$FEATURE_BRANCH" "https://${GITHUB_ACTOR}:${GITHUB_TOKEN}@github.com/navikt/$NAIS_APP"
    else
      git clone --depth 1 "https://${GITHUB_ACTOR}:${GITHUB_TOKEN}@github.com/navikt/$NAIS_APP"
    fi
  else
    git clone --depth 1 "https://${GITHUB_ACTOR}:${GITHUB_TOKEN}@github.com/navikt/$NAIS_APP"
  fi
}

############################################
#
# Følgende forutsetninger for dette skriptet
# - input til skriptet er applikasjonsnavn (github prosjekt navn)
#
# Følgende skjer i dette skriptet:
# 1) sjekker at vi har input argument
# 2) sletter eventuell eksisterende mappe og lager ny mappe som brukes til å hente disse prosjektene
# 3) lagrer input som fil og parser denne som json med jq
# 4) for hvert applikasjonsnavn (github prosjekt)
#    - sjekker ut prosjektet
# 5) setter mappa med <applikasjoner> (full filsti) som output
#
############################################

if [[ $# -ne 1 ]]; then
  usage
  exit 1;
fi


if [[ -d nais-apps ]]; then
  sudo rm -rf nais-apps
fi

mkdir nais-apps
cd nais-apps || exit 1

echo "$1" > json
NAIS_APPS=$(jq '.apps[]' json)

if [[ -z "$NAIS_APPS" ]]; then
  usage
  exit 1
fi

for app in $NAIS_APPS
do
  checkoutNais "$app"
done

echo ::set-output name=nais-apps-folder::"$PWD/nais-apps"
