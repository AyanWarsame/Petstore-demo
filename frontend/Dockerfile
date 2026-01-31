FROM nginx:stable-alpine

# Remove default nginx content and copy app
RUN rm -rf /usr/share/nginx/html/*
COPY . /usr/share/nginx/html/

# Default Nginx config will be provided by ConfigMap in k8s or overridden here
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
