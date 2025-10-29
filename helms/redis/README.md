```
SOPS_AGE_KEY_FILE=/Users/macos/STENGG-2/age-keygen/my-infra.txt \
helm secrets upgrade --install redis bitnami/redis \
  -f helms/redis/values.yaml \
  -f helms/redis/values.secrets.yaml \
  -n redis \
  --create-namespace
```