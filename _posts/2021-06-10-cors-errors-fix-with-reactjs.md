---
layout: post
title:  "Dealing with CORS Errors in React two ways"
tags: reactjs nginx cors how-tos
description: "Fix CORS errors in React.js applications. Understanding CORS policy, configuring headers, and resolving cross-origin issues."
---

{:.section}
It is always a problem when working with `reactjs` or any other frontend js framework in local development specially when connected to a backend api, is that you get `No 'Access-Control-Allow-Origin' header is present on the requested resource.` and you go crazy about the cause of the issue.

### You have committed a CORS foul against security policy

The problem rise when you are making requests to your backend api then you see in your browser an error similar to the one below as a response to your API call.

As explained on the [mozilla](https://developer.mozilla.org/en-US/docs/Web/HTTP/CORS), where you can also understand the concept better.

> An example of a cross-origin request: the front-end JavaScript code served from
> https://example.com uses XMLHttpRequest to make a request for https://api.example.com/v1.

which results instantly with the below error in your browser console

<pre>
    <code class="javascript">
        Access to XMLHttpRequest at 'http://api.example.com/v1/' from
        origin 'http://example.com' has been blocked by CORS policy: Response to preflight
        request doesn't pass access control check: No 'Access-Control-Allow-Origin'
        header is present on the requested resource.
    </code>
</pre>


And the reason for the above error might because you are accessing your backend api from:
{:.section}

#### <i class="bi bi-bug"></i> Locally served file

So, you just opened a HTML file in your browser with `file:///path/to/file/index.html` and this file has script to access your backend api `http://api.endpoint.internal/api`.
{:.section}

#### <i class="bi bi-bug"></i> Accessing the api on different domain

If your frontend is served on a different domain than from what your backend api is served from i.e.

<pre>
    <code class="shell">
        http://frontend.domain.com # frontend
        http://api.domain.com/v1/ # backend

        http://localhost:3000 # frontend
        http://localhost # backend running on a different port
    </code>
</pre>
{:.section}

#### <i class="bi bi-bug"></i> Different `http` schema

If you running your frontend on `https` and your backend is on `http` or vice versa.

All the above reasons doesn't mean that `ReactJS` sucks at making api requests, it means that a web application using those APIs can only request resources from the same origin the application was loaded from unless the response from other origins includes the right CORS headers.
{:.section}

## But how can we move on with development ?

If you are facing this issue during your local development, then you have two types of solutions.
{:.section}

#### ReactJS solution

Recently the `create-react-app` introduce a very nice feature to proxying API requests in development.

Where the only thing you have to do is add the below line in your project's `package.json`

    "proxy": "http://api.endpoint.com/v1"

where it tells the development server to proxy any unknown requests to your API server in development.

**NOTE** This only works for local development.
{:.section}

#### Webserver (NGINX) solution - Preferred

Alternatively, there is a solution that can be done on the webserver side, but it requires - as it implies - changes on the webserver.

The solution is to add headers to allow cross origin requests and respond with the right headers, so that the frontend gets the right response.

I will tell you more about the `nginx` solution and how to do it.

You can place the below snippet in your `nginx` config of the enabled website of your api.

<pre>
    <code class="nginxconf">
    location / {
        # below is the line that will tell the api to allow requests from different domains
        add_header 'Access-Control-Allow-Origin' '$http_origin' always;
        add_header 'Access-Control-Allow-Methods' 'GET, POST, OPTIONS';
        add_header 'Access-Control-Allow-Headers' 'DNT,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Range';
        add_header 'Access-Control-Expose-Headers' 'Content-Length,Content-Range';

        if ($request_method = 'OPTIONS') {
            add_header 'Access-Control-Max-Age' 1728000;
            add_header 'Content-Type' 'text/plain; charset=utf-8';
            add_header 'Content-Length' 0;
            return 204;
        }
    }
    </code>
</pre>

As you can see this add the right headers in the response so that it doesn't respond with CORS error.
{:.section}

##### What about if you are using different web servers ?

I would highly recommend that you go to this awesome website [enable-cors](https://enable-cors.org) which helps you configure your webserver for the `Access-Control-Allow-Origin` headers.

But be careful, as these configurations are widely open, so make sure to customize them according to your likely to not cause any security measures on your webserver.
{:.section}
