FROM node:14

WORKDIR /app

COPY src/package.json ./

RUN npm install

COPY src/app.js ./

# RUN npm run build

EXPOSE 3000

CMD ["npm", "start"]