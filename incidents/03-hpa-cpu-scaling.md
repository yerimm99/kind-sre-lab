# Incident 03 - HPA CPU Scaling

## 1. Summary

FastAPI 애플리케이션에 CPU 부하를 발생시켜 Kubernetes HPA가 Pod replica 수를 자동으로 증가시키는 상황을 재현했다.

`/api/cpu-load` 엔드포인트를 반복 호출하여 Pod CPU 사용률을 높였고, HPA가 설정된 CPU target을 초과한 것을 감지하여 Deployment의 replica 수를 증가시키는 것을 확인했다.

---

## 2. Symptoms

CPU 부하 발생 전 HPA와 Pod 상태를 확인했다.

```bash
kubectl get hpa -n sre-lab
kubectl get pods -n sre-lab
```

초기 상태에서는 Deployment가 최소 replica 수인 2개 Pod로 동작하고 있었다.

CPU 부하를 발생시킨 뒤 HPA 상태를 확인했다.

```bash
kubectl get hpa -n sre-lab -w
```

CPU 사용률이 target 값을 초과하면서 replica 수가 증가했다.

주요 증상은 다음과 같다.

* `/api/cpu-load` 반복 호출로 CPU 사용률 증가
* HPA target CPU utilization 초과
* Deployment replica 수 증가
* 신규 Pod 생성 및 `Running` 상태 전환

---

## 3. Configuration

HPA는 아래와 같이 설정했다.

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: sre-lab-api
  namespace: sre-lab
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: sre-lab-api
  minReplicas: 2
  maxReplicas: 5
  metrics:
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: 50
```

HPA가 CPU 사용률을 계산할 수 있도록 Deployment에는 CPU request가 설정되어 있다.

```yaml
resources:
  requests:
    cpu: "100m"
    memory: "128Mi"
  limits:
    cpu: "500m"
    memory: "256Mi"
```

---

## 4. Load Test

CPU 부하는 `/api/cpu-load` 엔드포인트를 반복 호출하여 발생시켰다.

```bash
while true; do curl -s http://sre-lab.local:8080/api/cpu-load > /dev/null; done
```

부하가 부족할 경우 여러 터미널에서 동일 명령어를 동시에 실행하여 CPU 사용률을 높였다.

---

## 5. Investigation

HPA 상태를 확인했다.

```bash
kubectl get hpa -n sre-lab
```

CPU 사용률이 target인 50%를 초과하면서 replica 수가 증가하는 것을 확인했다.

Pod CPU 사용량을 확인했다.

```bash
kubectl top pods -n sre-lab
```

Deployment replica 상태를 확인했다.

```bash
kubectl get deploy sre-lab-api -n sre-lab
```

Pod 생성 상태를 확인했다.

```bash
kubectl get pods -n sre-lab
```

HPA 상세 이벤트를 확인했다.

```bash
kubectl describe hpa sre-lab-api -n sre-lab
```

`describe hpa` 결과에서 `SuccessfulRescale` 이벤트를 통해 HPA가 Deployment replica 수를 조정한 것을 확인할 수 있다.

---

## 6. Result

CPU 부하가 증가하자 HPA가 Deployment의 replica 수를 자동으로 증가시켰다.

확인한 흐름은 다음과 같다.

```text
Initial replicas: 2
CPU load increased
HPA detected CPU utilization above target
Replicas increased up to maxReplicas: 5
New Pods created and became Running
```

부하를 중단한 뒤 CPU 사용률이 낮아지면 HPA는 일정 시간이 지난 후 replica 수를 다시 줄인다.

---

## 7. What I Learned

* HPA는 Pod의 CPU 사용률을 기준으로 Deployment replica 수를 자동 조정할 수 있다.
* CPU 기반 HPA가 동작하려면 metrics-server가 필요하다.
* CPU utilization 기준 HPA를 사용하려면 container resource request 설정이 필요하다.
* `kubectl get hpa`, `kubectl top pods`, `kubectl describe hpa`를 통해 HPA 동작 상태를 확인할 수 있다.
* Scale up은 비교적 빠르게 발생하지만, scale down은 안정화 시간을 두고 천천히 진행될 수 있다.
