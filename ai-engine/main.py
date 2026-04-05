import logging
from flask import Flask, request, jsonify
from decision_engine import decide_action

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

app = Flask(__name__)

@app.route('/alert', methods=['POST'])
def handle_alert():
    try:
        data = request.json
        if not data or 'alerts' not in data or len(data['alerts']) == 0:
            logger.warning("Invalid alert payload received")
            return jsonify({"error": "Invalid alert payload"}), 400
        
        alert = data['alerts'][0]['labels']['alertname']
        logger.info(f"Received alert: {alert}")
        
        action = decide_action(alert)
        logger.info(f"Action decided: {action}")
        
        return jsonify({"action": action}), 200
    
    except Exception as e:
        logger.error(f"Error processing alert: {str(e)}")
        return jsonify({"error": str(e)}), 500

@app.route('/health', methods=['GET'])
def health_check():
    return jsonify({"status": "healthy"}), 200

if __name__ == "__main__":
    logger.info("Starting AI-Engine on port 5000")
    app.run(host="0.0.0.0", port=5000, debug=False)