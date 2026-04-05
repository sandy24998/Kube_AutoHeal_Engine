import logging
from kubernetes_client import scale_deployment, restart_deployment

logger = logging.getLogger(__name__)

ALERT_ACTIONS = {
    "HighCPUUsage": lambda: scale_deployment("cpu-hog-app", 2),
    "HighMemoryUsage": lambda: restart_deployment("cpu-hog-app"),
    "PodCrashLooping": lambda: restart_deployment("cpu-hog-app"),
}

def decide_action(alert):
    """
    Decide the remediation action based on alert type.
    
    Args:
        alert (str): Alert name from Prometheus
    
    Returns:
        str: Description of action taken
    """
    logger.info(f"Deciding action for alert: {alert}")
    
    if alert not in ALERT_ACTIONS:
        logger.warning(f"Unknown alert type: {alert}")
        return f"No action defined for {alert}"
    
    try:
        action_func = ALERT_ACTIONS[alert]
        result = action_func()
        logger.info(f"Successfully executed action for {alert}: {result}")
        return result
    except Exception as e:
        logger.error(f"Error executing action for {alert}: {str(e)}")
        return f"Error: {str(e)}"
