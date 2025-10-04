# -----------------------------
# GitLab Docker 설치 및 실행
# -----------------------------
mkdir -p ~/gitlab
vi ~/.bash_profile
# export GITLAB_HOME=~/gitlab
source ~/.bash_profile
echo $GITLAB_HOME

docker run --detach \
  --hostname gitlab.example.com \
  --env GITLAB_OMNIBUS_CONFIG="external_url 'http://gitlab.example.com:8929'; gitlab_rails['gitlab_shell_ssh_port'] = 2424" \
  --publish 8929:8929 --publish 2424:22 \
  --name gitlab \
  --restart always \
  --volume $GITLAB_HOME/config:/etc/gitlab \
  --volume $GITLAB_HOME/logs:/var/log/gitlab \
  --volume $GITLAB_HOME/data:/var/opt/gitlab \
  --shm-size 256m \
  gitlab/gitlab-ce:latest

docker exec -it gitlab /bin/bash
vi /etc/gitlab/gitlab.rb
# external_url 'http://gitlab.example.com:8929'
# gitlab_rails['gitlab_shell_ssh_port'] = 2424
gitlab-ctl reconfigure

docker exec -it gitlab grep 'Password:' /etc/gitlab/initial_root_password

sudo vi /etc/hosts
# 0.0.0.0 gitlab.example.com

# -----------------------------
# Git 초기화 및 원격 리포지토리 연결
# -----------------------------
cd msaapp
vi .gitignore
git init
git add .
git commit -m "init .gitignore"
git branch
git remote add origin http://gitlab.example.com:8929/devadm/msaapp
git config --global http.sslVerify false
git push -u origin master

# -----------------------------
# GitLab Runner 설치 및 등록
# -----------------------------
sudo curl -L --output /usr/local/bin/gitlab-runner "https://s3.dualstack.us-east-1.amazonaws.com/gitlab-runner-downloads/latest/binaries/gitlab-runner-linux-amd64"
mkdir -p ~/gitlab-runner

sudo /usr/local/bin/gitlab-runner install --user=centos --working-directory=/home/centos/gitlab-runner
sudo /usr/local/bin/gitlab-runner start
sudo /usr/local/bin/gitlab-runner list

sudo /usr/local/bin/gitlab-runner register --url http://gitlab.example.com:8929 --registration-token GR1348941aCfo_Lg5Pz7SRc1TooWX
# 입력값
# Executor: shell

sudo vi /etc/hosts
# 0.0.0.0 gitlab.example.com

# -----------------------------
# ArgoCD 설치
# -----------------------------
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# ArgoCD CLI 설치
curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd

# ArgoCD admin 패스워드 확인 및 포트포워드
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo
kubectl port-forward svc/argocd-server -n argocd 8080:443 &

# CLI 로그인
argocd --insecure login localhost:8080

# 타겟 클러스터 등록
kubectl config get-contexts -o name
argocd cluster add minikube

# 샘플 앱 배포
argocd app create guestbook --repo https://github.com/argoproj/argocd-example-apps.git --path guestbook --dest-server https://kubernetes.default.svc --dest-namespace default
argocd app get guestbook

# 포트포워드
kubectl port-forward -n default service/guestbook-ui 8880:80 &

# -----------------------------
# ArgoCD + GitLab 연계 (SSH key 등록)
# -----------------------------
ssh-keygen -f argocd
# argocd.pub 파일 내용을 GitLab SSH Key에 등록

argocd repo add ssh://git@10.0.0.13:2424/devadm/msaapp.git --insecure-skip-server-verification --ssh-private-key-path ./argocd
