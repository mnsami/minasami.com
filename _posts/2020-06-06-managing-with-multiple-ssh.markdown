---
layout: post
title:  "Managing multiple ssh keys"
tags: ssh git
description: Managing multiple ssh keys, Usually when joining a new work place you are asked to provide your public `ssh` key to get access to all the private organization repositories. And after sometime, I came to the conclusion that I want to separate between work and personal `ssh` keys, and I want to achieve that in an easy, hassle free way from the same computer.
---

Usually when joining a new work place you are asked to provide your public `ssh` key to get access to all the private organization repositories.
And after sometime, I came to the conclusion that I want to separate between work and personal `ssh` keys, and I want to achieve that in an easy, hassle free way from the same computer.
{:.section}

#### Why do I want manage multiple `ssh` keys?

The answer is simple, I want one `SSH` key-pair for work related matters (i.e. code base, servers .. etc) and a different key-pair for my own personal matters. In that sense, I am not mixing up things - which I don't like having - and I don't want my work `ssh` fingerprint to be in my personal projects. So, the separation between the two became a higher need for me.

Also, I want to be mind free that when I decide to change my work place, on my last day, all I have to do is to just delete my work `ssh` key or it gets forgotten when my work laptop is wiped, then automatically I'm out of all the company's systems.

So, again the urge got higher to create another `ssh` key to be used for work place.
{:.section}

##### Assumption

I assume you have knowledge using `git`, `ssh` and you know your way around your OS terminal.
{:.section}

#### How will I do it?

##### 1. You need to create another separate `ssh` key, and you can do that simple by running

<pre>
    <code class="console">
$ ssh-keygen -t rsa -b 4096 -C "your_email@example.com"
    </code>
</pre>
and this will guide you to a step by step creating process. Or, you can follow this [github](https://help.github.com/en/github/authenticating-to-github/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent) guide for more details.
{:.section}

##### 2. Set your configuration

You need to modify your `ssh` configuration file located in `~/.ssh/config`, this is configuration exist per-user in the home folder, you will edit it as follows
<pre>
    <code class="sshconfig">
ForwardAgent yes

Host github.com
    HostName github.com
    User git
    IdentityFile ~/.ssh/personal_rsa # private/personal identity
    IdentitiesOnly yes

Host work.github.com
    HostName github.com
    User git
    IdentityFile ~/.ssh/work_rsa # work identity
    IdentitiesOnly yes
    </code>
</pre>
Let me explain what have we done:

- We are defining two different hosts, that have or points to the same `HostName` github.com.
- Since, we have defined two different hosts `github.com` and `work.github.com`, the second one in reality does not exist, it is just a mapping.
- You add which `ssh` key to be used when authenticating with the host defined, by this line `IdentityFile /path/to/ssh_private_key`
- **Bonus:** Adding `IdentitiesOnly yes`, tells the `ssh-agent` to not use the default behavior of trying to connect using the default `key` `~.ssh/id_rsa` first but only try the specified key.
{:.section}

##### 3. How to use to connect?

Now, that you have every thing setup to work with multiple `ssh` keys, let me show the final step of how to use it, and that is by

<pre>
    <code class="console">
$ git clone git@work.github.com:company/project.git
    </code>
</pre>

This will resolve to the `work.github.com` host defined in `~/.ssh/config` and use the defined key there and will use the right key for it.
{:.section}

#### Conclusion

Managing multiple `ssh` keys can become cumbersome as soon as you need to use a second key and is not a necessary for everyone, but some times the need come or you want to use unorthodox key names. You might need one for working on your company's private repos, one for your clients' work and another for your private work.

If you can avoid it, do so, as ideally, it is a good practice to have only one.

I hope someone found this useful!

[Want to know more about `ssh`?](https://www.ssh.com/ssh/public-key-authentication)
{:.section}
