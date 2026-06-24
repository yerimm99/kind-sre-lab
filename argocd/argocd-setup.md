# ArgoCD GitOps Deployment

이 프로젝트에서는 ArgoCD를 사용하여 GitHub repository 기반 GitOps 배포 환경을 구성했다.

기존에는 `kubectl apply` 명령어로 Kubernetes manifest를 직접 적용했지만, ArgoCD 구성 이후에는 GitHub repository의 `k8s/` 디렉터리를 기준으로 애플리케이션 상태가 자동 동기화되도록 설정했다.

## 구성 요소

- ArgoCD
- GitHub Repository
- ArgoCD Application
- Kubernetes manifests
- `sre-lab` namespace

## 설치

ArgoCD 전용 namespace를 생성한다.

```bash
kubectl create namespace argocd
```

ArgoCD 공식 manifest를 적용한다.

```bash
kubectl apply -n argocd --server-side --force-conflicts \
  -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

ArgoCD Pod 상태를 확인한다.

```bash
kubectl get pods -n argocd
```

모든 Pod가 `Running` 상태가 될 때까지 확인한다.

```bash
kubectl get pods -n argocd -w
```

## ArgoCD 접속

ArgoCD Server는 기본적으로 Kubernetes 클러스터 내부에서만 접근 가능한 Service로 생성된다.  
로컬 Mac 브라우저에서 ArgoCD UI에 접속하기 위해 `kubectl port-forward`를 사용한다.

```bash
kubectl port-forward svc/argocd-server -n argocd 8081:443
```

브라우저에서 아래 주소로 접속한다.

```text
https://localhost:8081
```

초기 계정은 다음과 같다.

```text
username: admin
```

초기 비밀번호는 Kubernetes Secret에서 확인한다.

```bash
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d; echo
```

## Application 설정

ArgoCD Application은 `argocd/application.yaml` 파일로 관리한다.

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: sre-lab-api
  namespace: argocd
spec:
  project: default

  source:
    repoURL: https://github.com/yerimm99/kind-sre-lab.git
    targetRevision: main
    path: k8s

  destination:
    server: https://kubernetes.default.svc
    namespace: sre-lab

  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
```

주요 설정은 다음과 같다.

- `repoURL`: Kubernetes manifest가 저장된 GitHub repository
- `targetRevision`: 배포 기준 브랜치
- `path`: 배포 대상 manifest 디렉터리
- `destination.namespace`: 애플리케이션이 배포될 namespace
- `automated.prune`: Git에서 삭제된 리소스를 클러스터에서도 삭제
- `automated.selfHeal`: 클러스터에서 수동 변경된 리소스를 Git 상태로 복구
- `CreateNamespace=true`: 대상 namespace가 없을 경우 자동 생성

## Application 적용

Application manifest를 적용한다.

```bash
kubectl apply -f argocd/application.yaml
```

Application 상태를 확인한다.

```bash
kubectl get application -n argocd
```

상세 상태를 확인한다.

```bash
kubectl describe application sre-lab-api -n argocd
```

ArgoCD UI에서도 `sre-lab-api` Application의 `Synced`, `Healthy` 상태를 확인할 수 있다.

## GitOps 동기화 테스트

Git 변경사항이 ArgoCD를 통해 Kubernetes 클러스터에 자동 반영되는지 확인하기 위해 Deployment replica 수를 변경했다.

`k8s/deployment.yaml`에서 replica 수를 변경한다.

```yaml
spec:
  replicas: 3
```

변경사항을 commit/push한다.

```bash
git add k8s/deployment.yaml
git commit -m "test argocd sync by updating replicas"
git push
```

ArgoCD가 GitHub repository의 변경사항을 감지하면 Application이 자동으로 동기화된다.

Pod 수가 증가했는지 확인한다.

```bash
kubectl get pods -n sre-lab
```

테스트 후 replica 수를 다시 2로 복구한다.

```yaml
spec:
  replicas: 2
```

복구한 내용도 commit/push한다.

```bash
git add k8s/deployment.yaml
git commit -m "restore replicas to two"
git push
```

## 확인한 내용

ArgoCD 구성 후 다음 내용을 확인했다.

- ArgoCD UI에서 `sre-lab-api` Application 생성 확인
- Application 상태가 `Synced`, `Healthy`로 표시되는지 확인
- GitHub repository의 `k8s/` manifest가 Kubernetes 클러스터에 반영되는지 확인
- Deployment replica 변경 후 commit/push 시 Pod 수가 변경되는지 확인
- `selfHeal` 옵션을 통해 클러스터 수동 변경이 Git 기준 상태로 복구되는 흐름 확인

## GitOps 방식에서 확인한 점

- Git repository가 Kubernetes 리소스의 기준 상태가 된다.
- `kubectl apply`로 직접 배포하지 않아도 Git 변경사항을 기준으로 클러스터 상태가 동기화된다.
- ArgoCD Application은 Git repository, manifest 경로, 배포 대상 namespace, sync 정책을 정의한다.
- `automated sync`를 사용하면 Git commit/push 이후 변경사항이 클러스터에 자동 반영된다.
- `selfHeal`을 통해 클러스터에서 수동 변경된 리소스를 Git 상태로 되돌릴 수 있다.
- `prune`을 통해 Git에서 삭제된 리소스를 클러스터에서도 정리할 수 있다.