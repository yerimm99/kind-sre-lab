# Incident 02 - Ingress 503 due to Service selector mismatch

## 1. Summary

Service의 `selector`를 잘못 설정하여 Ingress를 통한 애플리케이션 접근이 `503 Service Temporarily Unavailable`로 실패하는 상황을 재현했다.

Pod는 정상적으로 `Running` 상태였지만, Service selector가 Pod label과 일치하지 않아 Endpoint가 생성되지 않았다. 그 결과 Ingress가 요청을 전달할 backend를 찾지 못해 503 응답이 발생했다.

---

## 2. Symptoms

```bash
curl -i http://sre-lab.local:8080/health
```

Ingress를 통한 `/health` 요청 결과 `503 Service Temporarily Unavailable` 응답이 발생했다.

주요 증상은 다음과 같다.

* FastAPI Pod는 `Running` 상태
* Ingress 리소스는 정상 존재
* Service도 정상 존재
* 그러나 Service에 연결된 Endpoint가 없음
* Ingress 요청이 backend Pod로 전달되지 못함

---

## 3. Investigation

Pod 상태와 label을 확인했다.

```bash
kubectl get pods -n sre-lab --show-labels
```

Pod는 정상적으로 `Running` 상태였고, label은 `app=sre-lab-api`로 설정되어 있었다.

Service 설정을 확인했다.

```bash
kubectl describe svc sre-lab-api -n sre-lab
```

Service selector가 실제 Pod label과 다르게 설정되어 있었다.

```text
Selector: app=wrong-api
```

Endpoint를 확인했다.

```bash
kubectl get endpoints -n sre-lab
```

Service에 연결된 Endpoint가 없는 것을 확인했다.

```text
NAME          ENDPOINTS   AGE
sre-lab-api   <none>      ...
```

Ingress 설정을 확인했다.

```bash
kubectl describe ingress sre-lab-api -n sre-lab
```

Ingress는 `sre-lab-api:80` Service를 바라보고 있었지만, 해당 Service에 연결된 Endpoint가 없어 요청을 backend Pod로 전달할 수 없었다.

---

## 4. Root Cause

Service의 `selector`가 Pod label과 일치하지 않았다.

문제가 된 설정은 다음과 같다.

```yaml
selector:
  app: wrong-api
```

반면 Pod에는 아래 label이 설정되어 있었다.

```yaml
labels:
  app: sre-lab-api
```

Kubernetes Service는 selector와 일치하는 Pod를 Endpoint로 등록한다. 이번 경우 selector가 Pod label과 일치하지 않아 Endpoint가 생성되지 않았고, Ingress가 전달할 backend가 없어 503 응답이 발생했다.

---

## 5. Resolution

Service selector를 실제 Pod label과 일치하도록 수정했다.

```yaml
selector:
  app: sre-lab-api
```

수정 후 Service manifest를 다시 적용했다.

```bash
kubectl apply -f k8s/service.yaml
```

Endpoint가 정상 생성되었는지 확인했다.

```bash
kubectl get endpoints -n sre-lab
```

정상 예시:

```text
NAME          ENDPOINTS                         AGE
sre-lab-api   10.244.1.3:8000,10.244.2.4:8000   ...
```

이후 `/health` 요청이 정상 응답하는 것을 확인했다.

```bash
curl http://sre-lab.local:8080/health
```

```json
{"status":"ok"}
```

---

## 6. What I Learned

* Pod가 `Running` 상태여도 Service selector가 잘못되면 트래픽이 Pod로 전달되지 않는다.
* Service는 selector와 일치하는 Pod를 Endpoint로 등록한다.
* Ingress 503 장애 분석 시 `Ingress → Service → Endpoint → Pod` 순서로 확인하면 원인을 빠르게 좁힐 수 있다.
* `kubectl get endpoints` 결과가 `<none>`이면 Service가 backend Pod를 찾지 못하고 있다는 중요한 신호다.
* Service selector와 Pod label의 일치 여부는 Kubernetes 트래픽 라우팅에서 핵심 확인 포인트다.
