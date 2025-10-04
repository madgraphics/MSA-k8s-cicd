# ---- 유저 생성 및 Docker 설치 ----
sudo su -
useradd centos
usermod -aG wheel centos
passwd centos
sudo su - centos

sudo dnf config-manager --add-repo=https://download.docker.com/linux/centos/docker-ce.repo
sudo dnf install -y docker-ce
sudo systemctl enable docker.service
sudo systemctl start docker.service

sudo usermod -aG docker centos
sudo systemctl restart docker
exit
sudo su - centos
docker ps

# ---- GUI + VNC 설치 ----
sudo dnf -y update
sudo dnf groupinstall -y "Server with GUI" --skip-broken
sudo systemctl set-default graphical
sudo dnf install -y tigervnc-server
vncpasswd
vncserver

netstat -tunlp
sudo firewall-cmd --permanent --zone=public --add-port=5901/tcp
sudo firewall-cmd --reload

# ---- PostgreSQL 16 설치 ----
sudo dnf install -y https://download.postgresql.org/pub/repos/yum/reporpms/EL-8-x86_64/pgdg-redhat-repo-latest.noarch.rpm
sudo dnf -qy module disable postgresql
sudo dnf install -y postgresql16-server
sudo /usr/pgsql-16/bin/postgresql-16-setup initdb
sudo systemctl enable postgresql-16
sudo systemctl start postgresql-16

sudo su - postgres
psql
alter user postgres with password 'postgres';
\q

# ---- MongoDB 7 설치 ----
cat <<EOF | sudo tee /etc/yum.repos.d/mongodb-org-7.0.repo
[mongodb-org-7.0]
name=MongoDB Repository
baseurl=https://repo.mongodb.org/yum/redhat/8/mongodb-org/7.0/x86_64/
gpgcheck=1
enabled=1
gpgkey=https://www.mongodb.org/static/pgp/server-7.0.asc
EOF

sudo dnf install -y mongodb-org
sudo systemctl enable mongod
sudo systemctl start mongod

# ---- Python & Virtual Env ----
sudo yum install -y python38
python3.8 -V
python3.8 -m venv msaapp
source ~/msaapp/bin/activate
pip install --upgrade pip
pip install flask flask-restx faker-datasets pymongo psycopg2-binary

# ---- PostgreSQL DB 생성 ----
psql -U postgres -p 5432 -h 127.0.0.1
create database users;
\c users
\i users.sql
\q

# ---- MongoDB 유저 생성 ----
mongosh
use admin
db.createUser({ user:'mongo', pwd: 'mongo', roles: ['root'] })
exit

mongosh mongodb://127.0.0.1:27017 -u mongo -p
