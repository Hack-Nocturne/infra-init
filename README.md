# Infra Init

A comprehensive Ansible-based infrastructure automation solution for provisioning secure, containerized application deployment environments with blue-green deployment capabilities, Cloudflare integration, and hardened security configurations.

## 🎯 What's This About?

This project automates the complete setup of production-ready Linux servers optimized for containerized application deployments. It creates a secure, multi-layered environment with:

- **Blue-Green Deployment Infrastructure**: Seamless zero-downtime deployments using Nginx load balancing
- **Cloudflare Integration**: Automatic IP range updates and Origin Certificate management
- **Container Orchestration**: Podman-based rootless container management with systemd integration
- **Security Hardening**: Multi-layer security with restricted users, nftables firewall, and SSH hardening
- **Automated Monitoring**: Dynamic Cloudflare IP updates and system health monitoring

## 🏗️ Architecture

```
┌─────────────┐     ┌────────────┐    ┌─────────────────┐
│ Cloudflare  │───▶│  nftables  │───▶│     Nginx       │
│ (SSL/Proxy) │     │ (Firewall) │    │ (Load Balancer) │
└─────────────┘     └────────────┘    └─────────────────┘
                                               │
                                     ┌─────────┴─────────┐
                                     │                   │
                             ┌───────▼──────┐     ┌──────▼───────┐
                             │ Blue Pool    │     │ Green Pool   │
                             │ :2020, :2021 │     │ :4040, :4041 │
                             └──────────────┘     └──────────────┘
                                     │                    │
                               ┌─────▼──────┐       ┌─────▼──────┐
                               │ Podman     │       │ Podman     │
                               │ Containers │       │ Containers │
                               └────────────┘       └────────────┘
```

## 🔧 Configuration

### Environment Variables ([`group_vars/all.yml`](ansible/group_vars/all.yml))

```yaml
# Blue/Green Deployment Pools
blue_upstreams:
  - { host: "127.0.0.1", port: 2020 }
  - { host: "127.0.0.1", port: 2021 }

green_upstreams:
  - { host: "127.0.0.1", port: 4040 }
  - { host: "127.0.0.1", port: 4041 }

# Security Configuration
ssh_port: 4568
deploy_user: "deployer"
admin_user: "admin"

# SSL Configuration
server_name: "*.example.com"
ssl_cert_path: /etc/nginx/ssl/cf_origin.pem
ssl_key_path: /etc/nginx/ssl/cf_origin.key
```

### Required Secrets
- `SSH_KEY`: Private SSH key for server access
- `DEPLOY_SSH_PUB_KEY`: Public key for deployment user
- `ADMIN_SSH_PUB_KEY`: Public key for admin user
- `CF_CERT`: Cloudflare Origin Certificate
- `CF_KEY`: Cloudflare Origin Certificate private key
- `INVENTORY_YML`: Ansible inventory configuration
- `DEPLOY_PWD` & `ADMIN_PWD`: Respective users' passwords
- `OBSCURED_DIR`: Directory on hosts where scripts for deploy group resides

## 🚀 Usage

### Automated Deployment (GitHub Actions)

1. **Configure Secrets**: Add required secrets to your GitHub repository
2. **Run Workflow**: Trigger the "Initialize Infrastructure" workflow
3. **Select Environment**: Choose Dev or Prod environment
4. **Monitor Progress**: Watch the automated provisioning process

### Application Deployment
Use the [`deploy.sh`](ansible/files/deploy.sh) script for blue-green deployments:

```bash
# Deploy new version
./deploy.sh -a myapp -p 8080 -g 4040 -b 2020 -v v1.2.3 -r true

# Switch traffic to new deployment
./deploy.sh -a myapp -f true
```

## 🛡️ Security Features

### Network Security
- **Firewall**: nftables configuration allowing only Cloudflare IP ranges for HTTP/HTTPS
- **SSH Security**: Custom port, key-only authentication, connection limits
- **IP Whitelisting**: Automatic Cloudflare IP range updates every 6 hours

### User Security
- **Principle of Least Privilege**: Deployment user with minimal required permissions
- **Restricted Shell**: Custom rbash implementation with command filtering and path restrictions
- **Sudo Restrictions**: Whitelist of specific commands for deployment operations only
- **Directory ACLs**: Restricted access to sensitive system directories

### Container Security
- **Rootless Containers**: All containers run without root privileges
- **Read-Only Filesystems**: Containers mounted with read-only root filesystem
- **Capability Dropping**: All Linux capabilities removed from containers
- **No New Privileges**: Prevents privilege escalation within containers
- **Secret Management**: Environment variables stored as Podman secrets

### SSL/TLS Security
- **Cloudflare Origin Certificates**: End-to-end encryption with Cloudflare
- **Modern TLS**: TLS 1.2+ only with secure cipher suites
- **HSTS Ready**: Prepared for HTTP Strict Transport Security implementation

## 🔄 Automation Features

### Continuous Integration
- **GitHub Actions**: Automated infrastructure provisioning
- **Environment Management**: Separate Dev/Prod configurations
- **Secret Management**: Secure handling of sensitive configuration data

### Operational Automation
- **IP Range Updates**: Automated Cloudflare IP synchronization with nftables and Nginx
- **Container Management**: Systemd integration for automatic container restart and management

### Deployment Automation
- **Blue-Green Deployments**: Automated zero-downtime deployment switching
- **Image Management**: Automatic container image pulling and version management
- **Service Integration**: Seamless systemd service management for containers with [Podman Quadlets](https://www.redhat.com/en/blog/quadlet-podman)

## 🎯 Future Roadmap

### 🔐 Open Policy Agent (OPA) Integration
- **Policy Enforcement**: Fine-grained authorization policies for API access
- **Compliance**: Automated security policy validation and enforcement
- **Audit Logging**: Comprehensive access logging and policy decision tracking

### ⚡ Valkey Integration
- **Caching Layer**: High-performance Redis-compatible caching solution
- **Session Management**: Distributed session storage for scalable applications
- **Rate Limiting**: Advanced rate limiting and throttling capabilities

### 🏗️ Terraform Infrastructure as Code
- **Cloud Provisioning**: Automated cloud infrastructure provisioning
- **Multi-Cloud Support**: AWS, GCP, Azure infrastructure management
- **State Management**: Centralized Terraform state management and planning

### 📊 Enhanced Monitoring
- **Metrics Collection**: Prometheus/Grafana integration for comprehensive monitoring
- **Alerting**: Automated alerting for security events and system issues
- **Log Aggregation**: Centralized logging with ELK stack integration

## 📋 Prerequisites

- **Target Servers**: Ubuntu/Debian-based Linux servers
- **Ansible**: Version 2.9+ with required collections
- **SSH Access**: Root or sudo access to target servers
- **Cloudflare**: Account with Origin Certificate
- **GitHub**: Repository with GH-Actions (for automated deployment)

## 🤝 Contributing

We welcome contributions! Please feel free to submit issues, feature requests, or pull requests.

### Development Setup
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📄 License

**Copyright (c) 2024 Hack Nocturne Team**

This project is licensed under the **MIT License**. 

- ✅ **Permitted**: Use, modify, distribute, and sell for any purpose (personal or commercial)
- ✅ **Freedom**: Create derivative works and distribute them under any license
- ✅ **Open Source**: Full open source compliance with minimal restrictions
- 📝 **Attribution**: Simply include the original copyright notice and license text

See the full license terms in the [LICENSE](LICENSE) file.

## 👥 Developer

**Rishabh Kumar**
- Email: rishabh@hack-nocturne.in
- LinkedIn: https://www.linkedin.com/in/rishabh-kumar-438751207

---

**⚡ Powered by Ansible, Podman, Cloudflare & Terraform (WIP)**
