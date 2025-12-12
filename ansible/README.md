## Encrypt secrets key
```bash
ansible-vault encrypt inventory/host_vars/master-01.yml
ansible-vault encrypt group_vars/all.yml
```

## Decrypt by edit
```bash
ansible-vault edit inventory/host_vars/master-01.yml
ansible-vault edit group_vars/all.yml
```
#### Use VSCode to edit
```bash
# Run before edit
export EDITOR="code --wait"
```

## Run ansible playbook
```bash
ansible-playbook site.yml --ask-vault-pass

# Or run this if you config .vault_pass
ansible-playbook site.yml
```

## Test connection
```bash
ansible all -m ping
```