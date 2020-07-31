#!/bin/bash
set -e

# fuksjon som henter ut et github prosjekt for en applikasjon (github prosjekt)
function checkoutNais() {
  NAIS_APP=$1

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
# 1) sjekker og setter input
# 2) sletter eventuell eksisterende mappe og lager ny mappe som brukes til å hente disse prosjektene
# 3) for hvert applikasjonsnavn (github prosjekt)
#    - sjekker ut prosjektet
# 4) setter mappa med <applikasjoner> (full filsti) som output
#
############################################

if [[ $# -eq 0 ]]; then
  echo "Bruk: apps.sh <github project>...<another github project>"
  exit 1;
fi

# shellcheck disable=SC2124
NAIS_APPS=$@

if [[ -d nais-apps ]]; then
  sudo rm -rf nais-apps
fi

mkdir nais-apps
cd nais-apps || exit 1

for app in $NAIS_APPS
do
  checkoutNais "$app"
done

echo ::set-output name=nais-apps-folder::"$PWD/nais-apps"
