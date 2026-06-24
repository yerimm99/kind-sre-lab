# kind-sre-lab

## 1. Local Kubernetes Cluster Setup

- Docker Desktop 기반 로컬 컨테이너 환경 구성
- kind를 사용하여 1 control-plane, 2 worker node Kubernetes 클러스터 생성
- Ingress NGINX Controller 설치
- FastAPI 테스트 애플리케이션 Docker 이미지 빌드 및 kind 클러스터에 로드
- Deployment, Service, Ingress 리소스를 통해 `sre-lab.local:8080`으로 애플리케이션 접근 확인

## 2. Incident Scenarios

- [Incident 01 - CrashLoopBackOff](./incidents/01-crashloopbackoff.md)
- [Incident 02 - Ingress 503 due to Service selector mismatch](./incidents/02-ingress-service-selector-mismatch.md)
- [Incident 03 - HPA CPU Scaling](./incidents/03-hpa-cpu-scaling.md)

## 3. Monitoring Setup

- `kube-prometheus-stack` Helm chart를 사용하여 Prometheus/Grafana 기반 모니터링 환경 구성
- `monitoring` namespace에 Prometheus, Grafana, Alertmanager, kube-state-metrics, node-exporter 설치
- `kubectl port-forward`를 통해 로컬 브라우저에서 Grafana 대시보드 접근 확인
- Grafana에서 `sre-lab` namespace의 Pod CPU/Memory 사용량 및 Node 리소스 상태 확인
- HPA 부하 테스트 시 CPU 사용량 증가와 Pod replica 증가 흐름을 Grafana Dashboard에서 확인

 ## 4. GitOps Deployment with ArgoCD

- ArgoCD를 설치하여 GitHub repository 기반 GitOps 배포 환경 구성
- `argocd/application.yaml`을 통해 `k8s/` manifest를 ArgoCD Application으로 등록
- GitHub `main` 브랜치의 `k8s/` 디렉터리를 배포 소스로 설정
- ArgoCD automated sync를 사용하여 Git 변경사항이 Kubernetes 클러스터에 자동 반영되도록 구성
- Deployment replica 변경 테스트를 통해 Git commit/push 이후 ArgoCD가 애플리케이션 상태를 동기화하는 흐름 확인