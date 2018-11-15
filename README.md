# Helse

Et slags monorepo for helse.

# Komme i gang

[repo](https://source.android.com/setup/develop/repo) brukes til å sette opp
repositories for alle microservicene. Det kan [installeres
manuelt](https://source.android.com/setup/build/downloading) eller via homebrew

`brew install repo`

Repoet settes opp slik (bytt ut https med ssh om du vil pushe/pulle med ssh):

```
mkdir monorepo
cd monorepo
repo init -u https://github.com/navikt/helse.git
repo sync
repo start master --all
```

Nå kan git brukes som normalt for hvert repo.

## Nye repo

Når man legger til nye repo i `default.xml` må man først synce endringene:

`repo sync`

Deretter må man sørge for å tracke master-branchen i det nye repoet:

`cd new-repo && repo start master .`

## Opprette nye repo

Man kan bruke `new-repo.sh` for å komme kjapt i gang med å opprette nye repo:

```
./new-repo.sh min-app .
```

Dette vil opprette et nytt repo kalt `helse-min-app` i gjeldende katalog.

Docker imaget vil bli kalt `navikt/min-app`, men kan styres ved å legge til et argument på cli:

```
./new-repo.sh min-app . mitt-image-navn
```

Docker image vil nå hete `navikt/mitt-image-navn`.

Det eneste som mangler er å legge til secrets i `.travis.yml`:

```
travis encrypt-file ./travis/github-app.private-key.pem ./travis/github-app.private-key.pem.enc --add --com
travis encrypt DOCKER_USERNAME=brukernavn --add --com
travis encrypt DOCKER_PASSWORD=passord --add --com
travis encrypt GITHUB_APP=appId --add --com
```

# Henvendelser

Spørsmål knyttet til koden eller prosjektet kan stilles som issues her på GitHub.

## For NAV-ansatte

Interne henvendelser kan sendes via Slack i kanalen #område-helse.
