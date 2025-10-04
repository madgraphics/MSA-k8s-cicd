#!/bin/bash

# -------------------------------
# Istio 설치
# -------------------------------
curl -L https://istio.io/downloadIstio | sh -
export PATH="$PATH:$HOME/istio-1.20.2/bin"
source ~/.bash_profile

# Istio 설치 확인
istioctl version
istioctl profile list

# Istio default profile 설치
istioctl install --set profile=default -y

# default namespace에 Istio 사이드카 자동 주입 활성화
kubectl label namespace default istio-injection=enabled --overwrite
kubectl get namespaces -L istio-injection

# -------------------------------
# Istio Monitoring Add-ons 설치
# -------------------------------
# Prometheus
kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.20/samples/addons/prometheus.yaml

# Grafana
kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.20/samples/addons/grafana.yaml
POD_GRAFANA=$(kubectl -n istio-system get pod -l app=grafana -o jsonpath='{.items[0].metadata.name}')
kubectl port-forward --address='0.0.0.0' $POD_GRAFANA 3000:3000 -n istio-system &

# Kiali
kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.20/samples/addons/kiali.yaml
POD_KIALI=$(kubectl -n istio-system get pod -l app=kiali -o jsonpath='{.items[0].metadata.name}')
kubectl port-forward --address='0.0.0.0' $POD_KIALI 20001:20001 -n istio-system &

# Jaeger
kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.20/samples/addons/jaeger.yaml
POD_JAEGER=$(kubectl -n istio-system get pod -l app=jaeger -o jsonpath='{.items[0].metadata.name}')
kubectl port-forward --address='0.0.0.0' $POD_JAEGER 16686:16686 -n istio-system &

# -------------------------------
# Metric Server 설치 (Autoscaling, Node monitoring)
# -------------------------------
minikube addons enable metrics-server
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
kubectl get deployment metrics-server -n kube-system

# -------------------------------
# NodeJS 설치
# -------------------------------
sudo yum install -y nodejs npm nodejs-full-i18n
node -v
npm -v

# -------------------------------
# Manage 서비스용 NodeJS 프로젝트 준비
# -------------------------------
cd $HOME/msaapp
npm init -y
npm install swagger-jsdoc swagger-ui-express swagger-autogen request express


# -------------------------------
# 앱 실행
# -------------------------------
node app.js

# docker & k8s 
docker build -f Dockerfile.manageapp -t manage:v1.0 .

docker tag manage:v1.0 0.0.0.0:8000/manage:v1.0
docker push 0.0.0.0:8000/manage:v1.0

minikube image load manage:v1.0
kubectl apply -f manage.yaml

curl http://localhost:3000/v1/manage/hello

kubectl autoscale deployment manage --cpu-percent=30 --min=3 --max=5

minikube tunnel

kubectl delete -f users.yaml
kubectl delete -f movies.yaml
kubectl delete -f manage.yaml

kubectl apply -f users-mesh.yaml
kubectl apply -f movies-mesh.yaml
kubectl apply -f manage-mesh.yaml

kubectl apply -f demo-gateway.yaml
kubectl get gateways

# ----------------------------
# Canary 배포를 테스트하기 위한 반복 HTTP 호출
# ----------------------------
while true; do
  curl http://10.109.61.0/v1/manage/
  curl http://10.109.61.0/v1/manage/hello
  sleep 5
done > /dev/null &

# ----------------------------
# Grafana 포트포워드
# ----------------------------
POD_NAME=$(kubectl -n istio-system get pod -l app=grafana -o jsonpath='{.items[0].metadata.name}')
kubectl port-forward --address='0.0.0.0' $POD_NAME 3000:3000 -n istio-system &

# ----------------------------
# Kiali 포트포워드
# ----------------------------
POD_NAME=$(kubectl -n istio-system get pod -l app=kiali -o jsonpath='{.items[0].metadata.name}')
kubectl port-forward --address='0.0.0.0' $POD_NAME 20001:20001 -n istio-system &

# ----------------------------
# Jaeger 포트포워드
# ----------------------------
POD_NAME=$(kubectl -n istio-system get pod -l app=jaeger -o jsonpath='{.items[0].metadata.name}')
kubectl port-forward --address='0.0.0.0' $POD_NAME 16686:16686 -n istio-system &



