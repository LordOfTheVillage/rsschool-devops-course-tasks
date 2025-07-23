from flask import Flask, jsonify
import os

app = Flask(__name__)

VERSION = "1.0.0"

@app.route('/')
def hello():
    return 'Hello, World!'

@app.route('/health')
def health():
    """Health check endpoint for liveness probe"""
    return jsonify({
        'status': 'healthy',
        'version': VERSION,
        'service': 'flask-app'
    })

@app.route('/ready')
def ready():
    """Readiness check endpoint for readiness probe"""
    return jsonify({
        'status': 'ready',
        'version': VERSION,
        'service': 'flask-app'
    })

@app.route('/version')
def version():
    """Version endpoint"""
    return jsonify({
        'version': VERSION,
        'service': 'flask-app'
    })

@app.route('/api/test')
def api_test():
    """Test API endpoint for verification"""
    return jsonify({
        'message': 'API is working',
        'status': 'success',
        'version': VERSION
    })

if __name__ == '__main__':
    port = int(os.environ.get('PORT', 8080))
    app.run(host='0.0.0.0', port=port, debug=False)