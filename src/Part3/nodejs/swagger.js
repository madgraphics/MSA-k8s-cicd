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
