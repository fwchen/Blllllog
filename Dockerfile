FROM node:latest as build
COPY package.json pacakge-lock.json ./
RUN npm install
COPY . ./
RUN ./node_modules/.bin/starfish render .

FROM nginx:1.13.3-alpine
COPY nginx.conf /etc/nginx/conf.d/default.conf
RUN rm -rf /usr/share/nginx/html
COPY --from=build blog-static /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]