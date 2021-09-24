---
layout: post
title:  "Part 2: Setup a SPA reactjs frontend with hot reloading for development"
tags: reactjs how-tos php symfony docker
description: In this part 2 of this blog series, I will walk you through creating a SPA ReactJS frontend application, in a docker environment - using docker compose - connected to restful backend api using Symfony as a framework, to retrieve a mocking servicer health status, with hot reloading enabled for the ReactJs app. This completes a full stack development environment setup and the aim of it is to be environment agnostic with painless on-boarding for new developers in product teams.
---

Previously, in [part 1]({% link _posts/2021-06-23-part-1-setup-reactjs-symfony-app-with-hotloading.md %}) we went through building a very effective development environment using docker and achieved:

1. Created a dockerized development environment.
2. Created a RESTful microservice using [Symfony](symfony.com)

What we are going to tackle next, is to build a SPA using ReactJS and connect it to the back-end API to display a mocked server health-check status.

## Project Recall

Let's first quickly, recall our `monitoring-app` project, the project folder structure is as follows:

<pre>
    <code class="bash">
monitoring-app/
├── api
│   ├── bin
│   ├── composer.json
│   ├── composer.lock
│   ├── config
│   ├── public
│   ├── src
│   ├── symfony.lock
│   ├── var
│   └── vendor
├── docker
│   ├── nginx
│   └── php
└── docker-compose.yml
    </code>
</pre>
{:.section}

Where the `api` folder contains the Symfony RESTful api and the docker folder contains the docker images needed for the project.

## Getting started

Let's start by creating a ReactJS app.

<pre>
    <code class="bash">
$ npx create-react-app ui
    </code>
</pre>
{:section}

This, as the reactjs [documentation](https://reactjs.org/docs/create-a-new-react-app.html) mentions, creates the bare minimum for a reactjs app, which what we only need for our current tutorial.

### Setting the `docker-compose` service

In order to have this containerized like the backend api, we need to add the below snippet to our `docker-compose.yml` file under the `services:` section.

```yaml
    ui:
      build: ./ui
      restart: on-failure
      # below line starts the project
      command: "npm start"
      depends_on:
        - api
      networks:
        - monitoring
      volumes:
        # this will mount the ui folder which contains the code to the docker container
        - ${PWD}/ui:/var/www/ui:delegated
        # this will mount the node_modules folder for faster performance
        - nodemodules:/var/www/ui/node_modules
      ports:
      - "3000:3000"
```

Another part that is necessary to optimize performance and less disk I/O for the `node_modules` folder, we need to add a `volumes` section at the end of our `docker-compose.yml`.

```yaml
# volumes
volumes:
  nodemodules: {}
```

In the above snippet, it uses a `Dockerfile` image inside the `ui` folder, which builds and runs a `node` container and install all the dependencies inside.
{:.section}

#### Node Dockerfile

This would be placed in `ui/Dockerfile`

**NOTE** The below `Dockerfile` is intended for development purposes only and is not production ready.

<pre>
    <code class="dockerfile">
FROM node:16-alpine3.11

# this is a development Dockerfile
# and is not intended for production use
WORKDIR /var/www/ui

COPY package.json /var/www/ui/
COPY yarn.lock /var/www/ui/
RUN yarn install

COPY . /var/www/ui

# this what make hot reloading works
# because you are starting your project
# in the same way you running it locally
RUN yarn run build
CMD yarn start
    </code>
</pre>

#### Starting up the containers

Now, that you have everything setup, you can now start the containers. you can do that by:

<pre>
    <code class="bash">
$ docker-compose up --build
    </code>
</pre>

It will take some time to build, but you can monitor the progress in your Docker desktop dashboard or your `cli`.
<a href="#" data-bs-toggle="modal" data-bs-target="#hot-reloading-compiling-modal" tabindex="-1" aria-disabled="false" id="hot-reloading-compiling-modal-link">
    <img class="img-thumbnail img-fluid rounded mx-auto d-block" src="{{ "/assets/images/hot-reloading-compiling-docker.gif" | relative_url }}" alt="hot reloading" />
</a>
<!-- Modal -->
<div class="modal fade" id="hot-reloading-compiling-modal" tabindex="-1" aria-labelledby="hot-reloading-compiling-modal-label" aria-hidden="true">
  <div class="modal-dialog modal-xl">
    <div class="modal-content">
      <div class="modal-body">
        <img class="img-thumbnail img-fluid rounded mx-auto d-block" src="{{ "/assets/images/hot-reloading-compiling-docker.gif" | relative_url }}" alt="hot reloading" />
      </div>
    </div>
  </div>
</div>
{:.section}

But eventually you will be able to test it by going to `http://localhost:3000/`, you will see the famous ReactJS start page.

<img class="img-thumbnail img-fluid rounded mx-auto d-block" src="{{ "/assets/images/initial_reactjs_page.png" | relative_url }}" alt="Initial ReactJs page" />
{:.section}

### Let's display the server health check

Now, we have all the containers up and running, we need to connect them, because currently they are not connected and we want to make the ReactJs app make an API call request to pull the server status and display it.
{:.section}

#### Make api request

In your `ui/src/App.js`, modify it to be a class component so that we can make an API call from inside the component.

So, let's modify it to look as below

```js
import './App.css';
import React, { Component } from 'react';

class App extends Component {
    constructor(props) {
        super(props);
        this.state = {healthCheck: "Don't know"}; // initial status
    }

    componentDidMount() {
        // construct the url of the API call
        const url = `${process.env.REACT_APP_API_URL}/healthCheck`;
        fetch(url)
        .then(res => res.json())
        .then(
            (result) => {
                this.setState({
                    healthCheck: result.status
                });
            }
        )
    }

    render() {
        // get the status from the state
        const healthCheck = this.state.healthCheck;

        return (
          <div className="App">
            <header className="App-header">
              Server HealthCheck status: {healthCheck}
            </header>
          </div>
        );
    }
}

export default App;
```
{:.section}

If you go to `http://localhost:3000` you will immediately see the changes you made reflected.

But this doesn't prove hot reloading, so let me demonstrate it in a different way
<a href="#" data-bs-toggle="modal" data-bs-target="#hot-reloading-modal" tabindex="-1" aria-disabled="false" id="hot-reloading-modal-link">
    <img class="img-thumbnail img-fluid rounded mx-auto d-block" src="{{ "/assets/images/hot_reloading.gif" | relative_url }}" alt="hot reloading" />
</a>
<!-- Modal -->
<div class="modal fade" id="hot-reloading-modal" tabindex="-1" aria-labelledby="hot-reloading-modal-label" aria-hidden="true">
  <div class="modal-dialog modal-xl">
    <div class="modal-content">
      <div class="modal-body">
        <img class="img-thumbnail img-fluid rounded mx-auto d-block" src="{{ "/assets/images/hot_reloading.gif" | relative_url }}" alt="hot reloading" />
      </div>
    </div>
  </div>
</div>
{:.section}

### Wrapping up

Now, we came to the end of our [part 2]({% link _posts/2021-09-24-part-2-setup-spa-reactjs-frontend-with-hot-reloading-for-development.md %}) we have everything complete to have a full stack development environment, with hot reloading enabled for our ReactJS SPA.

So, what have we accomplished in this two parts tutorial:

1. Created a very optimized docker development environment.
2. Created a back-end RESTful API using Symfony and FOSRestBundle, to mock retrieving the server health.
3. Created a SPA with ReactJS, and enabled hot reloading.
4. Achieved faster painless on-boarding for new developers in product teams.
5. Environment agnostic development environment setup.
6. As a result of all this, we elevated the team from worrying about maintaining their development environment and enable more productivity on the team.
{:.section}

## Finally

You can find this project setup we created through out the tutorial on [github](https://github.com/mnsami/monitoring-app).

If you have any opinions, questions or shared experiences I would love to hear and discuss them.
