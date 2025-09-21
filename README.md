# Deployment

## Install
### Postgresql
```bash
SOPS_AGE_KEY_FILE=/Users/macos/STENGG-2/age-keygen/my-infra.txt \
helm secrets upgrade --install postgresql bitnami/postgresql \
  -f helms/postgresql/values.yaml \
  -f helms/postgresql/values.secrets.yaml \
  -n postgresql \
  --create-namespace
```

### Vocab-BE
```bash
SOPS_AGE_KEY_FILE=/Users/macos/STENGG-2/age-keygen/my-infra.txt \
helm secrets upgrade --install vocab-be helms/vocab-be \
  -f helms/vocab-be/values.yaml \
  -f helms/vocab-be/values.secrets.yaml \
  -n vocab-be \
  --create-namespace
```

## Helm

### SOPS

⚠️ **Remember: Encrypt before commit or push code**

- Encrypt

```bash
SOPS_AGE_KEY_FILE=/Users/macos/STENGG-2/age-keygen/my-infra.txt sops -e -i helms/postgresql/values.secrets.yaml
```

- Decrypt

```bash
SOPS_AGE_KEY_FILE=/Users/macos/STENGG-2/age-keygen/my-infra.txt sops -d -i helms/postgresql/values.secrets.yaml
```

- Deploy

```bash
SOPS_AGE_KEY_FILE=/your_directory_path/my-infra.txt \
helm secrets upgrade --install postgresql ./helms/postgresql \
  -f helms/postgresql/values.yaml \
  -f helms/postgresql/values.secrets.yaml \
  --namespace postgresql
  --create-namespace
```
