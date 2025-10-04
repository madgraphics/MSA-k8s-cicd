import logging, json
from pymongo import MongoClient
from flask import Flask, Response
from flask_restx import Api, Resource 
from faker import Faker
from faker_datasets import Provider, add_dataset

app = Flask(__name__)
api = Api(app, version='1.0', title='영화 관리 API', description='영화 등록,조회 API입니다') 
api = api.namespace('v1/movies', description='영화 등록, 조회') 
logger = logging.getLogger()
logger.setLevel(logging.INFO)

@add_dataset("movies", "movies.json", picker="movie")
class Movies(Provider):
    pass

fake = Faker()
fake.add_provider(Movies)

mongodb_host_ip = '127.0.0.1'
mongodb_user_name = 'mongo'
mongodb_passwd = 'mongo'
mongodb_port = 27017

@api.route('/')  
class movie(Resource):
    def post(self):
        try:
            movie = fake.movie()
            movie_data ={
                'moviecd': '{mov_cd}'.format(movie),
                'moviename': '{mov_nm}'.format(movie),
                'moviedirector': '{mov_dir}'.format(movie),
                'publishyear': '{pbl_year}'.format(movie),
                'cat1': '{cat1}'.format(movie),
                'cat2': '{cat2}'.format(movie),
                'moviedesc': '{mov_desc}'.format(movie)
            }
            mongodb_conn = MongoClient(mongodb_host_ip, mongodb_port, username=mongodb_user_name, password=mongodb_passwd)
            mongo_collection = mongodb_conn.test.movies
            mongo_collection.insert_one(movie_data)
        except Exception as e:
            logger.error("db error : could not insert data")
            logger.error(e)
        return Response(json.dumps("success : inserting data succeeded."), status=200, content_type='application/json; charset=utf-8')

    def get(self):
        try:
            mongodb_conn = MongoClient(mongodb_host_ip, mongodb_port, username=mongodb_user_name, password=mongodb_passwd)
            mongo_collection = mongodb_conn.test.movies
            mongo_objects = mongo_collection.find({},{'_id': 0, 'moviedesc':0}).sort("_id",-1).limit(3)
            mongo_result = str(json.dumps(list(mongo_objects), ensure_ascii=False, default=str))
        except Exception as e:
            logger.error("mongo db error : could not fetch data")
            logger.error(e)
        return Response(json.dumps(mongo_result, ensure_ascii=False).encode('utf-8'), status=200, content_type='application/json; charset=utf-8')

@api.route('/hello')  
class hello(Resource):
    def get(self):
        return "Hello, world!", 200, { "success" : "hello" } 

if __name__ == "__main__":
    app.debug = True
    app.run(host="0.0.0.0", port=int("5000"))
