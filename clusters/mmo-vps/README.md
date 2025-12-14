# Force sync for flux
```bash
flux reconcile kustomization apps-shared --with-source
flux reconcile kustomization infrastructure -n flux-system
flux reconcile source helm doppler-helm -n flux-system
flux reconcile helmrelease weave-gitops -n flux-system
flux reconcile helmrelease doppler-kubernetes-operator -n flux-system

flux reconcile hr postgresql -n shared

kubectl delete helmrelease postgresql -n shared
kubectl delete helmrelease redis -n shared

```

# Force update
```bash
kubectl annotate kustomization apps-shared -n flux-system \
  reconcile.timestamp="$(date +%s)" --overwrite
  
# Force secrets first (because apps-shared depends on apps-shared-secrets)
kubectl annotate kustomization apps-shared-secrets -n flux-system \
  reconcile.timestamp="$(date +%s)" --overwrite

# After force shared
kubectl annotate kustomization apps-shared -n flux-system \
  reconcile.timestamp="$(date +%s)" --overwrite
```

# Status settings of each apps
```bash
flux get kustomizations
```