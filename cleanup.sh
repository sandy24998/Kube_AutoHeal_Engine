#!/bin/bash

###############################################################################
# Kube_AutoHeal_Engine - Cleanup and Shutdown Script
#
# This script safely shuts down and cleans up all deployed services:
# 1. Deletes all Kubernetes resources
# 2. Stops Minikube
# 3. Optionally purges Docker images
#
# Usage: bash cleanup.sh [--full] [--keep-minikube]
#
# Options:
#   --full           : Also delete the Minikube cluster (vm deleted)
#   --keep-minikube  : Keep Minikube running (only delete K8s resources)
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

# Parse arguments
FULL_CLEANUP=false
KEEP_MINIKUBE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --full)
            FULL_CLEANUP=true
            shift
            ;;
        --keep-minikube)
            KEEP_MINIKUBE=true
            shift
            ;;
        *)
            echo "Unknown option: $1"
            echo "Usage: bash cleanup.sh [--full] [--keep-minikube]"
            exit 1
            ;;
    esac
done

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

# Main cleanup function
main() {
    echo -e "${GREEN}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║  Kube_AutoHeal_Engine - Cleanup Script                      ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""
    
    # Phase 1: Delete Kubernetes resources
    log_info "========== Phase 1: Deleting Kubernetes Resources =========="
    
    log_info "Deleting all resources from $NAMESPACE namespace..."
    
    log_info "Deleting AlertManager resources..."
    kubectl delete -f "$PROJECT_DIR/k8s/alertmanager/alertmanager.yaml" --ignore-not-found=true
    log_success "AlertManager deleted"
    
    log_info "Deleting Prometheus alert rules..."
    kubectl delete -f "$PROJECT_DIR/k8s/prometheus/alert-rules.yaml" --ignore-not-found=true
    log_success "Alert rules deleted"
    
    log_info "Deleting Prometheus..."
    kubectl delete -f "$PROJECT_DIR/k8s/prometheus/prometheus.yaml" --ignore-not-found=true
    log_success "Prometheus deleted"
    
    log_info "Deleting AI-Engine services..."
    kubectl delete -f "$PROJECT_DIR/k8s/ai-engine-service.yaml" --ignore-not-found=true
    kubectl delete -f "$PROJECT_DIR/k8s/ai-engine-deployment.yaml" --ignore-not-found=true
    log_success "AI-Engine services deleted"
    
    log_info "Deleting RBAC resources..."
    kubectl delete -f "$PROJECT_DIR/k8s/ai-engine-rbac.yaml" --ignore-not-found=true
    log_success "RBAC resources deleted"
    
    echo ""
    
    log_info "Verifying all pods are deleted..."
    sleep 3
    pod_count=$(kubectl get pods -n $NAMESPACE --no-headers 2>/dev/null | wc -l)
    if [ $pod_count -eq 0 ]; then
        log_success "All pods deleted"
    else
        log_warning "Some pods still exist: $pod_count"
    fi
    echo ""
    
    # Phase 2: Stop Minikube
    if [ "$KEEP_MINIKUBE" = false ]; then
        log_info "========== Phase 2: Stopping Minikube =========="
        
        if minikube status &> /dev/null; then
            status=$(minikube status | grep "host:" | awk '{print $2}')
            if [ "$status" = "Running" ]; then
                log_info "Stopping Minikube..."
                minikube stop
                log_success "Minikube stopped"
            else
                log_warning "Minikube is already stopped"
            fi
        else
            log_info "Minikube not configured, skipping stop"
        fi
        echo ""
    else
        log_warning "Keeping Minikube running (--keep-minikube flag used)"
        echo ""
    fi
    
    # Phase 3: Full cleanup (delete Minikube VM)
    if [ "$FULL_CLEANUP" = true ]; then
        log_info "========== Phase 3: Full Cleanup (Delete Minikube Cluster) =========="
        
        log_warning "This will delete the entire Minikube cluster VM"
        read -p "Are you sure? (yes/no): " confirm
        
        if [ "$confirm" = "yes" ]; then
            log_info "Deleting Minikube cluster..."
            minikube delete
            log_success "Minikube cluster deleted"
        else
            log_info "Full cleanup cancelled"
        fi
        echo ""
    fi
    
    # Phase 4: Docker image cleanup (optional)
    log_info "========== Phase 4: Docker Image Status =========="
    
    if docker images | grep -q "$DOCKER_IMAGE"; then
        log_info "Docker image '$DOCKER_IMAGE' still exists"
        log_info "To remove it, run: ${BLUE}docker rmi $DOCKER_IMAGE${NC}"
    else
        log_warning "Docker image '$DOCKER_IMAGE' not found"
    fi
    echo ""
    
    # Final summary
    echo -e "${GREEN}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║  ✓ Cleanup Complete!                                        ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""
    
    log_info "Cleanup Summary:"
    echo "  • All Kubernetes resources deleted from $NAMESPACE namespace"
    if [ "$KEEP_MINIKUBE" = false ]; then
        echo "  • Minikube stopped"
    fi
    if [ "$FULL_CLEANUP" = true ]; then
        echo "  • Minikube cluster VM deleted"
    fi
    echo "  • Docker image available for manual cleanup"
    echo ""
}

# Run main function
main "$@"
