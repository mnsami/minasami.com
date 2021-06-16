---
layout: post
title:  "Part 1: Setup a dockerized Symfony backend app with ReactJs for frontend with hotloading enabled"
tags: reactjs tips-tricks docker
description: It is always a problem when working with reactjs or any other frontend js framework in local development specially when connected to a backend api, is that you get No Access-Control-Allow-Origin header is present on the requested resource. and you go crazy about the cause of the issue.
---

As part of my work, I need to build backend services and attach it to frontend, and for this I use docker containers `docker-compose` to make life easier during development.

But I have always faced some problems with that approach, specially with UI frameworks like ReactJs which uses hotloading during development phase.

Previously, I have not been doing it correctly, I was just building the API in a container, then I run `npm start` locally to run the development server and connect to the backend api and have a headacheless development time.

But, finally I have had come to have the time and effort to research and come to the most optimized way to have a better development dockerized environment.
{:.section}

## Why should you use docker?

Docker is the most efficient tool to help you develop your apps in the most predictable way. You can use to avoid unexpected behavior of running your app in different environments setup.

Also, it solve the most biggest problem

<img class="img-thumbnail img-fluid rounded mx-auto d-block" src="{{ "/assets/images/works_on_my_machine.jpeg" | relative_url }}" alt="Works on my machine">
{:.section}

## Requirements of a development environment

When setting up your day-to-day development environment, you are installing plugins, take caring of a lot of noise around your real work. But in my opinion, you should take of it in a way to make it:

1. Easy to setup and run.
2. Environment agnostic
3. Agile, meaning: you don't need to spend a lot of time to make slightest changes or adjustments.

Also, this comes with a high **business value**, because it saves on development time, also, it is easier to on-board new comers to your team.
{:.section}

## Getting started

As mentioned during this blog series, I will describe the process on how to setup a `php` Symfony application with `ReactJs` acting as the frontend with hot-loading (live-loading) enabled for it.

And for this, I will create a backend RESTful api that displays the application healthcheck on the frontend.
{:.section}

### Setting up the project directory

For the ease of use during our tutorial, let's make a directory which will hold both our backend api and frontend app.

<pre>
    <code class="bash">
$ mkdir monitoring-app
    </code>
</pre>
{:section}

### Setting up a basic `docker-compose`

First, let's create `docker-compose.yml`, and add the below contents in the file for the API

```yaml
version: "3.7"

services:
  nginx:
    build: docker/nginx
    restart: on-failure
    volumes:
      - ${PWD}/monitoring-api:/var/www/api:delegated
      - ${PWD}/var/logs/nginx/:/var/log/nginx:delegated
      - ${PWD}/docker/nginx/monitoring-api.conf:/etc/nginx/conf.d/monitoring-api.conf:delegated
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
      - ${PWD}/monitoring-api:/var/www/api:delegated
      - ${PWD}/docker/php/php.ini:/usr/local/etc/php/php.ini:ro
    networks:
      - monitoring

networks:
  monitoring:
    driver: bridge
```

{:.section}

### Setting up the backend API

I'm using [Symfony](https://symfony.com) a my `php` framework for the backend api service.
{:.section}

#### Creating a Symfony application

To create a skeleton of a symfony app run the below command

<pre>
    <code class="shell">
$ composer create-project symfony/skeleton api
    </code>
</pre>

So the folder `monitoring-app` contents would be as below

<pre>
    <code class="shell">
monitoring-app/
├── api
└── docker-compose.yml
    </code>
</pre>
{:.section}

#### Installing Symfony's dependencies

To make the symfony app behave like a RESTful API, we need to install some packages as a dependencies

<pre>
    <code class="shell">
$ composer install friendsofsymfony/rest-bundle jms/serializer-bundle symfony/validator
    </code>
</pre>
{:.section}
