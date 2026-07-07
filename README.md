# k3s Cluster Security Hardening Playbook

This Ansible playbook hardens security settings for Ubuntu Server 22/24 systems running a k3s cluster.

## Features

- **Firewall Configuration (UFW)**: Configures firewall rules for SSH and k3s required ports
- **SSH Hardening**: Disables root login, password authentication, and configures secure SSH settings
- **Fail2ban**: Protects against brute-force attacks
- **Automatic Security Updates**: Configures unattended-upgrades for automatic security patches
- **System Hardening**: Network security settings, file permissions, and password policies
- **k3s Port Configuration**: Pre-configured firewall rules for k3s master and worker communication
- **k3s Control Plane Hardening**: Configures audit logging, API server TLS and auth settings, controller/scheduler hardening args, and kubelet hardening drop-in config

## Prerequisites

1. Ansible installed on your control machine (Ansible 2.9+)
2. SSH access to both servers (master and worker)
3. Sudo/root privileges on target servers
4. Python 3 installed on target servers
5. **Sudo access**: Either passwordless sudo configured, or you'll need to provide sudo password when prompted

## Installation

1. Install Ansible (if not already installed):
```bash
sudo apt update
sudo apt install ansible -y
```

2. Install required Ansible collections:
```bash
ansible-galaxy collection install -r collections.yml
```

## Configuration

1. **Edit the inventory file** (`inventory.ini`):
  - Replace `IP` with each server's real IP address
  - Update `ansible_user` if needed (default in inventory is `admin`)
  - Add `ansible_ssh_private_key_file` if required for your environment

2. **Configure SSH access**:
  - Ensure you can SSH into both servers without password prompts
  - Or set up SSH keys for your target user

3. **Configure sudo access** (recommended for automation):
  - Option A (Recommended): Set up passwordless sudo on target servers:
    ```bash
    # On each target server, run:
    echo "admin ALL=(ALL) NOPASSWD: ALL" | sudo tee /etc/sudoers.d/admin
    ```
  - Option B: Use `--ask-become-pass` flag when running ansible commands (you'll be prompted for sudo password)

4. **Review playbook variables** (in `security-hardening.yml`):
  - Adjust firewall ports if your k3s setup uses different ports
  - Modify SSH port if you're using a non-standard port
  - Adjust Fail2ban settings if needed
  - Review k3s hardening vars (`k3s_*`) for audit policy paths and component arguments

## Important Notes Before Running

⚠️ **WARNING**: This playbook will:
- Disable password authentication for SSH (only key-based auth will work)
- Disable root login via SSH
- Enable UFW firewall (make sure SSH port is accessible!)
- Restart SSH service (you may be disconnected briefly)
- Apply k3s API server and kubelet hardening settings, then restart k3s

**Before running, ensure:**
1. You have SSH key-based authentication set up
2. You have an alternative way to access the servers (console access recommended)
3. You've tested SSH key access works

## Usage

### Test connectivity first:
```bash
# If passwordless sudo is configured:
ansible all -m ping

# If sudo password is required:
ansible all -m ping --ask-become-pass
```

### Run the playbook:
```bash
# If passwordless sudo is configured:
ansible-playbook security-hardening.yml

# If sudo password is required:
ansible-playbook security-hardening.yml --ask-become-pass
```

### Run on specific hosts:
```bash
# Only master
ansible-playbook security-hardening.yml --limit k3s_master

# Only workers
ansible-playbook security-hardening.yml --limit k3s_workers
```

### Dry run (check mode):
```bash
ansible-playbook security-hardening.yml --check
```

### Quick start script:
```bash
chmod +x quick-start.sh
./quick-start.sh
```

## What Gets Configured

### Firewall (UFW)
- Default deny incoming, allow outgoing
- Allows SSH (port 22)
- Allows k3s API server (port 6443)
- Allows k3s Kubelet API (port 10250)
- Allows Flannel VXLAN (port 8472 UDP)
- Allows Flannel Wireguard (port 51820 UDP, if used)

### SSH Security
- Root login disabled
- Password authentication disabled
- Key-based authentication only
- Max authentication tries: 3
- Connection timeout settings
- Security banner

### Fail2ban
- SSH brute-force protection
- 1-hour ban time
- 5 max retries in 10 minutes

### System Updates
- Automatic security updates enabled
- Automatic cleanup of old packages

### Network Security
- IP forwarding enabled (required for k3s)
- ICMP redirects disabled
- TCP SYN cookies enabled
- IPv6 security settings

### k3s Hardening
- Audit policy file deployment (`/etc/rancher/k3s/audit-policy.yaml`)
- Audit log directory/file setup (`/var/log/k3s/audit.log`)
- API server hardening args:
  - TLS minimum version
  - RBAC/authorization settings
  - TLS cipher suites
  - kubelet client certificate/key args
- Controller manager and scheduler hardening args
- Kubelet hardening drop-in (`10-security-hardening.conf`)
- k3s service env updates in `/etc/systemd/system/k3s.service.env`

### Additional Security
- Restrictive file permissions
- Password policies
- Unnecessary services disabled

## Post-Deployment

After running the playbook:

1. **Verify SSH access still works** with your SSH key
2. **Check firewall status**: `sudo ufw status verbose`
3. **Check Fail2ban status**: `sudo fail2ban-client status`
4. **Verify k3s cluster connectivity** between master and worker
5. **Verify k3s hardening artifacts**:
  - `sudo systemctl status k3s`
  - `sudo ls -l /etc/systemd/system/k3s.service.env`
  - `sudo ls -l /etc/rancher/k3s/audit-policy.yaml`
  - `sudo ls -l /var/lib/rancher/k3s/agent/etc/kubelet.conf.d/10-security-hardening.conf`
6. **Review logs**: Check `/var/log/auth.log` and `/var/log/k3s/audit.log` for any issues

## Troubleshooting

### Can't SSH after running playbook
- Use console access to the server
- Check SSH configuration: `sudo sshd -T | grep -E "(PermitRootLogin|PasswordAuthentication)"`
- Temporarily allow password auth if needed

### k3s nodes can't communicate
- Check firewall rules: `sudo ufw status numbered`
- Verify k3s ports are open: `sudo ufw allow 6443/tcp`
- Check if IP forwarding is enabled: `sysctl net.ipv4.ip_forward`

### Fail2ban blocking legitimate access
- Check banned IPs: `sudo fail2ban-client status sshd`
- Unban an IP: `sudo fail2ban-client set sshd unbanip <IP_ADDRESS>`

## Customization

You can customize the playbook by modifying variables at the top of `security-hardening.yml`:

- `ssh_port`: Change SSH port (remember to update firewall rules)
- `ufw_allowed_ports`: Add/remove firewall rules
- `fail2ban_max_retry`: Adjust brute-force protection sensitivity
- `automatic_reboot`: Enable/disable automatic reboots after updates
- `k3s_service_env_path`, `k3s_audit_policy_path`, `k3s_audit_log_path`
- `k3s_apiserver_*`, `k3s_controller_manager_args`, `k3s_scheduler_args`

## Security Best Practices

After running this playbook, consider:

1. **Regular security audits**: Review logs regularly
2. **Keep systems updated**: The playbook enables automatic updates
3. **Monitor Fail2ban**: Check for attack patterns
4. **Backup configurations**: Keep backups of important configs
5. **Use VPN**: Consider setting up a VPN instead of exposing k3s API publicly
6. **k3s TLS**: Ensure k3s is using proper TLS certificates
7. **Network policies**: Configure Kubernetes network policies for pod-level security

## License

This playbook is provided as-is for security hardening purposes.
