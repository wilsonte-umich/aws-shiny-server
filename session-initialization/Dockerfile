# small footprint JS node image
FROM node:18.2-alpine3.14

# install express
ENV SERVICE_DIR /opt/node
WORKDIR $SERVICE_DIR
RUN npm install express

# expose the port we listen to on the Docker network
EXPOSE 8080

# copy app static files
COPY session-initialization.js $SERVICE_DIR

# start the app server as a persistent process
CMD ["node", "session-initialization.js"]
