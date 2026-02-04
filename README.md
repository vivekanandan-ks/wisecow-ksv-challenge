# Wisecow - DevOps Practical Assessment

This repository contains the solution for the Accuknox DevOps Trainee Practical Assessment. It demonstrates the containerization, deployment, security hardening, and monitoring of the "Wisecow" application.

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
*   **Audit:** All other process executions are audited.

---

## How to Run Locally (Using k0s)

This project uses `k0s` as the Kubernetes distribution.

### 1. Install k0s
```bash
curl -sSLf https://get.k0s.sh | sudo sh
```

### 2. Configure Cluster (with KubeArmor)
Copy the provided configuration file which includes the KubeArmor Helm chart extension.
```bash
sudo mkdir -p /etc/k0s
# Assuming you are in the project root
sudo cp config/k0s.yaml /etc/k0s/k0s.yaml
```

### 3. Start the Cluster
Initialize the controller with the configuration.
```bash
sudo k0s install controller --single --config /etc/k0s/k0s.yaml
sudo k0s start
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

### 1. Verify Application (HTTP)
The application is exposed via NodePort on port `32202` for HTTP.
```bash
# Replace 192.168.1.7 with your node IP
curl -v http://192.168.1.7:32202
```
**Expected Output:** The "Wisecow" ASCII art response.

### 2. Verify TLS (HTTPS)
The application is exposed via NodePort on port `32220` for HTTPS.
Note: You must use the hostname `wisecow.local` for the TLS handshake to succeed (SNI match).

**Using Curl:**
```bash
# Replace 192.168.1.7 with your node IP
curl -v -k --resolve wisecow.local:32220:192.168.1.7 https://wisecow.local:32220
```
**Expected Output:** Successful TLS handshake (TLS 1.3) and the Wisecow response.

### 3. Verify Security (KubeArmor)
Attempt to read a sensitive file inside the application pod to test the blocking policy.

**Command:**
```bash
POD=$(sudo k0s kubectl get pod -l app=wisecow -o jsonpath="{.items[0].metadata.name}")
sudo k0s kubectl exec -it $POD -- cat /etc/shadow
```
**Expected Output:**
`cat: can't open '/etc/shadow': Permission denied`