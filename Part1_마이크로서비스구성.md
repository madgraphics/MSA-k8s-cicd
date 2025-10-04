# 마이크로서비스 샘플 아키텍처 구성
<br>

## 1. CentOS Stream 8 x86환경 구성

<br>

실습환경을 위한 가상 환경을 구현합니다.

centos 유저를 추가합니다.

```jsx
[opc@k8sel-521149 ~]$ sudo su -

[root@k8sel-521149 ~]# useradd centos

[root@k8sel-521149 ~]# usermod -aG wheel centos

[root@k8sel-521149 ~]# passwd centos

[root@k8sel-521149 ~]# sudo su - centos
```
<br>
도커를 설치합니다.

```jsx
[centos@k8sel-521149 ~]$ sudo dnf config-manager --add-repo=https://download.docker.com/linux/centos/docker-ce.repo

[centos@k8sel-521149 ~]$ sudo dnf install -y docker-ce

[centos@k8sel-521149 ~]$ sudo systemctl enable docker.service

[centos@k8sel-521149 ~]$ sudo systemctl start docker.service
```
<br>
non Root 유저가 docker 커맨드를 수행하기 위한 작업을 수행합니다.

```jsx
[centos@k8sel-521149 ~]$ sudo usermod -aG docker centos

[centos@k8sel-521149 ~]$ sudo systemctl restart docker

[centos@k8sel-521149 ~]$ exit

[root@k8sel-521149 ~]# sudo su - centos

[centos@k8sel-521149 ~]$ docker ps
```
<br>
“Server with GUI” 그룹 인스톨을 셋업하여 GUI환경을 구성합니다.

```jsx
[centos@k8sel-521149 ~]$ sudo dnf -y update

[centos@k8sel-521149 ~]$ sudo dnf groupinstall -y "Server with GUI" --skip-broken

[centos@k8sel-521149 ~]$ sudo systemctl set-default graphical

[centos@k8sel-521149 ~]$ sudo dnf install -y tigervnc-server

[centos@k8sel-521149 ~]$ vncpasswd
Password:
Verify:
Would you like to enter a view-only password (y/n)? y
Password:
Verify:

[centos@k8sel-521149 ~]$ vncserver

WARNING: vncserver has been replaced by a systemd unit and is now considered deprecated and removed in upstream.
Please read /usr/share/doc/tigervnc/HOWTO.md for more information.

New 'k8sel-521149:1 (centos)' desktop is k8sel-521149:1

Starting applications specified in /home/centos/.vnc/xstartup
Log file is /home/centos/.vnc/k8sel-521149:1.log

[centos@k8sel-521149 ~]$ netstat -tunlp
(Not all processes could be identified, non-owned process info
 will not be shown, you would have to be root to see it all.)
Active Internet connections (only servers)
Proto Recv-Q Send-Q Local Address           Foreign Address         State       PID/Program name    
tcp        0      0 0.0.0.0:5901            0.0.0.0:*               LISTEN      -                   
tcp        0      0 0.0.0.0:111             0.0.0.0:*               LISTEN      -                   
tcp        0      0 192.168.122.1:53        0.0.0.0:*               LISTEN      -                   
tcp        0      0 0.0.0.0:22              0.0.0.0:*               LISTEN      -                   
tcp        0      0 127.0.0.1:631           0.0.0.0:*               LISTEN      -                   
tcp6       0      0 :::5901                 :::*                    LISTEN      -                   
tcp6       0      0 :::5902                 :::*                    LISTEN      9878/Xvnc           
tcp6       0      0 :::111                  :::*                    LISTEN      -                   
tcp6       0      0 :::22                   :::*                    LISTEN      -                   
tcp6       0      0 ::1:631                 :::*                    LISTEN      -                   
udp        0      0 0.0.0.0:5353            0.0.0.0:*                           -                   
udp        0      0 0.0.0.0:47167           0.0.0.0:*                           -                   
udp        0      0 192.168.122.1:53        0.0.0.0:*                           -                   
udp        0      0 0.0.0.0:67              0.0.0.0:*                           -                   
udp        0      0 0.0.0.0:111             0.0.0.0:*                           -                   
udp        0      0 127.0.0.1:323           0.0.0.0:*                           -                   
udp6       0      0 :::5353                 :::*                                -                   
udp6       0      0 :::50888                :::*                                -                   
udp6       0      0 :::111                  :::*                                -                   
udp6       0      0 ::1:323                 :::*                                -

[centos@k8sel-521149 ~]$ sudo firewall-cmd --permanent --zone=public --add-port=5901/tcp

[centos@k8sel-521149 ~]$ sudo firewall-cmd --reload
```
<br>
5901 포트를 오픈한 후 접속합니다.

![Untitled](src/Untitled%207.png)

![Untitled](src/Untitled%208.png)


테스트를 위한 VM 구성이 완료되었습니다. 
권장 VM 사양은 CPU 8vcpu, Storage 50GB 입니다.

<br><br>

## 2. 개발 환경 구성 (postgreSQL, MongoDB, python flask)

<br>


![Untitled](src/Untitled%2010.png)

<br>

postgreSQL 16을  설치합니다.

```jsx
# Install the repository RPM:
[centos@k8sel-521149 ~]$ sudo dnf install -y https://download.postgresql.org/pub/repos/yum/reporpms/EL-8-x86_64/pgdg-redhat-repo-latest.noarch.rpm

# Disable the built-in PostgreSQL module:
[centos@k8sel-521149 ~]$ sudo dnf -qy module disable postgresql

# Install PostgreSQL:
[centos@k8sel-521149 ~]$ sudo dnf install -y postgresql16-server

# Optionally initialize the database and enable automatic start:
[centos@k8sel-521149 ~]$ sudo /usr/pgsql-16/bin/postgresql-16-setup initdb
Initializing database ... OK

[centos@k8sel-521149 ~]$ sudo systemctl enable postgresql-16
Created symlink /etc/systemd/system/multi-user.target.wants/postgresql-16.service → /usr/lib/systemd/system/postgresql-16.service.

[centos@k8sel-521149 ~]$ sudo systemctl start postgresql-16
```
<br>
접속하여 postgres 유저 패스워드를 변경합니다.

```jsx
[centos@k8sel-521149 ~]$ sudo su - postgres

[postgres@k8sel-521149 ~]$ psql
psql (16.1)
Type "help" for help.

postgres=# alter user postgres with password 'postgres';
ALTER ROLE
```

 
 <br>
mongodb7 을 설치합니다. 

```jsx
[centos@k8sel-521149 ~]$ sudo vi /etc/yum.repos.d/mongodb-org-7.0.repo

[mongodb-org-7.0]
name=MongoDB Repository
baseurl=https://repo.mongodb.org/yum/redhat/8/mongodb-org/7.0/x86_64/
gpgcheck=1
enabled=1
gpgkey=https://www.mongodb.org/static/pgp/server-7.0.asc

:wq

[centos@k8sel-521149 ~]$ sudo dnf install -y mongodb-org

[centos@k8sel-521149 ~]$ sudo systemctl enable mongod

[centos@k8sel-521149 ~]$ sudo systemctl start mongod
```


개발 DB 환경 구성이 완료되었습니다.
 

<br>
파이썬 버전을 확인합니다. 

```jsx
[centos@k8sel-521149 ~]$ sudo yum install -y python38
[centos@k8sel-521149 bin]$ python3.8 -V
Python 3.8.17
```
<br>
virtual env 가상 환경을 생성하고 활성화합니다. 

```jsx
[centos@k8sel-521149 ~]$ python3.8 -m venv msaapp
[centos@k8sel-521149 ~]$ source ~/msaapp/bin/activate
(msaapp) [centos@k8sel-521149 ~]$
```
<br>
pip를 최신버전으로 업그레이드 합니다. 

```jsx
(msaapp) [centos@k8sel-521149 ~]$ pip install --upgrade pip
```
<br>
flask 기반의 rest api 개발을 위한 모듈을 설치합니다. 

```jsx
(msaapp) [centos@k8sel-521149 ~]$ pip install flask
(msaapp) [centos@k8sel-521149 ~]$ pip install flask-restx
(msaapp) [centos@k8sel-521149 ~]$ pip install faker-datasets
(msaapp) [centos@k8sel-521149 ~]$ pip install pymongo
(msaapp) [centos@k8sel-521149 ~]$ pip install psycopg2-binary
```
<br><br>

## 3. 샘플 앱 개발 

<br>
postgres에서 유저DB와 테이블을 생성합니다

```jsx
(msaapp) [centos@k8sel-521149 msaapp]$ psql -U postgres -p 5432 -h 127.0.0.1
Password for user postgres: 
psql (16.1)
Type "help" for help.

postgres=# create database users;
CREATE DATABASE

postgres=# \c users
You are now connected to database "users" as user "postgres".

users=# CREATE TABLE users
users-# (
users(#         user_id serial primary key,
users(#         user_name VARCHAR(100),
users(#         country VARCHAR(100),
users(#         job VARCHAR(100),
users(#         email VARCHAR(100),
users(#         client_ip VARCHAR(100),
users(#         user_agent VARCHAR(200),
users(#         birth VARCHAR(100),
users(#         last_conn_date timestamp
users(# );
CREATE TABLE
users=# \q
```
<br>
users.sql

```jsx
drop table users;
CREATE TABLE users
(
        user_id serial primary key,
        user_name VARCHAR(100),
        country VARCHAR(100),
        job VARCHAR(100),
        email VARCHAR(100),
        client_ip VARCHAR(100),
        user_agent VARCHAR(200),
        birth VARCHAR(100),
        last_conn_date timestamp
);
```
<br>
users.py 를 작성합니다. 

```jsx
import logging, psycopg2, json
from datetime import datetime
from flask import Flask, Response
from flask_restx import Api, Resource 
from faker import Faker #샘플 데이터 생성용 모듈

app = Flask(__name__)
app.config['JSON_AS_ASCII'] = False
api = Api(app, version='1.0', title='사용자 관리 API', description='사용자 등록,조회 API입니다') 
api = api.namespace('v1/user', description='사용자 등록, 조회') 

logger = logging.getLogger() #로거 선언
logger.setLevel(logging.INFO)
fake = Faker("ko_KR")

#------------------------------------------------------------------------------
# DB 접속 정보 (테스트 환경에 맞춰 변경할 것)
#------------------------------------------------------------------------------
users_host_ip = '127.0.0.1'
users_db_name = 'users'
users_user_name = 'postgres'
users_passwd = 'postgres'

@api.route('/')  
class user(Resource):
    def post(self):
        '''사용자 정보를 등록한다'''
        try:
            #db 접속
            postgres_conn = psycopg2.connect(host=users_host_ip, user=users_user_name, password=users_passwd, database=users_db_name)
            
            #사용자의 접속이력을 기록 
            postgres_sql = "insert into users (user_name,job,client_ip,user_agent,birth,last_conn_date) select %s,%s,%s,%s,%s,current_timestamp"
            postgres_sql_val = (fake.name(),fake.job(),fake.ipv4_private(),fake.user_agent(),fake.date_of_birth())
            #print(postgres_sql_val)
            postgres_conn.cursor().execute(postgres_sql,postgres_sql_val)
            postgres_conn.commit()
            
            #db연결 해제 
            postgres_conn.close()
        except Exception as e:
            logger.error("db error : could not insert data")
            logger.error(e)
        logger.info("success : inserting data succeeded.")
        return { "success" : "inserting data succeeded." }

    def get(self):  
        '''사용자 정보를 조회한다'''
        try:
            #db 접속
            postgres_conn = psycopg2.connect(host=users_host_ip, user=users_user_name, password=users_passwd, database=users_db_name)
           
            #최종 접속 유저를 조회 
            postgres_sql = "select row_to_json(users) from (select user_id,user_name,user_agent,last_conn_date from users)users order by last_conn_date desc limit 10"
            postgres_cursor = postgres_conn.cursor()
            postgres_cursor.execute(postgres_sql)
            postgres_results = postgres_cursor.fetchall()
            
            #db연결 해제 
            postgres_conn.close()
        except Exception as e:
            logger.error("db error : could not fecth data")
            logger.error(e)
        logger.info("success : querying data succeeded.")
        return Response(json.dumps(postgres_results, ensure_ascii=False).encode('utf-8'), status=200, content_type='application/json; charset=utf-8')

@api.route('/hello')  
class hello(Resource):
    def get(self):  
        '''hello를 조회한다'''
        return "Hello, world!", 200, { "success" : "hello" } 

if __name__ == "__main__":
    app.debug = True
    app.run(host="0.0.0.0", port=int("5000"))
```
<br>
mongodb에서 유저를 추가합니다.

```jsx
(msaapp) [centos@k8sel-521149 msaapp]$ mongosh
Current Mongosh Log ID:	658e913d2386c994b744fdeb
Connecting to:		mongodb://127.0.0.1:27017/?directConnection=true&serverSelectionTimeoutMS=2000&appName=mongosh+2.1.1
Using MongoDB:		7.0.4
Using Mongosh:		2.1.1

For mongosh info see: https://docs.mongodb.com/mongodb-shell/

------
   The server generated these startup warnings when booting
   2023-12-29T02:42:33.696+01:00: Access control is not enabled for the database. Read and write access to data and configuration is unrestricted
   2023-12-29T02:42:33.697+01:00: vm.max_map_count is too low
------

test> use admin
switched to db admin
admin> db.createUser({ user:'mongo', pwd: 'mongo', roles: ['root'] })
{ ok: 1 }
admin> exit

(msaapp) [centos@k8sel-521149 msaapp]$ mongosh mongodb://127.0.0.1:27017 -u mongo -p
Enter password: *
Current Mongosh Log ID:	658e933c725181dc1e1a4336
Connecting to:		mongodb://<credentials>@127.0.0.1:27017/?directConnection=true&serverSelectionTimeoutMS=2000&appName=mongosh+2.1.1
Using MongoDB:		7.0.4
Using Mongosh:		2.1.1

For mongosh info see: https://docs.mongodb.com/mongodb-shell/

------
   The server generated these startup warnings when booting
   2023-12-29T02:42:33.696+01:00: Access control is not enabled for the database. Read and write access to data and configuration is unrestricted
   2023-12-29T02:42:33.697+01:00: vm.max_map_count is too low
------

test>
```
<br>
movies.py 를 작성합니다. 

```jsx
import logging, json
from pymongo import MongoClient
from datetime import datetime
from flask import Flask, Response
from flask_restx import Api, Resource 
from faker import Faker #샘플 데이터 생성용 모듈
from faker_datasets import Provider, add_dataset

app = Flask(__name__)
api = Api(app, version='1.0', title='영화 관리 API', description='영화 등록,조회 API입니다') 
api = api.namespace('v1/movies', description='영화 등록, 조회') 
logger = logging.getLogger() #로거 선언
logger.setLevel(logging.INFO)

@add_dataset("movies", "movies.json", picker="movie")
class Movies(Provider):
    pass
fake = Faker()
fake.add_provider(Movies)

#------------------------------------------------------------------------------
# DB 접속 정보 (테스트 환경에 맞춰 변경할 것)
#------------------------------------------------------------------------------
mongodb_host_ip = '127.0.0.1'
mongodb_user_name = 'mongo'
mongodb_passwd = 'mongo'
mongodb_port = 27017

@api.route('/')  
class book(Resource):
    def post(self):
        '''영화 정보를 등록한다'''
        try:
            #데이터 생성 
            movie = fake.movie()
            movie_data ={}
            movie_data['moviecd'] = '{mov_cd}'.format(movie)
            movie_data['moviename'] = '{mov_nm}'.format(movie)
            movie_data['moviedirector'] = '{mov_dir}'.format(movie)
            movie_data['publishyear'] = '{pbl_year}'.format(movie)
            movie_data['cat1'] = '{cat1}'.format(movie)
            movie_data['cat2'] = '{cat2}'.format(movie)
            movie_data['moviedesc'] = '{mov_desc}'.format(movie)

            #db 접속
            mongodb_conn = MongoClient(mongodb_host_ip, mongodb_port, username=mongodb_user_name, password=mongodb_passwd)
            mongo_collection = mongodb_conn.test.movies

            movies = [
                    movie_data
                    ]

            #등록 이력을 기록 
            mongo_collection.insert_many(movies)
 
        except Exception as e:
            logger.error("db error : could not insert data")
            logger.error(e)
        logger.info("success : inserting data succeeded.")
        return Response( json.dumps("success : inserting data succeeded."), status=200, content_type='application/json; charset=utf-8')
   
    def get(self):  
        '''영화 정보를 조회한다'''
        try:
            #db 접속
            mongodb_conn = MongoClient(mongodb_host_ip, mongodb_port, username=mongodb_user_name, password=mongodb_passwd)
            mongo_collection = mongodb_conn.test.movies

            #최종 접속 사용자를 조회 
            mongo_objects = mongodb_conn.test.movies.find({},{'_id': 0, 'moviedesc' :0}).sort("_id",-1).limit(3)
            mongo_result = str(json.dumps(list(mongo_objects), ensure_ascii=False, default=str))

        except Exception as e:
            logger.error("mongodb db error : could not fecth data")
            logger.error(e)
        logger.info("success : querying data succeeded.")
        return Response(json.dumps(mongo_result, ensure_ascii=False).encode('utf-8'),  status=200, content_type='application/json; charset=utf-8')

@api.route('/hello')  
class hello(Resource):
    def get(self):  
        '''hello를 조회한다'''
        return "Hello, world!", 200, { "success" : "hello" } 

if __name__ == "__main__":
    app.debug = True
    app.run(host="0.0.0.0", port=int("5000"))
```

<br><br>
## 4. DB와 샘플 앱을 도커환경에 배포

<br>
docker 기반 registry를 구성합니다.

```jsx
[centos@k8sel-521149 ~]$ docker run --name localhub -d --restart=always -p 8000:5000 registry:latest
ab21f10bc6f5aab43b743df6cb0f54246fe00445ba0fc1883538f5051366cd03
```
<br>
registry insecure 구성후 도커를 재기동 합니다. 

```jsx
[centos@k8sel-521149 ~]$ sudo vi vi /etc/docker/daemon.json
{

    "insecure-registries": ["0.0.0.0:8000"]

}

:wq

[centos@k8sel-521149 ~]$ sudo systemctl restart docker
```

<br>
postgres를 docker 로 배포합니다.

<br>
postgres 컨테이너의 데이터를 관리하기 위한 볼륨을 먼저 생성합니다. 

```jsx
[centos@k8sel-521149 msaapp]$ docker volume create pgdata
pgdata

[centos@k8sel-521149 msaapp]$ docker volume inspect pgdata
[
    {
        "CreatedAt": "2024-01-04T06:23:36+01:00",
        "Driver": "local",
        "Labels": null,
        "Mountpoint": "/var/lib/docker/volumes/pgdata/_data",
        "Name": "pgdata",
        "Options": null,
        "Scope": "local"
    }
]
```
<br>
postgres 컨테이너를 구동합니다.

```jsx
[centos@k8sel-521149 msaapp]$ docker run --restart unless-stopped -p 5430:5432 --name testdb-postgres -v pgdata:/var/lib/postgresql/data -e POSTGRES_PASSWORD=postgres -d postgres:16
Unable to find image 'postgres:16' locally
16: Pulling from library/postgres
af107e978371: Pull complete 
85f7bca87921: Pull complete 
948f1cf08e62: Pull complete 
1a83ab26a0f0: Pull complete 
12bab27fafd3: Pull complete 
644cfda281a1: Pull complete 
03299695f2b9: Pull complete 
6e36bf1505f3: Pull complete 
a35465a6a76a: Pull complete 
83b026289c5c: Pull complete 
c158e73dda41: Pull complete 
264ae53c0064: Pull complete 
2e3c2c5fbb6d: Pull complete 
08c5357f23b5: Pull complete 
Digest: sha256:e2135391c55eb2ecabaaaeef4a9538bb8915c1980953fb6ce41a2d6d3e4b5695
Status: Downloaded newer image for postgres:16
3ecccf0736f91aa30d2c977815ab5ad970c50a4a2ceb3096a4dffd82013930c9

[centos@k8sel-521149 msaapp]$ docker ps
CONTAINER ID   IMAGE         COMMAND                  CREATED          STATUS         PORTS                                       NAMES
3ecccf0736f9   postgres:16   "docker-entrypoint.s…"   12 seconds ago   Up 4 seconds   0.0.0.0:5430->5432/tcp, :::5430->5432/tcp   testdb-postgres
```
<br>
posgres에 접속하여 스키마를 구성합니다. 

```jsx
[centos@k8sel-521149 msaapp]$ psql -h localhost -U postgres -p 5430
Password for user postgres: 
psql (16.1)
Type "help" for help.

postgres=# 

postgres=# create database users;
CREATE DATABASE

postgres=# \c users
You are now connected to database "users" as user "postgres".

users=# CREATE TABLE users
users-# (
users(#         user_id serial primary key,
users(#         user_name VARCHAR(100),
users(#         country VARCHAR(100),
users(#         job VARCHAR(100),
users(#         email VARCHAR(100),
users(#         client_ip VARCHAR(100),
users(#         user_agent VARCHAR(200),
users(#         birth VARCHAR(100),
users(#         last_conn_date timestamp
users(# );
CREATE TABLE
users=# \q
```
<br>
users.py에서 db ip, port를 수정 후, 실행합니다. 

```jsx
[centos@k8sel-521149 msaapp]$ msaapp
(msaapp) [centos@k8sel-521149 msaapp]$ vi users.py

.. 중략..
users_host_ip = '172.17.0.1' 

            postgres_conn = psycopg2.connect(host=users_host_ip, user=users_user_name, password=users_passwd, database=users_db_name,port=5430)

:wq

(msaapp) [centos@k8sel-521149 msaapp]$ export FLASK_APP=users
(msaapp) [centos@k8sel-521149 msaapp]$ flask run --host=0.0.0.0 &
[1] 103445
(msaapp) [centos@k8sel-521149 msaapp]$  * Serving Flask app 'users'
 * Debug mode: off
WARNING: This is a development server. Do not use it in a production deployment. Use a production WSGI server instead.
 * Running on all addresses (0.0.0.0)
 * Running on http://127.0.0.1:5000
 * Running on http://10.0.0.13:5000
Press CTRL+C to quit

msaapp) [centos@k8sel-521149 msaapp]$ curl -X 'POST'   'http://localhost:5000/v1/user/'   -H 'accept: application/json'   -d ''
127.0.0.1 - - [04/Jan/2024 07:11:18] "POST /v1/user/ HTTP/1.1" 200 -
{"success": "inserting data succeeded."}

(msaapp) [centos@k8sel-521149 msaapp]$ curl -X 'GET'   'http://localhost:5000/v1/user/'   -H 'accept: application/json'
127.0.0.1 - - [04/Jan/2024 07:11:20] "GET /v1/user/ HTTP/1.1" 200 -
[[{"user_id": 10, "user_name": "김성호", "user_agent": "Mozilla/5.0 (Windows CE) AppleWebKit/534.2 (KHTML, like Gecko) Chrome/51.0.880.0 Safari/534.2", "last_conn_date": "2024-01-04T06:11:18.139269"}]]
```
<br>
mongodb 컨테이너의 데이터를 관리하기 위한 볼륨을 생성합니다. 

```jsx
[centos@k8sel-521149 ~]$ docker volume create mongodata
mongodata

[centos@k8sel-521149 ~]$ docker volume inspect mongodata
[
    {
        "CreatedAt": "2024-01-07T06:00:19+01:00",
        "Driver": "local",
        "Labels": null,
        "Mountpoint": "/var/lib/docker/volumes/mongodata/_data",
        "Name": "mongodata",
        "Options": null,
        "Scope": "local"
    }
]
```
<br>
mongodb 컨테이너를 구동합니다. 

```jsx
[centos@k8sel-521149 ~]$ docker run --restart unless-stopped -p 27018:27017 --name testdb-mongo -v mongodata:/data/db -d mongo:7
Unable to find image 'mongo:7' locally
7: Pulling from library/mongo
a48641193673: Pull complete 
bf55b1330fca: Pull complete 
92bc53a6d6fe: Pull complete 
b429365d99b9: Pull complete 
9c7bc1166582: Pull complete 
261b4f40ad6b: Pull complete 
97d4b3f3d31c: Pull complete 
d60dd40f133c: Pull complete 
3a13e71e4c17: Pull complete 
Digest: sha256:d14158139a0bbc1741136d3eded7bef018a5980760a57f0014a1d4ac7677e4b1
Status: Downloaded newer image for mongo:7
024601580cc1f317abceb1c085775d0fff08b3b7c1d9d7047f3d48683e725958
```
<br>
mongodb 에 접속하여 콜렉션을 확인해 봅니다. 

```jsx
[centos@k8sel-521149 ~]$ mongosh mongodb://localhost:27018
Current Mongosh Log ID:	659a349b463f156f7a960e49
Connecting to:		mongodb://localhost:27018/?directConnection=true&serverSelectionTimeoutMS=2000&appName=mongosh+2.1.1
Using MongoDB:		7.0.4
Using Mongosh:		2.1.1

For mongosh info see: https://docs.mongodb.com/mongodb-shell/

------
   The server generated these startup warnings when booting
   2024-01-07T05:17:57.332+00:00: Access control is not enabled for the database. Read and write access to data and configuration is unrestricted
   2024-01-07T05:17:57.332+00:00: vm.max_map_count is too low
------

test> use admin
switched to db admin
admin> db.createUser({ user:'mongo', pwd: 'mongo', roles: ['root'] })
{ ok: 1 }
admin> use test
switched to db test
test> show collections

test>
```
<br>
movies.py 에서 ip, db port를 수정 후, 실행합니다. 

```jsx
[centos@k8sel-521149 msaapp]$ msaapp
(msaapp) [centos@k8sel-521149 msaapp]$ vi movies.py

.. 중략..
mongodb_host_ip = '172.17.0.1'
mongodb_port = 27018

:wq

(msaapp) [centos@k8sel-521149 msaapp]$ flask run --host=0.0.0.0 &
[1] 31156
(msaapp) [centos@k8sel-521149 msaapp]$  * Serving Flask app 'movies'
 * Debug mode: off
WARNING: This is a development server. Do not use it in a production deployment. Use a production WSGI server instead.
 * Running on all addresses (0.0.0.0)
 * Running on http://127.0.0.1:5000
 * Running on http://10.0.0.13:5000
Press CTRL+C to quit

(msaapp) [centos@k8sel-521149 msaapp]$ curl -X 'POST'   'http://localhost:5000/v1/movies/'   -H 'accept: application/json'   -d ''
127.0.0.1 - - [07/Jan/2024 06:33:33] "POST /v1/movies/ HTTP/1.1" 200 -
"success : inserting data succeeded."(msaapp) [centos@k8sel-521149 msaapp]$ 

(msaapp) [centos@k8sel-521149 msaapp]$ curl -X 'GET'   'http://localhost:5000/v1/movies/'   -H 'accept: application/json'  
127.0.0.1 - - [07/Jan/2024 06:33:36] "GET /v1/movies/ HTTP/1.1" 200 -
"[{\"moviecd\": \"K05257\", \"moviename\": \"공동경비구역 J.S.A\", \"moviedirector\": \"박찬욱\", \"publishyear\": \"2000\", \"cat1\": \"국내\", \"cat2\": \"[한겨레] 한국영화 100선 (2019)\"}]"
```
<br>
이제 user 관리 어플리케이션과 movies 관리 어플리케이션을 컨테이너화 합니다. 

user, movies app각각의 Dockerfile 을 작성한후 빌드하고 DB 컨테이너와 연동합니다. 

도커 컨테이너로 배포하기 위해, Flask 앱 개발 중 설치한 파이썬 모듈을 추출합니다. 

```jsx
(msaapp) [centos@k8sel-521149 msaapp]$ pip freeze > requirements.txt
```
<br>
Dockerfile.userapp을 작성하고 build 합니다. 

```jsx
(msaapp) [centos@k8sel-521149 msaapp]$ cat Dockerfile.userapp 
FROM quay.io/centos/centos:stream8
RUN mkdir /app
COPY users.py requirements.txt /app
WORKDIR /app
RUN dnf install -y python38 && \
    dnf clean all && \
    pip3 install -r requirements.txt
EXPOSE 5000
ENV FLASK_APP=users
CMD ["python3", "-m", "flask", "run", "--host=0.0.0.0"]

(msaapp) [centos@k8sel-521149 msaapp]$ docker build -t users:v1.0 -f Dockerfile.userapp .
[+] Building 43.0s (10/10) FINISHED                                                                       docker:default
 => [internal] load .dockerignore                                                                                   0.0s
 => => transferring context: 2B                                                                                     0.0s
 => [internal] load build definition from Dockerfile.userapp                                                        0.0s
 => => transferring dockerfile: 411B                                                                                0.0s
 => [internal] load metadata for quay.io/centos/centos:stream8                                                      0.0s
 => [1/5] FROM quay.io/centos/centos:stream8                                                                        0.0s
 => [internal] load build context                                                                                   0.0s
 => => transferring context: 184B                                                                                   0.0s
 => CACHED [2/5] RUN mkdir /app                                                                                     0.0s
 => CACHED [3/5] COPY users.py requirements.txt /app                                                                0.0s
 => CACHED [4/5] WORKDIR /app                                                                                       0.0s
 => [5/5] RUN dnf install -y python38 &&     dnf clean all &&     pip3 install -r requirements.txt                 41.9s
 => exporting to image                                                                                              1.0s 
 => => exporting layers                                                                                             1.0s 
 => => writing image sha256:1f5f4cc199fbbbcc389c5933f8ce617fa55c822fc339767a1a0beebe91cd7c31                        0.0s 
 => => naming to docker.io/library/users:v1.0                                                                       0.0s 
```
<br>
Dockerfile.moviesapp을 작성하고 build 합니다. 

```jsx
(msaapp) [centos@k8sel-521149 msaapp]$ cat Dockerfile.moviesapp 
FROM quay.io/centos/centos:stream8
RUN mkdir /app
COPY movies.py requirements.txt movies.json /app
WORKDIR /app
RUN dnf install -y python38 && \
    dnf clean all && \
    pip3 install -r requirements.txt
EXPOSE 5000
ENV FLASK_APP=movies
CMD ["python3", "-m", "flask", "run", "--host=0.0.0.0"]

(msaapp) [centos@k8sel-521149 msaapp]$ docker build -t movies:v1.0 -f Dockerfile.moviesapp .
[+] Building 44.2s (10/10) FINISHED                                                                       docker:default
 => [internal] load .dockerignore                                                                                   0.0s
 => => transferring context: 2B                                                                                     0.0s
 => [internal] load build definition from Dockerfile.moviesapp                                                      0.0s
 => => transferring dockerfile: 401B                                                                                0.0s
 => [internal] load metadata for quay.io/centos/centos:stream8                                                      0.0s
 => [1/5] FROM quay.io/centos/centos:stream8                                                                        0.0s
 => [internal] load build context                                                                                   0.1s
 => => transferring context: 9.18MB                                                                                 0.1s
 => CACHED [2/5] RUN mkdir /app                                                                                     0.0s
 => [3/5] COPY movies.py requirements.txt movies.json /app                                                          0.1s
 => [4/5] WORKDIR /app                                                                                              0.0s
 => [5/5] RUN dnf install -y python38 &&     dnf clean all &&     pip3 install -r requirements.txt                 42.8s
 => exporting to image                                                                                              1.0s
 => => exporting layers                                                                                             1.0s
 => => writing image sha256:220f3f2d87fa73ff78f39af5b5506d5d023e284bab86548aa50fcf08b5d98a99                        0.0s 
 => => naming to docker.io/library/movies:v1.0                                                                      0.0s
```
<br>
docker 이미지로 컨테이너화된 DB와 App 목록입니다. 

```jsx
(msaapp) [centos@k8sel-521149 msaapp]$ docker images
REPOSITORY              TAG       IMAGE ID       CREATED          SIZE
movies                  v1.0      220f3f2d87fa   50 seconds ago   349MB
users                   v1.0      1f5f4cc199fb   3 minutes ago    340MB
quay.io/centos/centos   stream8   b27dee4ed0c4   4 days ago       218MB
mongo                   7         2e123a0ccb4b   2 weeks ago      757MB
postgres                16        398d34d3cc5e   3 weeks ago      425MB
```
<br>
어플리케이션 컨테이너를 구동하여 테스트해 봅니다. 

```jsx
(msaapp) [centos@k8sel-521149 msaapp]$ docker run -d -p 5001:5000 --name usersapp users:v1.0
45e2d9105b23d6c0acfe9857e75b803638a04426816ebebcfc4b28e3310b400d

(msaapp) [centos@k8sel-521149 msaapp]$ docker run -d -p 5002:5000 --name moviesapp movies:v1.0
f93f0e3de37e31cb62d7e77c30e8b81177c7b283f159a3f11615175eb27332e7

(msaapp) [centos@k8sel-521149 msaapp]$ docker ps 
CONTAINER ID   IMAGE         COMMAND                  CREATED          STATUS         PORTS                                           NAMES
f93f0e3de37e   movies:v1.0   "python3 -m flask ru…"   3 seconds ago    Up 2 seconds   0.0.0.0:5002->5000/tcp, :::5002->5000/tcp       moviesapp
45e2d9105b23   users:v1.0    "python3 -m flask ru…"   10 seconds ago   Up 8 seconds   0.0.0.0:5001->5000/tcp, :::5001->5000/tcp       usersapp
024601580cc1   mongo:7       "docker-entrypoint.s…"   2 hours ago      Up 2 hours     0.0.0.0:27018->27017/tcp, :::27018->27017/tcp   testdb-mongo
3ecccf0736f9   postgres:16   "docker-entrypoint.s…"   3 days ago       Up 2 hours     0.0.0.0:5430->5432/tcp, :::5430->5432/tcp       testdb-postgres

(msaapp) [centos@k8sel-521149 msaapp]$ curl -X 'POST'   'http://localhost:5001/v1/user/'   -H 'accept: application/json'   -d ''
{"success": "inserting data succeeded."}

(msaapp) [centos@k8sel-521149 msaapp]$ curl -X 'GET'   'http://localhost:5001/v1/user/'   -H 'accept: application/json'
[[{"user_id": 11, "user_name": "김예진", "user_agent": "Opera/8.81.(Windows NT 6.2; ps-AF) Presto/2.9.177 Version/10.00", "last_conn_date": "2024-01-07T06:58:19.655834"}], [{"user_id": 10, "user_name": "김성호", "user_agent": "Mozilla/5.0 (Windows CE) AppleWebKit/534.2 (KHTML, like Gecko) Chrome/51.0.880.0 Safari/534.2", "last_conn_date": "2024-01-04T06:11:18.139269"}]]

(msaapp) [centos@k8sel-521149 msaapp]$ curl -X 'POST'   'http://localhost:5002/v1/movies/'   -H 'accept: applica'   -d ''
"success : inserting data succeeded."

(msaapp) [centos@k8sel-521149 msaapp]$ curl -X 'GET'   'http://localhost:5002/v1/mov   /'   -H 'accept: application/json'
"[{\"moviecd\": \"F06355\", \"moviename\": \"산딸기\", \"moviedirector\": \"잉마르 베르히만\", \"publishyear\": \"1957\", \"cat1\": \"사이트 & 사운드\", \"cat2\": \"2012 (평론가)\"}, {\"moviecd\": \"K05257\", \"moviename\": \"공동경비구역 J.S.A\", \"moviedirector\": \"박찬욱\", \"publishyear\": \"2000\", \"cat1\": \"국내\", \"cat2\": \"[한겨레] 한국영화 100선 (2019)\"}]"
```
<br>
삽입된 데이터들은 아래 host path에 영구 스토리지로 관리됩니다. 

```jsx
(msaapp) [centos@k8sel-521149 msaapp]$ sudo ls /var/lib/docker/volumes/mongodata/_data
collection-0-1077918119646473304.wt   index-1-1077918119646473304.wt   index-9-1077918119646473304.wt  WiredTiger
collection-12-1077918119646473304.wt  index-13-1077918119646473304.wt  journal			       WiredTigerHS.wt
collection-2-1077918119646473304.wt   index-3-1077918119646473304.wt   _mdb_catalog.wt		       WiredTiger.lock
collection-4-1077918119646473304.wt   index-5-1077918119646473304.wt   mongod.lock		       WiredTiger.turtle
collection-7-1077918119646473304.wt   index-6-1077918119646473304.wt   sizeStorer.wt		       WiredTiger.wt
diagnostic.data			      index-8-1077918119646473304.wt   storage.bson

(msaapp) [centos@k8sel-521149 msaapp]$ sudo ls /var/lib/docker/volumes/pgdata/_data
base	      pg_dynshmem    pg_logical    pg_replslot	 pg_stat      pg_tblspc    pg_wal		 postgresql.conf
global	      pg_hba.conf    pg_multixact  pg_serial	 pg_stat_tmp  pg_twophase  pg_xact		 postmaster.opts
pg_commit_ts  pg_ident.conf  pg_notify	   pg_snapshots  pg_subtrans  PG_VERSION   postgresql.auto.conf  postmaster.pid
```
<br><br>
## 5. 쿠버네티스 환경 구성 (minikube)

![Untitled](src/Untitled%2014.png)

쿠버네티스의 싱글 노드 테스트 환경을 구현하기 위해 minikube를 설치합니다. 

```jsx
[centos@k8sel-521149 msaapp]$ curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64

[centos@k8sel-521149 msaapp]$ sudo install minikube-linux-amd64 /usr/local/bin/minikube

[centos@k8sel-521149 msaapp]$ minikube config set cpus 2
❗  These changes will take effect upon a minikube delete and then a minikube start

[centos@k8sel-521149 msaapp]$ minikube config set memory 32G
❗  These changes will take effect upon a minikube delete and then a minikube start

[centos@k8sel-521149 msaapp]$ minikube config set driver docker
❗  These changes will take effect upon a minikube delete and then a minikube start

[centos@k8sel-521149 msaapp]$ minikube config view
- cpus: 2
- driver: docker
- memory: 32G

[centos@k8sel-521149 msaapp]$ minikube start
😄  minikube v1.32.0 on Centos 8 (kvm/amd64)
✨  Using the docker driver based on user configuration
📌  Using Docker driver with root privileges
👍  Starting control plane node minikube in cluster minikube
🚜  Pulling base image ...
💾  Downloading Kubernetes v1.28.3 preload ...
    > preloaded-images-k8s-v18-v1...:  403.35 MiB / 403.35 MiB  100.00% 34.51 M
    > gcr.io/k8s-minikube/kicbase...:  453.90 MiB / 453.90 MiB  100.00% 33.46 M
🔥  Creating docker container (CPUs=2, Memory=32768MB) ...
🐳  Preparing Kubernetes v1.28.3 on Docker 24.0.7 ...
    ▪ Generating certificates and keys ...
    ▪ Booting up control plane ...
    ▪ Configuring RBAC rules ...
🔗  Configuring bridge CNI (Container Networking Interface) ...
🔎  Verifying Kubernetes components...
    ▪ Using image gcr.io/k8s-minikube/storage-provisioner:v5
🌟  Enabled addons: storage-provisioner, default-storageclass
💡  kubectl not found. If you need it, try: 'minikube kubectl -- get pods -A'
🏄  Done! kubectl is now configured to use "minikube" cluster and "default" namespace by default

[centos@k8sel-521149 msaapp]$ vi ~/.bash_profile

..중략
alias kubectl="minikube kubectl --"

:wq

[centos@k8sel-521149 msaapp]$ . ~/.bash_profile 
```

<br>
minikube 기반 로컬 private registry를 구성합니다. 

```jsx
[centos@k8sel-521149 ~]$ minikube addons enable registry
💡  registry is an addon maintained by minikube. For any concerns contact minikube on GitHub.
You can view the list of minikube maintainers at: https://github.com/kubernetes/minikube/blob/master/OWNERS
    ▪ Using image docker.io/registry:2.8.3
    ▪ Using image gcr.io/k8s-minikube/kube-registry-proxy:0.0.5
🔎  Verifying registry addon...
🌟  The 'registry' addon is enabled
```
<br>
registry 애드온이 80포트로 서비스되는 것을 확인 합니다.

```jsx
[centos@k8sel-521149 ~]$ kubectl get pods -A
NAMESPACE     NAME                               READY   STATUS    RESTARTS   AGE
 
kube-system   registry-dgnsv                     1/1     Running   0          40s
kube-system   registry-proxy-7l9xn               1/1     Running   0          40s
 
[centos@k8sel-521149 ~]$ kubectl get svc -A
NAMESPACE     NAME         TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)                  AGE

kube-system   registry     ClusterIP   10.96.74.176   <none>        80/TCP,443/TCP           74s

```
<br>
포트포워드를 하여 로컬호스트 포트로 서비스 합니다. 

```jsx
[centos@k8sel-521149 ~]$ kubectl port-forward --namespace kube-system service/registry 8000:80 &
[1] 247224
[centos@k8sel-521149 ~]$ Forwarding from 127.0.0.1:8000 -> 5000
Forwarding from [::1]:8000 -> 5000

[centos@k8sel-521149 ~]$ curl http://localhost:8000/v2/_catalog 
Handling connection for 8000
{"repositories":[]}
```
<br>
로컬 도커 이미지를 push 합니다.

```jsx
[centos@k8sel-521149 ~]$ docker tag users:v1.0 localhost:8000/users:v1.0
[centos@k8sel-521149 ~]$ docker push localhost:8000/users:v1.0
The push refers to repository [localhost:8000/users]
Handling connection for 8000
Handling connection for 8000
d0a29cc683c1: Preparing 
5f70bf18a086: Preparing 
676bbc11f182: Preparing 
e3f0e4311556: Preparing 
563d42adea21: Preparing 
Handling connection for 8000
Handling connection for 8000
Handling connection for 8000
Handling connection for 8000
676bbc11f182: Pushing [======>                                            ]     512B/3.887kB
Handling connection for 8000
d0a29cc683c1: Pushing [>                                                  ]  531.5kB/121.7MB
676bbc11f182: Pushing [==================================================>]  7.168kB
Handling connection for 8000
e3f0e4311556: Pushing  2.048kB
563d42adea21: Pushing [>                                                  ]  546.8kB/218.4MB
Handling connection for 8000
d0a29cc683c1: Pushing [==================================================>]  128.2MB
5f70bf18a086: Pushed 
d0a29cc683c1: Pushed 
Handling connection for 8000
563d42adea21: Pushing [==========================>                        ]  117.8MB/218.4MB
563d42adea21: Pushing [===========================>                       ]  120.6MB/218.4MB
563d42adea21: Pushing [==================================================>]  225.3MB
Handling connection for 8000
563d42adea21: Pushed 
Handling connection for 8000
Handling connection for 8000
Handling connection for 8000
Handling connection for 8000
Handling connection for 8000
Handling connection for 8000
v1.0: digest: sha256:949d718eaaefab0cf5e33df158de3611121309d31618ae8b574cfce9bfa4780c size: 1362

[centos@k8sel-521149 ~]$ docker tag movies:v1.0 localhost:8000/movies:v1.0
[centos@k8sel-521149 ~]$ docker push localhost:8000/movies:v1.0
The push refers to repository [localhost:8000/movies]
Handling connection for 8000
Handling connection for 8000
7ce5278782ea: Preparing 
5f70bf18a086: Preparing 
08f45eed5a59: Preparing 
e3f0e4311556: Preparing 
563d42adea21: Preparing 
Handling connection for 8000
Handling connection for 8000
Handling connection for 8000
Handling connection for 8000
Handling connection for 8000
7ce5278782ea: Pushing [>                                                  ]  531.5kB/121.7MB
Handling connection for 8000
08f45eed5a59: Pushing [>                                                  ]  99.33kB/9.176MB
7ce5278782ea: Pushing [=>                                                 ]   2.76MB/121.7MB
5f70bf18a086: Mounted from users 
7ce5278782ea: Pushing [==================================================>]  128.2MB
e3f0e4311556: Mounted from users 
7ce5278782ea: Pushed 
Handling connection for 8000
Handling connection for 8000
Handling connection for 8000
Handling connection for 8000
Handling connection for 8000
Handling connection for 8000
Handling connection for 8000
Handling connection for 8000
Handling connection for 8000
Handling connection for 8000
v1.0: digest: sha256:cce184b6ddae784b3704cf87a4f122250ecb9804b54e96dd46284b8f4e8bfdcc size: 1364

[centos@k8sel-521149 ~]$ curl http://localhost:8000/v2/_catalog 
Handling connection for 8000
{"repositories":["movies","users"]}
```

<br><br>
## 6. k8s 플랫폼에 샘플 앱 배포

<br>
mongodb.yaml을 작성한후 k8s에 배포합니다. 

```jsx
(msaapp) [centos@k8sel-521149 msaapp]$ vi mongodb.yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: mongodb-pv
spec:
  capacity:
    storage: 256Mi
  accessModes:
    - ReadWriteOnce
  hostPath:
    path: /tmp/db
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: mongodb-pvc
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 256Mi
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mongodb
spec:
  selector:
    matchLabels:
      app: mongodb
  template:
    metadata:
      labels:
        app: mongodb
    spec:
      containers:
        - name: mongodb
          image: mongo:7
          ports:
            - containerPort: 27017
          volumeMounts:
            - name: storage
              mountPath: /data/db
      volumes:
        - name: storage
          persistentVolumeClaim:
            claimName: mongodb-pvc
---
apiVersion: v1
kind: Service
metadata:
  name: mongodb-service
spec:
  selector:
    app: mongodb
  ports:
    - port: 27017
      targetPort: 27017
  type: ClusterIP

:wq

(msaapp) [centos@k8sel-521149 msaapp]$ kubectl apply -f  mongodb.yaml
persistentvolume/mongodb-pv created
persistentvolumeclaim/mongodb-pvc created
deployment.apps/mongodb created
service/mongodb-service created

(msaapp) [centos@k8sel-521149 msaapp]$ kubectl exec pod/mongodb-6f4797467-j5fm4 -it -- bin/sh
# ps -ef 
UID          PID    PPID  C STIME TTY          TIME CMD
mongodb        1       0  0 10:55 ?        00:00:01 mongod --bind_ip_all
root          57       0  0 11:00 pts/0    00:00:00 bin/sh
root          63      57  0 11:00 pts/0    00:00:00 ps -ef

# mongosh
Current Mongosh Log ID:	65b633c384a3da9d5e2cedf7
Connecting to:		mongodb://127.0.0.1:27017/?directConnection=true&serverSelectionTimeoutMS=2000&appName=mongosh+2.1.1
Using MongoDB:		7.0.5
Using Mongosh:		2.1.1

For mongosh info see: https://docs.mongodb.com/mongodb-shell/

To help improve our products, anonymous usage data is collected and sent to MongoDB periodically (https://www.mongodb.com/legal/privacy-policy).
You can opt-out by running the disableTelemetry() command.

------
   The server generated these startup warnings when booting
   2024-01-28T10:55:24.081+00:00: Access control is not enabled for the database. Read and write access to data and configuration is unrestricted
   2024-01-28T10:55:24.081+00:00: vm.max_map_count is too low
------

test> use admin
switched to db admin

admin> db.createUser({ user:'mongo', pwd: 'mongo', roles: ['root'] })
{ ok: 1 }
admin> exit
# exit

(msaapp) [centos@k8sel-521149 msaapp]$ mongosh mongodb://192.168.49.2:31319 -u mongo -p
Enter password: *
Current Mongosh Log ID:	65b6346d31e48df04a7a8f91
Connecting to:		mongodb://<credentials>@192.168.49.2:31319/?directConnection=true&appName=mongosh+2.1.1
Using MongoDB:		7.0.5
Using Mongosh:		2.1.1

For mongosh info see: https://docs.mongodb.com/mongodb-shell/

------
   The server generated these startup warnings when booting
   2024-01-28T10:55:24.081+00:00: Access control is not enabled for the database. Read and write access to data and configuration is unrestricted
   2024-01-28T10:55:24.081+00:00: vm.max_map_count is too low
------

test> exit

# mongosh mongodb://mongodb-service.default.svc.cluster.local:27017 -u mongo -p
Enter password: *
Current Mongosh Log ID:	65b635d1c67e506805e817c6
Connecting to:		mongodb://<credentials>@mongodb-service.default.svc.cluster.local:27017/?directConnection=true&appName=mongosh+2.1.1
Using MongoDB:		7.0.5
Using Mongosh:		2.1.1

For mongosh info see: https://docs.mongodb.com/mongodb-shell/

------
   The server generated these startup warnings when booting
   2024-01-28T10:55:24.081+00:00: Access control is not enabled for the database. Read and write access to data and configuration is unrestricted
   2024-01-28T10:55:24.081+00:00: vm.max_map_count is too low
------

test>
```
<br>
postgres.yaml을 작성한후 k8s에 배포합니다. 

```jsx
(msaapp) [centos@k8sel-521149 msaapp]$ vi postgres.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: postgres-config
data:
  POSTGRES_DB: testdb-postgres
  POSTGRES_USER: postgres
  POSTGRES_PASSWORD: postgres
---
kind: PersistentVolume
apiVersion: v1
metadata:
  name: postgres-pv
spec:
  capacity:
    storage: 1Gi  
  accessModes:
    - ReadWriteOnce
  hostPath:
    path: "/tmp/db"
---
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: postgres-pvc  
spec:
  accessModes:
    - ReadWriteOnce   
  resources:
    requests:
      storage: 1Gi   
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: postgres   
spec:
  replicas: 1
  selector:
    matchLabels:
      app: postgres
  template:
    metadata:
      labels:
        app: postgres
    spec:
      containers:
        - name: postgres
          image: postgres:16
          ports:
            - containerPort: 5432   
          envFrom:
            - configMapRef:
                name: postgres-config
          volumeMounts:
            - name: postgredb
              mountPath: /var/lib/postgresql/data
      volumes:
        - name: postgredb
          persistentVolumeClaim:
            claimName: postgres-pvc
---
apiVersion: v1
kind: Service
metadata:
  name: postgres-service  
spec:
  selector:
    app: postgres
  ports:
    - port: 5432  
  type: ClusterIP

:wq

(msaapp) [centos@k8sel-521149 msaapp]$ kubectl apply -f postgres.yaml 
configmap/postgres-config created
persistentvolume/postgres-pv created
persistentvolumeclaim/postgres-pvc created
deployment.apps/postgres created
service/postgres-service created

(msaapp) [centos@k8sel-521149 msaapp]$ kubectl exec pod/postgres-76fb566885-rdfp2 -it -- /bin/sh
# su - postgres

postgres@postgres-76fb566885-rdfp2:~$ psql
psql (16.1 (Debian 16.1-1.pgdg120+1))
Type "help" for help.

postgres=# create database users;
CREATE DATABASE

postgres=# \c users
You are now connected to database "users" as user "postgres".

users=# CREATE TABLE users
(
        user_id serial primary key,
        user_name VARCHAR(100),
        country VARCHAR(100),
        job VARCHAR(100),
        email VARCHAR(100),
        client_ip VARCHAR(100),
        user_agent VARCHAR(200),
        birth VARCHAR(100),
        last_conn_date timestamp
);
CREATE TABLE

users=# \q

postgres@postgres-76fb566885-rdfp2:~$ psql -h postgres-service.default.svc.cluster.local -U postgres -p 5432
Password for user postgres: 
psql (16.1 (Debian 16.1-1.pgdg120+1))
Type "help" for help.

postgres=# \q
postgres@postgres-76fb566885-rdfp2:~$
```
<br>
user.py 와 movies.py 를 수정하고 dockerimage 를 새로 빌드합니다.

mongodb와 postgres가 k8s에서 서비스-clusterIP를 가지고 있고, 

flask앱은 k8s안에서 서비스명을 통해 DB를 바라보게 구성합니다. (k8s내 DNS가 서비스명으로 endpoint를 제공)

```jsx
(msaapp) [centos@k8sel-521149 msaapp]$ vi movies.py

#mongodb_host_ip = '172.17.0.1'
mongodb_host_ip = 'mongodb-service'
mongodb_user_name = 'mongo'
mongodb_passwd = 'mongo'
mongodb_port = 27017
#mongodb_port = 27018

:wq

(msaapp) [centos@k8sel-521149 msaapp]$ vi users.py

#users_host_ip = '172.17.0.1'
users_host_ip = 'postgres-service'

            #db 접속
            postgres_conn = psycopg2.connect(host=users_host_ip, user=users_user_name, password=users_passwd, database=users_db_name,port=5432)

:wq

(msaapp) [centos@k8sel-521149 msaapp]$ docker build -t movies:v1.0 -f Dockerfile.moviesapp .
[+] Building 23.4s (10/10) FINISHED                                                                                    docker:default
 => [internal] load .dockerignore                                                                                                0.0s
 => => transferring context: 2B                                                                                                  0.0s
 => [internal] load build definition from Dockerfile.moviesapp                                                                   0.0s
 => => transferring dockerfile: 402B                                                                                             0.0s
 => [internal] load metadata for quay.io/centos/centos:stream8                                                                   0.0s
 => [1/5] FROM quay.io/centos/centos:stream8                                                                                     0.0s
 => [internal] load build context                                                                                                0.1s
 => => transferring context: 9.18MB                                                                                              0.1s
 => CACHED [2/5] RUN mkdir /app                                                                                                  0.0s
 => [3/5] COPY movies.py requirements.txt movies.json /app                                                                       0.1s
 => [4/5] WORKDIR /app                                                                                                           0.0s
 => [5/5] RUN dnf install -y python38 &&     dnf clean all &&     pip3 install -r requirements.txt                              22.0s
 => exporting to image                                                                                                           1.1s
 => => exporting layers                                                                                                          1.1s
 => => writing image sha256:51125416096bb856a8235728a80b70cddf0c51ce4bad60290ae8a7855498f2cc                                     0.0s 
 => => naming to docker.io/library/movies:v1.0                                                                                   0.0s 

(msaapp) [centos@k8sel-521149 msaapp]$ docker build -t users:v1.0 -f Dockerfile.userapp .
[+] Building 32.6s (10/10) FINISHED                                                                                    docker:default
 => [internal] load build definition from Dockerfile.userapp                                                                     0.0s
 => => transferring dockerfile: 411B                                                                                             0.0s
 => [internal] load .dockerignore                                                                                                0.0s
 => => transferring context: 2B                                                                                                  0.0s
 => [internal] load metadata for quay.io/centos/centos:stream8                                                                   0.0s
 => [1/5] FROM quay.io/centos/centos:stream8                                                                                     0.0s
 => [internal] load build context                                                                                                0.0s
 => => transferring context: 3.61kB                                                                                              0.0s
 => CACHED [2/5] RUN mkdir /app                                                                                                  0.0s
 => [3/5] COPY users.py requirements.txt /app                                                                                    0.1s
 => [4/5] WORKDIR /app                                                                                                           0.0s
 => [5/5] RUN dnf install -y python38 &&     dnf clean all &&     pip3 install -r requirements.txt                              31.3s
 => exporting to image                                                                                                           1.1s
 => => exporting layers                                                                                                          1.1s
 => => writing image sha256:6ea8c17ad07fd1c71c64f9005a69ca71e3ab9f66c623917bf18a393cd997e87e                                     0.0s 
 => => naming to docker.io/library/users:v1.0                                                                                    0.0s 
```
<br>
k8s에 도커 이미지를 로드합니다. (minikube에 image로 관리)

```jsx
(msaapp) [centos@k8sel-521149 msaapp]$ docker images
REPOSITORY                    TAG       IMAGE ID       CREATED          SIZE                                                          
users                         v1.0      6ea8c17ad07f   27 seconds ago   340MB
movies                        v1.0      51125416096b   43 minutes ago   349MB

(msaapp) [centos@k8sel-521149 msaapp]$ minikube image load movies:v1.0
(msaapp) [centos@k8sel-521149 msaapp]$ minikube image load users:v1.0
```
<br>
샘플 앱을 위한 yaml을 작성합니다.

```jsx
(msaapp) [centos@k8sel-521149 msaapp]$ vi users.yaml
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
  template:
    metadata:
      labels:
        app: users
    spec:
      containers:
      - image: docker.io/library/users:v1.0
        imagePullPolicy: IfNotPresent
        name: users
        ports:
        - containerPort: 5000
          protocol: TCP
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
    app: users

(msaapp) [centos@k8sel-521149 msaapp]$ vi movies.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: movies-deployment
spec:
  selector:
    matchLabels:
      app: movies
      version: v1.0
  replicas: 3
  template:
    metadata:
      labels:
        app: movies
        version: v1.0
    spec:
      containers:
      - name: movies
        image: docker.io/library/movies:v1.0
        imagePullPolicy: IfNotPresent
        ports:
        - name: movies
          containerPort: 5000
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
  name: movies-service
  labels:
    app: movies
spec:
  type: NodePort
  ports:
  - port: 5000
  selector:
    app: movies
```
<br>
리플리카 pod 3개와 서비스를 배포합니다. 

```jsx
(msaapp) [centos@k8sel-521149 msaapp]$ kubectl apply -f users.yaml
deployment.apps/users created
service/users-service created

(msaapp) [centos@k8sel-521149 msaapp]$ kubectl apply -f movies.yaml
deployment.apps/movies created
service/movies-service created

(msaapp) [centos@k8sel-521149 msaapp]$ kubectl get all -A
NAMESPACE     NAME                                   READY   STATUS    RESTARTS      AGE
default       pod/movies-744b4586c4-8xj7r            1/1     Running   0             59s
default       pod/movies-744b4586c4-9gt2s            1/1     Running   0             59s
default       pod/movies-744b4586c4-lm59n            1/1     Running   0             59s
default       pod/users-68468f8bc7-465wb             1/1     Running   0             64s
default       pod/users-68468f8bc7-kcnbx             1/1     Running   0             64s
default       pod/users-68468f8bc7-pc5tm             1/1     Running   0             64s
kube-system   pod/coredns-5dd5756b68-689d4           1/1     Running   3 (19m ago)   21d
kube-system   pod/etcd-minikube                      1/1     Running   3 (19m ago)   21d
kube-system   pod/kube-apiserver-minikube            1/1     Running   3 (19m ago)   21d
kube-system   pod/kube-controller-manager-minikube   1/1     Running   3 (19m ago)   21d
kube-system   pod/kube-proxy-vjfkt                   1/1     Running   3 (19m ago)   21d
kube-system   pod/kube-scheduler-minikube            1/1     Running   3 (19m ago)   21d
kube-system   pod/registry-dgnsv                     1/1     Running   3 (19m ago)   21d
kube-system   pod/registry-proxy-7l9xn               1/1     Running   3 (19m ago)   21d
kube-system   pod/storage-provisioner                1/1     Running   6 (18m ago)   21d

NAMESPACE     NAME                             DESIRED   CURRENT   READY   AGE
kube-system   replicationcontroller/registry   1         1         1       21d

NAMESPACE     NAME                     TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)                  AGE
default       service/kubernetes       ClusterIP   10.96.0.1        <none>        443/TCP                  21d
default       service/movies-service   NodePort    10.104.205.206   <none>        5000:32281/TCP           59s
default       service/users-service    NodePort    10.109.4.217     <none>        5000:31194/TCP           64s
kube-system   service/kube-dns         ClusterIP   10.96.0.10       <none>        53/UDP,53/TCP,9153/TCP   21d
kube-system   service/registry         ClusterIP   10.96.74.176     <none>        80/TCP,443/TCP           21d

NAMESPACE     NAME                            DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR            AGE
kube-system   daemonset.apps/kube-proxy       1         1         1       1            1           kubernetes.io/os=linux   21d
kube-system   daemonset.apps/registry-proxy   1         1         1       1            1           <none>                   21d

NAMESPACE     NAME                      READY   UP-TO-DATE   AVAILABLE   AGE
default       deployment.apps/movies    3/3     3            3           59s
default       deployment.apps/users     3/3     3            3           65s
kube-system   deployment.apps/coredns   1/1     1            1           21d

NAMESPACE     NAME                                 DESIRED   CURRENT   READY   AGE
default       replicaset.apps/movies-744b4586c4    3         3         3       59s
default       replicaset.apps/users-68468f8bc7     3         3         3       64s
kube-system   replicaset.apps/coredns-5dd5756b68   1         1         1       21d

(msaapp) [centos@k8sel-521149 msaapp]$ curl http://192.168.49.2:32281/v1/movies/
"[]"

(msaapp) [centos@k8sel-521149 msaapp]$ curl http://192.168.49.2:32281/v1/movies/hello
"Hello, world!"

(msaapp) [centos@k8sel-521149 msaapp]$ curl -X 'POST'   'http://192.168.49.2:32281/v1/movies/'   -H 'accept: application/json'   -d '' 
"success : inserting data succeeded."

(msaapp) [centos@k8sel-521149 msaapp]$ curl -X 'POST'   'http://192.168.49.2:32281/v1/movies/'   -H 'accept: application/json'   -d '' 
"success : inserting data succeeded."

(msaapp) [centos@k8sel-521149 msaapp]$ curl -X 'POST'   'http://192.168.49.2:32281/v1/movies/'   -H 'accept: application/json'   -d '' 
"success : inserting data succeeded."

(msaapp) [centos@k8sel-521149 msaapp]$ curl -X 'POST'   'http://192.168.49.2:32281/v1/movies/'   -H 'accept: application/json'   -d '' 
"success : inserting data succeeded."

(msaapp) [centos@k8sel-521149 msaapp]$ curl http://192.168.49.2:32281/v1/movies/
"[{\"moviecd\": \"K21967\", \"moviename\": \"도망친 여자\", \"moviedirector\": \"홍상수\", \"publishyear\": \"2019\", \"cat1\": \"사사로운 영화리스트\", \"cat2\": \"2020\"}, {\"moviecd\": \"F02308\", \"moviename\": \"19번째 남자\", \"moviedirector\": \"론 셀턴\", \"publishyear\": \"1988\", \"cat1\": \"미국영화협회 AFI\", \"cat2\": \"AFI's 10 Top 10 (2008)\"}, {\"moviecd\": \"F22873\", \"moviename\": \"푸른 천사\", \"moviedirector\": \"요제프 폰 슈테른베르크\", \"publishyear\": \"1930\", \"cat1\": \"기타\", \"cat2\": \"죽기 전에 꼭 봐야 할 영화 1001 (2019)\"}]"(msaapp) [centos@k8sel-521149 msaapp]$

(msaapp) [centos@k8sel-521149 msaapp]$ curl -X 'POST'   'http://192.168.49.2:31194/v1/user/' -H 'accept: application/json'   -d '' 
{"success": "inserting data succeeded."}

(msaapp) [centos@k8sel-521149 msaapp]$ curl -X 'POST'   'http://192.168.49.2:31194/v1/user/' -H 'accept: application/json'   -d '' 
{"success": "inserting data succeeded."}

(msaapp) [centos@k8sel-521149 msaapp]$ curl -X 'POST'   'http://192.168.49.2:31194/v1/user/' -H 'accept: application/json'   -d '' 
{"success": "inserting data succeeded."}

(msaapp) [centos@k8sel-521149 msaapp]$ curl -X 'POST'   'http://192.168.49.2:31194/v1/user/' -H 'accept: application/json'   -d '' 
{"success": "inserting data succeeded."}

(msaapp) [centos@k8sel-521149 msaapp]$ curl http://192.168.49.2:31194/v1/user/hello
"Hello, world!"

(msaapp) [centos@k8sel-521149 msaapp]$ curl -X 'GET' http://192.168.49.2:31194/v1/user/
[[{"user_id": 4, "user_name": "김성현", "user_agent": "Opera/9.20.(Windows NT 10.0; lt-LT) Presto/2.9.168 Version/11.00", "last_conn_date": "2024-01-28T13:39:48.232142"}], [{"user_id": 3, "user_name": "권성수", "user_agent": "Mozilla/5.0 (Android 11; Mobile; rv:24.0) Gecko/24.0 Firefox/24.0", "last_conn_date": "2024-01-28T13:39:08.934672"}], [{"user_id": 2, "user_name": "이현준", "user_agent": "Mozilla/5.0 (Windows; U; Windows NT 6.0) AppleWebKit/534.27.3 (KHTML, like Gecko) Version/5.0.3 Safari/534.27.3", "last_conn_date": "2024-01-28T13:39:08.210067"}], [{"user_id": 1, "user_name": "엄하은", "user_agent": "Mozilla/5.0 (Windows NT 6.2; om-ET; rv:1.9.0.20) Gecko/5009-09-11 23:10:09.665222 Firefox/3.6.13", "last_conn_date": "2024-01-28T13:39:06.118517"}]](msaapp) [centos@k8sel-521149 msaapp]$
```
