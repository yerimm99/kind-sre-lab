## Monitoring Setup

이 프로젝트에서는 `kube-prometheus-stack`을 사용하여 로컬 Kubernetes 모니터링 환경을 구성했다.

### 구성 요소

- Prometheus
- Grafana
- Alertmanager
- kube-state-metrics
- node-exporter

### 설치

```bash
./monitoring/install-monitoring.sh
```

스크립트 실행 권한이 없을 경우 아래 명령어를 실행한다.

```bash
chmod +x monitoring/install-monitoring.sh
./monitoring/install-monitoring.sh
```

### Grafana 접속

Grafana는 기본적으로 Kubernetes 클러스터 내부에서만 접근 가능한 `ClusterIP` Service로 생성된다.  
로컬 Mac 브라우저에서 Grafana에 접속하기 위해 `kubectl port-forward`를 사용한다.

```bash
kubectl port-forward svc/monitoring-grafana -n monitoring 3000:80
```

브라우저에서 아래 주소로 접속한다.

```text
http://localhost:3000
```

기본 계정은 다음과 같다.

```text
username: admin
```

초기 비밀번호는 Kubernetes Secret에서 확인한다.

```bash
kubectl get secret monitoring-grafana -n monitoring \
  -o jsonpath="{.data.admin-password}" | base64 --decode; echo
```

초기 비밀번호가 동작하지 않을 경우 아래 명령어로 admin 비밀번호를 재설정할 수 있다.

```bash
kubectl exec -n monitoring deploy/monitoring-grafana -c grafana -- \
  grafana cli admin reset-admin-password admin1234
```

### 확인한 모니터링 지표

Grafana Dashboard에서 다음 지표를 확인했다.

- Pod CPU 사용량
- Pod Memory 사용량
- Deployment replica 수
- HPA scaling 동작
- Node CPU / Memory 사용량

### 모니터링 테스트

CPU 부하를 발생시키기 위해 `/api/cpu-load` 엔드포인트를 반복 호출했다.

```bash
while true; do curl -s http://sre-lab.local:8080/api/cpu-load > /dev/null; done
```

다른 터미널에서 HPA와 Pod 상태를 확인했다.

```bash
kubectl get hpa -n sre-lab -w
kubectl top pods -n sre-lab
kubectl get pods -n sre-lab -w
```

Grafana에서는 `sre-lab` namespace를 선택하여 CPU 사용량 증가, Pod replica 증가, 신규 Pod 생성 흐름을 확인했다.

테스트가 끝난 뒤 부하 발생 명령어는 `Ctrl + C`로 중지한다.