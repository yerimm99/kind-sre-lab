# kind-sre-lab

kind 기반 로컬 Kubernetes 환경에서 애플리케이션 배포, 장애 시나리오 분석, HPA 오토스케일링, Prometheus/Grafana 모니터링, ArgoCD GitOps 배포, Terraform 기반 리소스 관리, Atlantis PR 자동화, GitHub Actions CI를 실습한 SRE Lab 프로젝트입니다.

단순히 애플리케이션을 배포하는 것에 그치지 않고, 운영 환경에서 발생할 수 있는 장애 상황을 직접 재현하고 `kubectl describe`, logs, events, metrics를 기반으로 원인을 분석하는 흐름을 정리했습니다.

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

## 5. Kubernetes Baseline with Terraform

- Terraform Kubernetes provider를 사용하여 Kubernetes baseline 리소스 관리
- `sre-lab` namespace의 ConfigMap, ResourceQuota, LimitRange를 Terraform 코드로 구성
- `terraform init`, `plan`, `apply`를 통해 kind 클러스터에 baseline 리소스 적용
- ResourceQuota와 LimitRange를 통해 namespace 단위 리소스 사용량과 기본 컨테이너 request/limit 설정 관리
- 애플리케이션 배포 리소스는 ArgoCD로 관리하고, namespace 운영 기준 리소스는 Terraform으로 분리 관리

## 6. Terraform PR Automation with Atlantis

- Atlantis를 사용하여 Terraform 변경사항을 Pull Request 기반으로 검토하는 흐름 구성
- GitHub Webhook과 ngrok을 통해 로컬 Atlantis 서버가 PR 이벤트를 수신하도록 구성
- `atlantis.yaml`을 통해 `terraform/k8s-baseline` 디렉터리를 Atlantis project로 등록
- Pull Request 생성 시 Atlantis가 Terraform plan을 실행하고 결과를 PR comment로 출력하는지 확인
- `No changes` 결과를 통해 Terraform 코드와 실제 Kubernetes 리소스 상태가 일치함을 확인

## 7. CI Pipeline with GitHub Actions

- GitHub Actions를 사용하여 Pull Request 및 main 브랜치 push 시 CI 검증 수행
- FastAPI 애플리케이션 Docker image build 검증
- Kubernetes manifest YAML 문법 검증
- Terraform fmt, init, validate 검증
- 코드 변경사항이 배포/운영 리소스에 반영되기 전 기본적인 품질 검사를 자동화

## What I Learned

- Kubernetes 애플리케이션 배포와 Ingress 라우팅 흐름을 구성했다.
- CrashLoopBackOff, Ingress 503, HPA Scaling 상황을 직접 재현하고 원인을 분석했다.
- Prometheus/Grafana를 통해 Pod, Node, HPA 지표를 관측했다.
- ArgoCD를 사용하여 Git 기반 배포 흐름을 구성했다.
- Terraform으로 Kubernetes baseline 리소스를 코드로 관리했다.
- Atlantis를 통해 Terraform 변경사항을 Pull Request에서 plan으로 검토하는 흐름을 구성했다.
- GitHub Actions를 사용하여 Docker build, Kubernetes manifest, Terraform 코드 검증을 자동화했다.
