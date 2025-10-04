# 로컬 레지스트리 실행
docker run --name localhub -d --restart=always -p 8000:5000 registry:latest

# Docker insecure registry 설정
cat <<EOF | sudo tee /etc/docker/daemon.json
{
    "insecure-registries": ["0.0.0.0:8000"]
}
EOF
sudo systemctl restart docker

# PostgreSQL 데이터 볼륨 생성
docker volume create pgdata
docker volume inspect pgdata

# PostgreSQL 컨테이너
docker run --restart unless-stopped -p 5430:5432 --name testdb-postgres -v pgdata:/var/lib/postgresql/data -e POSTGRES_PASSWORD=postgres -d postgres:16

psql -h localhost -U postgres -p 5430
create database users;
\c users
\i users.sql
\q

# Mongodb 데이터 볼륨 생성
docker volume create mongodata
docker volume inspect mongodata

# Mongodb 컨테이너
docker run --restart unless-stopped -p 27018:27017 --name testdb-mongo -v mongodata:/data/db -d mongo:7
Unable to find image 'mongo:7' locally

mongosh mongodb://localhost:27018
use admin
db.createUser({ user:'mongo', pwd: 'mongo', roles: ['root'] })
exit

# Docker 빌드
docker build -t users:v1.0 -f Dockerfile.userapp .
docker build -t movies:v1.0 -f Dockerfile.moviesapp .

# 샘플 앱 도커 기동
docker run -d -p 5001:5000 --name usersapp users:v1.0
docker run -d -p 5002:5000 --name moviesapp movies:v1.0

# curl call
curl -X 'POST' 'http://localhost:5001/v1/user/' -H 'accept: application/json' -d ''
curl -X 'GET' 'http://localhost:5001/v1/user/' -H 'accept: application/json'
curl -X 'POST' 'http://localhost:5002/v1/movies/' -H 'accept: applica' -d ''
curl -X 'GET' 'http://localhost:5002/v1/mov   /' -H 'accept: application/json'
