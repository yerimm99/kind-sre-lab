# Atlantis Terraform PR Automation

이 프로젝트에서는 Atlantis를 사용하여 Terraform 변경사항을 Pull Request 기반으로 검토하는 흐름을 구성했다.

Terraform 리소스를 로컬에서 직접 적용하기 전에, GitHub Pull Request에서 `terraform plan` 결과를 확인할 수 있도록 GitHub Webhook, ngrok, Atlantis 서버를 연동했다.

## 구성 요소

- Atlantis
- Terraform
- GitHub Repository
- GitHub Webhook
- ngrok
- Kubernetes provider
- `terraform/k8s-baseline` directory

## Atlantis 설치

Atlantis는 Homebrew를 사용하여 로컬 Mac에 설치했다.

```bash
brew install atlantis
```

설치 후 버전을 확인한다.

```bash
atlantis version
```

## ngrok 실행

로컬에서 실행 중인 Atlantis 서버가 GitHub Webhook 요청을 받을 수 있도록 ngrok을 사용하여 외부 URL을 생성했다.

Atlantis 기본 포트인 `4141`을 ngrok으로 노출한다.

```bash
ngrok http 4141
```

ngrok 실행 후 표시되는 Forwarding 주소를 확인한다.

```text
https://shown-dial-irregular.ngrok-free.dev
```

GitHub Webhook에서는 해당 주소 뒤에 `/events`를 붙여 사용한다.

```text
https://shown-dial-irregular.ngrok-free.dev/events
```

## Atlantis 서버 실행

Atlantis 서버 실행에 필요한 환경변수를 설정한다.

```bash
export ATLANTIS_URL="https://shown-dial-irregular.ngrok-free.dev"
export ATLANTIS_GH_USER="yerimm99"
export ATLANTIS_GH_TOKEN="<YOUR_GITHUB_TOKEN>"
export ATLANTIS_GH_WEBHOOK_SECRET="<YOUR_WEBHOOK_SECRET>"
export ATLANTIS_REPO_ALLOWLIST="github.com/yerimm99/kind-sre-lab"
```

Atlantis 서버를 실행한다.

```bash
atlantis server \
  --atlantis-url="$ATLANTIS_URL" \
  --gh-user="$ATLANTIS_GH_USER" \
  --gh-token="$ATLANTIS_GH_TOKEN" \
  --gh-webhook-secret="$ATLANTIS_GH_WEBHOOK_SECRET" \
  --repo-allowlist="$ATLANTIS_REPO_ALLOWLIST"
```

`ATLANTIS_URL`에는 `/events`를 붙이지 않고 ngrok base URL만 입력한다.

```text
ATLANTIS_URL = https://shown-dial-irregular.ngrok-free.dev
```

GitHub Webhook Payload URL에는 `/events`를 붙인다.

```text
Payload URL = https://shown-dial-irregular.ngrok-free.dev/events
```

## GitHub Webhook 설정

GitHub repository에서 Webhook을 추가한다.

```text
Repository → Settings → Webhooks → Add webhook
```

Webhook 설정값은 다음과 같이 구성했다.

```text
Payload URL: https://shown-dial-irregular.ngrok-free.dev/events
Content type: application/json
Secret: ATLANTIS_GH_WEBHOOK_SECRET 값과 동일하게 입력
SSL verification: Enable SSL verification
```

Webhook 이벤트는 다음 항목을 선택했다.

- Pull requests
- Issue comments
- Pull request reviews
- Pushes

Webhook 설정 후 Recent Deliveries에서 요청이 정상적으로 전달되는지 확인했다.

## Atlantis Project 설정

프로젝트 루트에 `atlantis.yaml` 파일을 생성하여 Atlantis가 Terraform을 실행할 디렉터리를 지정했다.

```yaml
version: 3
projects:
  - name: k8s-baseline
    dir: terraform/k8s-baseline
    workspace: default
    autoplan:
      when_modified:
        - "*.tf"
        - "../**/*.tf"
      enabled: true
```

위 설정을 통해 `terraform/k8s-baseline` 디렉터리의 Terraform 코드가 변경되면 Atlantis가 해당 project 기준으로 plan을 실행한다.

## Pull Request 테스트

Atlantis 동작을 확인하기 위해 테스트 브랜치를 생성했다.

```bash
git checkout -b test/atlantis-plan
```

Terraform 변수 값을 수정한 뒤 commit/push를 수행했다.

```bash
git add terraform/k8s-baseline/variables.tf
git commit -m "test atlantis plan"
git push -u origin test/atlantis-plan
```

GitHub에서 `main` 브랜치를 base로 하고 `test/atlantis-plan` 브랜치를 compare로 선택하여 Pull Request를 생성했다.

```text
base: main
compare: test/atlantis-plan
```

Pull Request 생성 후 Atlantis가 자동으로 Terraform plan을 실행하고 PR comment로 결과를 남기는지 확인했다.

필요한 경우 PR 댓글에 아래 명령어를 직접 입력하여 plan을 다시 실행할 수 있다.

```text
atlantis plan
```

특정 project만 다시 plan 하려면 아래 명령어를 사용한다.

```text
atlantis plan -p k8s-baseline
```

## 확인한 결과

Pull Request에서 Atlantis가 다음과 같이 plan 결과를 comment로 남기는 것을 확인했다.

```text
Ran Plan for project: k8s-baseline
dir: terraform/k8s-baseline
workspace: default

No changes. Your infrastructure matches the configuration.
```

이는 Terraform 코드와 실제 Kubernetes 리소스 상태가 일치한다는 의미이다.

## 확인한 내용

Atlantis 구성 후 다음 내용을 확인했다.

- GitHub Webhook 요청이 ngrok을 통해 로컬 Atlantis 서버로 전달되는지 확인
- Atlantis `/events` endpoint가 정상적으로 동작하는지 확인
- `atlantis.yaml`을 통해 Terraform 실행 디렉터리를 project로 등록
- Pull Request 생성 시 Atlantis가 Terraform plan을 자동 실행하는지 확인
- Terraform plan 결과가 Pull Request comment로 출력되는지 확인
- `No changes` 결과를 통해 Terraform 코드와 실제 클러스터 상태가 일치함을 확인

## 문제 해결

### Webhook Recent Delivery가 404인 경우

GitHub Webhook Payload URL에 `/events`가 포함되어 있는지 확인한다.

```text
https://shown-dial-irregular.ngrok-free.dev/events
```

또한 ngrok 주소가 현재 실행 중인 Forwarding 주소와 동일한지 확인한다.

### `/events` 호출 시 405가 발생하는 경우

아래 명령어로 `/events` endpoint를 확인했을 때 405가 발생할 수 있다.

```bash
curl -i http://localhost:4141/events
curl -i https://shown-dial-irregular.ngrok-free.dev/events
```

`/events` endpoint는 GitHub Webhook의 POST 요청을 처리하는 endpoint이기 때문에, 브라우저나 curl의 GET 요청에는 `405 Method Not Allowed`가 발생할 수 있다.

따라서 405 응답은 endpoint가 존재하고 Atlantis 서버까지 요청이 도달했다는 의미로 볼 수 있다.

### Homebrew tap 설치 오류

아래 명령어는 더 이상 사용하지 않는다.

```bash
brew install runatlantis/tap/atlantis
```

현재는 아래 명령어로 설치한다.

```bash
brew install atlantis
```

## 정리

이번 단계에서는 Atlantis를 사용하여 Terraform 변경사항을 Pull Request 기반으로 검토하는 흐름을 구성했다.

이를 통해 Terraform 코드를 로컬에서 바로 적용하기 전에, GitHub Pull Request에서 plan 결과를 확인하고 변경 내용을 검토하는 IaC 변경관리 방식을 실습했다.