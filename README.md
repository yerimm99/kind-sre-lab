# kind-sre-lab

## 1. Local Kubernetes Cluster Setup

- Docker Desktop 기반 로컬 컨테이너 환경 구성
- kind를 사용하여 1 control-plane, 2 worker node Kubernetes 클러스터 생성
- Ingress NGINX Controller 설치
- FastAPI 테스트 애플리케이션 Docker 이미지 빌드 및 kind 클러스터에 로드
- Deployment, Service, Ingress 리소스를 통해 `sre-lab.local:8080`으로 애플리케이션 접근 확인

## 2. Incident Scenarios

- [Incident 01 - CrashLoopBackOff](./incidents/01-crashloopbackoff.md)