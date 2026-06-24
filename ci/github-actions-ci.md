# GitHub Actions CI Pipeline

이 프로젝트에서는 GitHub Actions를 사용하여 Pull Request 및 main 브랜치 push 시 기본 CI 검증을 수행하도록 구성했다.

애플리케이션 Docker image build, Kubernetes manifest 검증, Terraform fmt/validate 검사를 자동화하여 코드 변경사항이 병합되기 전에 기본적인 품질 검사를 수행할 수 있도록 했다.

## 구성 요소

- GitHub Actions
- Docker build
- Kubernetes manifest validation
- Terraform fmt
- Terraform validate

## Workflow 위치

GitHub Actions workflow 파일은 아래 경로에 작성했다.

```text
.github/workflows/ci.yaml
```

## 실행 조건

CI workflow는 다음 조건에서 실행되도록 구성했다.

- main 브랜치 대상 Pull Request 생성 또는 변경
- main 브랜치 push

```yaml
on:
  pull_request:
    branches:
      - main
  push:
    branches:
      - main
```

## 검증 항목

### Docker Build

FastAPI 애플리케이션의 Docker image build가 정상적으로 수행되는지 확인한다.

```bash
docker build -t kind-sre-lab-api:ci ./app
```

### Kubernetes YAML Validate

Kubernetes manifest 파일의 문법과 schema를 검증한다.

검증 대상은 `k8s/` 디렉터리의 YAML 파일이다.

```bash
kubeconform -strict -summary k8s/*.yaml
```

### Terraform Validate

Terraform baseline 코드의 포맷과 문법을 검증한다.

```bash
terraform fmt -check -recursive
terraform init -backend=false
terraform validate
```

## 확인한 내용

GitHub Actions 구성 후 다음 내용을 확인했다.

- Pull Request 생성 시 CI workflow가 자동 실행되는지 확인
- FastAPI Docker image build 성공 확인
- Kubernetes manifest validation 성공 확인
- Terraform fmt, init, validate 성공 확인
- PR 화면에서 CI check 결과가 표시되는지 확인

## 정리

이번 단계에서는 GitHub Actions를 사용하여 프로젝트의 기본 CI 검증 흐름을 구성했다.

이를 통해 애플리케이션 코드, Kubernetes manifest, Terraform 코드가 병합되기 전에 자동으로 검증되는 구조를 만들었다.