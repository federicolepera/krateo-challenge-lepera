# Neon Postgres Database for Krateo

Questo repository contiene un blueprint Krateo per creare un database PostgreSQL su Neon tramite un chart Helm.

Il provisioning viene eseguito da un Job Kubernetes installato dal chart. Il Job chiama le API Neon Claimable Postgres, crea il database e salva la connection string in un Secret Kubernetes.

Il chart Helm è pubblicato come OCI artifact su GHCR:

```text
oci://ghcr.io/federicolepera/krateo-challenge-lepera/charts/neon-postgres-database:0.1.2
```

La `CompositionDefinition` punta al chart pubblico:

```yaml
chart:
  url: oci://ghcr.io/federicolepera/krateo-challenge-lepera/charts
  repo: neon-postgres-database
  version: 0.1.2
```

## Cosa viene creato

Quando viene creata una `NeonPostgresDatabase`, Krateo installa il chart Helm e crea:

- un Job Kubernetes per chiamare Neon;
- un Secret con le connection string del database;
- le risorse frontend per la pagina di dettaglio della Composition, tramite `portal-composition-page-generic`.

Il Secret contiene:

```text
DATABASE_URL
DATABASE_URL_DIRECT
CLAIM_URL
EXPIRES_AT
NEON_DATABASE_ID
NEON_PROJECT_ID
```

## Prerequisiti

Servono:

- `kubectl`
- `helm`
- `kind`
- `krateoctl`
- un cluster Kubernetes con Krateo PlatformOps installato

Gli script nella cartella `scripts/` possono essere usati per creare un ambiente locale con Kind e Krateo.

## Setup locale

### 1. Crea il cluster Kind

```bash
./scripts/create-kind-cluster.sh
```

Verifica:

```bash
kubectl cluster-info
kubectl get nodes
```

### 2. Installa krateoctl

```bash
./scripts/install-krateoctl.sh
```

Verifica:

```bash
krateoctl version
```

### 3. Crea i Secret richiesti da Krateo

```bash
./scripts/create-krateo-secrets.sh
```

Verifica:

```bash
kubectl -n krateo-system get secrets
```

### 4. Installa Krateo PlatformOps

```bash
./scripts/install-krateo-platformops.sh
```

Verifica che i pod siano pronti:

```bash
kubectl -n krateo-system get pods
```

### 5. Crea il namespace applicativo

```bash
kubectl apply -f krateo/namespace.yaml
```

Il namespace usato dagli esempi è:

```text
neon-demo
```

Verifica:

```bash
kubectl get ns neon-demo
```

## Creazione del database

Ci sono due modalità alternative.

## Opzione A - CompositionDefinition + kubectl

Usa questa opzione se vuoi registrare il tipo Krateo e creare la Composition da terminale.

### A1. Registra la CompositionDefinition

```bash
./scripts/register-compositiondefinition.sh
```

Lo script applica:

```text
krateo/compositiondefinition.yaml
```

La `CompositionDefinition` registra il tipo `NeonPostgresDatabase` e permette a Krateo di generare la relativa CRD.

Verifica:

```bash
kubectl -n krateo-system get compositiondefinitions.core.krateo.io
kubectl -n krateo-system describe compositiondefinition neon-postgres-database
kubectl get crd | grep -i neon
```

### A2. Crea la Composition con kubectl

```bash
kubectl apply -f krateo/neonpostgres-test.yaml
```

Esempio di Composition:

```yaml
apiVersion: composition.krateo.io/v0-1-2
kind: NeonPostgresDatabase
metadata:
  name: neonpostgres-test
  namespace: neon-demo
spec:
  databaseName: krateo-database
  referrer: krateo-neon-postgres
  enableLogicalReplication: false
  createConnectionSecret: true
  seedSampleData: true
```

Krateo installa il chart e avvia il Job Kubernetes che crea il database Neon.

Verifica:

```bash
kubectl -n neon-demo get neonpostgresdatabases.composition.krateo.io
kubectl -n neon-demo get jobs,pods,secrets
```

Guarda i log del Job:

```bash
kubectl -n neon-demo logs job/<job-name>
```

## Opzione B - Blueprint frontend Krateo

Usa questa opzione se vuoi esporre `Neon Postgres` nella pagina **Blueprints** del frontend Krateo e creare la Composition tramite form.

Questa modalità installa il chart ufficiale `portal-blueprint-page`, configurato con:

```text
krateo/portal-blueprint-page-values.yaml
```

Il chart `portal-blueprint-page` crea:

- la card `Neon Postgres` nella pagina **Blueprints**;
- il form per creare la Composition;
- le risorse frontend necessarie (`Panel`, `Form`, `RESTAction`, `Markdown`, `Button`);
- una `CompositionDefinition` per il tipo `NeonPostgresDatabase`.

Quindi, usando questa opzione, non serve registrare separatamente `krateo/compositiondefinition.yaml`.

### B1. Registra il Blueprint

```bash
./scripts/register-portal-blueprint.sh
```

Verifica:

```bash
helm -n neon-demo status neon-postgres-database
kubectl -n neon-demo get compositiondefinition neon-postgres-database
kubectl -n neon-demo get panels,forms,restactions | grep neon-postgres-database
```

### B2. Apri il frontend Krateo

Con Kind, il NodePort potrebbe non essere esposto direttamente sull'host. Usa il port-forward:

```bash
./scripts/run-krateo-frontend.sh
```

Apri:

```text
http://localhost:30080
```

Lo script espone anche:

```text
Auth API:  http://127.0.0.1:30082
Snowplow:  http://127.0.0.1:30081
Events:    http://127.0.0.1:30083
```

### B3. Crea la Composition dal frontend

Nel frontend Krateo:

1. vai nella pagina **Blueprints**;
2. clicca **Neon Postgres**;
3. compila il form;
4. conferma la creazione.

La Composition creata dal frontend sarà dello stesso tipo usato nella modalità CLI:

```yaml
apiVersion: composition.krateo.io/v0-1-2
kind: NeonPostgresDatabase
metadata:
  name: <nome-scelto-nel-form>
  namespace: neon-demo
spec:
  databaseName: <database-name>
```

Verifica da terminale:

```bash
kubectl -n neon-demo get neonpostgresdatabases.composition.krateo.io
kubectl -n neon-demo get jobs,pods,secrets
```

## Recupero connection string

Lista i Secret creati nel namespace applicativo:

```bash
kubectl -n neon-demo get secrets
```

Decodifica `DATABASE_URL`:

```bash
kubectl -n neon-demo get secret <secret-name> \
  -o jsonpath='{.data.DATABASE_URL}' | base64 --decode; echo
```

## Verifica generale

```bash
./scripts/check-setup-status.sh
```

## Sviluppo e pubblicazione del chart

Per validare il chart localmente:

```bash
helm dependency build chart/neon-postgres-chart
helm lint chart/neon-postgres-chart
helm template neon-postgres-database chart/neon-postgres-chart
```

Per pubblicare una nuova versione su GHCR:

```bash
helm registry login ghcr.io -u <github-user>
GITHUB_OWNER=<github-owner> ./scripts/publish-chart-ghcr.sh
```

Dopo la pubblicazione, aggiorna la versione nei file Krateo se necessario:

- `krateo/compositiondefinition.yaml`
- `krateo/neonpostgres-test.yaml`
- `krateo/portal-blueprint-page-values.yaml`

## Cleanup locale

```bash
helm -n neon-demo uninstall neon-postgres-database || true
kubectl delete -f krateo/neonpostgres-test.yaml || true
kubectl delete -f krateo/compositiondefinition.yaml || true
kind delete cluster --name krateo-neon-challenge
```
