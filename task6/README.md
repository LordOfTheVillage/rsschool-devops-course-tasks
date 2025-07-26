# Flask Application CI/CD Pipeline

A complete CI/CD pipeline for Flask application deployment using Jenkins, SonarQube Cloud, Docker, and Kubernetes.

## 🏗️ Architecture Overview

```
GitHub → Jenkins → SonarQube Cloud → Docker Registry → Kubernetes (Helm)
                                                           ↓
                                              Telegram Notifications
```

## 📦 Project Structure

```
task6/
├── flask_app/                 # Flask application source code
│   ├── main.py               # Main application file
│   ├── test_main.py          # Unit tests
│   ├── requirements.txt      # Python dependencies
│   ├── Dockerfile           # Docker image definition
│   └── pytest.ini          # Test configuration
├── flask-app-chart/         # Helm chart for Kubernetes deployment
│   ├── Chart.yaml
│   ├── values.yaml
│   └── templates/
├── jenkins-agent.yaml       # Kubernetes Pod template for Jenkins agent
├── k8s-setup.yaml          # Kubernetes resources (ServiceAccount, RBAC)
├── Jenkinsfile             # CI/CD pipeline definition
└── README.md               # This documentation
```

## 🚀 Pipeline Stages

### 1. 🚀 Checkout

- Clones the repository
- Displays Git information (branch, commit, author)

### 2. 🔐 SonarQube Analysis

- Performs static code analysis using SonarQube Cloud
- Analyzes Python code for bugs, vulnerabilities, and code smells
- **Organization:** `lordofthevillage`
- **Project:** `lordofthevillage_rsschool-devops-course-tasks`

### 3. 🧪 Run Tests

- Executes unit tests with pytest
- Generates code coverage reports
- Publishes coverage results in Jenkins

### 4. 🐳 Build Docker Image

- Builds Docker image using the Dockerfile
- Tags image with build number: `flask-app:1.0.${BUILD_NUMBER}`

### 5. 📤 Push Docker Image

- Pushes Docker image to local registry
- Registry URL: `10.110.122.152:80`

### 6. 🚀 Deploy with Helm

- Deploys application to Kubernetes using Helm
- Updates image tag to current build number
- Waits for deployment completion

### 7. ✅ Health Check

- Verifies application endpoints:
  - `/health` - Health check endpoint
  - `/ready` - Readiness check endpoint
  - `/` - Main application page
  - `/api/test` - API functionality test

### 8. 📱 Notifications

- Sends Telegram notifications for pipeline status
- Includes build information and links

## 🛠️ Prerequisites

### Infrastructure Requirements

- **Kubernetes cluster** (minikube for development)
- **Jenkins** with Kubernetes plugin
- **Docker registry** (local registry in minikube)
- **SonarQube Cloud** account

### Jenkins Configuration

1. **Kubernetes Plugin** - for dynamic agent provisioning
2. **SonarQube Scanner Plugin** - for code analysis
3. **Credentials:**
   - `TELEGRAM_BOT_TOKEN` - Telegram bot token
   - `TELEGRAM_CHAT_ID` - Telegram chat ID for notifications

### Kubernetes Resources

```bash
# Apply Kubernetes resources
kubectl apply -f task6/k8s-setup.yaml

# Create SonarQube token secret
kubectl create secret generic sonarqube-token \
  --from-literal=SONAR_TOKEN=<your-sonarqube-token>
```

## 📱 Telegram Notifications Setup

### 1. Create Telegram Bot

1. Message @BotFather in Telegram
2. Send `/newbot` command
3. Follow instructions to create bot
4. Save the bot token

### 2. Get Chat ID

1. Message @userinfobot in Telegram
2. Copy your Chat ID

### 3. Configure Jenkins Credentials

- **TELEGRAM_BOT_TOKEN**: Secret text with bot token
- **TELEGRAM_CHAT_ID**: Secret text with chat ID

## 🔐 SonarQube Cloud Setup

### 1. Create Project

1. Go to [sonarcloud.io](https://sonarcloud.io)
2. Create organization: `lordofthevillage`
3. Create project: `lordofthevillage_rsschool-devops-course-tasks`

### 2. Generate Token

1. Go to My Account → Security → Generate Tokens
2. Create a token for Jenkins integration

### 3. Configure Kubernetes Secret

```bash
echo -n "your-sonar-token" | base64
kubectl patch secret sonarqube-token -p='{"data":{"SONAR_TOKEN":"<base64-encoded-token>"}}'
```

## 🐳 Docker Registry

The pipeline uses a local Docker registry running in minikube:

```bash
# Enable registry addon
minikube addons enable registry

# Check registry service
kubectl get svc -n kube-system registry
```

## 📊 Application Endpoints

After deployment, the application exposes:

- **Main page:** `http://<service-ip>/`
- **Health check:** `http://<service-ip>/health`
- **Readiness:** `http://<service-ip>/ready`
- **API test:** `http://<service-ip>/api/test`

## 🔍 Monitoring and Verification

### Build Artifacts

- **Docker Images:** Stored in local registry
- **Helm Charts:** Version controlled in Git
- **Coverage Reports:** Available in Jenkins UI
- **SonarQube Reports:** Available at sonarcloud.io

### Application Verification

The pipeline automatically verifies:

1. Health endpoint responds with 200
2. Readiness endpoint responds with 200
3. Main page contains "Hello, World!"
4. API endpoint returns "API is working"

## 🚨 Troubleshooting

### Common Issues

#### Pipeline Fails at SonarQube Stage

- **Cause:** OutOfMemoryError in SonarQube scanner
- **Solution:** Increase memory allocation in `jenkins-agent.yaml`

#### Docker Build Fails

- **Cause:** Docker socket not accessible
- **Solution:** Ensure Docker socket is mounted correctly

#### Helm Deployment Fails

- **Cause:** Insufficient RBAC permissions
- **Solution:** Check ServiceAccount and ClusterRole configuration

### Debug Commands

```bash
# Check Jenkins agent pods
kubectl get pods -l jenkins/jenkins-jenkins-agent=true

# Check application deployment
kubectl get pods -l app.kubernetes.io/name=flask-app-chart

# View application logs
kubectl logs -l app.kubernetes.io/name=flask-app-chart

# Check service status
kubectl get svc -l app.kubernetes.io/name=flask-app-chart
```

## 📈 Metrics and Quality Gates

### SonarQube Quality Metrics

- **Reliability:** Code bugs and error-prone constructs
- **Security:** Vulnerabilities and security hotspots
- **Maintainability:** Code smells and technical debt
- **Coverage:** Unit test coverage percentage

### Pipeline Performance

- **Average build time:** ~8 minutes
- **Success rate:** Monitored via Jenkins
- **Deployment frequency:** On every successful build

## 🔄 Continuous Improvement

### Future Enhancements

1. **Multi-environment deployments** (dev, staging, prod)
2. **Integration tests** with test containers
3. **Performance testing** with load tests
4. **Security scanning** with container vulnerability scans
5. **GitOps integration** with ArgoCD

## 📝 Changelog

- **v1.0.11:** Added comprehensive documentation
- **v1.0.10:** Fixed SonarQube memory allocation
- **v1.0.9:** Updated SonarQube project configuration
- **v1.0.1-8:** Initial pipeline development and fixes

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make changes and test locally
4. Submit a pull request
5. Ensure pipeline passes all stages

## 📄 License

This project is for educational purposes as part of RS School DevOps course.

---

**Built with ❤️ using Jenkins, Kubernetes, and modern DevOps practices**
