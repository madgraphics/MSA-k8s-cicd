

### 13. Istio와 서비스 메시 모니터링도구 구성

Istio를 설치한다. 

```jsx
[centos@k8sel-521149 ~]$ curl -L https://istio.io/downloadIstio | sh -
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100   101  100   101    0     0    294      0 --:--:-- --:--:-- --:--:--   293
100  4899  100  4899    0     0   8165      0 --:--:-- --:--:-- --:--:--  8165

Downloading istio-1.20.2 from https://github.com/istio/istio/releases/download/1.20.2/istio-1.20.2-linux-amd64.tar.gz ...

Istio 1.20.2 Download Complete!

Istio has been successfully downloaded into the istio-1.20.2 folder on your system.

Next Steps:
See https://istio.io/latest/docs/setup/install/ to add Istio to your Kubernetes cluster.

To configure the istioctl client tool for your workstation,
add the /home/centos/istio-1.20.2/bin directory to your environment path variable with:
	 export PATH="$PATH:/home/centos/istio-1.20.2/bin"

Begin the Istio pre-installation check by running:
	 istioctl x precheck 

Need more information? Visit https://istio.io/latest/docs/setup/install/

[centos@k8sel-521149 ~]$ vi ~/.bash_profile
 
export PATH="$PATH:/home/centos/istio-1.20.2/bin"

:wq

[centos@k8sel-521149 ~]$ . ~/.bash_profile

[centos@k8sel-521149 ~]$ istioctl version
no ready Istio pods in "istio-system"
1.20.2

[centos@k8sel-521149 ~]$ istioctl profile list
Istio configuration profiles:
    ambient
    default
    demo
    empty
    external
    minimal
    openshift
    preview
    remote

[centos@k8sel-521149 ~]$ istioctl install --set profile=default
This will install the Istio 1.20.2 "default" profile (with components: Istio core, Istiod, and Ingress gateways) into the cluster. Proceed? (y/N) y
✔ Istio core installed                                                                                                                               
✔ Istiod installed                                                                                                                                   
✔ Ingress gateways installed                                                                                                                         
✔ Installation complete                                                                                                                              
Made this installation the default for injection and validation.
```

istio가 배포된 내용을 확인한다.

```jsx
[centos@k8sel-521149 ~]$ kubectl get ns
NAME              STATUS   AGE
argocd            Active   5d6h
default           Active   30d
istio-system      Active   82s
kube-node-lease   Active   30d
kube-public       Active   30d
kube-system       Active   30d

[centos@k8sel-521149 ~]$ kubectl -n istio-system get deploy
NAME                   READY   UP-TO-DATE   AVAILABLE   AGE
istio-ingressgateway   1/1     1            1           119s
istiod                 1/1     1            1           2m18s

[centos@k8sel-521149 ~]$ kubectl -n istio-system get service
NAME                   TYPE           CLUSTER-IP    EXTERNAL-IP   PORT(S)                                      AGE
istio-ingressgateway   LoadBalancer   10.109.61.0   <pending>     15021:30920/TCP,80:30168/TCP,443:32702/TCP   2m7s
istiod                 ClusterIP      10.104.8.21   <none>        15010/TCP,15012/TCP,443/TCP,15014/TCP        2m25s

[centos@k8sel-521149 ~]$ kubectl label namespace default istio-injection=enabled --overwrite
namespace/default labeled

[centos@k8sel-521149 ~]$ kubectl get namespaces -L istio-injection
NAME              STATUS   AGE    ISTIO-INJECTION
argocd            Active   5d6h   
default           Active   30d    enabled
istio-system      Active   4m     
kube-node-lease   Active   30d    
kube-public       Active   30d    
kube-system       Active   30d
```

istio기반 서비스 모니터링 도구를 구성하겠다.

```jsx
[centos@k8sel-521149 ~]$ kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.20/samples/addons/prometheus.yaml
serviceaccount/prometheus created
configmap/prometheus created
clusterrole.rbac.authorization.k8s.io/prometheus created
clusterrolebinding.rbac.authorization.k8s.io/prometheus created
service/prometheus created
deployment.apps/prometheus created

[centos@k8sel-521149 ~]$ kubectl get deploy,po,svc -n istio-system --selector=app=prometheus
NAME                         READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/prometheus   1/1     1            1           26s

NAME                              READY   STATUS    RESTARTS   AGE
pod/prometheus-7f467df8b6-qn2l4   2/2     Running   0          26s

NAME                 TYPE        CLUSTER-IP    EXTERNAL-IP   PORT(S)    AGE
service/prometheus   ClusterIP   10.98.34.45   <none>        9090/TCP   26s

[centos@k8sel-521149 ~]$ kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.20/samples/addons/grafana.yaml
serviceaccount/grafana created
configmap/grafana created
service/grafana created
Warning: spec.template.spec.containers[0].ports[1]: duplicate port definition with spec.template.spec.containers[0].ports[0]
deployment.apps/grafana created
configmap/istio-grafana-dashboards created
configmap/istio-services-grafana-dashboards created

[centos@k8sel-521149 ~]$ kubectl get deploy,po,svc -n istio-system | grep grafana
deployment.apps/grafana                1/1     1            1           27s
pod/grafana-545465bf4c-b9jnq                1/1     Running   0          27s
service/grafana                ClusterIP      10.108.243.114   <none>        3000/TCP                                     27s
```

포트포워드를 한후 브라우저에서 접속한다. 

```jsx
[centos@k8sel-521149 ~]$ POD_NAME=$(kubectl -n istio-system get pod -l app=grafana -o jsonpath='{.items[0].metadata.name}')
[centos@k8sel-521149 ~]$ kubectl port-forward --address='0.0.0.0' $POD_NAME 3000:3000 -n istio-system &
[1] 216106
[centos@k8sel-521149 ~]$ Forwarding from 0.0.0.0:3000 -> 3000
```

![Untitled](src/Untitled%2056.png)

$ kubectl delete -f [https://raw.githubusercontent.com/istio/istio/release-1.17/samples/addons/kiali.yaml](https://raw.githubusercontent.com/istio/istio/release-1.20/samples/addons/kiali.yaml)

istio기반 kiali를 구성한다. 

```jsx
[centos@k8sel-521149 ~]$ kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.20/samples/addons/kiali.yaml
serviceaccount/kiali created
configmap/kiali created
clusterrole.rbac.authorization.k8s.io/kiali-viewer created
clusterrole.rbac.authorization.k8s.io/kiali created
clusterrolebinding.rbac.authorization.k8s.io/kiali created
role.rbac.authorization.k8s.io/kiali-controlplane created
rolebinding.rbac.authorization.k8s.io/kiali-controlplane created
service/kiali created
deployment.apps/kiali created

[centos@k8sel-521149 ~]$ kubectl get deploy,po,svc -n istio-system --selector=app=kiali
NAME                    READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/kiali   1/1     1            1           48s

NAME                        READY   STATUS    RESTARTS   AGE
pod/kiali-8f985c677-xdzlq   1/1     Running   0          48s

NAME            TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)              AGE
service/kiali   ClusterIP   10.105.82.182   <none>        20001/TCP,9090/TCP   48s

[centos@k8sel-521149 ~]$ POD_NAME=$(kubectl -n istio-system get pod -l app=kiali -o jsonpath='{.items[0].metadata.name}')
[centos@k8sel-521149 ~]$ kubectl port-forward --address='0.0.0.0' $POD_NAME 20001:20001 -n istio-system &
[2] 237490
[centos@k8sel-521149 ~]$ Forwarding from 0.0.0.0:20001 -> 20001
```

[http://localhost:20001](http://localhost:20001) 로 접속했다. 

![Untitled](src/Untitled%2057.png)

예거를 구성한다. 

```jsx
[centos@k8sel-521149 ~]$ kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.20/samples/addons/jaeger.yaml
deployment.apps/jaeger created
service/tracing created
service/zipkin created
service/jaeger-collector created

[centos@k8sel-521149 ~]$ kubectl get deploy,po,svc -n istio-system --selector=app=jaeger
NAME                     READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/jaeger   1/1     1            1           47s

NAME                          READY   STATUS    RESTARTS   AGE
pod/jaeger-7cf8c7c56d-pgzcj   1/1     Running   0          47s

NAME                       TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)                        AGE
service/jaeger-collector   ClusterIP   10.102.73.221   <none>        14268/TCP,14250/TCP,9411/TCP   46s
service/tracing            ClusterIP   10.109.43.80    <none>        80/TCP,16685/TCP               47s

[centos@k8sel-521149 ~]$ POD_NAME=$(kubectl -n istio-system get pod -l app=jaeger -o jsonpath='{.items[0].metadata.name}')
[centos@k8sel-521149 ~]$ kubectl port-forward --address='0.0.0.0' $POD_NAME 16686:16686 -n istio-system &
[3] 257298
[centos@k8sel-521149 ~]$ Forwarding from 0.0.0.0:16686 -> 16686
```

웹브라우저 [http://localhost:16686](http://localhost:16686) 으로 확인한다. 

![Untitled](src/Untitled%2058.png)

k8s autoscaling 및 node 자원 모니터링을 위한 metric server를 설치한다. 

```jsx

(msaapp) [centos@k8sel-521149 msaapp]$ minikube addons enable metrics-server
💡  metrics-server is an addon maintained by Kubernetes. For any concerns contact minikube on GitHub.
You can view the list of minikube maintainers at: https://github.com/kubernetes/minikube/blob/master/OWNERS
    ▪ Using image registry.k8s.io/metrics-server/metrics-server:v0.6.4
🌟  The 'metrics-server' addon is enabled

~~[centos@k8sel-521149 ~]$ kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
serviceaccount/metrics-server created
clusterrole.rbac.authorization.k8s.io/system:aggregated-metrics-reader created
clusterrole.rbac.authorization.k8s.io/system:metrics-server created
rolebinding.rbac.authorization.k8s.io/metrics-server-auth-reader created
clusterrolebinding.rbac.authorization.k8s.io/metrics-server:system:auth-delegator created
clusterrolebinding.rbac.authorization.k8s.io/system:metrics-server created
service/metrics-server created
deployment.apps/metrics-server created
apiservice.apiregistration.k8s.io/v1beta1.metrics.k8s.io created

[centos@k8sel-521149 ~]$ kubectl get deployment metrics-server -n kube-system
NAME             READY   UP-TO-DATE   AVAILABLE   AGE
metrics-server   0/1     1            0           44s

[centos@k8sel-521149 ~]$ kubectl get deployment
NAME               READY   UP-TO-DATE   AVAILABLE   AGE
guestbook-ui       1/1     1            1           19h
mongodb            1/1     1            1           8d
movies             3/3     3            3           8d
nginx-deployment   3/3     3            3           18h
postgres           1/1     1            1           8d
users              3/3     3            3           8d~~
```

### 14. 마이크로서비스 관리자 앱 작성 (manange app ← user app & movies app)

NodeJS를 설치한다. 

```jsx
[centos@k8sel-521149 ~]$ msaapp
(msaapp) [centos@k8sel-521149 msaapp]$ sudo yum install nodejs
Failed loading plugin "osmsplugin": No module named 'librepo'
Last metadata expiration check: 0:00:08 ago on Tue 13 Feb 2024 09:15:59 AM CET.
Dependencies resolved.
=======================================================================================================================================================
 Package                         Architecture          Version                                                          Repository                Size
=======================================================================================================================================================
Installing:
 nodejs                          x86_64                1:10.23.1-1.module_el8.4.0+645+9ce14ba2                          appstream                8.9 M
Installing dependencies:
 npm                             x86_64                1:6.14.10-1.10.23.1.1.module_el8.4.0+645+9ce14ba2                appstream                3.7 M
Installing weak dependencies:
 nodejs-full-i18n                x86_64                1:10.23.1-1.module_el8.4.0+645+9ce14ba2                          appstream                7.3 M
Enabling module streams:
 nodejs                                                10                                                                                             

Transaction Summary
=======================================================================================================================================================
Install  3 Packages

Total download size: 20 M
Installed size: 71 M
Is this ok [y/N]: y
Downloading Packages:
(1/3): npm-6.14.10-1.10.23.1.1.module_el8.4.0+645+9ce14ba2.x86_64.rpm                                                   19 MB/s | 3.7 MB     00:00    
(2/3): nodejs-full-i18n-10.23.1-1.module_el8.4.0+645+9ce14ba2.x86_64.rpm                                                31 MB/s | 7.3 MB     00:00    
(3/3): nodejs-10.23.1-1.module_el8.4.0+645+9ce14ba2.x86_64.rpm                                                          32 MB/s | 8.9 MB     00:00    
-------------------------------------------------------------------------------------------------------------------------------------------------------
Total                                                                                                                   23 MB/s |  20 MB     00:00     
Running transaction check
Transaction check succeeded.
Running transaction test
Transaction test succeeded.
Running transaction
  Running scriptlet: npm-1:6.14.10-1.10.23.1.1.module_el8.4.0+645+9ce14ba2.x86_64                                                                  1/1 
  Preparing        :                                                                                                                               1/1 
  Installing       : nodejs-full-i18n-1:10.23.1-1.module_el8.4.0+645+9ce14ba2.x86_64                                                               1/3 
  Installing       : npm-1:6.14.10-1.10.23.1.1.module_el8.4.0+645+9ce14ba2.x86_64                                                                  2/3 
  Installing       : nodejs-1:10.23.1-1.module_el8.4.0+645+9ce14ba2.x86_64                                                                         3/3 
  Running scriptlet: nodejs-1:10.23.1-1.module_el8.4.0+645+9ce14ba2.x86_64                                                                         3/3 
  Verifying        : nodejs-1:10.23.1-1.module_el8.4.0+645+9ce14ba2.x86_64                                                                         1/3 
  Verifying        : nodejs-full-i18n-1:10.23.1-1.module_el8.4.0+645+9ce14ba2.x86_64                                                               2/3 
  Verifying        : npm-1:6.14.10-1.10.23.1.1.module_el8.4.0+645+9ce14ba2.x86_64                                                                  3/3 

Installed:
  nodejs-1:10.23.1-1.module_el8.4.0+645+9ce14ba2.x86_64                    nodejs-full-i18n-1:10.23.1-1.module_el8.4.0+645+9ce14ba2.x86_64            
  npm-1:6.14.10-1.10.23.1.1.module_el8.4.0+645+9ce14ba2.x86_64            

Complete!

(msaapp) [centos@k8sel-521149 msaapp]$ node -v
v10.23.1

(msaapp) [centos@k8sel-521149 msaapp]$ npm -v
6.14.10
```

[https://docs.nestjs.com/](https://docs.nestjs.com/)

Hello World 예제를 작성해 본다. NodeJS의 express 프레임워크를 쓰겠다. 

```jsx
(msaapp) [centos@k8sel-521149 msaapp]$ npm init -y
Wrote to /home/centos/msaapp/package.json:

{
  "name": "msaapp",
  "version": "1.0.0",
  "description": "",
  "main": "app.js",
  "directories": {
    "lib": "lib"
  },
  "dependencies": {
    "express": "^4.18.2",
    "got": "^14.2.0",
    "request": "^2.88.2"
  },
  "devDependencies": {},
  "scripts": {
    "test": "echo \"Error: no test specified\" && exit 1"
  },
  "repository": {
    "type": "git",
    "url": "https://gitlab.example.com:8929/devadm/msa"
  },
  "keywords": [],
  "author": "",
  "license": "ISC"
}

(msaapp) [centos@k8sel-521149 msaapp]$ npm list express
/home/centos/msaapp
└── (empty)

(msaapp) [centos@k8sel-521149 msaapp]$ npm install express
npm WARN saveError ENOENT: no such file or directory, open '/home/centos/msaapp/package.json'
npm notice created a lockfile as package-lock.json. You should commit this file.
npm WARN enoent ENOENT: no such file or directory, open '/home/centos/msaapp/package.json'
npm WARN msaapp No description
npm WARN msaapp No repository field.
npm WARN msaapp No README data
npm WARN msaapp No license field.

+ express@4.18.2
added 64 packages from 41 contributors and audited 64 packages in 2.672s

12 packages are looking for funding
  run `npm fund` for details

found 0 vulnerabilities

(msaapp) [centos@k8sel-521149 msaapp]$ vi app.js

const express = require('express');
const app = express();
const port = 3000;

app.get('/', (req, res) => {
  res.send('Hello World!');
});

app.listen(port, () => {
  console.log(`app listening port : ${port}`);
});

:wq

(msaapp) [centos@k8sel-521149 msaapp]$ node app.js &
[1] 168354
(msaapp) [centos@k8sel-521149 msaapp]$ app listening port : 3000

(msaapp) [centos@k8sel-521149 msaapp]$ curl http://localhost:3000
Hello World! 

(msaapp) [centos@k8sel-521149 msaapp]$ ps -ef | grep node
(msaapp) [centos@k8sel-521149 msaapp]$ kill -9 168354
(msaapp) [centos@k8sel-521149 msaapp]$ 
[1]+  Killed                  node app.js
```

minikube에 배포된 유저 및 영화 서비스 endpoint를 확인한다. 

```jsx
(msaapp) [centos@k8sel-521149 msaapp]$ kubectl get svc 
NAME               TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)          AGE
guestbook-ui       ClusterIP   10.107.160.253   <none>        80/TCP           7d17h
kubernetes         ClusterIP   10.96.0.1        <none>        443/TCP          37d
mongodb-service    ClusterIP   10.105.228.58    <none>        27017/TCP        15d
movies-service     NodePort    10.105.225.65    <none>        5000:32281/TCP   15d
postgres-service   ClusterIP   10.107.135.138   <none>        5432/TCP         15d
users-service      NodePort    10.104.195.135   <none>        5000:31971/TCP   15d

(msaapp) [centos@k8sel-521149 msaapp]$ curl http://192.168.49.2:32281/v1/movies/
"[{\"moviecd\": \"K21967\", \"moviename\": \"도망친 여자\", \"moviedirector\": \"홍상수\", \"publishyear\": \"2019\", \"cat1\": \"사사로운 영화리스트\", \"cat2\": \"2020\"}, {\"moviecd\": \"F02308\", \"moviename\": \"19번째 남자\", \"moviedirector\": \"론 셀턴\", \"publishyear\": \"1988\", \"cat1\": \"미국영화협회 AFI\", \"cat2\": \"AFI's 10 Top 10 (2008)\"}, {\"moviecd\": \"F22873\", \"moviename\": \"푸른 천사\", \"moviedirector\": \"요제프 폰 슈테른베르크\", \"publishyear\": \"1930\", \"cat1\": \"기타\", \"cat2\": \"죽기 전에 꼭 봐야 할 영화 1001 (2019)\"}]"(msaapp) [centos@k8sel-521149 msaapp]$ 

(msaapp) [centos@k8sel-521149 msaapp]$ curl http://192.168.49.2:31971/v1/user/
[[{"user_id": 4, "user_name": "김성현", "user_agent": "Opera/9.20.(Windows NT 10.0; lt-LT) Presto/2.9.168 Version/11.00", "last_conn_date": "2024-01-28T13:39:48.232142"}], [{"user_id": 3, "user_name": "권성수", "user_agent": "Mozilla/5.0 (Android 11; Mobile; rv:24.0) Gecko/24.0 Firefox/24.0", "last_conn_date": "2024-01-28T13:39:08.934672"}], [{"user_id": 2, "user_name": "이현준", "user_agent": "Mozilla/5.0 (Windows; U; Windows NT 6.0) AppleWebKit/534.27.3 (KHTML, like Gecko) Version/5.0.3 Safari/534.27.3", "last_conn_date": "2024-01-28T13:39:08.210067"}], [{"user_id": 1, "user_name": "엄하은", "user_agent": "Mozilla/5.0 (Windows NT 6.2; om-ET; rv:1.9.0.20) Gecko/5009-09-11 23:10:09.665222 Firefox/3.6.13", "last_conn_date": "2024-01-28T13:39:06.118517"}]](msaapp) [centos@k8sel-521149 msaapp]$
```

manage서비스를 만든다. 

NodeJS exporess 및 swagger-autogen을 적용하고, 기존 flask기반 user, movies 마이크로서비스를 call하는 관리 역할의 앱 이다. 

DB는 연계하지 않고, http request만 수행하는 역할의 앱이다.  

REST API spec 문서를 자동 생성할 것이므로 swagger autogen 라이브러리를 설치한다.

```jsx
(msaapp) [centos@k8sel-521149 msaapp]$ npm install swagger-jsdoc swagger-ui-express swagger-autogen request
```

app.js에서 user와 movies 앱을 call하도록 작성한다. 

```jsx
(msaapp) [centos@k8sel-521149 msaapp]$ vi app.js
const express = require('express');
const app = express();
const request = require('request');
const port = 3000;

app.get('/v1/manage/hello', (req, res) => {
  res.send('Hello World!');
});

app.get('/v1/manage/', (req, res) => {
  var data, data2
  request('http://192.168.49.2:31971/v1/user/', function (error, response, body) {
          if(!error && response.statusCode == 200) {
                  data = JSON.stringify(body);
                  console.log(data);
          }
  });
  request('http://192.168.49.2:32281/v1/movies/', function (error, response, body) {
          if(!error && response.statusCode == 200) {
                  data2 = JSON.stringify(body);
                  console.log(data2);
                  res.send(data.concat(' ',data2));
          }
  });
});

app.listen(port, () => {
  console.log(`app listening port : ${port}`);
});

:wq

(msaapp) [centos@k8sel-521149 msaapp]$ node app.js
app listening port : 3000
```

다른 터미널에서 http call을 수행해본다.

```jsx
[centos@k8sel-521149 ~]$ curl http://localhost:3000/v1/manage/hello
Hello World!

[centos@k8selcurl http://localhost:3000/v1/manage/
"[[{\"user_id\": 4, \"user_name\": \"김성현\", \"user_agent\": \"Opera/9.20.(Windows NT 10.0; lt-LT) Presto/2.9.168 Version/11.00\", \"last_conn_date\": \"2024-01-28T13:39:48.232142\"}], [{\"user_id\": 3, \"user_name\": \"권성수\", \"user_agent\": \"Mozilla/5.0 (Android 11; Mobile; rv:24.0) Gecko/24.0 Firefox/24.0\", \"last_conn_date\": \"2024-01-28T13:39:08.934672\"}], [{\"user_id\": 2, \"user_name\": \"이현준\", \"user_agent\": \"Mozilla/5.0 (Windows; U; Windows NT 6.0) AppleWebKit/534.27.3 (KHTML, like Gecko) Version/5.0.3 Safari/534.27.3\", \"last_conn_date\": \"2024-01-28T13:39:08.210067\"}], [{\"user_id\": 1, \"user_name\": \"엄하은\", \"user_agent\": \"Mozilla/5.0 (Windows NT 6.2; om-ET; rv:1.9.0.20) Gecko/5009-09-11 23:10:09.665222 Firefox/3.6.13\", \"last_conn_date\": \"2024-01-28T13:39:06.118517\"}]]" "\"[{\\\"moviecd\\\": \\\"K21967\\\", \\\"moviename\\\": \\\"도망친 여자\\\", \\\"moviedirector\\\": \\\"홍상수\\\", \\\"publishyear\\\": \\\"2019\\\", \\\"cat1\\\": \\\"사사로운 영화리스트\\\", \\\"cat2\\\": \\\"2020\\\"}, {\\\"moviecd\\\": \\\"F02308\\\", \\\"moviename\\\": \\\"19번째 남자\\\", \\\"moviedirector\\\": \\\"론 셀턴\\\", \\\"publishyear\\\": \\\"1988\\\", \\\"cat1\\\": \\\"미국영화협회 AFI\\\", \\\"cat2\\\": \\\"AFI's 10 Top 10 (2008)\\\"}, {\\\"moviecd\\\": \\\"F22873\\\", \\\"moviename\\\": \\\"푸른 천사\\\", \\\"moviedirector\\\": \\\"요제프 폰 슈테른베르크\\\", \\\"publishyear\\\": \\\"1930\\\", \\\"cat1\\\": \\\"기타\\\", \\\"cat2\\\": \\\"죽기 전에 꼭 봐야 할 영화 1001 (2019)\\\"}]\""[centos@k8sel-521149 ~]$
```

swagger api 문서 작업을 적용한다. 

```jsx
(msaapp) [centos@k8sel-521149 msaapp]$ vi swagger.js
const swaggerAutogen = require('swagger-autogen')({ language: 'ko' });

const doc = {
  info: {
    title: "매니저서비스",
    description: "유저서비스와 영화서비스를 연계",
  },
  host: "localhost",
  schemes: ["http"],
  // schemes: ["https" ,"http"],
};

const outputFile = "./swagger-output.json";     // 같은 위치에 swagger-output.json을 만든다.
const endpointsFiles = [
  "./app.js"                                    // 라우터가 명시된 곳을 지정해준다.
];

swaggerAutogen(outputFile, endpointsFiles, doc);

:wq

(msaapp) [centos@k8sel-521149 msaapp]$ node swagger.js 
Swagger-autogen:  Success ✔

(msaapp) [centos@k8sel-521149 msaapp]$ cat swagger-output.json 
{
  "swagger": "2.0",
  "info": {
    "title": "매니저서비스",
    "description": "유저서비스와 영화서비스를 연계",
    "version": "1.0.0"
  },
  "host": "localhost",
  "basePath": "/",
  "schemes": [
    "http"
  ],
  "paths": {
    "/v1/manage/hello": {
      "get": {
        "description": "",
        "responses": {
          "200": {
            "description": "성공"
          }
        }
      }
    },
    "/v1/manage/": {
      "get": {
        "description": "",
        "responses": {
          "200": {
            "description": "성공"
          }
        }
      }
    }
  }
}

(msaapp) [centos@k8sel-521149 msaapp]$ vi app.js
const express = require('express');
const app = express();
const request = require('request');
const port = 3000;

const swaggerUi = require('swagger-ui-express');
const swaggerFile = require('./swagger-output.json');

app.use('/swagger', swaggerUi.serve, swaggerUi.setup(swaggerFile));

app.get('/v1/manage/hello', (req, res) => {
  res.send('Hello World!');
});

app.get('/v1/manage/', (req, res) => {
  var data, data2
  request('http://192.168.49.2:31971/v1/user/', function (error, response, body) {
	  if(!error && response.statusCode == 200) {
		  data = JSON.stringify(body);
		  console.log(data);
	  }
  });
  request('http://192.168.49.2:32281/v1/movies/', function (error, response, body) {
	  if(!error && response.statusCode == 200) {
		  data2 = JSON.stringify(body);
		  console.log(data2);
		  res.send(data.concat(' ',data2));
	  }
  });
});

app.listen(port, () => {
  console.log(`app listening port : ${port}`);
});

:wq

(msaapp) [centos@k8sel-521149 msaapp]$ node app.js
app listening port : 3000
```

다른 터미널에서 http call을 수행해본다.

```jsx
[centos@k8sel-521149 ~]$ curl http://localhost:3000/v1/manage/hello
Hello World!

[centos@k8sel-521149 ~]$ curl http://localhost:3000/swagger
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<title>Redirecting</title>
</head>
<body>
<pre>Redirecting to <a href="/swagger/">/swagger/</a></pre>
</body>
</html>
[centos@k8sel-521149 ~]$ curl http://localhost:3000/swagger/

<!-- HTML for static distribution bundle build -->
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  
  <title>Swagger UI</title>
  <link rel="stylesheet" type="text/css" href="./swagger-ui.css" >
  <link rel="icon" type="image/png" href="./favicon-32x32.png" sizes="32x32" /><link rel="icon" type="image/png" href="./favicon-16x16.png" sizes="16x16" />
  <style>
    html
    {
      box-sizing: border-box;
      overflow: -moz-scrollbars-vertical;
      overflow-y: scroll;
    }
    *,
    *:before,
    *:after
    {
      box-sizing: inherit;
    }

    body {
      margin:0;
      background: #fafafa;
    }
  </style>
</head>

<body>

<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" style="position:absolute;width:0;height:0">
  <defs>
    <symbol viewBox="0 0 20 20" id="unlocked">
      <path d="M15.8 8H14V5.6C14 2.703 12.665 1 10 1 7.334 1 6 2.703 6 5.6V6h2v-.801C8 3.754 8.797 3 10 3c1.203 0 2 .754 2 2.199V8H4c-.553 0-1 .646-1 1.199V17c0 .549.428 1.139.951 1.307l1.197.387C5.672 18.861 6.55 19 7.1 19h5.8c.549 0 1.428-.139 1.951-.307l1.196-.387c.524-.167.953-.757.953-1.306V9.199C17 8.646 16.352 8 15.8 8z"></path>
    </symbol>

    <symbol viewBox="0 0 20 20" id="locked">
      <path d="M15.8 8H14V5.6C14 2.703 12.665 1 10 1 7.334 1 6 2.703 6 5.6V8H4c-.553 0-1 .646-1 1.199V17c0 .549.428 1.139.951 1.307l1.197.387C5.672 18.861 6.55 19 7.1 19h5.8c.549 0 1.428-.139 1.951-.307l1.196-.387c.524-.167.953-.757.953-1.306V9.199C17 8.646 16.352 8 15.8 8zM12 8H8V5.199C8 3.754 8.797 3 10 3c1.203 0 2 .754 2 2.199V8z"/>
    </symbol>

    <symbol viewBox="0 0 20 20" id="close">
      <path d="M14.348 14.849c-.469.469-1.229.469-1.697 0L10 11.819l-2.651 3.029c-.469.469-1.229.469-1.697 0-.469-.469-.469-1.229 0-1.697l2.758-3.15-2.759-3.152c-.469-.469-.469-1.228 0-1.697.469-.469 1.228-.469 1.697 0L10 8.183l2.651-3.031c.469-.469 1.228-.469 1.697 0 .469.469.469 1.229 0 1.697l-2.758 3.152 2.758 3.15c.469.469.469 1.229 0 1.698z"/>
    </symbol>

    <symbol viewBox="0 0 20 20" id="large-arrow">
      <path d="M13.25 10L6.109 2.58c-.268-.27-.268-.707 0-.979.268-.27.701-.27.969 0l7.83 7.908c.268.271.268.709 0 .979l-7.83 7.908c-.268.271-.701.27-.969 0-.268-.269-.268-.707 0-.979L13.25 10z"/>
    </symbol>

    <symbol viewBox="0 0 20 20" id="large-arrow-down">
      <path d="M17.418 6.109c.272-.268.709-.268.979 0s.271.701 0 .969l-7.908 7.83c-.27.268-.707.268-.979 0l-7.908-7.83c-.27-.268-.27-.701 0-.969.271-.268.709-.268.979 0L10 13.25l7.418-7.141z"/>
    </symbol>

    <symbol viewBox="0 0 24 24" id="jump-to">
      <path d="M19 7v4H5.83l3.58-3.59L8 6l-6 6 6 6 1.41-1.41L5.83 13H21V7z"/>
    </symbol>

    <symbol viewBox="0 0 24 24" id="expand">
      <path d="M10 18h4v-2h-4v2zM3 6v2h18V6H3zm3 7h12v-2H6v2z"/>
    </symbol>

  </defs>
</svg>

<div id="swagger-ui"></div>

<script src="./swagger-ui-bundle.js"> </script>
<script src="./swagger-ui-standalone-preset.js"> </script>
<script src="./swagger-ui-init.js"> </script>

<style>
  .swagger-ui .topbar .download-url-wrapper { display: none } undefined
</style>
</body>

</html>

[centos@k8sel-521149 ~]$ curl http://localhost:3000/v1/manage/
"[[{\"user_id\": 4, \"user_name\": \"김성현\", \"user_agent\": \"Opera/9.20.(Windows NT 10.0; lt-LT) Presto/2.9.168 Version/11.00\", \"last_conn_date\": \"2024-01-28T13:39:48.232142\"}], [{\"user_id\": 3, \"user_name\": \"권성수\", \"user_agent\": \"Mozilla/5.0 (Android 11; Mobile; rv:24.0) Gecko/24.0 Firefox/24.0\", \"last_conn_date\": \"2024-01-28T13:39:08.934672\"}], [{\"user_id\": 2, \"user_name\": \"이현준\", \"user_agent\": \"Mozilla/5.0 (Windows; U; Windows NT 6.0) AppleWebKit/534.27.3 (KHTML, like Gecko) Version/5.0.3 Safari/534.27.3\", \"last_conn_date\": \"2024-01-28T13:39:08.210067\"}], [{\"user_id\": 1, \"user_name\": \"엄하은\", \"user_agent\": \"Mozilla/5.0 (Windows NT 6.2; om-ET; rv:1.9.0.20) Gecko/5009-09-11 23:10:09.665222 Firefox/3.6.13\", \"last_conn_date\": \"2024-01-28T13:39:06.118517\"}]]" "\"[{\\\"moviecd\\\": \\\"K21967\\\", \\\"moviename\\\": \\\"도망친 여자\\\", \\\"moviedirector\\\": \\\"홍상수\\\", \\\"publishyear\\\": \\\"2019\\\", \\\"cat1\\\": \\\"사사로운 영화리스트\\\", \\\"cat2\\\": \\\"2020\\\"}, {\\\"moviecd\\\": \\\"F02308\\\", \\\"moviename\\\": \\\"19번째 남자\\\", \\\"moviedirector\\\": \\\"론 셀턴\\\", \\\"publishyear\\\": \\\"1988\\\", \\\"cat1\\\": \\\"미국영화협회 AFI\\\", \\\"cat2\\\": \\\"AFI's 10 Top 10 (2008)\\\"}, {\\\"moviecd\\\": \\\"F22873\\\", \\\"moviename\\\": \\\"푸른 천사\\\", \\\"moviedirector\\\": \\\"요제프 폰 슈테른베르크\\\", \\\"publishyear\\\": \\\"1930\\\", \\\"cat1\\\": \\\"기타\\\", \\\"cat2\\\": \\\"죽기 전에 꼭 봐야 할 영화 1001 (2019)\\\"}]\""[centos@k8sel-521149 ~]$
```

매니저서비스 API swagger 화면이다. 

![Untitled](src/Untitled%2059.png)

영화 관리 API swagger 이다. 

![Untitled](src/Untitled%2060.png)

사용자 관리 API swagger 이다. 

![Untitled](src/Untitled%2061.png)

manage서비스 docker 이미지를 빌드한다. 

```jsx
(msaapp) [centos@k8sel-521149 msaapp]$ kubectl get svc
NAME               TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)          AGE
movies-service     NodePort    10.105.225.65    <none>        5000:32281/TCP   16d
users-service      NodePort    10.104.195.135   <none>        5000:31971/TCP   16d

(msaapp) [centos@k8sel-521149 msaapp]$ vi app.js

request('http://users-service:5000/v1/user/', function (error, response, body) {
   
request('http://movies-service:5000/v1/movies/', function (error, response, body) {

:wq

(msaapp) [centos@k8sel-521149 msaapp]$ vi Dockerfile.manageapp
FROM node:16
WORKDIR /usr/src/app
COPY package*.json ./
COPY swa*.json ./

RUN npm install 
COPY *.js ./
EXPOSE 3000
CMD ["node", "app.js"]

(msaapp) [centos@k8sel-521149 msaapp]$ docker build -f Dockerfile.manageapp -t manage:v1.0 .
[+] Building 42.0s (11/11) FINISHED                                                                                                     docker:default
 => [internal] load build definition from Dockerfile.manageapp                                                                                    0.0s
 => => transferring dockerfile: 273B                                                                                                              0.0s
 => [internal] load .dockerignore                                                                                                                 0.0s
 => => transferring context: 2B                                                                                                                   0.0s
 => [internal] load metadata for docker.io/library/node:16                                                                                        2.3s
 => [1/6] FROM docker.io/library/node:16@sha256:f77a1aef2da8d83e45ec990f45df50f1a286c5fe8bbfb8c6e4246c6389705c0b                                 16.6s
 => => resolve docker.io/library/node:16@sha256:f77a1aef2da8d83e45ec990f45df50f1a286c5fe8bbfb8c6e4246c6389705c0b                                  0.0s
 => => sha256:1ddc7e4055fdb6f6bf31063b593befda814294f9f904b6ddfc21ab1513bafa8e 7.23kB / 7.23kB                                                    0.0s
 => => sha256:311da6c465ea1576925360eba391bcd32dece9be95960a0bc9ffcb25fe712017 50.50MB / 50.50MB                                                  0.8s
 => => sha256:ffd9397e94b74abcb54e514f1430e00f604328d1f895eadbd482f08cc02444e5 51.89MB / 51.89MB                                                  1.3s
 => => sha256:f77a1aef2da8d83e45ec990f45df50f1a286c5fe8bbfb8c6e4246c6389705c0b 776B / 776B                                                        0.0s
 => => sha256:c94b82f9827cab6e421b350965a9ef11b25b13ffbd1030536203d541f55dcbe2 2.00kB / 2.00kB                                                    0.0s
 => => sha256:7e9bf114588c05b2df612b083b96582f3b8dbf51647aa6138a50d09d42df2454 17.58MB / 17.58MB                                                  0.9s
 => => sha256:513d779256048c961239af5f500589330546b072775217272e19ffae1635e98e 191.90MB / 191.90MB                                                5.9s
 => => extracting sha256:311da6c465ea1576925360eba391bcd32dece9be95960a0bc9ffcb25fe712017                                                         2.6s
 => => sha256:ae3b95bbaa61ce24cefdd89e7c74d6fbd7713b2bcae93af47063d06bd7e02172 4.20kB / 4.20kB                                                    1.1s
 => => sha256:0e421f66aff42bb069dffc26af6d132194b22a1082b08c5ef7cd69c627783c04 34.79MB / 34.79MB                                                  1.9s
 => => sha256:ca266fd6192108b67fb57b74753a8c4ca5d8bd458baae3d4df7ce9f42dedcc1d 2.27MB / 2.27MB                                                    1.6s
 => => sha256:ee7d78be1eb92caf6ae84fc3af736b23eca018d5dedc967ae5bdee6d7082403b 450B / 450B                                                        1.9s
 => => extracting sha256:7e9bf114588c05b2df612b083b96582f3b8dbf51647aa6138a50d09d42df2454                                                         0.8s
 => => extracting sha256:ffd9397e94b74abcb54e514f1430e00f604328d1f895eadbd482f08cc02444e5                                                         2.2s
 => => extracting sha256:513d779256048c961239af5f500589330546b072775217272e19ffae1635e98e                                                         6.5s
 => => extracting sha256:ae3b95bbaa61ce24cefdd89e7c74d6fbd7713b2bcae93af47063d06bd7e02172                                                         0.0s
 => => extracting sha256:0e421f66aff42bb069dffc26af6d132194b22a1082b08c5ef7cd69c627783c04                                                         1.3s
 => => extracting sha256:ca266fd6192108b67fb57b74753a8c4ca5d8bd458baae3d4df7ce9f42dedcc1d                                                         0.1s
 => => extracting sha256:ee7d78be1eb92caf6ae84fc3af736b23eca018d5dedc967ae5bdee6d7082403b                                                         0.0s
 => [internal] load build context                                                                                                                 0.1s
 => => transferring context: 56.07kB                                                                                                              0.1s
 => [2/6] WORKDIR /usr/src/app                                                                                                                   17.5s
 => [3/6] COPY package*.json ./                                                                                                                   0.1s
 => [4/6] COPY swa*.json ./                                                                                                                       0.1s
 => [5/6] RUN npm install                                                                                                                         4.8s
 => [6/6] COPY *.js ./                                                                                                                            0.0s
 => exporting to image                                                                                                                            0.5s 
 => => exporting layers                                                                                                                           0.5s 
 => => writing image sha256:c03e9914ecb834d6ab8269708be7af8552ced68387418dc9dfff1498a535023d                                                      0.0s 
 => => naming to docker.io/library/manage:v1.0                                                                                                    0.0s

(msaapp) [centos@k8sel-521149 msaapp]$ docker tag manage:v1.0 0.0.0.0:8000/manage:v1.0
(msaapp) [centos@k8sel-521149 msaapp]$ docker push 0.0.0.0:8000/manage:v1.0
The push refers to repository [0.0.0.0:8000/manage]
e4fab1ca7c24: Pushed 
1e32d9f972c5: Pushed 
34e3a177e51d: Pushed 
cdfd155b3d7e: Pushed 
f647d740af85: Pushed 
be322b479aee: Pushed 
d41bcd3a037b: Pushed 
fe0d845e767b: Pushed 
f25ec1d93a58: Pushed 
794ce8b1b516: Pushed 
3220beed9b06: Pushed 
684f82921421: Pushed 
9af5f53e8f62: Pushed 
1.0: digest: sha256:e69f54db15dacc682aa4880e1d8daaa2ed9abbbebae014dd455a07cc019840b8 size: 3046

(msaapp) [centos@k8sel-521149 msaapp]$ docker images
REPOSITORY                                                          TAG              IMAGE ID       CREATED          SIZE
0.0.0.0:8000/manage                                                 v1.0             e994797d98ed   2 minutes ago    948MB
manage                                                              v1.0             e994797d98ed   2 minutes ago    948MB..중략.. 

(msaapp) [centos@k8sel-521149 msaapp]$ docker run -p 3000:3000 -d manage:v1.0 
838565c95d8c7ccf74c217001d1b3bb03b9a057d5f081b1342351d6c7c585d64

(msaapp) [centos@k8sel-521149 msaapp]$ docker container ps 
CONTAINER ID   IMAGE                                 COMMAND                  CREATED         STATUS                 PORTS                                                                                                                                  NAMES
838565c95d8c   manage:v1.0                           "docker-entrypoint.s…"   7 seconds ago   Up 6 seconds           0.0.0.0:3000->3000/tcp, :::3000->3000/tcp                                                                                              blissful_mclean
..중략..

(msaapp) [centos@k8sel-521149 msaapp]$ curl http://localhost:3000/v1/manage/hello
Hello World!

(msaapp) [centos@k8sel-521149 msaapp]$ vi manage.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: manage
  name: manage
spec:
  replicas: 3
  selector:
    matchLabels:
      app: manage
  template:
    metadata:
      labels:
        app: manage
    spec:
      containers:
      - image: docker.io/library/manage:v1.0
        imagePullPolicy: IfNotPresent
        name: manage
        ports:
        - containerPort: 3000
          protocol: TCP
        resources:
          limits:
            cpu: 500m
          requests:
            cpu: 200m
---
apiVersion: v1
kind: Service
metadata:
  labels:
    app: manage
  name: manage-service
spec:
  type: NodePort
  ports:
  - port: 3000
  selector:
    app: manage

:wq

(msaapp) [centos@k8sel-521149 msaapp]$ minikube image load manage:v1.0
(msaapp) [centos@k8sel-521149 msaapp]$ minikube image list
..중략..
docker.io/library/manage:v1.0
..중략..

(msaapp) [centos@k8sel-521149 msaapp]$ kubectl apply -f manage.yaml
deployment.apps/manage created
service/manage-service created

(msaapp) [centos@k8sel-521149 msaapp]$ kubectl get svc
NAME               TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)          AGE
guestbook-ui       ClusterIP   10.107.160.253   <none>        80/TCP           8d
kubernetes         ClusterIP   10.96.0.1        <none>        443/TCP          38d
manage-service     NodePort    10.103.60.121    <none>        3000:31576/TCP   19s
mongodb-service    ClusterIP   10.105.228.58    <none>        27017/TCP        16d
movies-service     NodePort    10.105.225.65    <none>        5000:32281/TCP   16d
postgres-service   ClusterIP   10.107.135.138   <none>        5432/TCP         16d
users-service      NodePort    10.104.195.135   <none>        5000:31971/TCP   16d

(msaapp) [centos@k8sel-521149 msaapp]$ kubectl get pods
NAME                                READY   STATUS    RESTARTS         AGE
guestbook-ui-56c646849b-s2sqd       1/1     Running   5 (5h25m ago)    8d
manage-797ccbf97d-g6jc4             2/2     Running   0                28s
manage-797ccbf97d-h9ssr             2/2     Running   0                28s
manage-797ccbf97d-kj4zd             2/2     Running   0                28s
mongodb-6f4797467-j5fm4             1/1     Running   14 (5h25m ago)   16d
movies-744b4586c4-l97vh             1/1     Running   14 (5h25m ago)   16d
movies-744b4586c4-nrmfk             1/1     Running   14 (5h25m ago)   16d
movies-744b4586c4-s452w             1/1     Running   14 (5h25m ago)   16d
nginx-deployment-7c79c4bf97-25x56   1/1     Running   4 (5h25m ago)    8d
nginx-deployment-7c79c4bf97-67426   1/1     Running   4 (5h25m ago)    8d
nginx-deployment-7c79c4bf97-svzn6   1/1     Running   4 (5h25m ago)    8d
postgres-76fb566885-rdfp2           1/1     Running   14 (5h25m ago)   16d
users-68468f8bc7-2mm9g              1/1     Running   14 (5h25m ago)   16d
users-68468f8bc7-8nz86              1/1     Running   14 (5h25m ago)   16d
users-68468f8bc7-tltbm              1/1     Running   14 (5h25m ago)   16d
```

manage 서비스 스웨거에 접속했다. 

![Untitled](src/Untitled%2062.png)

manage 서비스 hello를 호출했다. 

![Untitled](src/Untitled%2063.png)

manage 서비스를 call하여 유저서비스, 영화서비스를 조합한 결과를 반환했다. 

![Untitled](src/Untitled%2064.png)

### 15. POD 부하테스트 및 오토스케일링

Horizontal Pod Autoscaler 구성을 한다. 

```jsx
(msaapp) [centos@k8sel-521149 msaapp]$ kubectl autoscale deployment manage --cpu-percent=30 --min=3 --max=5
horizontalpodautoscaler.autoscaling/manage autoscaled

(msaapp) [centos@k8sel-521149 msaapp]$ kubectl get hpa
NAME     REFERENCE           TARGETS         MINPODS   MAXPODS   REPLICAS   AGE
manage   Deployment/manage   <unknown>/30%   3         5         0          7s

(msaapp) [centos@k8sel-521149 msaapp]$ sudo yum install httpd-tools

[centos@k8sel-521149 ~]$ kubectl get hpa --watch
NAME     REFERENCE           TARGETS         MINPODS   MAXPODS   REPLICAS   AGE
manage   Deployment/manage   <unknown>/30%   3         5         3          3m57s
```

다른 터미널을 열어 부하를 준다. CPU를 올리기 위해 백그라운드로 3개를 돌려준다.

```jsx
(msaapp) [centos@k8sel-521149 msaapp]$ ab -n 10000000000 -c 10 http://192.168.49.2:31576/v1/manage/hello &
[1] 3583740
(msaapp) [centos@k8sel-521149 msaapp]$ This is ApacheBench, Version 2.3 <$Revision: 1843412 $>
Copyright 1996 Adam Twiss, Zeus Technology Ltd, http://www.zeustech.net/
Licensed to The Apache Software Foundation, http://www.apache.org/

Benchmarking 192.168.49.2 (be patient)

(msaapp) [centos@k8sel-521149 msaapp]$ ab -n 10000000000 -c 10 http://192.168.49.2:31576/swagger/ &
[2] 3585743
(msaapp) [centos@k8sel-521149 msaapp]$ This is ApacheBench, Version 2.3 <$Revision: 1843412 $>
Copyright 1996 Adam Twiss, Zeus Technology Ltd, http://www.zeustech.net/
Licensed to The Apache Software Foundation, http://www.apache.org/

Benchmarking 192.168.49.2 (be patient)

(msaapp) [centos@k8sel-521149 msaapp]$ ab -n 10000000000 -c 10 http://192.168.49.2:31576/swagger/ &
[3] 3643310
(msaapp) [centos@k8sel-521149 msaapp]$ This is ApacheBench, Version 2.3 <$Revision: 1843412 $>
Copyright 1996 Adam Twiss, Zeus Technology Ltd, http://www.zeustech.net/
Licensed to The Apache Software Foundation, http://www.apache.org/

Benchmarking 192.168.49.2 (be patient)

(msaapp) [centos@k8sel-521149 msaapp]$ kill -9 3630853  3632005 3643310
(msaapp) [centos@k8sel-521149 msaapp]$ 
[1]   Killed                  ab -n 10000000000 -c 10 http://192.168.49.2:31576/v1/manage/hello
[2]-  Killed                  ab -n 10000000000 -c 10 http://192.168.49.2:31576/swagger/
[3]+  Killed                  ab -n 10000000000 -c 10 http://192.168.49.2:31576/swagger/
```

오토스케일이 동작하여 POD가 증가하고, 부하를 중지하면 개수가 3개로 원복된다. 

```jsx
[centos@k8sel-521149 ~]$ kubectl get hpa --watch
NAME     REFERENCE           TARGETS   MINPODS   MAXPODS   REPLICAS   AGE
manage   Deployment/manage   0%/30%    3         5         3          21m
manage   Deployment/manage   6%/30%    3         5         3          21m
manage   Deployment/manage   14%/30%   3         5         3          22m
manage   Deployment/manage   0%/30%    3         5         3          23m
manage   Deployment/manage   112%/30%   3         5         3          24m
manage   Deployment/manage   112%/30%   3         5         5          25m
manage   Deployment/manage   52%/30%    3         5         5          25m
```

### 16. Minikube에서 external IP적용하기

[https://kyeongseo.tistory.com/entry/minikube-service-web에서-접속하는-방법](https://kyeongseo.tistory.com/entry/minikube-service-web%EC%97%90%EC%84%9C-%EC%A0%91%EC%86%8D%ED%95%98%EB%8A%94-%EB%B0%A9%EB%B2%95)

터미널을 추가로 열어 minikube tunnel을 수행한다. 

```jsx
[centos@k8sel-521149 ~]$ minikube tunnel
[sudo] password for centos: 
Status:	
	machine: minikube
	pid: 3951472
	route: 10.96.0.0/12 -> 192.168.49.2
	minikube: Running
	services: [istio-ingressgateway]
    errors: 
		minikube: no errors
		router: no errors
		loadbalancer emulator: no errors
```

minikube LB에서 펜딩상태였던 External-IP가 설정이 된다. 

```jsx
(msaapp) [centos@k8sel-521149 msaapp]$ kubectl get all -A

..중략..

NAMESPACE      NAME                                              TYPE           CLUSTER-IP       EXTERNAL-IP   PORT(S)                                      AGE
istio-system   service/istio-ingressgateway                      LoadBalancer   10.109.61.0      <pending>     15021:30920/TCP,80:30168/TCP,443:32702/TCP   8d

..중략..

(msaapp) [centos@k8sel-521149 msaapp]$ kubectl get all -A

..중략..

NAMESPACE      NAME                                              TYPE           CLUSTER-IP       EXTERNAL-IP   PORT(S)                                      AGE
istio-system   service/istio-ingressgateway                      LoadBalancer   10.109.61.0      10.109.61.0   15021:30920/TCP,80:30168/TCP,443:32702/TCP   8d

..중략..

(msaapp) [centos@k8sel-521149 msaapp]$ ping 10.109.61.0
PING 10.109.61.0 (10.109.61.0) 56(84) bytes of data.
From 192.168.49.2 icmp_seq=2 Redirect Host(New nexthop: 192.168.49.1)
From 192.168.49.2 icmp_seq=3 Redirect Host(New nexthop: 192.168.49.1)
From 192.168.49.2 icmp_seq=5 Redirect Host(New nexthop: 192.168.49.1)
```

### 17. Istio Ingress Gateway 적용하기

users-mesh.yaml, movies-mesh.yaml, manage-mesh.yaml을 작성하고 apply한다. 

```jsx
(msaapp) [centos@k8sel-521149 msaapp]$ vi users-mesh.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: users
  name: users
spec:
  replicas: 3
  selector:
    matchLabels:
      app: users
      version : v1.0
  template:
    metadata:
      labels:
        app: users
        version : v1.0
    spec:
      containers:
      - image: docker.io/library/users:v1.0
        imagePullPolicy: IfNotPresent
        name: users
        ports:
        - containerPort: 5000
          protocol: TCP
        resources:
          limits:
            cpu: 500m
          requests:
            cpu: 200m
---
apiVersion: v1
kind: Service
metadata:
  labels:
    app: users
  name: users-service
spec:
  type: NodePort
  ports:
  - port: 5000
  selector:

(msaapp) [centos@k8sel-521149 msaapp]$ vi movies-mesh.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: movies 
  name: movies
spec:
  replicas: 3
  selector:
    matchLabels:
      app: movies
      version : v1.0
  template:
    metadata:
      labels:
        app: movies
        version : v1.0
    spec:
      containers:
      - image: docker.io/library/movies:v1.0
        imagePullPolicy: IfNotPresent
        name: movies
        ports:
        - containerPort: 5000
          protocol: TCP
        resources:
          limits:
            cpu: 500m
          requests:
            cpu: 200m
---
apiVersion: v1
kind: Service
metadata:
  labels:
    app: movies
  name: movies-service
spec:
  type: NodePort
  ports:
  - port: 5000
  selector:
    app: movies

(msaapp) [centos@k8sel-521149 msaapp]$ vi manage-mesh.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: manage
  name: manage
spec:
  replicas: 3
  selector:
    matchLabels:
      app: manage
      version : v1.0
  template:
    metadata:
      labels:
        app: manage
        version : v1.0
    spec:
      containers:
      - image: docker.io/library/manage:v1.0
        imagePullPolicy: IfNotPresent
        name: manage
        ports:
        - containerPort: 3000
          protocol: TCP
        resources:
          limits:
            cpu: 500m
          requests:
            cpu: 200m
---
apiVersion: v1
kind: Service
metadata:
  labels:
    app: manage
  name: manage-service
spec:
  type: NodePort
  ports:
  - port: 3000
  selector:
    app: manage

(msaapp) [centos@k8sel-521149 msaapp]$ kubectl delete -f users.yaml
deployment.apps "users" deleted
service "users-service" deleted
(msaapp) [centos@k8sel-521149 msaapp]$ kubectl delete -f movies.yaml
deployment.apps "movies" deleted
service "movies-service" deleted
(msaapp) [centos@k8sel-521149 msaapp]$ kubectl delete -f manage.yaml
deployment.apps "manage" deleted
service "manage-service" deleted

(msaapp) [centos@k8sel-521149 msaapp]$ kubectl apply -f users-mesh.yaml 
deployment.apps/users created
service/users-service created
(msaapp) [centos@k8sel-521149 msaapp]$ kubectl apply -f movies-mesh.yaml 
deployment.apps/movies created
service/movies-service created
(msaapp) [centos@k8sel-521149 msaapp]$ kubectl apply -f manage-mesh.yaml 
deployment.apps/manage created
service/manage-service created
```

istio를 사용하여 demo-gateway를 생성한다. 

```jsx
(msaapp) [centos@k8sel-521149 msaapp]$ vi demo-gateway.yaml
apiVersion: networking.istio.io/v1alpha3
kind: Gateway
metadata:
  name: demo-gateway
spec:
  selector:
    istio: ingressgateway
  servers:
  - port:
      number: 80
      name: http
      protocol: HTTP
    hosts:
    - "*"

:wq

(msaapp) [centos@k8sel-521149 msaapp]$ kubectl apply -f demo-gateway.yaml 
gateway.networking.istio.io/demo-gateway created

(msaapp) [centos@k8sel-521149 msaapp]$ kubectl get gateways
NAME           AGE
demo-gateway   19s

```

istio virtualservice를 구성하여 user, movies, manage 서비스를 등록한다.

```jsx
(msaapp) [centos@k8sel-521149 msaapp]$ vi demo-virtualservices.yaml
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: demo-virtualservice
spec:
  hosts:
  - "*"
  gateways:
  - demo-gateway
  http:
  - match:
    - uri:
        prefix: /v1/user
    route:
    - destination:
        host: users-service
        port:
          number: 5000
  - match:
    - uri:
        prefix: /v1/movies
    route:
    - destination:
        host: movies-service
        port:
          number: 5000
  - match:
    - uri:
        prefix: /v1/manage
    route:
    - destination:
        host: manage-service
        port:
          number: 3000

:wq

(msaapp) [centos@k8sel-521149 msaapp]$ kubectl apply -f demo-virtualservices.yaml 
virtualservice.networking.istio.io/demo-virtualservice created

(msaapp) [centos@k8sel-521149 msaapp]$ kubectl get virtualservices
NAME                  GATEWAYS           HOSTS   AGE
demo-virtualservice   ["demo-gateway"]   ["*"]   17s
```

istio ingress 접속 IP 포트를 확인하고, minikube tunnel 을 구동한다. 

```jsx
(msaapp) [centos@k8sel-521149 msaapp]$ kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
10.109.61.0

(msaapp) [centos@k8sel-521149 msaapp]$ kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="http2")].port}'
80(msaapp)  

[centos@k8sel-521149 ~]$ minikube tunnel
[sudo] password for centos: 
Status:	
	machine: minikube
	pid: 294318
	route: 10.96.0.0/12 -> 192.168.49.2
	minikube: Running
	services: [istio-ingressgateway]
    errors: 
		minikube: no errors
		router: no errors
		loadbalancer emulator: no errors
```

단일 istio ingress gateway로 API URI를 통합하여, API Gateway의 역할을 수행한다. 

![Untitled](src/Untitled%2065.png)

![Untitled](src/Untitled%2066.png)

![Untitled](src/Untitled%2067.png)

canary 배포를 테스트하기 위해 app.js를 수정하고, 컨테이너이미지를 빌드하여 minikube에 업로드한다. 

```jsx
(msaapp) [centos@k8sel-521149 msaapp]$ vi app.js

app.get('/v1/manage/hello', (req, res) => {
  res.send('Hello Canary!');
});

(msaapp) [centos@k8sel-521149 msaapp]$ docker build -t manage:v1.1 -f Dockerfile.manageapp .
(msaapp) [centos@k8sel-521149 msaapp]$ docker tag manage:v1.1 0.0.0.0:8000/manage:v1.1
(msaapp) [centos@k8sel-521149 msaapp]$ docker push 0.0.0.0:8000/manage:v1.1
(msaapp) [centos@k8sel-521149 msaapp]$ minikube image load manage:v1.1
```

manage-mesh_v1.1.yaml을 작성하여 apply한다.

```jsx
(msaapp) [centos@k8sel-521149 msaapp]$ vi manage-mesh_v1.1.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: manage
  name: manage-v1.1
spec:
  replicas: 3
  selector:
    matchLabels:
      app: manage
      version : v1.1
  template:
    metadata:
      labels:
        app: manage
        version : v1.1
    spec:
      containers:
      - image: docker.io/library/manage:v1.1
        imagePullPolicy: IfNotPresent
        name: manage
        ports:
        - containerPort: 3000
          protocol: TCP
        resources:
          limits:
            cpu: 500m
          requests:
            cpu: 200m
---
apiVersion: v1
kind: Service
metadata:
  labels:
    app: manage
  name: manage-service
spec:
  type: NodePort
  ports:
  - port: 3000
  selector:
    app: manage

(msaapp) [centos@k8sel-521149 msaapp]$ kubectl apply -f manage-mesh_v1.1.yaml 
Warning: metadata.name: this is used in Pod names and hostnames, which can result in surprising behavior; a DNS label is recommended: [must not contain dots]
deployment.apps/manage-v1.1 created
service/manage-service unchanged
```

canary 배포를 적용한다. 

```jsx
(msaapp) [centos@k8sel-521149 msaapp]$ vi demo-destinationrule.yaml
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: demo-destinationrule
spec:
  host: manage-service
  subsets:
  - name: base
    labels:
      version: v1.0
  - name: canary
    labels:
      version: v1.1

(msaapp) [centos@k8sel-521149 msaapp]$ kubectl apply -f demo-destinationrule.yaml 
destinationrule.networking.istio.io/demo-destinationrule created

(msaapp) [centos@k8sel-521149 msaapp]$ vi demo-virtualservices.yaml
metadata:
  name: demo-virtualservice
spec:
  hosts:
  - "*"
  gateways:
  - demo-gateway
  http:
  - match:
    - uri:
        prefix: /v1/user
    route:
    - destination:
        host: users-service
        port:
          number: 5000
  - match:
    - uri:
        prefix: /v1/movies
    route:
    - destination:
        host: movies-service
        port:
          number: 5000
  - match:
    - uri:
        prefix: /v1/manage
    route:
    - destination:
        host: manage-service
        subset : base
        port:
          number: 3000
      weight: 80
    - destination:
        host: manage-service
        subset : canary
        port:
          number: 3000
      weight: 20

(msaapp) [centos@k8sel-521149 msaapp]$ kubectl apply -f demo-virtualservices.yaml 
virtualservice.networking.istio.io/demo-virtualservice configured
```

HTTP get call을 해보면 80:20으로 카나리배포가 동작한다. 

![Untitled](src/Untitled%2068.png)

![Untitled](src/Untitled%2069.png)

![Untitled](src/Untitled%2070.png)

![Untitled](src/Untitled%2071.png)

![Untitled](src/Untitled%2072.png)

### 18. 서비스 메시 모니터링

원할한 모니터링을 위해 조회 워크로드를 수행한다. 

```jsx
while true;do curl http://10.109.61.0/v1/manage/; curl http://10.109.61.0/v1/manage/hello; sleep 5;done > /dev/null
```

그라파나 포트포워드를 한후 브라우저에서 접속한다. 

```jsx
[centos@k8sel-521149 ~]$ POD_NAME=$(kubectl -n istio-system get pod -l app=grafana -o jsonpath='{.items[0].metadata.name}')
[centos@k8sel-521149 ~]$ kubectl port-forward --address='0.0.0.0' $POD_NAME 3000:3000 -n istio-system &
[1] 216106
[centos@k8sel-521149 ~]$ Forwarding from 0.0.0.0:3000 -> 3000
```

왼쪽 메뉴의 대시보드>istio에서 다양한 대시보드로 서비스 메시 모니터링이 가능하다.

아래 화면은 워크로드 대시보드이다. 

![Untitled](src/Untitled%2073.png)

Istio 서비스 대시보드 이다. 

![Untitled](src/Untitled%2074.png)

퍼포먼스 대시보드이다. 

![Untitled](src/Untitled%2075.png)

kiali를 포트포워드해서 모니터링한다. 

```jsx

[centos@k8sel-521149 ~]$ POD_NAME=$(kubectl -n istio-system get pod -l app=kiali -o jsonpath='{.items[0].metadata.name}')
[centos@k8sel-521149 ~]$ kubectl port-forward --address='0.0.0.0' $POD_NAME 20001:20001 -n istio-system &
[2] 237490
[centos@k8sel-521149 ~]$ Forwarding from 0.0.0.0:20001 -> 20001
```

[http://localhost:20001](http://localhost:20001) 로 접속했다. 

네임스페이스별 정보가 보인다.

![Untitled](src/Untitled%2076.png)

왼쪽 메뉴 그래프메뉴의 모습이다. 서비스 트래픽이 보인다. 

![Untitled](src/Untitled%2077.png)

예거를 포트포워드해서 모니터링한다.  

```jsx
[centos@k8sel-521149 ~]$ POD_NAME=$(kubectl -n istio-system get pod -l app=jaeger -o jsonpath='{.items[0].metadata.name}')
[centos@k8sel-521149 ~]$ kubectl port-forward --address='0.0.0.0' $POD_NAME 16686:16686 -n istio-system &
[3] 257298
[centos@k8sel-521149 ~]$ Forwarding from 0.0.0.0:16686 -> 16686
```

웹브라우저 [http://localhost:16686](http://localhost:16686) 으로 확인한다. 

![Untitled](src/Untitled%2078.png)

![Untitled](src/Untitled%2079.png)

### 기타. CentOS 8 Stream Boot Volume 확장하기

OCI에서 boot volume을 60GB로 늘린 후 rescan을 작업한 후 확장을 시도한다. 

```jsx
sudo dd iflag=direct if=/dev/<DEVICE_NAME> of=/dev/null count=1

echo "1" | sudo tee /sys/class/block/<DEVICE_NAME>/device/rescan
```

lv확장한다. 

```jsx
[root@k8sel-521149 ~]# growpart /dev/sda 3
CHANGED: partition=3 start=2304000 old: size=81920000 end=84223999 new: size=123525087 end=125829086

[root@k8sel-521149 ~]# pvresize /dev/sda3
  Physical volume "/dev/sda3" changed
  1 physical volume(s) resized or updated / 0 physical volume(s) not resized

[root@k8sel-521149 ~]# vgs
  VG           #PV #LV #SN Attr   VSize   VFree  
  centosvolume   1   1   0 wz--n- <58.90g <19.84g

[root@k8sel-521149 ~]# lvextend -L +19G /dev/mapper/centosvolume-root
  Size of logical volume centosvolume/root changed from <39.06 GiB (9999 extents) to <58.06 GiB (14863 extents).
  Logical volume centosvolume/root successfully resized.

[root@k8sel-521149 ~]# xfs_growfs /dev/mapper/centosvolume-root
meta-data=/dev/mapper/centosvolume-root isize=512    agcount=4, agsize=2559744 blks
         =                       sectsz=4096  attr=2, projid32bit=1
         =                       crc=1        finobt=1, sparse=1, rmapbt=0
         =                       reflink=1    bigtime=0 inobtcount=0
data     =                       bsize=4096   blocks=10238976, imaxpct=25
         =                       sunit=0      swidth=0 blks
naming   =version 2              bsize=4096   ascii-ci=0, ftype=1
log      =internal log           bsize=4096   blocks=4999, version=2
         =                       sectsz=4096  sunit=1 blks, lazy-count=1
realtime =none                   extsz=4096   blocks=0, rtextents=0
data blocks changed from 10238976 to 15219712

[root@k8sel-521149 ~]# lsblk
NAME                  MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda                     8:0    0   60G  0 disk 
├─sda1                  8:1    0  100M  0 part /boot/efi
├─sda2                  8:2    0    1G  0 part /boot
└─sda3                  8:3    0 58.9G  0 part 
  └─centosvolume-root 253:0    0 58.1G  0 lvm  /

[root@k8sel-521149 ~]# df -h
Filesystem                     Size  Used Avail Use% Mounted on
devtmpfs                        32G     0   32G   0% /dev
tmpfs                           32G     0   32G   0% /dev/shm
tmpfs                           32G   33M   32G   1% /run
tmpfs                           32G     0   32G   0% /sys/fs/cgroup
/dev/mapper/centosvolume-root   59G   40G   19G  68% /
/dev/sda2                     1014M  565M  450M  56% /boot
/dev/sda1                      100M  7.3M   93M   8% /boot/efi
tmpfs                          6.3G     0  6.3G   0% /run/user/987
tmpfs                          6.3G  4.0K  6.3G   1% /run/user/1000

```
