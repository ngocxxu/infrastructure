# Force sync for flux
```bash
flux reconcile kustomization infrastructure -n flux-system
flux reconcile source helm doppler-helm -n flux-system
flux reconcile helmrelease doppler-kubernetes-operator -n flux-system
```

# Status settings of each apps
```bash
flux get kustomizations
```