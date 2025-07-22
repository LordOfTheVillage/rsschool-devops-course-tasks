# Task 6: Flask Application CI/CD Pipeline with Jenkins

![Python](https://img.shields.io/badge/Python-3.9-blue)
![Flask](https://img.shields.io/badge/Flask-2.3.3-green)
![Docker](https://img.shields.io/badge/Docker-enabled-blue)
![Kubernetes](https://img.shields.io/badge/Kubernetes-1.28+-blue)
![Jenkins](https://img.shields.io/badge/Jenkins-CI%2FCD-orange)

## 📋 Overview

This project implements a complete CI/CD pipeline for a Flask application using Jenkins, Docker, Kubernetes (minikube), and Helm. The pipeline covers the entire software development lifecycle including build, test, security checks, containerization, and deployment.

## 🏗️ Architecture

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Developer     │    │     Jenkins      │    │    Minikube     │
│                 │    │                  │    │                 │
│ 1. Push Code    │───▶│ 2. Trigger       │───▶│ 3. Deploy App   │
│                 │    │    Pipeline      │    │                 │
└─────────────────┘    └──────────────────┘    └─────────────────┘
                                │
                                ▼
                        ┌──────────────────┐
                        │    SonarQube     │
                        │ Security Check   │
                        └──────────────────┘
```

## 🚀 Quick Start

### Prerequisites

- **Windows 10/11** with Docker Desktop
- **Minikube** with Docker driver
- **Jenkins** (local installation or Docker)
- **Helm 3.x**
- **Git**
- **Python 3.9+**

### 1. Setup Minikube Environment

```powershell
# Run the setup script
cd task6
.\jenkins\minikube-setup.sh

# Verify setup
minikube status
kubectl get nodes
```

### 2. Configure Jenkins

1. Install required plugins from `jenkins/jenkins-plugins.txt`
2. Configure Kubernetes plugin with minikube config
3. Set up environment variables:
   ```
   KUBECONFIG=C:\Users\{username}\.kube\config
   DOCKER_REGISTRY=localhost:5000
   SLACK_WEBHOOK_URL=https://hooks.slack.com/services/...
   ```

### 3. Create Jenkins Pipeline

1. New Item → Pipeline
2. Pipeline script from SCM
3. Repository URL: `your-repo-url`
4. Script Path: `task6/Jenkinsfile`

### 4. Run Pipeline

```bash
# Trigger pipeline manually or push to task_6 branch
git push origin task_6
```

## 📦 Application Structure

```
task6/
├── flask_app/                 # Flask application
│   ├── main.py               # Main application file
│   ├── test_main.py          # Unit tests
│   ├── requirements.txt      # Python dependencies
│   ├── Dockerfile            # Container definition
│   └── pytest.ini           # Test configuration
├── flask-app-chart/          # Helm chart
│   ├── Chart.yaml           # Chart metadata
│   ├── values.yaml          # Default values
│   └── templates/           # K8s manifests
├── jenkins/                  # Jenkins configurations
│   ├── minikube-setup.sh    # Environment setup
│   ├── jenkins-plugins.txt  # Required plugins
│   └── slack-notification-template.json
├── Jenkinsfile              # CI/CD pipeline
├── sonar-project.properties # SonarQube config
└── README.md               # This documentation
```

## 🔄 CI/CD Pipeline Stages

### 1. 🚀 Checkout & Setup

- Git repository checkout
- Environment information display
- Workspace preparation

### 2. 🏗️ Application Build

- Python virtual environment setup
- Dependencies installation
- Build artifacts preparation

### 3. 🧪 Unit Tests

- Test execution with pytest
- Code coverage analysis
- Test results publishing
- HTML coverage reports

### 4. 🔐 Security Check (SonarQube)

- Static code analysis
- Security vulnerability scanning
- Quality gate validation
- Code quality metrics

### 5. 🐳 Docker Build & Push

- Container image building
- Image tagging with build number
- Push to local registry (minikube)
- Cleanup of local images

### 6. 🚀 Deploy to Kubernetes

- Helm chart deployment
- Rolling update strategy
- Health check validation
- Service and ingress creation

### 7. ✅ Application Verification

- Health endpoint testing
- Readiness probe validation
- Main application functionality test
- API endpoint verification

## 🔧 Configuration

### Environment Variables

| Variable            | Description         | Example                       |
| ------------------- | ------------------- | ----------------------------- |
| `APP_NAME`          | Application name    | `flask-app`                   |
| `APP_VERSION`       | Build version       | `1.0.${BUILD_NUMBER}`         |
| `DOCKER_REGISTRY`   | Registry URL        | `localhost:5000`              |
| `KUBECONFIG`        | Kubernetes config   | `~/.kube/config`              |
| `SLACK_WEBHOOK_URL` | Slack notifications | `https://hooks.slack.com/...` |

### Helm Values

Key configuration in `flask-app-chart/values.yaml`:

```yaml
image:
  repository: flask-app
  tag: "latest"
  pullPolicy: IfNotPresent

service:
  type: ClusterIP
  port: 8080

ingress:
  enabled: true
  className: "nginx"
  hosts:
    - host: flask-app.local
      paths:
        - path: /
          pathType: Prefix

resources:
  limits:
    cpu: 100m
    memory: 128Mi
  requests:
    cpu: 50m
    memory: 64Mi
```

## 🏥 Health Checks

The application provides several health endpoints:

- **`/health`** - Liveness probe endpoint
- **`/ready`** - Readiness probe endpoint
- **`/version`** - Application version info
- **`/api/test`** - API functionality test

Example response:

```json
{
  "status": "healthy",
  "version": "1.0.0",
  "service": "flask-app"
}
```

## 🧪 Testing

### Running Tests Locally

```powershell
cd task6/flask_app

# Create virtual environment
python -m venv venv
venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt

# Run tests
pytest --verbose --cov=main

# Run with coverage report
pytest --cov=main --cov-report=html
```

### Test Coverage

Current test coverage includes:

- ✅ Main application endpoint
- ✅ Health check endpoints
- ✅ API functionality
- ✅ Error handling (404)

## 🔐 Security

### SonarQube Integration

The pipeline includes security scanning with:

- **Static code analysis**
- **Security vulnerability detection** (Bandit)
- **Code quality metrics**
- **Coverage analysis**

Configuration in `sonar-project.properties`:

```properties
sonar.projectKey=flask-app-devops
sonar.sources=flask_app
sonar.python.coverage.reportPaths=flask_app/coverage.xml
sonar.exclusions=**/venv/**,**/__pycache__/**
```

### Security Best Practices

- ✅ Non-root container execution
- ✅ Resource limits defined
- ✅ Health checks implemented
- ✅ Static code analysis
- ✅ Dependency scanning

## 📧 Notifications

### Slack Integration

Configure Slack notifications in Jenkins:

1. Install Slack Notification Plugin
2. Configure webhook in Jenkins settings
3. Set `SLACK_WEBHOOK_URL` environment variable

Notification templates available in `jenkins/slack-notification-template.json`

### Email Notifications

Email notifications are configured for:

- ✅ Pipeline success
- ❌ Pipeline failure
- ⚠️ Pipeline unstable

## 🚀 Deployment

### Manual Deployment

```powershell
# Build and push image manually
cd task6/flask_app
docker build -t flask-app:manual .
docker tag flask-app:manual localhost:5000/flask-app:manual
docker push localhost:5000/flask-app:manual

# Deploy with Helm
cd ../flask-app-chart
helm upgrade --install flask-app . \
  --set image.tag=manual \
  --set image.repository=localhost:5000/flask-app
```

### Accessing the Application

After deployment:

```powershell
# Get service information
kubectl get services

# Port forward to access locally
kubectl port-forward service/flask-app 8080:8080

# Test the application
curl http://localhost:8080
curl http://localhost:8080/health
```

For ingress access (requires hosts file update):

```
127.0.0.1 flask-app.local
```

Then visit: http://flask-app.local

## 🐛 Troubleshooting

### Common Issues

1. **Minikube registry not accessible**

   ```powershell
   kubectl port-forward --namespace kube-system service/registry 5000:80
   ```

2. **Jenkins can't access Kubernetes**

   - Verify KUBECONFIG path in Jenkins
   - Check Kubernetes plugin configuration
   - Ensure minikube is running

3. **Docker push fails**

   ```powershell
   # Check registry status
   curl http://localhost:5000/v2/

   # Restart port forwarding
   kubectl port-forward --namespace kube-system service/registry 5000:80
   ```

4. **Pipeline fails at SonarQube stage**
   - SonarQube stage skips if SONAR_HOST_URL not set
   - For testing, this stage can be skipped

### Logs and Debugging

```powershell
# Check pod logs
kubectl logs -l app.kubernetes.io/name=flask-app-chart

# Check ingress
kubectl get ingress

# Check events
kubectl get events --sort-by=.metadata.creationTimestamp
```

## 📊 Monitoring

### Application Metrics

The pipeline publishes:

- Test results and coverage
- Build artifacts
- Deployment status
- Performance metrics

### Kubernetes Monitoring

```powershell
# Check deployment status
kubectl get deployments

# Check pod health
kubectl get pods -o wide

# Check resource usage
kubectl top pods
```

## 🏆 Success Criteria

✅ **Pipeline Configuration (40 points)**

- Jenkins pipeline with Jenkinsfile
- All required stages implemented
- Proper error handling

✅ **Artifact Storage (20 points)**

- Docker images in registry
- Helm chart in git repository
- Build artifacts preserved

✅ **Repository Submission (5 points)**

- Complete application in task6 directory
- All files properly organized

✅ **Verification (5 points)**

- Application deploys successfully
- Health checks pass
- All endpoints accessible

✅ **Additional Tasks (30 points)**

- Application verification implemented
- Notification system configured
- Complete documentation provided

## 🤝 Contributing

1. Fork the repository
2. Create feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Open Pull Request

## 📝 License

This project is part of RS School DevOps Course 2025.

## 📞 Support

For issues and questions:

- Check troubleshooting section
- Review Jenkins build logs
- Verify minikube status
- Check Kubernetes events

---

**🎉 Happy Deploying!**

This CI/CD pipeline provides a solid foundation for Flask application deployment with enterprise-grade practices including testing, security scanning, and automated deployment to Kubernetes.
