FROM node:dubnium-alpine
LABEL Author=mpneuried

RUN apk add --update make gcc g++ python git curl

RUN mkdir /app
WORKDIR /app

COPY package.json ./
COPY package-lock.json ./
COPY Gruntfile.coffee ./
RUN npm install

COPY _src/ ./_src

RUN npm run build

CMD [ "npm", "run", "test" ]
