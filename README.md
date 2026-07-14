# Krateo Challenge: Neon Postgres

Flow completo per preparare la challenge da zero: creazione cluster Kind, installazione `krateoctl`, installazione Krateo, deploy della `CompositionDefinition` e creazione della Composition che provisiona un database Neon Postgres tramite Job.

Il chart Helm è pubblico su GHCR:

```text
oci://ghcr.io/federicolepera/krateo-challenge-lepera/charts/neon-postgres-database:0.1.2
```

La `CompositionDefinition` usa:

```yaml
chart:
  url: oci://ghcr.io/federicolepera/krateo-challenge-lepera/charts
  repo: neon-postgres-database
  version: 0.1.2
```

## 1. Crea il cluster Kind

```bash
./scripts/create-kind-cluster.sh
```

Crea il cluster:

```text
krateo-neon-challenge
```

e imposta il context Kubernetes.

Verifica:

```bash
kubectl cluster-info
kubectl get nodes
```

## 2. Installa krateoctl

```bash
./scripts/install-krateoctl.sh
```

Verifica:

```bash
krateoctl version
```

## 3. Crea i secret richiesti da Krateo

```bash
./scripts/create-krateo-secrets.sh
```

Crea i secret nel namespace `krateo-system`:

```text
jwt-sign-key
krateo-db
krateo-db-user
```

Verifica:

```bash
kubectl -n krateo-system get secrets
```

## 4. Installa Krateo PlatformOps

```bash
./scripts/install-krateo-platformops.sh
```

Lo script esegue:

```bash
krateoctl install plan --version 3.0.0 --type nodeport --namespace krateo-system
krateoctl install apply --version 3.0.0 --type nodeport --namespace krateo-system
```

Verifica che tutti i pod siano pronti:

```bash
kubectl -n krateo-system get pods
```

## 5. Crea il namespace workload

```bash
kubectl apply -f krateo/namespace.yaml
```

Crea:

```text
neon-demo
```

Verifica:

```bash
kubectl get ns neon-demo
```

## 6. Registra la CompositionDefinition

```bash
./scripts/register-compositiondefinition.sh
```

Questo applica:

```text
krateo/compositiondefinition.yaml
```

La CompositionDefinition registra il blueprint `neon-postgres-database` e punta al chart pubblico su GHCR.

Verifica:

```bash
kubectl -n krateo-system get compositiondefinitions.core.krateo.io
kubectl -n krateo-system describe compositiondefinition neon-postgres-database
```

Attendi che Krateo generi la CRD della Composition:

```bash
kubectl get crd | grep -i neon
```

## 7. Registra il blueprint nel frontend Krateo

```bash
./scripts/register-portal-blueprint.sh
```

Questo installa il chart ufficiale `portal-blueprint-page` con Helm usando:

```text
krateo/portal-blueprint-page-values.yaml
```

Serve per vedere `Neon Postgres` nella pagina **Blueprints** del frontend.

Verifica:

```bash
helm -n neon-demo status neon-postgres-database
kubectl -n neon-demo get compositiondefinition neon-postgres-database
kubectl -n neon-demo get panels,forms,restactions | grep neon-postgres-database
```

## 8. Crea la Composition NeonPostgresDatabase

```bash
kubectl apply -f krateo/neonpostgres-test.yaml
```

La Composition è:

```yaml
apiVersion: composition.krateo.io/v0-1-2
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

Krateo installerà il chart e farà partire un Job Kubernetes che chiama Neon Claimable Postgres API.

Verifica:

```bash
kubectl -n neon-demo get neonpostgresdatabases.composition.krateo.io
kubectl -n neon-demo get jobs,pods,secrets
```

Guarda i log del Job:

```bash
kubectl -n neon-demo logs job/<job-name>
```

Il chart include anche `portal-composition-page-generic`, quindi per ogni Composition crea le risorse frontend necessarie alla pagina di dettaglio della Composition.

## 9. Recupera la connection string Neon

Lista i Secret:

```bash
kubectl -n neon-demo get secrets
```

Decodifica `DATABASE_URL`:

```bash
kubectl -n neon-demo get secret <secret-name> \
  -o jsonpath='{.data.DATABASE_URL}' | base64 --decode; echo
```

Il Secret contiene:

```text
DATABASE_URL
DATABASE_URL_DIRECT
CLAIM_URL
EXPIRES_AT
NEON_DATABASE_ID
NEON_PROJECT_ID
```

## 10. Apri il frontend Krateo

Con Kind, il NodePort `30080` potrebbe non essere esposto direttamente sul tuo host. Usa il port-forward:

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

## 11. Check generale

```bash
./scripts/check-setup-status.sh
```

## Comando unico parziale

Puoi usare anche:

```bash
./scripts/run-challenge-flow.sh
```

Poi, se la CRD non è ancora pronta, rilancia:

```bash
kubectl apply -f krateo/neonpostgres-test.yaml
```

## Cleanup

```bash
kubectl delete -f krateo/neonpostgres-test.yaml || true
kubectl delete -f krateo/compositiondefinition.yaml || true
kind delete cluster --name krateo-neon-challenge
```
