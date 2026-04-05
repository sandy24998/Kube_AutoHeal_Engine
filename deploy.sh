#!/bin/bash

###############################################################################
# Kube_AutoHeal_Engine - Complete Deployment Automation Script
# 
# This script automates the entire deployment process:
# 1. Builds Docker image
# 2. Starts Minikube
# 3. Loads image into Minikube
# 4. Deploys all services in correct order
# 5. Verifies deployment
#
# Usage: bash deploy.sh
###############################################################################

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PROJECT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
DOCKER_IMAGE="ai-engine:latest"
NAMESPACE="default"
TIMEOUT=300

# Helper functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[✗]${NC} $1"
}

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    if ! command -v docker &> /dev/null; then
        log_error "Docker is not installed"
        exit 1
    fi
    log_success "Docker installed"
    
    if ! command -v minikube &> /dev/null; then
        log_error "Minikube is not installed"
        exit 1
    fi
    log_success "Minikube installed"
    
    if ! command -v kubectl &> /dev/null; then
        log_error "kubectl is not installed"
        exit 1
    fi
    log_success "kubectl installed"
    
    echo ""
}

# Phase 1: Build Docker Image
build_docker_image() {
    log_info "========== Phase 1: Building Docker Image =========="
    
    log_info "Building Docker image: $DOCKER_IMAGE"
    cd "$PROJECT_DIR/ai-engine"
    docker build -t $DOCKER_IMAGE .
    
    log_success "Docker image built successfully"
    docker images | grep ai-engine
    echo ""
    
    cd "$PROJECT_DIR"
}

# Phase 2: Start Minikube
start_minikube() {
    log_info "========== Phase 2: Starting Minikube =========="
    
    log_info "Checking Minikube status..."
    if minikube status &> /dev/null; then
        status=$(minikube status | grep "host:" | awk '{print $2}')
        if [ "$status" = "Running" ]; then
            log_warning "Minikube is already running, skipping start"
        else
            log_info "Starting Minikube..."
            minikube start
            log_success "Minikube started"
        fi
    else
        log_info "Starting Minikube..."
        minikube start
        log_success "Minikube started"
    fi
    
    sleep 3
    minikube status
    echo ""
}

# Phase 3: Load Docker Image into Minikube
load_image_to_minikube() {
    log_info "========== Phase 3: Loading Docker Image into Minikube =========="
    
    log_info "Loading Docker image into Minikube: $DOCKER_IMAGE"
    minikube image load $DOCKER_IMAGE
    
    log_success "Docker image loaded into Minikube"
    
    # Verify image is loaded
    log_info "Verifying image in Minikube..."
    minikube ssh docker image ls | grep ai-engine || true
    echo ""
}

# Phase 4: Deploy Services
deploy_services() {
    log_info "========== Phase 4: Deploying Services =========="
    
    # 4.1: Deploy RBAC
    log_info "Step 1/5: Deploying RBAC..."
    kubectl apply -f "$PROJECT_DIR/k8s/ai-engine-rbac.yaml"
    log_success "RBAC deployed"
    
    # 4.2: Deploy AI-Engine
    log_info "Step 2/5: Deploying AI-Engine..."
    kubectl apply -f "$PROJECT_DIR/k8s/ai-engine-deployment.yaml"
    kubectl apply -f "$PROJECT_DIR/k8s/ai-engine-service.yaml"
    
    log_info "Waiting for AI-Engine pod to be ready (timeout: ${TIMEOUT}s)..."
    kubectl wait --for=condition=ready pod -l app=ai-engine --timeout=${TIMEOUT}s -n $NAMESPACE || {
        log_warning "Timeout waiting for AI-Engine pod"
        kubectl logs -l app=ai-engine -n $NAMESPACE || true
        return 1
    }
    log_success "AI-Engine deployed and running"
    
    # 4.3: Deploy Prometheus
    log_info "Step 3/5: Deploying Prometheus..."
    kubectl apply -f "$PROJECT_DIR/k8s/prometheus/prometheus.yaml"
    log_success "Prometheus deployed"
    
    # 4.4: Deploy Alert Rules
    log_info "Step 4/5: Deploying Alert Rules..."
    kubectl apply -f "$PROJECT_DIR/k8s/prometheus/alert-rules.yaml"
    log_success "Alert rules deployed"
    
    # 4.5: Deploy AlertManager
    log_info "Step 5/5: Deploying AlertManager..."
    kubectl apply -f "$PROJECT_DIR/k8s/alertmanager/alertmanager.yaml"
    log_success "AlertManager deployed"
    
    echo ""
}

# Phase 5: Verification
verify_deployment() {
    log_info "========== Phase 5: Verifying Deployment =========="
    
    log_info "Checking all pods..."
    kubectl get pods -n $NAMESPACE
    echo ""
    
    log_info "Checking all services..."
    kubectl get svc -n $NAMESPACE
    echo ""
    
    log_info "Checking AI-Engine deployment details..."
    kubectl describe deployment ai-engine -n $NAMESPACE | head -20
    echo ""
    
    log_info "Checking recent logs from AI-Engine..."
    kubectl logs deployment/ai-engine -n $NAMESPACE --tail=10 || true
    echo ""
    
    log_success "Deployment verification complete"
}

# Phase 6: Display Access Information
display_access_info() {
    log_info "========== Phase 6: Access Information =========="
    
    echo -e "${YELLOW}To access the services, use the following commands:${NC}"
    echo ""
    echo "1. AI-Engine Webhook (Port 5000):"
    echo "   ${BLUE}kubectl port-forward svc/ai-engine-service 5000:5000${NC}"
    echo ""
    echo "2. Prometheus Dashboard (Port 9090):"
    echo "   ${BLUE}minikube service prometheus --url${NC}"
    echo ""
    echo "3. AlertManager Dashboard (Port 9093):"
    echo "   ${BLUE}kubectl port-forward svc/alertmanager 9093:9093${NC}"
    echo ""
    
    echo -e "${YELLOW}Testing the AI-Engine webhook:${NC}"
    echo "   ${BLUE}curl -X POST http://localhost:5000/alert \\${NC}"
    echo "   ${BLUE}-H 'Content-Type: application/json' \\${NC}"
    echo "   ${BLUE}-d '{\"alerts\": [{\"labels\": {\"alertname\": \"HighCPUUsage\"}}]}'${NC}"
    echo ""
    
    echo -e "${YELLOW}View logs:${NC}"
    echo "   ${BLUE}kubectl logs deployment/ai-engine -f${NC}"
    echo ""
}

# Main execution
main() {
    echo -e "${GREEN}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║  Kube_AutoHeal_Engine - Complete Deployment Script          ║"
    echo "║  Version: 1.0                                               ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""
    
    # Run all phases
    check_prerequisites
    build_docker_image
    start_minikube
    load_image_to_minikube
    deploy_services
    verify_deployment
    display_access_info
    
    echo -e "${GREEN}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║  ✓ Deployment Complete!                                     ║"
    echo "║                                                              ║"
    echo "║  Your Kube_AutoHeal_Engine is now running on Minikube       ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""
}

# Error handling
trap 'log_error "Script failed at line $LINENO"; exit 1' ERR

# Run main function
main "$@"
