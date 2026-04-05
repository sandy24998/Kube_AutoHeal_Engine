from kubernetes import client, config

def load_kube_config():
    """Load Kubernetes configuration from in-cluster or kubeconfig"""
    try:
        config.load_incluster_config()
    except config.config_exception.ConfigException:
        config.load_kube_config()

def scale_deployment(name, replicas, namespace="default"):
    """Scale a Kubernetes deployment to specified replicas"""
    load_kube_config()
    v1 = client.AppsV1Api()
    
    deployment = v1.read_namespaced_deployment(name, namespace)
    deployment.spec.replicas = replicas
    v1.patch_namespaced_deployment(name, namespace, deployment)
    return f"Scaled {name} to {replicas} replicas"

def restart_deployment(name, namespace="default"):
    """Restart a Kubernetes deployment by rolling out restart"""
    load_kube_config()
    v1 = client.AppsV1Api()
    
    deployment = v1.read_namespaced_deployment(name, namespace)
    deployment.spec.template.metadata.annotations = {
        "kubectl.kubernetes.io/restartedAt": str(__import__('datetime').datetime.now())
    }
    v1.patch_namespaced_deployment(name, namespace, deployment)
    return f"Restarted {name}"

def get_pod_metrics(namespace="default"):
    """Retrieve pod metrics for monitoring"""
    load_kube_config()
    v1 = client.CoreV1Api()
    
    pods = v1.list_namespaced_pod(namespace)
    return [{"name": pod.metadata.name, "status": pod.status.phase} for pod in pods.items]
