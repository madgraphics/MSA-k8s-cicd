# 마이크로서비스 CICD 아키텍처 구성 

<br>

## 1. gitlab을 활용한 CICD 구성

<br>
docker 기반으로 gitlab을 구성합니다.

```jsx
[centos@k8sel-521149 ~]$ mkdir -p ~/gitlab
[centos@k8sel-521149 ~]$ vi ~/.bash_profile

..중략..
export GITLAB_HOME=~/gitlab

:wq

[centos@k8sel-521149 ~]$ . ~/.bash_profile 
[centos@k8sel-521149 ~]$ echo $GITLAB_HOME
/home/centos/gitlab

[centos@k8sel-521149 ~]$ docker run --detach \
>   --hostname gitlab.example.com \
>   --env GITLAB_OMNIBUS_CONFIG="external_url 'http://gitlab.example.com:8929'; gitlab_rails['gitlab_shell_ssh_port'] = 2424" \
>   --publish 8929:8929 --publish 2424:22 \
>   --name gitlab \
>   --restart always \
>   --volume $GITLAB_HOME/config:/etc/gitlab \
>   --volume $GITLAB_HOME/logs:/var/log/gitlab \
>   --volume $GITLAB_HOME/data:/var/opt/gitlab \
>   --shm-size 256m \
>   gitlab/gitlab-ce:latest
Unable to find image 'gitlab/gitlab-ce:latest' locally
latest: Pulling from gitlab/gitlab-ce
df2fac849a45: Pull complete 
dcff1b8d9064: Pull complete 
5f22a8084868: Pull complete 
2d2a37742a29: Pull complete 
5bfec0e1a7be: Pull complete 
a836fb539f8e: Pull complete 
f1f3ef7fba21: Pull complete 
425005aee4af: Pull complete 
Digest: sha256:f179b2e747bfa3df5fe886ebb4d6af7169edfc1bd0f2d999ca6abab3378de56f
Status: Downloaded newer image for gitlab/gitlab-ce:latest
573fd2f81043cc4df96038b1b664558d01989dc5e011b9d4928aa52dc3ad801d

[centos@k8sel-521149 ~]$ docker exec -it gitlab /bin/bash
root@gitlab:/# vi /etc/gitlab/gitlab.rb

external_url 'http://gitlab.example.com:8929'
gitlab_rails['gitlab_shell_ssh_port'] = 2424

:wq

root@gitlab:/# gitlab-ctl reconfigure
```
<br>
root 패스워드를 복사해둡니다.

```jsx
[centos@k8sel-521149 ~]$ docker exec -it gitlab grep 'Password:' /etc/gitlab/initial_root_password
Password: gU7dsPsScJqdx8bBwjSAMe0MuK3uHUmAM2pFII1cggY=
```

<br>
http://localhost:8929로 접속합니다. 

root/<위에서 복사한 패스워드>를 입력합니다. 

![Untitled](src/Untitled%2015.png)

<br>
로그인이 완료 되었습니다.

![Untitled](src/Untitled%2016.png)

<br>
왼쪽 메뉴(Admin Area)를 띄워서, Admin > Users 를 선택합니다. 

<br>
New user 를 클릭합니다. 

![Untitled](src/Untitled%2017.png)

<br>
- 다음과 같이 입력하여 생성합니다.
    - Name : devadm
    - Username : devadm
    - Email : <유저 email>

![Untitled](src/Untitled%2018.png)

<br>
유저 생성이 완료되었습니다. 

![Untitled](src/Untitled%2019.png)

<br>
devadm 유저에서 오른쪽의 Edit 버튼을 눌러 패스워드를 설정해 줍니다. 

![Untitled](src/Untitled%2020.png)

<br>
root를 로그아웃하고, devadm으로 로그인합니다. 

![Untitled](src/Untitled%2021.png)

<br>
호스트명에 gitlab을 추가해 줍니다.
로컬의 소스 디렉토리로 이동하여, git push를 진행합니다. 

```jsx
[centos@k8sel-521149 ~]$ sudo vi /etc/hosts

0.0.0.0 gitlab.example.com

:wq

[centos@k8sel-521149 gitlab]$ msaapp 

(msaapp) [centos@k8sel-521149 msaapp]$ vi .gitignore
 
bin/
.git/
include/
lib/
*.sh
*.cfg
minikube*
lib64
mongodb_sim*

:wq

(msaapp) [centos@k8sel-521149 msaapp]$ git init
hint: Using 'master' as the name for the initial branch. This default branch name
hint: is subject to change. To configure the initial branch name to use in all
hint: of your new repositories, which will suppress this warning, call:
hint: 
hint: 	git config --global init.defaultBranch <name>
hint: 
hint: Names commonly chosen instead of 'master' are 'main', 'trunk' and
hint: 'development'. The just-created branch can be renamed via this command:
hint: 
hint: 	git branch -m <name>
Initialized empty Git repository in /home/centos/msaapp/.git/

(msaapp) [centos@k8sel-521149 msaapp]$ git add .

(msaapp) [centos@k8sel-521149 msaapp]$ git commit -m "init .gitignore"
[master (root-commit) a9f720f] init .gitignore
 Committer: devadm <centos@k8sel-521149.sub04151622050.ocidemo.oraclevcn.com>
Your name and email address were configured automatically based
on your username and hostname. Please check that they are accurate.
You can suppress this message by setting them explicitly:

    git config --global user.name "Your Name"
    git config --global user.email you@example.com

After doing this, you may fix the identity used for this commit with:

    git commit --amend --reset-author

 17 files changed, 92760 insertions(+)
 create mode 100644 .gitignore
 create mode 100644 Dockerfile.moviesapp
 create mode 100644 Dockerfile.userapp
 create mode 100644 __pycache__/hello.cpython-38.pyc
 create mode 100644 __pycache__/movies.cpython-38.pyc
 create mode 100644 __pycache__/users.cpython-38.pyc
 create mode 100644 hello.py
 create mode 100644 mongodb.yaml
 create mode 100644 movies.json
 create mode 100644 movies.py
 create mode 100644 movies.yaml
 create mode 100644 nginx-pod.yaml
 create mode 100644 postgres.yaml
 create mode 100644 requirements.txt
 create mode 100644 users.py
 create mode 100644 users.sql
 create mode 100644 users.yaml

(msaapp) [centos@k8sel-521149 msaapp]$ git branch
* master

(msaapp) [centos@k8sel-521149 msaapp]$ git remote add origin http://gitlab.example.com:8929/devadm/msaapp

(msaapp) [centos@k8sel-521149 msaapp]$ git config --global http.sslVerify false
(msaapp) [centos@k8sel-521149 msaapp]$ git push -u origin master

(gnome-ssh-askpass:3258031): Gtk-WARNING : 13:38:39.981: cannot open display: 
error: unable to read askpass response from '/usr/libexec/openssh/gnome-ssh-askpass'
Username for 'http://gitlab.example.com:8929': devadm

(gnome-ssh-askpass:3258982): Gtk-WARNING : 13:39:07.588: cannot open display: 
error: unable to read askpass response from '/usr/libexec/openssh/gnome-ssh-askpass'
Password for 'http://devadm@gitlab.example.com:8929': 
warning: redirecting to http://gitlab.example.com:8929/devadm/msaapp.git/
Enumerating objects: 20, done.
Counting objects: 100% (20/20), done.
Delta compression using up to 8 threads
Compressing objects: 100% (20/20), done.
Writing objects: 100% (20/20), 290.73 KiB | 2.91 MiB/s, done.
Total 20 (delta 4), reused 0 (delta 0), pack-reused 0
remote: 
remote: 
remote: The private project devadm/msaapp was successfully created.
remote: 
remote: To configure the remote, run:
remote:   git remote add origin http://gitlab.example.com:8929/devadm/msaapp.git
remote: 
remote: To view the project, visit:
remote:   http://gitlab.example.com:8929/devadm/msaapp
remote: 
remote: 
remote: 
To http://localhost:8929/devadm/msa
 * [new branch]      master -> master
branch 'master' set up to track 'origin/master'.
(msaapp) [centos@k8sel-521149 msaapp]$

```

<br>
gitlab 웹브라우저를 리로드하면 프로젝트에 소스가 업로드된 것을 볼수 있습니다. 

![Untitled](src/Untitled%2022.png)

![Untitled](src/Untitled%2023.png)

<br>
왼편메뉴에서 Setting > CI/CD를 선택합니다. 

![Untitled](src/Untitled%2024.png)

<br>
Runners를 Expand합니다. 

![Untitled](src/Untitled%2025.png)

<br>
New project runner 오른쪽의 콤보버튼을 누르면, registration token과 runner 설치방법을 확인할 수 있습니다.

token을 복사해 둡니다.  

![Untitled](src/Untitled%2026.png)
 
 
<br>
centos 로컬환경을 gitlab-runner 구동 환경으로 구성합니다.

```jsx
[centos@k8sel-521149 ~]$ sudo curl -L --output /usr/local/bin/gitlab-runner "https://s3.dualstack.us-east-1.amazonaws.com/gitlab-runner-downloads/latest/binaries/gitlab-runner-linux-amd64"

[centos@k8sel-521149 ~]$ mkdir -p ~/gitlab-runner

[centos@k8sel-521149 ~]$ sudo /usr/local/bin/gitlab-runner install --user=centos --working-directory=/home/centos/gitlab-runner
Runtime platform                                    arch=amd64 os=linux pid=914117 revision=c72a09b6 version=16.8.0

[centos@k8sel-521149 ~]$ sudo /usr/local/bin/gitlab-runner start
Runtime platform                                    arch=amd64 os=linux pid=914644 revision=c72a09b6 version=16.8.0

[centos@k8sel-521149 ~]$ sudo /usr/local/bin/gitlab-runner list
Runtime platform                                    arch=amd64 os=linux pid=955821 revision=c72a09b6 version=16.8.0
Listing configured runners                          ConfigFile=/etc/gitlab-runner/config.toml

~~[centos@k8sel-521149 ~]$ sudo yum install openssl
[centos@k8sel-521149 ~]$ sudo usermod -aG docker gitlab-runner~~

[centos@k8sel-521149 ~]$ sudo /usr/local/bin/gitlab-runner register --url http://gitlab.example.com:8929 --registration-token GR1348941aCfo_Lg5Pz7SRc1TooWX
Runtime platform                                    arch=amd64 os=linux pid=956405 revision=c72a09b6 version=16.8.0
Running in system-mode.                            
                                                   
Enter the GitLab instance URL (for example, https://gitlab.com/):
[https://0.0.0.0:8929]: 
Enter the registration token:
[GR1348941aCfo_Lg5Pz7SRc1TooWX]: 
Enter a description for the runner:
[k8sel-521149]: gr-local
Enter tags for the runner (comma-separated):
test
Enter optional maintenance note for the runner:

WARNING: Support for registration tokens and runner parameters in the 'register' command has been deprecated in GitLab Runner 15.6 and will be replaced with support for authentication tokens. For more information, see https://docs.gitlab.com/ee/ci/runners/new_creation_workflow 
Registering runner... succeeded                     runner=GR1348941aCfo_Lg5
Enter an executor: docker, docker+machine, instance, custom, parallels, virtualbox, docker-windows, kubernetes, docker-autoscaler, shell, ssh:
shell
Runner registered successfully. Feel free to start it, but if it's running already the config should be automatically reloaded!
 
Configuration (with the authentication token) was saved in "/etc/gitlab-runner/config.toml"

[centos@k8sel-521149 ~]$ sudo vi /etc/hosts

0.0.0.0 gitlab.example.com

:wq
```

<br>
왼쪽 메뉴 CI/CD > Runners > Expand 를 선택하면 생성된 runner가 보입니다. 

![Untitled](src/Untitled%2027.png)

<br>
프로젝트로 가서 .gitlab-ci.yml을 작성합니다.

![Untitled](src/Untitled%2028.png)

<br>
.gitlab-ci.yml을 다음과 같이 작성합니다. 

```jsx
stages:          # List of stages for jobs, and their order of execution
  - build
  - deploy

build-job:       # This job runs in the build stage, which runs first.
  tags:
    - test

  stage: build

  script:
    - echo "build dockerfile..."
    - docker container ls -a
    - docker build -t 0.0.0.0:8000/users:v1.0 -f Dockerfile.userapp .
    - docker push 0.0.0.0:8000/users:v1.0
    - docker build -t 0.0.0.0:8000/movies:v1.0 -f Dockerfile.moviesapp .
    - docker push 0.0.0.0:8000/movies:v1.0
    - docker images
    - echo "build complete."

deploy-job:      # This job runs in the deploy stage.
  stage: deploy  # It only runs when *both* jobs in the test stage complete successfully.
  tags:
    - test
	environment: production
  script:
    - echo "Deploying application image..."
    - minikube image load 0.0.0.0:8000/users:v1.0
    - minikube image load 0.0.0.0:8000/movies:v1.0
    - echo "Application image successfully deployed."
```

<br>
Gitlab에 내장된 CI는 파이프라인 파일인 .gitlab-ci.yml을 커밋하자마자 gitlab-runner를 호출하여 동작합니다. 

<br>
빌드stage가 잘 진행되는 것을 볼 수 있습니다. 

![Untitled](src/Untitled%2029.png)

<br>
도커 이미지가 빌드되고 push된 결과입니다.

```jsx
[centos@k8sel-521149 ~]$ curl http://0.0.0.0:8000/v2/_catalog
{"repositories":["docker","hello-world","movies","users"]}
```

![Untitled](src/Untitled%2030.png)

![Untitled](src/Untitled%2031.png)

![Untitled](src/Untitled%2032.png)


<br>
## 2. ArgoCD를 활용한 k8s CICD 구성

 <br>
k8s에 argocd를 구성합니다. 

```jsx
[centos@k8sel-521149 ~]$ kubectl create namespace argocd
namespace/argocd created

[centos@k8sel-521149 ~]$ kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
customresourcedefinition.apiextensions.k8s.io/applications.argoproj.io created
customresourcedefinition.apiextensions.k8s.io/applicationsets.argoproj.io created
customresourcedefinition.apiextensions.k8s.io/appprojects.argoproj.io created
serviceaccount/argocd-application-controller created
serviceaccount/argocd-applicationset-controller created
serviceaccount/argocd-dex-server created
serviceaccount/argocd-notifications-controller created
serviceaccount/argocd-redis created
serviceaccount/argocd-repo-server created
serviceaccount/argocd-server created
role.rbac.authorization.k8s.io/argocd-application-controller created
role.rbac.authorization.k8s.io/argocd-applicationset-controller created
role.rbac.authorization.k8s.io/argocd-dex-server created
role.rbac.authorization.k8s.io/argocd-notifications-controller created
role.rbac.authorization.k8s.io/argocd-server created
clusterrole.rbac.authorization.k8s.io/argocd-application-controller created
clusterrole.rbac.authorization.k8s.io/argocd-server created
rolebinding.rbac.authorization.k8s.io/argocd-application-controller created
rolebinding.rbac.authorization.k8s.io/argocd-applicationset-controller created
rolebinding.rbac.authorization.k8s.io/argocd-dex-server created
rolebinding.rbac.authorization.k8s.io/argocd-notifications-controller created
rolebinding.rbac.authorization.k8s.io/argocd-server created
clusterrolebinding.rbac.authorization.k8s.io/argocd-application-controller created
clusterrolebinding.rbac.authorization.k8s.io/argocd-server created
configmap/argocd-cm created
configmap/argocd-cmd-params-cm created
configmap/argocd-gpg-keys-cm created
configmap/argocd-notifications-cm created
configmap/argocd-rbac-cm created
configmap/argocd-ssh-known-hosts-cm created
configmap/argocd-tls-certs-cm created
secret/argocd-notifications-secret created
secret/argocd-secret created
service/argocd-applicationset-controller created
service/argocd-dex-server created
service/argocd-metrics created
service/argocd-notifications-controller-metrics created
service/argocd-redis created
service/argocd-repo-server created
service/argocd-server created
service/argocd-server-metrics created
deployment.apps/argocd-applicationset-controller created
deployment.apps/argocd-dex-server created
deployment.apps/argocd-notifications-controller created
deployment.apps/argocd-redis created
deployment.apps/argocd-repo-server created
deployment.apps/argocd-server created
statefulset.apps/argocd-application-controller created
networkpolicy.networking.k8s.io/argocd-application-controller-network-policy created
networkpolicy.networking.k8s.io/argocd-applicationset-controller-network-policy created
networkpolicy.networking.k8s.io/argocd-dex-server-network-policy created
networkpolicy.networking.k8s.io/argocd-notifications-controller-network-policy created
networkpolicy.networking.k8s.io/argocd-redis-network-policy created
networkpolicy.networking.k8s.io/argocd-repo-server-network-policy created
networkpolicy.networking.k8s.io/argocd-server-network-policy created
```

<br>
argocd 관리용으로 argocd CLI도 설치합니다. 

```jsx
[centos@k8sel-521149 ~]$ curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
[centos@k8sel-521149 ~]$ sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd
```

<br>
admin패스워드를 확인하고, port-forward를 수행합니다. 

```jsx
[centos@k8sel-521149 ~]$ kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo
-XbHb2A0PbiOxzif

[centos@k8sel-521149 ~]$ kubectl port-forward svc/argocd-server -n argocd 8080:443 &
[1] 146814
[centos@k8sel-521149 ~]$ Forwarding from 127.0.0.1:8080 -> 8080
Forwarding from [::1]:8080 -> 8080
```

<br>
로컬호스트:8080 으로 접속하면 argocd api서버에 gui방식으로 접속할 수 있습니다.

- Username : admin
- Paaword : <위에서 확인한 패스워드>

![Untitled](src/Untitled%2033.png)

<br>
로그인이 되었습니다. 

![Untitled](src/Untitled%2034.png)

<br>
왼쪽 메뉴에서 User Info > UPDATE PASSWORD 를 선택합니다.

![Untitled](src/Untitled%2035.png)

<br>
admin 패스워드를 업데이트 합니다. 

![Untitled](src/Untitled%2036.png)

![Untitled](src/Untitled%2037.png)

 
<br>
argocd에 cli로 로그인합니다. 

```jsx
[centos@k8sel-521149 ~]$ argocd --insecure login localhost:8080
Username: admin
Password: 
'admin:login' logged in successfully
Context 'localhost:8080' updated

[centos@k8sel-521149 ~]$
```

<br>
타겟 클러스터를 등록합니다. argocd가 설치된 클러스터의 경우, 아주 쉽게 권한을 생성해서 연동할 수 있습니다. 

```jsx
[centos@k8sel-521149 ~]$ kubectl config get-contexts -o name
minikube

[centos@k8sel-521149 ~]$ argocd cluster add minikube
WARNING: This will create a service account `argocd-manager` on the cluster referenced by context `minikube` with full cluster level privileges. Do you want to continue [y/N]? y
INFO[0005] ServiceAccount "argocd-manager" created in namespace "kube-system" 
INFO[0005] ClusterRole "argocd-manager-role" created    
INFO[0005] ClusterRoleBinding "argocd-manager-role-binding" created 
INFO[0010] Created bearer token secret for ServiceAccount "argocd-manager" 
Cluster 'https://192.168.49.2:8443' added
```

<br>
argocd의 샘플 앱을 배포해 봅니다.

```jsx
[centos@k8sel-521149 ~]$ argocd app create guestbook --repo https://github.com/argoproj/argocd-example-apps.git --path guestbook --dest-server https://kubernetes.default.svc --dest-namespace default
application 'guestbook' created

[centos@k8sel-521149 ~]$ argocd app get guestbook
Name:               argocd/guestbook
Project:            default
Server:             https://kubernetes.default.svc
Namespace:          default
URL:                https://localhost:8080/applications/guestbook
Repo:               https://github.com/argoproj/argocd-example-apps.git
Target:             
Path:               guestbook
SyncWindow:         Sync Allowed
Sync Policy:        <none>
Sync Status:        OutOfSync from  (d7927a2)
Health Status:      Missing

GROUP  KIND        NAMESPACE  NAME          STATUS     HEALTH   HOOK  MESSAGE
       Service     default    guestbook-ui  OutOfSync  Missing        
apps   Deployment  default    guestbook-ui  OutOfSync  Missing        

[centos@k8sel-521149 ~]$
```

<br>
gusetbook app이 생성 되었습니다.

![Untitled](src/Untitled%2038.png)

<br>
sync버튼을 누르고, synchronize를 선택합니다. 

![Untitled](src/Untitled%2039.png)

<br>
k8s에 배포가 되고 있습니다. 

```jsx
[centos@k8sel-521149 ~]$ kubectl get all -A
NAMESPACE     NAME                                                   READY   STATUS              RESTARTS       AGE
argocd        pod/argocd-application-controller-0                    1/1     Running             8 (83m ago)    4d11h
argocd        pod/argocd-applicationset-controller-5f975ff5-g84h7    1/1     Running             8 (83m ago)    4d11h
argocd        pod/argocd-dex-server-7bb445db59-hbsvc                 1/1     Running             8 (83m ago)    4d11h
argocd        pod/argocd-notifications-controller-566465df76-87lfv   1/1     Running             8 (83m ago)    4d11h
argocd        pod/argocd-redis-6976fc7dfc-tc2kc                      1/1     Running             8 (83m ago)    4d11h
argocd        pod/argocd-repo-server-6d8d59bbc7-487mt                1/1     Running             8 (83m ago)    4d11h
argocd        pod/argocd-server-58f5668765-rszrs                     1/1     Running             8 (83m ago)    4d11h
default       pod/guestbook-ui-56c646849b-s2sqd                      0/1     ContainerCreating   0              23s
default       pod/mongodb-6f4797467-j5fm4                            1/1     Running             9 (83m ago)    8d
default       pod/movies-744b4586c4-l97vh                            1/1     Running             9 (51m ago)    8d
default       pod/movies-744b4586c4-nrmfk                            1/1     Running             9 (51m ago)    8d
default       pod/movies-744b4586c4-s452w                            1/1     Running             9 (51m ago)    8d
```

<br>
sync가 완료 되었습니다. 

![Untitled](src/Untitled%2040.png)

<br>
guestbook을 클릭하여 상세 배포내용을 볼수 있습니다. 

![Untitled](src/Untitled%2041.png)

<br>
샘플 app을 포트포워드 합니다. 

```jsx
[centos@k8sel-521149 ~]$ kubectl port-forward -n default service/guestbook-ui 8880:80 &
[2] 2058190
[centos@k8sel-521149 ~]$ Forwarding from 127.0.0.1:8880 -> 80
Forwarding from [::1]:8880 -> 80
```

<br>
브라우저로 접속한 샘플앱 모습입니다. 

![Untitled](src/Untitled%2042.png)

<br>
## 3. ArgoCD and Gitlab 연계

<br>
리파지토리 연동은 HTTPS, SSH방식이 가능합니다.

SSH방식으로 gitlab private repository를 등록하기 위해 우선 ssh 키쌍을 생성이 필요합니다. 

```jsx
[centos@k8sel-521149 ~]$ ssh-keygen -f argocd
Generating public/private rsa key pair.
Enter passphrase (empty for no passphrase): 
Enter same passphrase again: 
Your identification has been saved in argocd.
Your public key has been saved in argocd.pub.
The key fingerprint is:
SHA256:+qD+jNSLyJviT84Jdt6zRe8qJ+40eAr4q4tl2nv+xm0 centos@k8sel-521149
The key's randomart image is:
+---[RSA 3072]----+
|                 |
|                 |
|                 |
|                 |
|       .S        |
|.   .....        |
|.+o+.=+o .       |
|+BO+BO==E        |
|*=@#OO@oo.       |
+----[SHA256]-----+

[centos@k8sel-521149 ~]$ ls argo*
argocd  argocd.pub

```
<br>
gitlab에 가서, 유저메뉴에서 edit profile을 선택합니다.

![Untitled](src/Untitled%2044.png)

<br>
왼쪽의 SSH Keys를 선택합니다. 

![Untitled](src/Untitled%2045.png)

<br>
Add keys를 선택후, 만들어둔 argocd.pub 파일의 내용을 붙여넣기 합니다. 

![Untitled](src/Untitled%2046.png)

<br>
등록이 완료 되었습니다. 

![Untitled](src/Untitled%2047.png)

<br>
argocd cli로 리파지토리를 등록 합니다.

argocd가 있는 k8s pod N/W에서 VM OS를 거쳐, 도커 컨테이너 N/W인 gitlab서버의 2424 포트와 통신해야 하므로, VM의 private IP를 바라보게 했습니다. 

```jsx
[centos@k8sel-521149 ~]$ argocd repo add ssh://git@10.0.0.13:2424/devadm/msaapp.git --insecure-skip-server-verification --ssh-private-key-path ./argocd
Repository 'ssh://git@10.0.0.13:2424/devadm/msaapp.git' added
```

<br>
Settings > Repositories에 리파지토리가 생성 되었습니다. 

![Untitled](src/Untitled%2048.png)

<br>
argocd 어플리케이션을 생성합니다.

다음과 같이 입력하고 CREATE 합니다. 

- General
    - Application Name : msaapp
    - Project Name : default
    - SYNC POLICY : Manual
- SOURCE
    - Repository URL : ssh://git@10.0.0.13:2424/devadm/msaapp.git
    - Revision : HEAD
    - Path : k8s
- DESTINATION
    - Cluster URL : https://kubernetes.default.svc
    - Namespace : default
    

![Untitled](src/Untitled%2049.png)

![Untitled](src/Untitled%2050.png)

![Untitled](src/Untitled%2051.png)

![Untitled](src/Untitled%2052.png)


<br>
앱이 생성되었습니다. 

![Untitled](src/Untitled%2053.png)


<br>
user app, movies app등의 yaml을 sync하는 argocd앱 입니다. 

![Untitled](src/Untitled%2054.png)
![Untitled](src/Untitled%2055.png)


