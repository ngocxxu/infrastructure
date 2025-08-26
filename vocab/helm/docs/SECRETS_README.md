# Secrets Management with SOPS and Helm-Secrets

This Helm chart includes a comprehensive secrets management system using SOPS for encryption and helm-secrets for integration.

## Prerequisites

- Helm plugin: `helm-secrets` (already installed)
- SOPS tool (already installed via brew)
- Age key for encryption

## Files Overview

- `templates/secrets.yaml` - Kubernetes Secret template
- `values.yaml` - Main values file with secrets configuration (disabled by default)
- `values.secrets.yaml` - Encrypted file containing actual secret values
- `.sops.yaml` - SOPS configuration for encryption rules

## Usage

### 1. Generate Age Key (if not already done)

```bash
age-keygen -o key.txt
# Copy the public key to .sops.yaml
```

### 2. Update .sops.yaml

Replace the age key in `.sops.yaml` with your actual public key.

### 3. Edit values.secrets.yaml

Update the `values.secrets.yaml` file with your actual secret values.

### 4. Encrypt the secrets file

```bash
sops -e -i values.secrets.yaml
```

### 5. Deploy with secrets

```bash
# Install
helm secrets install vocab-be ./vocab-be -f values.secrets.yaml

# Upgrade
helm secrets upgrade vocab-be ./vocab-be -f values.secrets.yaml
```

## Secret Categories

The secrets template supports the following categories:

- **Database**: Connection strings, usernames, passwords
- **JWT**: Authentication and refresh token secrets
- **API**: External API keys
- **Redis**: Cache/database passwords
- **Email**: SMTP and email service credentials
- **External**: Any additional external service secrets

## Security Notes

- Never commit unencrypted secret files to version control
- Use strong, unique passwords for each environment
- Rotate secrets regularly
- Consider using external secret management systems for production

## Environment Variables

When secrets are enabled, the following environment variables will be available in your pods:

- `DATABASE_URL`
- `DATABASE_USERNAME`
- `DATABASE_PASSWORD`
- `JWT_SECRET`
- `JWT_REFRESH_SECRET`
- `API_KEY`
- `REDIS_PASSWORD`
- `SMTP_PASSWORD`
- `EMAIL_API_KEY`
- Any custom secrets defined in `external` section

## Troubleshooting

- Ensure SOPS is properly configured with your age key
- Verify helm-secrets plugin is installed and working
- Check that the secret values are properly base64 encoded in the generated Secret
- Ensure the deployment can access the secret (check RBAC if using service accounts)
