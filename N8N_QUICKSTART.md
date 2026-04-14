# n8n Quick Start Guide

## 🚀 Deployment Commands

### 1. Create Doppler Token Secret (Required First!)

```bash
# Generate encryption key
openssl rand -hex 16

# Create the Doppler token secret
kubectl create secret generic doppler-token-n8n \
  --namespace external \
  --from-literal=serviceToken=dp.st.YOUR_DOPPLER_TOKEN_HERE
```

### 2. Configure Doppler Variables

Add these to your Doppler project:

```
N8N_ENCRYPTION_KEY=<output from openssl rand -hex 16>
DB_POSTGRESDB_HOST=postgresql.shared.svc.cluster.local
DB_POSTGRESDB_PORT=5432
DB_POSTGRESDB_DATABASE=n8n
DB_POSTGRESDB_USER=n8n
DB_POSTGRESDB_PASSWORD=<your-secure-password>
WEBHOOK_URL=https://n8n.ngocquach.com
```

### 3. Commit and Push to Git

```bash
cd /Users/macos/MyProject/infrastructure
git add .
git commit -m "feat: add n8n workflow automation to external namespace"
git push
```

### 4. Verify Flux Reconciliation

```bash
# Watch Flux reconcile the changes
flux get helmreleases -n external -w

# Check n8n pod status
kubectl get pods -n external -l app.kubernetes.io/name=n8n

# View n8n logs
kubectl logs -n external -l app.kubernetes.io/name=n8n -f

# Check PVC
kubectl get pvc -n external

# Verify ingress
kubectl get ingress -n external
```

## 🔍 Troubleshooting

### Pod not starting?

```bash
# Check pod events
kubectl describe pod -n external -l app.kubernetes.io/name=n8n

# Check if PostgreSQL is ready
kubectl get pods -n shared -l app.kubernetes.io/name=postgresql

# Verify Doppler secret exists
kubectl get secret n8n-env -n external
```

### Database connection issues?

```bash
# Test PostgreSQL connectivity from n8n pod
kubectl exec -n external -it <n8n-pod-name> -- sh
# Inside pod:
nc -zv postgresql.shared.svc.cluster.local 5432
```

### Ingress not working?

```bash
# Check Traefik ingress controller
kubectl get pods -n kube-system -l app.kubernetes.io/name=traefik

# Verify ingress configuration
kubectl describe ingress -n external n8n
```

## 📊 Monitoring

### Check n8n health

```bash
# Health endpoint
curl https://n8n.ngocquach.com/healthz

# Check resource usage
kubectl top pod -n external -l app.kubernetes.io/name=n8n
```

### View execution logs

```bash
# Real-time logs
kubectl logs -n external -l app.kubernetes.io/name=n8n -f

# Last 100 lines
kubectl logs -n external -l app.kubernetes.io/name=n8n --tail=100
```

## 🔄 Updates

### Manual image update

```bash
# Update to specific version
kubectl set image deployment/n8n -n external \
  n8n=docker.io/n8nio/n8n:1.95.0
```

### Flux auto-update

Flux will automatically update to the latest tag based on the ImagePolicy.

## 🗑️ Cleanup (if needed)

```bash
# Delete n8n (keeps PVC due to helm.sh/resource-policy: keep)
flux delete helmrelease n8n -n external

# Delete PVC (if you want to remove data)
kubectl delete pvc n8n-data -n external

# Delete Doppler secret
kubectl delete secret doppler-token-n8n -n external
kubectl delete secret n8n-env -n external
```

## 🎯 Access n8n

1. **URL**: https://n8n.ngocquach.com
2. **First-time setup**: Create admin account
3. **Webhook URL**: Use `https://n8n.ngocquach.com` for external webhooks

## 📝 Grafana Alert Integration

### Example Webhook Configuration in Grafana

```
URL: https://n8n.ngocquach.com/webhook/grafana-alert
Method: POST
Content-Type: application/json
```

### Example n8n Workflow

1. **Webhook Trigger** → Receive Grafana alert
2. **Function Node** → Parse alert data
3. **GitHub Node** → Create issue with alert details

## 🔐 Security Notes

- n8n runs as non-root user (UID 1000)
- Encryption key is stored in Doppler (never in Git)
- Database credentials managed via Doppler
- HTTPS enforced via Traefik ingress
- Execution history auto-pruned after 7 days
