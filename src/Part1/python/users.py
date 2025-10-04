import logging, psycopg2, json
from datetime import datetime
from flask import Flask, Response
from flask_restx import Api, Resource 
from faker import Faker

app = Flask(__name__)
app.config['JSON_AS_ASCII'] = False
api = Api(app, version='1.0', title='사용자 관리 API', description='사용자 등록,조회 API입니다') 
api = api.namespace('v1/user', description='사용자 등록, 조회') 

logger = logging.getLogger()
logger.setLevel(logging.INFO)
fake = Faker("ko_KR")

users_host_ip = '127.0.0.1'
users_db_name = 'users'
users_user_name = 'postgres'
users_passwd = 'postgres'

@api.route('/')  
class user(Resource):
    def post(self):
        try:
            postgres_conn = psycopg2.connect(host=users_host_ip, user=users_user_name, password=users_passwd, database=users_db_name)
            postgres_sql = "insert into users (user_name,job,client_ip,user_agent,birth,last_conn_date) select %s,%s,%s,%s,%s,current_timestamp"
            postgres_sql_val = (fake.name(),fake.job(),fake.ipv4_private(),fake.user_agent(),fake.date_of_birth())
            postgres_conn.cursor().execute(postgres_sql,postgres_sql_val)
            postgres_conn.commit()
            postgres_conn.close()
        except Exception as e:
            logger.error("db error : could not insert data")
            logger.error(e)
        return { "success" : "inserting data succeeded." }

    def get(self):
        try:
            postgres_conn = psycopg2.connect(host=users_host_ip, user=users_user_name, password=users_passwd, database=users_db_name)
            postgres_sql = "select row_to_json(users) from (select user_id,user_name,user_agent,last_conn_date from users)users order by last_conn_date desc limit 10"
            postgres_cursor = postgres_conn.cursor()
            postgres_cursor.execute(postgres_sql)
            postgres_results = postgres_cursor.fetchall()
            postgres_conn.close()
        except Exception as e:
            logger.error("db error : could not fetch data")
            logger.error(e)
        return Response(json.dumps(postgres_results, ensure_ascii=False).encode('utf-8'), status=200, content_type='application/json; charset=utf-8')

@api.route('/hello')  
class hello(Resource):
    def get(self):
        return "Hello, world!", 200, { "success" : "hello" } 

if __name__ == "__main__":
    app.debug = True
    app.run(host="0.0.0.0", port=int("5000"))
