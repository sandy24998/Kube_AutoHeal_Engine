import subprocess

def decide_action(alert):
    if alert == "HighCPUUsage":
        return scale_deployment()
    else:
        return "No action"

def scale_deployment():
    subprocess.run(["kubectl", "scale", "deployment/cpu-hog-app", "--replicas=2"])
    return "Scaled deployment to 2 replicas"