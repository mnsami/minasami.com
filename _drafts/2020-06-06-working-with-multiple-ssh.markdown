---
layout: post
title:  "Working with multiple ssh keys"
tags: ssh git
---

Usually when joining a new work place you are asked to provide your public `ssh` key to get access to all the private organization repositories.
And after sometime, I came to the conclusion that I want to separate between work and personal `ssh` keys, and I want to achieve that in an easy, hassle free way from the same computer.

<h4>Why do I want to do that?</h4>

The answer is simple, I want one `SSH` key-pair for work related matters (i.e. code base, servers .. etc) and a different key-pair for my own personal matters. In that sense, I am not mixing up things - which I don't like having - and I don't want my work `ssh` fingerprint to be in my personal projects. So, the separation between the two became a higher need for me.

Also, I want to be mind free that when I decide to leave the work place for another, on my last day, all I have to do is to just delete my work `ssh` key or it gets forgotten when my work laptop is wiped, then automatically I'm out of all the company's systems.

So, again the urge got higher to create another `ssh` key to be used for work place.

<h4>How will I do that?</h4>
1. You need to create another separate `ssh` key, and you can do that simple by running

    <pre>
        <code class="bash">
$ ssh-keygen -t rsa -b 4096 -C "your_email@example.com"
        </code>
    </pre>
and this will guide you to a step by step creating process. Or, you can follow this [github](https://help.github.com/en/github/authenticating-to-github/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent) guide for more details.

2. Set your configuration

    You need to modify your `ssh` configuration file located in `~/.ssh/config` as follows
    <pre>
        <code class="common config">
    ForwardAgent yes

    Host github.com
        HostName github.com
        IdentityFile ~/.ssh/personal_rsa
        IdentitiesOnly yes

    Host work.github.com
        HostName github.com
        IdentityFile ~/.ssh/work_rsa
        IdentitiesOnly yes
        </code>
    </pre>
    


[Want to know more about `ssh`?](https://www.ssh.com/ssh/public-key-authentication)
