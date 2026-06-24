# Incident 01 - CrashLoopBackOff

## 1. Summary

FastAPI 애플리케이션 Deployment에 잘못된 `command`를 설정하여 신규 Pod가 `CrashLoopBackOff` 상태가 되는 상황을 재현했다.

신규 Pod는 정상 기동되지 않았지만, 기존 ReplicaSet의 Pod 2개가 `Running` 상태로 유지되어 전체 서비스 중단은 발생하지 않았다. 이를 통해 Kubernetes Deployment의 RollingUpdate 동작과 배포 실패 시 확인 흐름을 검증했다.

---

## 2. Symptoms

```bash
kubectl get pods -n sre-lab
```

```text
NAME                           READY   STATUS             RESTARTS      AGE
sre-lab-api-567d9c685b-pcwgb   0/1     CrashLoopBackOff   5 (46s ago)   3m34s
sre-lab-api-7f4b5f955c-kbffg   1/1     Running            0             74m
sre-lab-api-7f4b5f955c-pfdk8   1/1     Running            0             74m
```

* 신규 Pod 1개가 `CrashLoopBackOff` 상태로 전환됨
* 기존 Pod 2개는 `Running` 상태 유지
* 신규 버전 배포가 완료되지 않음

---

## 3. Investigation

Pod 상세 상태 확인:

```bash
kubectl describe pod <pod-name> -n sre-lab
```

확인한 내용:

```text
State: Waiting
Reason: CrashLoopBackOff

Last State: Terminated
Reason: Error

Events:
Back-off restarting failed container
```

컨테이너 로그 확인:

```bash
kubectl logs <pod-name> -n sre-lab --previous
```

확인된 에러:

```text
python: can't open file '/app/not_exist.py': [Errno 2] No such file or directory
```

ReplicaSet 상태 확인:

```bash
kubectl get rs -n sre-lab
```

이를 통해 신규 ReplicaSet의 Pod는 Ready 상태가 되지 못했고, 기존 ReplicaSet의 Pod가 유지되고 있음을 확인했다.

---

## 4. Root Cause

Deployment manifest에 존재하지 않는 Python 파일을 실행하는 command가 설정되어 있었다.

```yaml
command: ["python", "not_exist.py"]
```

컨테이너가 시작되자마자 `/app/not_exist.py`를 찾지 못해 종료되었고, Kubernetes가 컨테이너를 반복 재시작하면서 `CrashLoopBackOff` 상태가 발생했다.

---

## 5. Resolution

잘못된 command 설정을 제거한 뒤 Deployment를 다시 적용했다.

```bash
kubectl apply -f k8s/deployment.yaml
kubectl rollout status deployment/sre-lab-api -n sre-lab
```

복구 후 Pod 상태와 `/health` 응답을 확인했다.

```bash
kubectl get pods -n sre-lab
curl http://sre-lab.local:8080/health
```

정상 응답:

```json
{"status":"ok"}
```

---

## 6. What I Learned

* `CrashLoopBackOff`는 컨테이너가 반복적으로 종료될 때 발생한다.
* `kubectl logs --previous`를 통해 직전 실패 컨테이너 로그를 확인할 수 있다.
* Deployment RollingUpdate 중 신규 Pod가 실패하면 기존 정상 Pod가 유지될 수 있다.
* 배포 실패 분석 시 `Pod 상태 → describe → logs → events → ReplicaSet/Rollout 상태` 순서로 확인하면 원인을 좁히기 쉽다.
