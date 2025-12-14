# Force sync for flux
```bash
flux reconcile kustomization flux-system --with-source
```

# Status settings of each apps
```bash
flux get kustomizations
```