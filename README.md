# Kube_AutoHeal_Engine 🚀

An AI-driven autonomous remediation engine for Kubernetes. This project monitors cluster health via Prometheus and uses a Python-based decision engine to automatically resolve infrastructure issues.

## Architecture
- **Monitoring:** Prometheus & Alertmanager
- **Logic:** Python AI-Engine (Decision Logic)
- **Execution:** Kubernetes Python Client
- **Infrastructure:** Minikube / Kubernetes Manifests
- **Containerization:** Docker

## Quick Start

### One-Command Deployment
```bash
bash deploy.sh
```

This script will:
1. Build Docker image
2. Start Minikube
3. Load image into Minikube
4. Deploy all services in correct order
5. Verify deployment
6. Display access information

### Cleanup
```bash
bash cleanup.sh                    # Stop services and Minikube
bash cleanup.sh --full             # Delete entire Minikube cluster
bash cleanup.sh --keep-minikube    # Keep Minikube running
```

## Prerequisites
- Docker
- Minikube
- kubectl
- Python 3.9+
- Git

## Project Structure
```
.
├── ai-engine/              # Core Flask application
│   ├── main.py             # Flask webhook server
│   ├── decision_engine.py  # Decision logic
│   ├── kubernetes_client.py# K8s API integration
│   ├── requirements.txt   
│   └── Dockerfile
├── k8s/                    # Kubernetes manifests
│   ├── ai-engine-*.yaml   # AI-Engine deployment &  resources
│   ├── prometheus/        # Prometheus configurations
│   └── alertmanager/      # AlertManager configurations
├── config/                # Application configurations
│   └── alerts.json       # Alert definitions
├── docs/                  # Documentation
│   └── architecture.md   
├── deploy.sh              # **Complete deployment automation**
└── cleanup.sh             # **Cleanup and shutdown automation**
```
