# Kube AutoHeal Engine - System Architecture

## Overview
The Kube AutoHeal Engine is an autonomous remediation system that monitors Kubernetes cluster health and automatically resolves common infrastructure issues without manual intervention.

## Architecture Components

### 1. Monitoring Layer
- **Prometheus**: Scrapes metrics from Kubernetes nodes and pods
- **Alert Rules**: Define conditions that trigger alerts (e.g., High CPU > 50%, Memory > 80%)
- **AlertManager**: Processes alerts and routes them via webhooks

### 2. Decision Engine (AI-Engine)
- **Flask API**: Exposes `/alert` webhook endpoint to receive AlertManager events
- **Decision Logic**: Analyzes alerts and determines remediation actions
- **Kubernetes Client**: Communicates with K8s API to execute remediation (scaling, restarts)

### 3. Execution Layer
- **Shell Scripts**: Provide kubectl commands for manual execution if needed
- **K8s Manifests**: Define deployments, services, and configurations
- **Docker Container**: Containerizes the AI-Engine for deployment

### 4. Configuration
- **prometheus.yaml**: Prometheus scrape targets and retention
- **alertmanager.yaml**: Alert routing and webhook configuration
- **alert-rules.yaml**: Prometheus alert rule definitions
- **alerts.json**: Application-level alert configurations

## Data Flow

```
Prometheus (metrics collection)
         ↓
  Alert Rules (evaluation)
         ↓
  AlertManager (routing)
         ↓
  AI-Engine Webhook (/alert)
         ↓
  Decision Engine (logic)
         ↓
  Kubernetes Client (execution)
         ↓
  Remediation Actions (scale, restart)
```

## Supported Actions

1. **Scale Deployment**: Increase replica count for load distribution
2. **Restart Deployment**: Trigger rolling restart for pod recovery
3. **Custom Scripts**: Use shell scripts for complex remediation

## Deployment

The system can be deployed on:
- Local Minikube cluster
- Production Kubernetes clusters
- Any K8s distribution (EKS, AKS, GKE, on-premises)

## Security Considerations

- AI-Engine requires RBAC permissions: deployments (get, patch, scale)
- AlertManager and Prometheus run in isolated namespaces
- Webhook endpoints should be protected with authentication
