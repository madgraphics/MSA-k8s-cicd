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
