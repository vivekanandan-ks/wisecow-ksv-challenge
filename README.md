# Wisecow - DevOps Practical Assessment

> **TL;DR:** See the `artifacts/` directory for a consolidated view of all deliverables organized by Problem Statement if u feel like not reading much today :-)

This repository contains the solution for the Accuknox DevOps Trainee Practical Assessment. It demonstrates the containerization, deployment, security hardening, and monitoring of the "Wisecow" application.

> **If u are curious**: Read the last section 

> **Note on HTTPS:** Since a registered public domain is not available for this assessment (preventing ACME/Let's Encrypt validation), **self-signed certificates** are used to demonstrate secure TLS termination.

> **Note on CD:** **FluxCD** is implemented for GitOps-based Continuous Deployment, automating the synchronization of Kubernetes manifests from this repository to the cluster.

## Project Structure

*   `Dockerfile`: The container image definition for the application.
*   `wisecow.sh`: The source code for the application.
*   `k8s/`: Kubernetes manifests.
    *   `apps/`: Deployment, Service, Gateway, and Route manifests.
    *   `infrastructure/`: Gateway API (Envoy) and Cert-Manager configurations.
    *   `security/`: Zero-trust security policies (KubeArmor).
*   `tests/`: Monitoring and health check scripts.
*   `config/`: Cluster configuration files (k0s).
*   `.github/workflows`: CI/CD pipeline definitions.

---

## Problem Statement 1: Containerization and Deployment

**Objective:** Containerize and deploy the Wisecow application with secure TLS communication.

**Artifacts:**
1.  **Dockerfile:** A multi-stage build Dockerfile (see `Dockerfile`).
2.  **Kubernetes Deployment:** Manifests located in `k8s/apps/` (Deployment, Service).
3.  **TLS Implementation:** Implemented using Envoy Gateway and Cert-Manager. The application is exposed via HTTPS with a self-signed certificate.
4.  **CI/CD:** GitHub Actions workflow in `.github/workflows/docker-build-push.yaml` triggers on commit.

---

## Problem Statement 2: Scripting Solutions

**Objective:** Automation and monitoring scripts.

**Artifacts:**
1.  **System Health Monitoring:**
    *   Script: `tests/system_health_monitor.py`
    *   Function: Monitors CPU, Memory, and Disk usage and logs alerts if thresholds (e.g., 80%) are exceeded.
2.  **Application Health Checker:**
    *   Script: `tests/application_health_test.sh`
    *   Function: Checks the HTTP status code of the application to determine uptime.

---

## Problem Statement 3: Zero-Trust Security (KubeArmor)

**Objective:** Write and apply a zero-trust KubeArmor policy.

**Artifacts:**
1.  **Policy:** `k8s/security/wisecow-hardening.yaml`
2.  **Configuration:** `k8s/security/kubearmor-config.yaml` and `config/k0s.yaml` (Helm extension).

**Implementation:**
The applied policy (`wisecow-hardening`) enforces the following rules on the Wisecow pods:
*   **Block Package Managers:** Prevents execution of `apt`, `apt-get`, and `dpkg` to stop unauthorized tool installation.
*   **Block Sensitive Files:** Denies read access to `/etc/shadow` and `/etc/passwd`.
*   **Block Service Tokens:** Denies access to Kubernetes Service Account tokens to prevent lateral movement.

---

## How to Run Locally (Using k0s)

This project uses `k0s` as the Kubernetes distribution.

### 1. Install k0s
```bash
curl -sSLf https://get.k0s.sh | sudo sh
```

### 2. Configure Cluster
Copy the provided configuration file.

> **Note:** `k0s` natively supports Helm charts, which can be defined directly in the configuration file (`/etc/k0s/k0s.yaml`). In this project, **KubeArmor** is installed using this method as a cluster extension.

```bash
sudo mkdir -p /etc/k0s
# Assuming you are in the project root
sudo cp config/k0s.yaml /etc/k0s/k0s.yaml
```

### 3. Start the Cluster
Initialize the controller with the configuration.
```bash
sudo k0s start controller --single --config /etc/k0s/k0s.yaml
```
Wait for the node to become ready and for KubeArmor pods to start (check `sudo k0s kubectl get pods -n kubearmor`).

### 4. Deploy Infrastructure
Deploy the Gateway API (Envoy) and Cert-Manager.
```bash
sudo k0s kubectl apply -k k8s/infrastructure
```
Wait for the Envoy Gateway pods to be running in `envoy-gateway-system`.

### 5. Deploy Application
Deploy the Wisecow application and its route configuration.
```bash
sudo k0s kubectl apply -k k8s/apps
```

### 6. Apply Security Policies
Apply the KubeArmor hardening policy.
```bash
sudo k0s kubectl apply -f k8s/security/wisecow-hardening.yaml
```

---

## Verification Steps

### 1. Verify Application and TLS
Run the automated health check script to verify both HTTP and HTTPS endpoints. This script automatically detects the gateway IP and performs the necessary checks.

```bash
bash tests/application_health_test.sh
```
**Expected Output:**
Along with hte output you'll see these:
✅ HTTP Test PASSED (Status: 200)

✅ HTTPS Test PASSED (Status: 200)
```

### 2. Verify Security (KubeArmor)
Attempt to read a sensitive file inside the application pod to test the blocking policy.

**Command:**
```bash
POD=$(sudo k0s kubectl get pod -l app=wisecow -o jsonpath="{.items[0].metadata.name}")
sudo k0s kubectl exec -it $POD -- cat /etc/shadow
```
**Expected Output:**
`cat: can't open '/etc/shadow': Permission denied`

**NOTE TO THE READER:**
I have a fundamentally better immutable and deterministic approach for the deployment of this. Like a more single source of truth appproach which could potentially remove the need for **Kubearmor** itself and can be setup easily with less moving parts and more rigid dependency management.