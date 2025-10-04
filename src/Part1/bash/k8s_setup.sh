# Minikube 설치
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube

# Minikube 리소스 설정
minikube config set cpus 2
minikube config set memory 32G
minikube config set driver docker
minikube config view

# Minikube 클러스터 시작
minikube start

# kubectl alias 등록
vi ~/.bash_profile
. ~/.bash_profile

# Minikube registry 애드온 활성화
minikube addons enable registry

# 레지스트리 확인
kubectl get pods -A
kubectl get svc -A

# 로컬 포트포워딩 (레지스트리)
kubectl port-forward --namespace kube-system service/registry 8000:80 &

# 레지스트리 확인
curl http://localhost:8000/v2/_catalog 

# users 이미지 push
docker tag users:v1.0 localhost:8000/users:v1.0
docker push localhost:8000/users:v1.0

# movies 이미지 push
docker tag movies:v1.0 localhost:8000/movies:v1.0
docker push localhost:8000/movies:v1.0

# 최종 레지스트리 확인
curl http://localhost:8000/v2/_catalog

# yaml 배포
kubectl apply -f  mongodb.yaml
kubectl exec pod/mongodb-6f4797467-j5fm4 -it -- bin/sh
mongosh
use admin
db.createUser({ user:'mongo', pwd: 'mongo', roles: ['root'] })
exit

kubectl apply -f postgres.yaml
kubectl exec pod/postgres-76fb566885-rdfp2 -it -- /bin/sh
su - postgres
psql
create database users;
\c users
\i users.sql
\q

# minikube image load
minikube image load movies:v1.0
minikube image load users:v1.0

# yaml app 배포
kubectl apply -f users.yaml
kubectl apply -f movies.yaml
kubectl get all -A

#curl call
curl http://192.168.49.2:32281/v1/movies/
curl http://192.168.49.2:32281/v1/movies/hello
