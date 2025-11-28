---
layout: post
title:  "How to make use of Makefile to shorthand long commands"
categories: [devops]
tags: makefile docker automation build-tools workflow ci-cd
description: "Learn how to use Makefiles to automate development workflows. Practical examples for PHP, Node.js, and Docker projects."
---

I like automation and none repetitive tasks, also, I don't like to write too much when it comes to handling with `cli` commands. And, since I work much with `docker` in my projects (whether [building SPAs with React and Symfony]({{ site.baseurl }}{% post_url 2021-06-23-part-1-setup-reactjs-symfony-app-with-hotloading %}) or backend APIs), I spend extra time writing and thinking about the command I would like to run inside my container, so, let's say I would like to run a simple `composer install` so this will result in typing

<pre>
    <code class="bash">
# where `api` is the docker service name
$ docker-compose exec api composer install
    </code>
</pre>

But, by the end of this article you will be able to run in just two words, also with the support of autocomplete.

<pre>
    <code class="bash">
# where `api` is the docker service name
$ make composer-install
    </code>
</pre>

I picked up the habit of making use of `make` files for my projects, when I used to work at [leaseweb](https://leaseweb.com){:target="_blank"}, that it was of a great use, and I continued using it and extended the use of it with some extra logic.
{:.section}

*This article is not intended to be dedicated for `php` and `symfony` projects only, but those are used as an example only*
{:.section .h6}

## How does it work ?

Let's try it out together, you don't need to install anything extra on your `mac` or `linux`, it should work out of the box in you `bash` or `zsh` terminal.

Also, let's set a base ground for this how-to, and assume that:

1. We have a symfony `php` project connected to a `mysql` db running on `nginx` and `php-fpm`.
2. All of these are running in `docker` containers as services.
3. `docker` is used only in development and not in production.

So, your project's `docker-compose.yml` file looks like below

<pre>
    <code class="yaml">
version: "3.7"

services:
  db:
    image: mysql:8
    env_file:
      - .docker.mysql.env
    restart: always
    volumes:
      - dbdata:/var/lib/mysql
    ports:
      - 3307:3306
    networks:
      - backend

  nginx:
    build: docker/nginx
    restart: on-failure
    ports:
      - "8080:80"
    volumes:
      - ./:/var/www/api:delegated
      - ./var/logs/nginx/:/var/log/nginx:delegated
      - ./docker/nginx/api.conf:/etc/nginx/conf.d/default.conf:delegated
    depends_on:
      - db
      - api
    networks:
      - backend

  api:
    build: docker/php
    restart: on-failure
    depends_on:
      - db
    volumes:
      - ./:/var/www/api:delegated
      - ./docker/php/php.ini:/usr/local/etc/php/php.ini:ro
    networks:
      - backend

# volumes
volumes:
  dbdata:
    driver: local

networks:
  backend:
    </code>
</pre>

### 1. Create an empty `Makefile`

In your project root folder, create a `Makefile`

**Note** all `Makefile` has to be named `Makefile`, otherwise they will not work, don't try to rename the file to something else, otherwise it will not work.

<pre>
    <code class="bash">
$ touch Makefile
    </code>
</pre>

this will create a file on your hard disk inside the project root folder with the name `Makefile`, now let's start adding some commands in the next step.
{:.section}

### 2. Let's add the below lines

<pre>
    <code class="makefile">
# In order to help running the project with less intervention and dynamically,
# setting some variables to be used inside the makefile,
# some of them are to prefix commands specially for commands to be run inside a container

DOCKER_COMPOSE = docker-compose
PROJECT = "Monitoring API."
COMPOSER ?= composer
PHP_CMD = php

# The php service defined in the docker-compose.yml
PHP_SERVICE = api

# the below line make sure the service name are prefixed with the folder name
COMPOSE_PROJECT_NAME ?= $(notdir $(shell pwd))

# Here the command is determined based on the environment
# I'm not using docker in production
ifeq ($(APP_ENV), prod)
	CMD :=
else
	CMD := docker-compose exec $(PHP_SERVICE)
endif

# If you type make in your cli, it will list all the available commands.
help:
	@ echo "Usage: make \<target\>\n"
	@ echo "Available targets:\n"
	@ cat Makefile | grep -oE "^[^: ]+:" | grep -oE "[^:]+" | grep -Ev "help|default|.PHONY"

# This will stop all containers services
container-stop:
	@echo "\n==> Stopping docker container"
	$(DOCKER_COMPOSE) stop

# This will remove all containers services
container-down:
	@echo "\n==> Removing docker container"
	$(DOCKER_COMPOSE) down

# Start the containers and build them every time this commands is called
container-up:
	@echo "\n==> Docker container building and starting ..."
	$(DOCKER_COMPOSE) up --build -d

# This is a shortcut command to stop and remove containers
tear-down: container-stop container-down
    </code>
</pre>

As you can see above, we have built a basic `makefile` to run `docker-compose` commands without typing much.

Now, if you want to run any of the above commands, just prefix it with `make`

<pre>
    <code class="bash">
$ make container-up
    </code>
</pre>

### 3. Let's make things complex little bit

Let's make our project's `makefile` more advanced and add some `make` commands to:

1. install composer dependencies
2. Lint your project files.
3. Check your project files if they follow the correct coding standards

and in order to do this add the below lines at the end of your `Makefile` you just created.

<pre>
    <code class="makefile">
# This will run inside the api container to install all composer dependencies.
composer-install:
	@echo "\n==> Running composer install, runner $(RUNNER)"
	$(CMD) $(COMPOSER) install

# This will run tests
tests:
	@echo "\n==> Running tests"
	$(CMD) bin/phpunit

# This will run coverage
coverage:
	@echo "\n==> Generating coverage report"
	$(CMD) bin/phpunit --coverage-html coverage

# This will lint all your project
lint: lint-json lint-yaml lint-php phpcs lint-composer lint-eol
	@echo All good.

# This will validate line endings of your file
lint-eol:
	@echo "\n==> Validating unix style line endings of files:"
	@! grep -lIUr --color '^M' app/ web/ src/ composer.* || ( echo '[ERROR] Above files have CRLF line endings' && exit 1 )
	@echo All files have valid line endings

# This will lint your composer.json and composer.lock
lint-composer:
	@echo "\n==> Validating composer.json and composer.lock:"
	$(CMD) $(COMPOSER) validate --strict

# This will lint your *.json* files if any, in the `src` folder
lint-json:
	@echo "\n==> Validating all json files:"
	@find src -type f -name \*.json -o -name \*.schema | php -R 'echo "$$argn\t\t";json_decode(file_get_contents($$argn));if(json_last_error()!==0){echo "<-- invalid\n";exit(1);}else{echo "\n";}'

# This will lint your *.yml* files if any, in the `src` and `app/config` folders
lint-yaml:
	@echo "\n==> Validating all yaml files:"
	@find app/config src -type f -name \*.yml | while read file; do echo -n "$$file"; $(CMD) php bin/console --no-debug --no-interaction --env=test lint:yaml "$$file" || exit 1; done

# This will lint your *.php* files in the `src` folder
lint-php:
	@echo "\n==> Validating all php files:"
	$(CMD) find src -type f -iname '*php' -exec $(PHP_CMD) -l {} \;

# If you have defined `phpcs.xml` and installed 
# the dependant package (https://github.com/squizlabs/PHP_CodeSniffer)
# you can make use of the below command to check if your code has styling errors
phpcs:
	@echo "\n==> Checking php styles"
	$(CMD) vendor/bin/phpcs --standard=phpcs.xml -p

# This will fix all your styling standard issues
phpcbf:
	@echo "\n==> Fixing styling errors"
	$(CMD) vendor/bin/phpcbf
    </code>
</pre>

### 4. Let's handle database

Now, in our project we are working with databases, so we need to shortcut some Symfony doctrine ORM commands to interact with our databases. While we're automating database workflows, you might also want to check out my guide on [building production-ready database backup systems]({{ site.baseurl }}{% post_url 2025-11-10-periodically-run-database-backup %}) for automating backups with bash scripts and cron jobs. Below we are going to append some useful `make` commands, which I consider the most used commands during development.

You can adjust them to your liking.

<pre>
    <code class="makefile">
# These commands are very project specific

# Create your database
orm-database-create:
	@echo "\n==> Creating database"
	$(CMD) php bin/console doctrine:database:create

# Drop your database
orm-database-drop:
	@echo "\n==> Dropping database"
	$(CMD) php bin/console doctrine:database:drop --force

# Create your database schema
orm-schema-create:
	@echo "\n==> Creating schema"
	$(CMD) php bin/console doctrine:schema:create

# Drop your database schema
orm-schema-drop:
	@echo "\n==> Dropping schema"
	$(CMD) php bin/console doctrine:schema:drop --force

# Generate database migration based on the difference
# between your existing schema and mapping files
orm-migrations-generate-diff:
	@echo "\n==> Generating migration diff"
	$(CMD) php bin/console doctrine:migrations:diff

# Migrate your database to the next version
orm-migrations-migrate:
	@echo "\n==> Executing migration"
	$(CMD) php bin/console doctrine:migrations:migrate
    </code>
</pre>

### Advantages

1. Time saver if your run any of the above commands many times during development.
2. You don't have to `ssh` to the container just to run commands.
3. Abstracts commands
4. It can be environment agnostic, by using environment variables.
5. It can be used easily in your CI/CD pipelines.
6. You can create `Makefile` templates for every project type you most work with, then it works out of the box, as you don't have to repeat your self.

### Disadvantages

1. You spend some time in the beginning of your project to setup your `Makefile`.
2. It can get complex, if you increase the amount of logic inside your `Makefile`, and you start to get the feeling your programming in `make`.

## Conclusion

As you can, you can go nuts with your `makefile` and make adapt whatever command you like, and make it easier to run commands inside your `docker` container.

But this doesn't mean you can get ride of running `docker-compose exec api bash` to switch to the `terminal` of the container, the above is intended to save time and effort in writing too much in the cli.

You can also, make use of `makefile` in any of the projects you are working on, I use it for my frontend projects as well. Combined with [other productivity tools and automation workflows]({{ site.baseurl }}{% post_url 2020-06-22-syncing-vs-code-extensions-and-settings %}), Makefiles can significantly boost your development efficiency.

## References

If you would like to learn more about `Makefile` and how to use/extend them, you will easily find a lot of resources on the internet. But, I recently stepped on a very handy website called [MakefileTutorial](https://makefiletutorial.com/){:target="_blank"}, which has a lot of examples on how to write extensive `Makefile` with examples as well.
