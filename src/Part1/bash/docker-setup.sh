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
