# Krateo Challenge: Neon Claimable Postgres Playground

Challenge tecnica per creare un database **Postgres cloud reale** su **Neon** usando **Krateo PlatformOps** e un **Kubernetes Job**.

Questa prima versione è volutamente semplice: **niente OASGen per ora**. Il provisioning avviene tramite un Job creato dal chart Helm.

## Obiettivo

Costruire un blueprint self-service Krateo che permetta a un utente di richiedere un database Postgres cloud compilando pochi campi.

Il chart chiama la Neon Claimable Postgres API:

```http
POST https://neon.new/api/v1/database
```

Questa API crea un database temporaneo gratuito, senza account Neon e senza API key. Il database scade se non viene claimato.

## Architettura

```text
Utente
  ↓
Krateo Portal
  ↓
Composition: NeonPostgresDatabase
  ↓
Krateo Core Provider / CDC
  ↓
Helm chart neon-postgres-database
  ↓
Kubernetes Job
  ↓
Neon Claimable Postgres API
  ↓
Postgres cloud reale
```

## Cosa viene creato localmente

- cluster Kind `krateo-neon-challenge`;
- Krateo nel namespace `krateo-system`;
- namespace workload `neon-demo`;
- ServiceAccount, Role e RoleBinding per il Job;
- Job di provisioning;
- Secret con connection string Neon.

## Cosa viene creato su Neon cloud

- database Postgres Claimable;
- progetto Neon associato;
- connection string;
- claim URL;
- expiration date.

## Form / valori esposti

Il chart espone questi valori:

```yaml
databaseName: krateo-challenge-db
referrer: krateo-challenge-lepera
enableLogicalReplication: false
createConnectionSecret: true
seedSampleData: true
```

## Secret generato

Il Job crea un Secret Kubernetes con:

```text
DATABASE_URL
DATABASE_URL_DIRECT
CLAIM_URL
EXPIRES_AT
NEON_DATABASE_ID
NEON_PROJECT_ID
```

Il Job è idempotente: se il Secret esiste già e contiene `DATABASE_URL`, non crea un nuovo database.

## Prerequisiti

- Docker;
- kind;
- kubectl;
- helm;
- krateoctl;
- accesso internet dal cluster verso `https://neon.new`.

## Validazione rapida senza Krateo

Questo è il primo test consigliato, perché non richiede pubblicare il chart in OCI.

```bash
./scripts/create-kind-cluster.sh
./scripts/deploy-wrapper-chart.sh
```

Verifica:

```bash
kubectl -n neon-demo get jobs,pods,secrets
kubectl -n neon-demo logs job/neon-postgres-wrapper-neon-postgres-database
kubectl -n neon-demo get secret neon-postgres-wrapper-neon-postgres-database-connection -o yaml
```

Decodifica la connection string:

```bash
kubectl -n neon-demo get secret neon-postgres-wrapper-neon-postgres-database-connection \
  -o jsonpath='{.data.DATABASE_URL}' | base64 --decode; echo
```

## Flow completo con Krateo

Krateo Core Provider deve poter scaricare il chart da un registry OCI o da un repository Helm. Quindi, per usare la CompositionDefinition, prima pubblica il chart.

### 1. Setup cluster e Krateo

```bash
./scripts/create-kind-cluster.sh
./scripts/install-krateoctl.sh
./scripts/create-krateo-secrets.sh
./scripts/install-krateo-platformops.sh
kubectl apply -f krateo/namespace.yaml
```

### 2. Pubblica il chart su GHCR

Ad ogni push su `main`/`master`, la GitHub Action:

```text
.github/workflows/publish-helm-chart.yml
```

pacchettizza il chart e lo pubblica su:

```text
oci://ghcr.io/federicolepera/krateo-challenge-lepera/charts/neon-postgres-database:0.1.0
```

Per Krateo i valori sono:

```yaml
chart:
  url: oci://ghcr.io/federicolepera/krateo-challenge-lepera/charts
  repo: neon-postgres-database
  version: 0.1.0
```

Nota: se il package GHCR resta privato, Krateo dentro il cluster non riuscirà a scaricarlo senza credenziali. Per una challenge semplice conviene rendere pubblico il package oppure configurare le credenziali OCI per il core-provider.

#### Pubblicazione manuale

Prima fai login:

```bash
helm registry login ghcr.io -u <github-user>
```

Poi pubblica e registra la CompositionDefinition:

```bash
./scripts/publish-chart-ghcr.sh
```

Lo script registra:

```yaml
apiVersion: core.krateo.io/v1alpha1
kind: CompositionDefinition
metadata:
  name: neon-postgres-database
  namespace: krateo-system
spec:
  chart:
    repo: neon-postgres-database
    url: oci://ghcr.io/federicolepera/krateo-challenge-lepera/charts
    version: 0.1.0
```

### 3. Crea una Composition

Quando la CRD generata è disponibile:

```bash
kubectl apply -f krateo/neonpostgres-test.yaml
```

Manifest:

```yaml
apiVersion: composition.krateo.io/v0-1-0
kind: NeonPostgresDatabase
metadata:
  name: neonpostgres-test
  namespace: neon-demo
spec:
  databaseName: krateo-challenge-db
  referrer: krateo-challenge-lepera
  enableLogicalReplication: false
  createConnectionSecret: true
  seedSampleData: true
```

## Frontend Krateo

```bash
./scripts/run-krateo-frontend.sh
```

URL:

```text
http://localhost:30080
```

Lo script stampa anche le password degli utenti `admin` e `cyberjoker`, se i secret sono presenti.

## Stato e troubleshooting

```bash
./scripts/check-setup-status.sh
kubectl -n neon-demo get jobs,pods,secrets
kubectl -n neon-demo describe job <job-name>
kubectl -n neon-demo logs job/<job-name>
```

Se il Job fallisce per assenza di tooling nell’immagine, controlla i log: lo script prova a installare `curl`, `jq`, `kubectl` e `postgresql-client` via `apk` quando necessario.

## Differenza con la challenge MongoDB Atlas

Nella challenge MongoDB Atlas:

```text
Krateo → Helm chart → AtlasProject/AtlasDeployment → Atlas Operator → MongoDB Atlas API
```

Qui invece:

```text
Krateo → Helm chart → Kubernetes Job → Neon Claimable Postgres API
```

Pro:

- niente account cloud;
- niente API key;
- niente carta;
- demo più semplice;
- Postgres cloud reale.

Contro:

- il Job non è un controller vero;
- update/delete non sono robusti come con un operator;
- il database Neon Claimable è temporaneo se non viene claimato.

## Cleanup

Risorse locali:

```bash
helm -n neon-demo uninstall neon-postgres-wrapper || true
kubectl delete -f krateo/neonpostgres-test.yaml || true
kind delete cluster --name krateo-neon-challenge
```

Risorse Neon:

- se non claimi il database, scade automaticamente;
- se lo claimi, cancellalo dalla console Neon quando non serve più.

## Prossimo step possibile

La versione successiva può introdurre OASGen:

```text
Krateo → OASGen → CRD NeonDatabase → Rest Dynamic Controller → Neon API
```

Per ora questa challenge resta volutamente Job-based per massimizzare semplicità e affidabilità.
