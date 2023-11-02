---
layout: post
title:  "Part 1: Setup a dockerized Symfony backend app with ReactJs for frontend with hotloading enabled"
tags: reactjs how-tos php symfony docker
description: A step-by-step guide on how to setup a dockerized development environment for building backend services using Symfony and a frontend in ReactJS with hotloading enabled. Explore the advantages of using Docker and learn how to overcome common challenges faced during development.
---

As part of my work, I need to build backend services and attach it to frontend, and for this I use docker containers `docker-compose` to make life easier during development.

But I have always faced some problems with that approach, specially with UI frameworks like ReactJs which uses hotloading during development phase.

Previously, I have not been doing it correctly, I was just building the API in a container, then I run `npm start` locally to run the development server and connect to the backend api and have a headacheless development time.

But, finally I have had come to have the time and effort to research and come to the most optimized way to have a better development dockerized environment.
{:.section}

## Why should you use docker?

Docker is the most efficient tool to help you develop your apps in the most predictable way. You can use to avoid unexpected behavior of running your app in different environments setup.

Also, it solve the most biggest problem

<img class="img-thumbnail img-fluid rounded mx-auto d-block" src="{{ "/assets/images/works_on_my_machine.jpeg" | relative_url }}" alt="Works on my machine" width="310" height="235" />
{:.section}

## Requirements for the development environment

When setting up your day-to-day development environment, you are installing plugins, take caring of a lot of noise around your real work. But in my opinion, you shouldn't waste time on all the noise around the task at hand, instead your development environment should be:

1. Easy to setup and run.
2. Environment agnostic.
3. Agile, meaning: you don't need to spend a lot of time to make slightest changes or adjustments.

Also, this comes with a high **business value**, because:

1. It saves on development time, also, it is easier to on-board new comers to your team.
2. Your team doesn't spend too much time fixing cross environment problems or operating system dependencies.
{:.section}

## Getting started

As mentioned, during this blog series, I will describe the process on how to setup a `php` Symfony application with `ReactJs` acting as the frontend with hot-loading (live-loading) enabled for it.

And for this, I will create a backend RESTful api that displays the application healthcheck on the frontend.

So this tutorial will be split into two parts:
1. Part 1: Setup a dockerized Symfony backend app with ReactJs for frontend with hotloading enabled.
2. [Part 2: Setup a SPA reactjs frontend with hot reloading for development]({% link _posts/2021-09-24-part-2-setup-spa-reactjs-frontend-with-hot-reloading-for-development.md %})
{:.section}

### Setting up the project directory

For the ease of use during our tutorial, let's make a directory which will hold both our backend api and frontend app.

<pre>
    <code class="bash">
$ mkdir monitoring-app
    </code>
</pre>
{:section}

### Setting up the backend API

I'm using [Symfony](https://symfony.com) as my `php` framework for the backend api service. So, let's first create a symfony skeleton app.
{:.section}

#### Creating a Symfony application

To create a skeleton of a symfony app run the below command

<pre>
    <code class="bash">
$ composer create-project symfony/skeleton api
    </code>
</pre>

So the folder `monitoring-app` contents would be as below

<pre>
    <code class="bash">
monitoring-app/
├── api
└── docker-compose.yml
    </code>
</pre>
{:.section}

### Setting up a basic `docker-compose`

Second, let's create `docker-compose.yml`, and add the below contents in the file for the API

```yaml
version: "3.7"

services:
  nginx:
    build: docker/nginx
    restart: on-failure
    volumes:
      # this will mount the api folder which contains the code to the docker container
      - ${PWD}/api:/var/www/api:delegated
      # this will mount the nginx logs so that you can check the logs for errors,
      # without logging into the container
      - ${PWD}/var/logs/nginx/:/var/log/nginx:delegated
      # this will create the server config to serve the api
      - ${PWD}/docker/nginx/api.conf:/etc/nginx/conf.d/api.conf:delegated
    ports:
    - "90:80"
    depends_on:
      - api
      - ui
    networks:
      - monitoring

  api:
    build: docker/php
    restart: on-failure
    volumes:
      # this will mount the api folder which contains the code to the docker container
      - ${PWD}/api:/var/www/api:delegated
      # this will mount the custom `.ini` to the container
      - ${PWD}/docker/php/php.ini:/usr/local/etc/php/php.ini:ro
    networks:
      - monitoring

networks:
  monitoring:
    driver: bridge
```

The above will create two docker container services:

1. **nginx**: the webserver to serve your api.
2. **api**: which is running `php-fpm`
{:.section}

#### Your Dockerfiles

In the `docker-compose.yaml`, we used custom docker images to tweak it to our liking.

Below are the contents of the `Dockerfile` and configs for `nginx` and `php`.

##### Nginx Dockerfile and config

This would be placed in `docker/nginx/Dockerfile`

<pre>
    <code class="dockerfile">
FROM nginx:alpine

MAINTAINER Mina Sami <mina.nsami@gmail.com>

RUN apk update \
    && apk add git curl vim wget bash acl

COPY nginx.conf /etc/nginx/
# remove the default domain conf
RUN rm /etc/nginx/conf.d/default.conf

# set right permissions for symfony cache
RUN HTTPDUSER=$(ps axo user,comm | grep -E '[a]pache|[h]ttpd|[_]www|[w]ww-data|[n]ginx' | grep -v root | head -1 | cut -d\  -f1) \
    && setfacl -dR -m u:"$HTTPDUSER":rwX -m u:$(whoami):rwX var \
    && setfacl -R -m u:"$HTTPDUSER":rwX -m u:$(whoami):rwX var
    </code>
</pre>

And in `docker/nginx/nginx.conf`

<pre>
    <code class="nginxconf">
user nginx;
worker_processes 4;
pid /run/nginx.pid;

events {
  worker_connections  2048;
  multi_accept on;
  use epoll;
}

http {
  server_tokens off;
  sendfile on;
  tcp_nopush on;
  tcp_nodelay on;
  keepalive_timeout 15;
  types_hash_max_size 2048;
  include /etc/nginx/mime.types;
  default_type application/octet-stream;
  access_log off;
  error_log on;
  gzip on;
  gzip_disable "msie6";
  include /etc/nginx/conf.d/*.conf;
  include /etc/nginx/sites-enabled/*;
  open_file_cache max=100;
}
    </code>
</pre>

And to define the `api` config to server the symfony project you need to add `docker/nginx/api.conf`

The below config, is copied from the Symfony's documentation.

<pre>
<code class="nginxconf">
server {
    # you can use those domain, if and only if you added them to
    # your local /etc/hosts
    server_name api.local.internal www.api.local.internal;
    root /var/www/api/public;

    location / {
        # try to serve file directly, fallback to index.php
        try_files $uri /index.php$is_args$args;
    }

    # optionally disable falling back to PHP script for the asset directories;
    # nginx will return a 404 error when files are not found instead of passing the
    # request to Symfony (improves performance but Symfony 404 page is not displayed)
    # location /bundles {
    #     try_files $uri =404;
    # }

    location ~ ^/index\.php(/|$) {
        # Here I used the docker service name and port for `php-fpm`
        fastcgi_pass api:9000;
        fastcgi_split_path_info ^(.+\.php)(/.*)$;
        include fastcgi_params;

        # optionally set the value of the environment variables used in the application

        # When you are using symlinks to link the document root to the
        # current version of your application, you should pass the real
        # application path instead of the path to the symlink to PHP
        # FPM.
        # Otherwise, PHP's OPcache may not properly detect changes to
        # your PHP files (see https://github.com/zendtech/ZendOptimizerPlus/issues/126
        # for more information).
        fastcgi_param SCRIPT_FILENAME $realpath_root$fastcgi_script_name;
        fastcgi_param DOCUMENT_ROOT $realpath_root;

        # Prevents URIs that include the front controller. This will 404:
        # http://domain.tld/index.php/some-path
        # Remove the internal directive to allow URIs like this
        internal;
    }

    # return 404 for all other php files not matching the front controller
    # this prevents access to other php files you don't want to be accessible.
    location ~ \.php$ {
        return 404;
    }

    error_log /var/log/nginx/api_error.log;
    access_log /var/log/nginx/api_access.log;
}
</code>
</pre>

##### php-fpm Dockerfile and config

The `php-fpm` `Dockerfile` would be placed in `docker/php/Dockerfile`

<pre>
    <code class="dockerfile">
FROM php:7-fpm-alpine

MAINTAINER Mina Sami <mina.nsami@gmail.com>

RUN apk update \
    && apk add git \
        curl \
        vim \
        wget \
        bash \
        zlib \
        zlib-dev \
        patch \
        icu-dev

# install php dependencies
RUN apk add --no-cache $PHPIZE_DEPS \
    && pecl install -f xdebug \
    && docker-php-ext-install intl opcache bcmath sockets \
    && docker-php-ext-enable xdebug intl opcache bcmath sockets \
    && rm -rf /var/lib/apt/lists/*

# install composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer
RUN composer selfupdate

# Set timezone
ENV TIMEZONE=Etc/UCT
RUN ln -snf /usr/share/zoneinfo/${TIMEZONE} /etc/localtime && echo ${TIMEZONE} > /etc/timezone \
    && printf '[PHP]\ndate.timezone = "%s"\n', ${TIMEZONE} > /usr/local/etc/php/conf.d/tzone.ini \
    && "date"

CMD ["php-fpm", "-F"]

COPY . /var/www/api
WORKDIR /var/www/api

EXPOSE 9000
    </code>
</pre>

And optimize `php` with the following `php.ini` which would be placed in `docker/php/php.ini`

<pre>
    <code class="ini">
date.timezone = ${TIMEZONE}
short_open_tag = Off
log_errors = On
error_reporting = E_ALL
display_errors = Off
error_log = /proc/self/fd/2
memory_limit = -1

; Optimizations for Symfony, as documented on http://symfony.com/doc/current/performance.html
opcache.max_accelerated_files = 20000
realpath_cache_size = 4096K
realpath_cache_ttl = 600
    </code>
</pre>

Now, all the configs and `Dockerfile`s need are created and put in the right place.
{:.section}

#### Starting up the containers

Now, that you have everything setup, you can now start the containers. you can do that by:

<pre>
    <code class="bash">
$ docker-compose up --build
    </code>
</pre>

### Installing Symfony's dependencies

To make the symfony app behave like a RESTful API, we need to install some packages as a dependencies

<pre>
    <code class="bash">
$ docker-compose exec api composer require friendsofsymfony/rest-bundle jms/serializer-bundle symfony/validator
    </code>
</pre>
{:.section}

#### Configuring FOSRestbundle

After installing the `fosrestbundle` you will see that it will place a config file in `api/config/packages/fos_rest.yaml`, but it is an empty file, in order to make work as expected, you can add the following to it

<pre>
    <code class="yaml">
# Read the documentation: https://symfony.com/doc/master/bundles/FOSRestBundle/index.html
fos_rest:
  disable_csrf_role: ROLE_API
  param_fetcher_listener:  true
  body_listener: true
  view:
    view_response_listener:  true
    formats:
      json: true
      html: false
    mime_types:
      json: [ 'application/json', 'application/json;version=1.0', 'application/json;version=1.1', 'application/json;version=1.2' ]
  exception:
    enabled: true
  format_listener:
    enabled: true
    rules:
      - { path: ^/api/v1, prefer_extension: true, fallback_format: json, priorities: [ json ] }
    </code>
</pre>

The above configuration will:

1. Put your restful api behind `https://domain.com/api/v1`
2. Allow `json` format only as default.
3. Disable csrf for API calls.

For further explanation you can check the [FOSRest bundle docs](https://symfony.com/doc/master/bundles/FOSRestBundle/index.){:target="_blank"}
{:.section}

#### Creating the health check controller

In your `src/Controller` folder, create a new `php` file `HealthCheckController.php` which this will be the RESTful controller.

<pre>
    <code class="php">
<?php
declare(strict_types=1);

namespace App\Controller;

use FOS\RestBundle\Controller\AbstractFOSRestController;
use FOS\RestBundle\Controller\Annotations\Get;
use Symfony\Component\HttpFoundation\JsonResponse;

class HealthCheckController extends AbstractFOSRestController
{
    /**
     * A controller action function, defined with the
     * `http` method `GET` to retrieve the server
     * health status.
     *
     * @Get("/healthCheck", name="get_health_check")
     */
    public function getHealthCheck()
    {
        return new JsonResponse([
            'status' => "I'm alive",
            'code' => 'ok'
        ]);
    }
}
    </code>
</pre>

To make your controllers Restful you need them to extend `AbstractFOSRestController`.

Then, the next thing is to create an action function to show the get and respond the health check of the server, using the `FOSRestBundle` annotations to define the route for it.

Now, we are one step closer to finishing our first RESTful `api` call to retrieve the server status.
{:.section}

#### Tunning the routes definition

In the `fos_rest.yaml` we configured the api routes to be prefixed with `/api/v1` url path, that means that all the `api` routes will lay under this url path, but in order for this config to complete and take effect, we need one more step to be done.

If you go and look into `api/config/routes/annotations.yaml` file, its content will be

<pre>
    <code class="yaml">
controllers:
    resource: ../../src/Controller/
    type: annotation

kernel:
    resource: ../../src/Kernel.php
    type: annotation
    </code>
</pre>

In order to make all the controller routes prefixed with the path configured in the `fos_rest.yaml` file, all you need to do is add the line to file so that it looks like ths

<pre>
    <code class="yaml">
controllers:
    prefix: /api/v1
    resource: ../../src/Controller/
    type: annotation

kernel:
    resource: ../../src/Kernel.php
    type: annotation
    </code>
</pre>

Now, if you run

<pre>
    <code class="bash">
$ docker-compose exec api php bin/console debug:router
    </code>
</pre>

The output will be like this

<pre>
    <code class="bash">
------------------ -------- -------- ------ --------------------------
 Name               Method   Scheme   Host   Path
------------------ -------- -------- ------ --------------------------
 get_health_check   GET      ANY      ANY    /api/v1/healthCheck
 _preview_error     ANY      ANY      ANY    /_error/{code}.{_format}
------------------ -------- -------- ------ --------------------------
    </code>
</pre>
{:.section}

### Testing your api call

So, after we have setup everything for our api to work, let's test it.

If you go to your browser the type `http://localhost:90/api/v1/healthCheck` you will get the following response.

<img class="img-thumbnail img-fluid rounded mx-auto d-block" src="{{ "/assets/images/i_am_alive.png" | relative_url }}" alt="I am alive" width="399" height="134" />
{:.section}

### Wrapping up

So, we have come to an end of this tutorial, where we so far accomplished the following:

1. Created a RESTful Symfony api, using the skeleton of Symfony and FOSRestBundle.
2. Created a development using `docker`.
3. Created our first API endpoint to retrieve the server health check.
4. Achieved faster on-boarding for new developers in product teams.
5. Help developers focus more on the user stories, rather than worry about a stable development environment.
{:.section}

### What is next ?

In the next blog of this series, I will create simple reactjs frontend to consume and API, and make it work with hot-loading.
{:.section}
