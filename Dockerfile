FROM node:12.20.2-alpine3.10 as build
COPY package.json package-lock.json ./
RUN npm install
COPY . ./
RUN ./node_modules/.bin/starfish render $(pwd) --output="blog-static"
RUN ./node_modules/.bin/starfish angular-ssr $(pwd)

FROM nginx:1.19.6-alpine
COPY nginx.conf /etc/nginx/conf.d/default.conf
RUN rm -rf /usr/share/nginx/html
COPY --from=build blog-static /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]