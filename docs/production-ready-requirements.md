# Production ready requirements

1. [ ] VPS instance and Domain Name to have a DNS record pointing to our server
2. [ ] Hardening OpenSSH to prevent brute force attacks
3. [ ] App Running
4. [ ] TLS + HTTPS + Auto-renew Certificates
5. [ ] Firewall to block unnecessary ports
6. [ ] Load Balancer to distribute traffic to multiple instances to ensure good UX and High Availability
7. [ ] Automated Deployments while keeping the service available
8. [ ] Website Monitoring to notify if the service is unavailable


# Technologies to avoid

1. Lightweight Kubernetes deployments like K3S or MicroK8s
2. Full-featured solutions like Coolify
3. Infrastructure as code such as Terraform, Pulumi, or OpenTofu (Maybe on a future implementation)

## 1. VPS Instance and Domain Name

1. Sign up for a Hostinger VPS server with a plain OS, Ubuntu 24.04.
2. Create a user with a strong password.
3. Add an SSH key.
4. Create a new user account (never work as root):
   - Add a user: `adduser username`
   - Grant sudo permissions: `usermod -aG sudo username`
   - Switch to the new user: `su - username`
5. Purchase a domain from Hostinger.
6. Configure DNS records:
   - Delete existing A and CNAME records.
   - Add a new Type A record:
     - TTL: 300
     - Point to the server IP (check with the `ip addr` command).
7. Verify that the new record has propagated by using `nslookup username@domain`.

## 2. Hardening OpenSSH

1. Copy SSH key to server:
   - Use `ssh-copy-id username@server-ip` to copy your public key
   - Verify SSH key login works before proceeding

2. Edit main SSH configuration:
   ```bash
   sudo nano /etc/ssh/sshd_config
   ```
   Modify these settings:
   - `PasswordAuthentication no`
   - `PermitRootLogin no`
   - `UsePAM no`
   - `MaxAuthTries 3`
   - `ClientAliveInterval 300`
   - `ClientAliveCountMax 2`

3. Edit cloud-init configuration:
   ```bash
   sudo nano /etc/ssh/sshd_config.d/50-cloud-init.conf
   ```
   Set:
   - `PasswordAuthentication no`

4. Change default SSH port (optional but recommended):
   - Edit `/etc/ssh/sshd_config`
   - Change `Port 22` to a number between 1024-65535 (e.g., `Port 2222`)
   - Remember to update firewall rules for the new port

5. Disable unused SSH features:
   ```bash
   sudo nano /etc/ssh/sshd_config
   ```
   Add:
   - `PermitEmptyPasswords no`
   - `X11Forwarding no`
   - `AllowTcpForwarding no`
   - `AllowAgentForwarding no`

6. Apply changes:
   ```bash
   sudo systemctl reload ssh
   ```

7. Test configuration:
   - Open new terminal and verify SSH access works
   - Confirm password authentication is rejected
   - Verify root login is blocked

## 3. App Running

1. Add Docker and Docker Compose plugin to the server following official instructions: 
```
# Add Docker's official GPG key:
sudo apt-get update
sudo apt-get install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update

# Install the latest version:
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

2. Check with `sudo docker ps` the Docker service is up and running. If doesn't work you can enable the service with sudo systemctl enable docker.

3. Then add the user to the Docker group and prevent the use od sudo every time, do `sudo usermod -aG docker username`.
