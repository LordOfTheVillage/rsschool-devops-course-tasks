# Task 5: Flask Application Deployment with Helm

This project deploys a simple Flask application in Kubernetes using Helm.

## 🛠️ Requirements

- Docker
- Minikube
- Helm 3.x
- kubectl

## Deploying the Application

### 1. Environment Setup

```bash
minikube start

minikube addons enable ingress

minikube docker-env --shell powershell | Invoke-Expression
```

### 2. Docker image

```bash
cd flask_app
docker build -t flask-app:latest .
```

### 3. Deployment with Helm

```bash
helm install flask-app ./flask-app-chart

kubectl get pods
kubectl get services
kubectl get ingress
```

### 4. Access to application

#### V1: Port Forward

```bash
kubectl port-forward service/flask-app-flask-app-chart 8080:8080
```

Open in browser: http://localhost:8080

#### V2: Through Ingress

1. Get IP minikube:

```bash
minikube ip
```

2. Add in file hosts:
   - Windows: `C:\Windows\System32\drivers\etc\hosts`
   - Linux/Mac: `/etc/hosts`

```
192.168.49.2 flask-app.local
```

3. Open in browser: http://flask-app.local

## 📊 State check

```bash
kubectl get pods

kubectl get services

kubectl get ingress

kubectl logs -l app.kubernetes.io/name=flask-app-chart

helm list
```

## 🧹 Remove

```bash
helm uninstall flask-app
```

## 📋 Helm Chart config

### Main parameters (values.yaml)

- `replicaCount: 1`
- `image.repository: flask-app`
- `image.tag: latest`
- `service.port: 8080` 
- `ingress.enabled: true`
- `resources.limits` -

### Resource settings

```yaml
resources:
  limits:
    cpu: 100m
    memory: 128Mi
  requests:
    cpu: 50m
    memory: 64Mi
```

## 🏗️ Arch of deployment

```
[Браузер]
    ↓
[Ingress] (flask-app.local)
    ↓
[Service] (flask-app-flask-app-chart:8080)
    ↓
[Deployment] (flask-app-flask-app-chart)
    ↓
[Pod] (flask-app:latest)
```