FROM node:14

WORKDIR /app

COPY src/package.json ./

RUN npm install

COPY src/app.js ./

# RUN npm run build

EXPOSE 6263

CMD ["npm", "start"]