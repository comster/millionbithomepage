FROM node:12-buster

ARG NODE_ENV
ENV NODE_ENV $NODE_ENV

ARG TZ=UTC
ENV TZ $TZ

RUN apt-get update

RUN apt-get install -y build-essential libcairo2-dev libpango1.0-dev libjpeg-dev libgif-dev librsvg2-dev libjpeg62-turbo-dev g++ python3-pip curl groff less jq

RUN pip3 install awscli --upgrade

RUN aws --version

WORKDIR /usr/src/app

COPY . /usr/src/app

RUN npm install .
