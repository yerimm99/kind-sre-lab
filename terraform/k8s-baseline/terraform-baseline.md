# Terraform Kubernetes Baseline

이 프로젝트에서는 Terraform Kubernetes provider를 사용하여 `sre-lab` namespace의 baseline 리소스를 코드로 관리했다.

애플리케이션 배포 리소스는 `k8s/` manifest와 ArgoCD를 통해 관리하고, ConfigMap, ResourceQuota, LimitRange와 같은 운영 기준 리소스는 Terraform으로 관리하도록 구성했다.

## 구성 요소

- Terraform
- Kubernetes provider
- ConfigMap
- ResourceQuota
- LimitRange
- kind Kubernetes cluster

## 관리 대상 리소스

Terraform으로 관리한 Kubernetes 리소스는 다음과 같다.

- `sre-lab-config` ConfigMap
- `sre-lab-quota` ResourceQuota
- `sre-lab-limit-range` LimitRange

## Provider 설정

Terraform Kubernetes provider는 로컬 kubeconfig를 사용하여 kind 클러스터에 접근하도록 설정했다.

```hcl
provider "kubernetes" {
  config_path    = "~/.kube/config"
  config_context = "kind-sre-lab"
}
```

현재 Kubernetes context는 아래 명령어로 확인할 수 있다.

```bash
kubectl config current-context
```

## Terraform 실행

Terraform 작업 디렉터리로 이동한다.

```bash
cd terraform/k8s-baseline
```

Terraform provider를 초기화한다.

```bash
terraform init
```

Terraform 코드 포맷을 정리한다.

```bash
terraform fmt
```

Terraform 문법 및 provider 설정을 검증한다.

```bash
terraform validate
```

적용 전 변경사항을 확인한다.

```bash
terraform plan
```

문제가 없으면 리소스를 적용한다.

```bash
terraform apply
```

## 적용 확인

ConfigMap이 생성되었는지 확인한다.

```bash
kubectl get configmap -n sre-lab
kubectl describe configmap sre-lab-config -n sre-lab
```

ResourceQuota가 생성되었는지 확인한다.

```bash
kubectl get resourcequota -n sre-lab
kubectl describe resourcequota sre-lab-quota -n sre-lab
```

LimitRange가 생성되었는지 확인한다.

```bash
kubectl get limitrange -n sre-lab
kubectl describe limitrange sre-lab-limit-range -n sre-lab
```

## 리소스 역할

### ConfigMap

`ConfigMap`은 애플리케이션 설정값을 컨테이너 이미지와 분리하여 관리하기 위해 사용했다.

관리하는 주요 값은 다음과 같다.

- `APP_ENV`
- `LOG_LEVEL`

### ResourceQuota

`ResourceQuota`는 namespace 단위의 리소스 사용량을 제한하기 위해 사용했다.

설정한 제한값은 다음과 같다.

- `requests.cpu`: 2
- `requests.memory`: 2Gi
- `limits.cpu`: 4
- `limits.memory`: 4Gi
- `pods`: 20

### LimitRange

`LimitRange`는 namespace 내 컨테이너에 기본 CPU/Memory request와 limit을 설정하기 위해 사용했다.

기본 설정값은 다음과 같다.

- default request cpu: 100m
- default request memory: 128Mi
- default limit cpu: 500m
- default limit memory: 256Mi

## Git 관리 제외 대상

Terraform 실행 시 생성되는 `.terraform/` 디렉터리와 state 파일은 Git에 포함하지 않는다.

`.gitignore`에 아래 항목을 추가한다.

```gitignore
.terraform/
terraform.tfstate
terraform.tfstate.backup
*.tfstate
*.tfstate.*
```

## 확인한 내용

Terraform 적용 후 다음 내용을 확인했다.

- Terraform Kubernetes provider를 통해 kind 클러스터의 Kubernetes 리소스 생성 확인
- `sre-lab` namespace에 ConfigMap, ResourceQuota, LimitRange 생성 확인
- `terraform plan`을 통해 적용 전 변경사항 확인
- `terraform apply`를 통해 baseline 리소스 반영 확인
- 애플리케이션 배포 리소스와 운영 기준 리소스를 분리하여 관리하는 구조 확인

## 정리

이번 단계에서는 Terraform을 사용하여 Kubernetes namespace baseline 리소스를 코드로 관리했다.

이를 통해 애플리케이션 배포는 ArgoCD로 관리하고, namespace 운영 기준 리소스는 Terraform으로 관리하는 구조를 구성했다. 이후 Atlantis를 붙여 Terraform 변경사항을 PR 기반으로 plan/apply하는 흐름으로 확장할 예정이다.