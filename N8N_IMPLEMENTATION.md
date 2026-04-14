# n8n Integration - Implementation Summary

## ✅ Completed

All n8n components have been successfully created and integrated into your GitOps infrastructure.

### 1. Helm Chart (`helms/n8n/`)

- ✅ `Chart.yaml` - Chart metadata
- ✅ `values.yaml` - Configuration with PostgreSQL, Doppler secrets, Traefik ingress
- ✅ `templates/_helpers.tpl` - Template helpers
- ✅ `templates/deployment.yaml` - n8n deployment with security context
- ✅ `templates/service.yaml` - ClusterIP service on port 5678
- ✅ `templates/ingress.yaml` - Traefik ingress for n8n.ngocquach.com
- ✅ `templates/pvc.yaml` - 2Gi persistent storage at `/home/node/.n8n`
- ✅ `templates/serviceaccount.yaml` - RBAC service account

### 2. Flux GitOps Integration

- ✅ `clusters/mmo-vps/apps/external/n8n.yaml` - HelmRelease with PostgreSQL dependency
- ✅ `clusters/mmo-vps/apps/external/n8n-secret.yaml` - DopplerSecret CRD
- ✅ `clusters/mmo-vps/infrastructure/image-repositories.yaml` - Added n8n ImageRepository
- ✅ `clusters/mmo-vps/apps/external/image-policies.yaml` - Added n8n-latest ImagePolicy

## 🔧 Configuration Details

**Namespace**: `external` (alongside omniroute)

**Database**: PostgreSQL from `shared` namespace

- Host: `postgresql.shared.svc.cluster.local`
- Port: `5432`
- Database: `n8n`

**Domain**: `n8n.ngocquach.com`

**Storage**: 2Gi PVC with `local-path` storageClass (k3s default)

**Resources**:

- Request: 100m CPU, 256Mi memory
- Limit: 500m CPU, 512Mi memory

**Security**:

- Non-root user (UID 1000)
- No privilege escalation
- FSGroup: 1000

**Timezone**: Asia/Ho_Chi_Minh

## 📋 Next Steps - Manual Configuration Required

### 1. Create Doppler Token Secret

Before Flux reconciliation, create the Doppler service token secret:

```bash
kubectl create secret generic doppler-token-n8n \
  --namespace external \
  --from-literal=serviceToken=dp.st.xxxxx
```

Replace `dp.st.xxxxx` with your actual Doppler service token.

### 2. Configure Doppler Variables

Add these variables to your Doppler project for n8n:

```
N8N_ENCRYPTION_KEY=<generate with: openssl rand -hex 16>
DB_POSTGRESDB_HOST=postgresql.shared.svc.cluster.local
DB_POSTGRESDB_PORT=5432
DB_POSTGRESDB_DATABASE=n8n
DB_POSTGRESDB_USER=n8n
DB_POSTGRESDB_PASSWORD=<your-secure-password>
WEBHOOK_URL=https://n8n.ngocquach.com
```

### 3. Verify Deployment

After Flux reconciliation:

```bash
# Check HelmRelease status
flux get helmreleases -n external

# Verify pod is running
kubectl get pods -n external -l app.kubernetes.io/name=n8n

# Check PVC creation
kubectl get pvc -n external

# View logs
kubectl logs -n external -l app.kubernetes.io/name=n8n

# Test ingress
curl -I https://n8n.ngocquach.com
```

### 4. Initial Setup

1. Navigate to `https://n8n.ngocquach.com`
2. Complete the n8n initial setup wizard
3. Create your first user account
4. Configure webhooks for Grafana alerts

## 📁 File Structure Created

```
helms/n8n/
├── Chart.yaml
├── values.yaml
└── templates/
    ├── _helpers.tpl
    ├── deployment.yaml
    ├── service.yaml
    ├── ingress.yaml
    ├── pvc.yaml
    └── serviceaccount.yaml

clusters/mmo-vps/apps/external/
├── n8n.yaml (HelmRelease)
└── n8n-secret.yaml (DopplerSecret)

clusters/mmo-vps/infrastructure/
└── image-repositories.yaml (updated with n8n)

clusters/mmo-vps/apps/external/
└── image-policies.yaml (updated with n8n-latest)
```

## 🔄 Flux Reconciliation Flow

1. **Infrastructure** → Doppler Operator, Helm repos
2. **Shared** → PostgreSQL (n8n dependency)
3. **External** → n8n (waits for PostgreSQL via `dependsOn`)

## 🎯 Key Features

- ✅ PostgreSQL backend for scalability
- ✅ Doppler-managed secrets (encryption key, DB credentials)
- ✅ Traefik ingress with HTTPS support
- ✅ Persistent storage for workflows (2Gi)
- ✅ Flux image automation for latest tag updates
- ✅ Non-root security context
- ✅ Health checks (liveness & readiness probes)
- ✅ Resource limits for k3s optimization

## 📝 Notes

- n8n will automatically prune execution history older than 7 days (168 hours)
- Diagnostics and personalization are disabled for production
- The chart follows your existing omniroute pattern for consistency
- All secrets are managed through Doppler, not hardcoded
