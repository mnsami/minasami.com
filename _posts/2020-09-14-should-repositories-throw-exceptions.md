---
layout: post
title:  "Should repositories throw exceptions ?"
categories: [php-development]
tags: php software-architecture design-patterns exception-handling repository-pattern best-practices clean-code solid-principles
description: "Should repository layer throw exceptions? Exploring error handling patterns in repository design with practical PHP examples."
---

Recently, I have been practicing separating the infrastructure layer in the projects I work or contribute to (particularly in [Symfony-based applications]({{ site.baseurl }}{% post_url 2021-06-23-part-1-setup-reactjs-symfony-app-with-hotloading %})), from the rest of the application by using/writing repository classes. Which in turn consumed by the application services to read and/or write to the data models.

What I want to focus on here, is mainly lookup operations, and model lookup isn't found, should the repository throw the exception, which in turn surrounded by a `try...catch` block in the application service, to decide how to handle this exception ? or should the repository just return `null` and the service checks for the return value ?

Following the separation of concerns/responsibilities best practices, this was a question took sometime from myself to answer, specially I have worked with people belonging to the two teams and I have also seen that in code as well, and I couldn't makeup my mind at first.

But, after giving it little time and thought, it was obvious for me to take sides with `return null` from the repository team, and let me explain why.

Let's take a very basic example here, of interacting with users, below is `UserRepository` contract interface.
<pre>
    <code class="php">
    interface UserRepository
    {
        /**
         * Get user details provided `UserId`
         *
         * @return User|null
         */
        public function byId(UserId $userId): ?User;
    }
    </code>
</pre>
{:.section}

### Infrastructure implementation

Let's see the difference between returning `null` and throwing an `Exception` from the repository.
{:.section}

#### Repository throwing `Exception`

<pre>
    <code class="php">
    class DoctrineUserRepository extends EntityRepository implements UserInterface
    {
        /**
         * @inheritDoc
         */
        public function byId(UserId $userId): ?User
        {
            $user = $this->find((string) $userId);

            // Here the repository immediately throws an exception when a record is not found.
            if (!$user) {
                throw new UserNotFound('User with id: ' . (string) $userId . ', not found.');
            }

            return $user;
        }
    }
    </code>
</pre>

and since, the repository is now responsible for throwing the exception, the application service has to first `catch` this exception and figure out what or how to handle it.

<pre>
    <code class="php">
    class UserReadService
    {
        public function getUserbyId(UserId $userId): UserDetailsDto
        {
            try {
                $user = $this->userRepository->byId($userId);
            } catch (UserNotFound $e) {
                // we re-throw the exception, because may be we need to log it,
                // or respond in an API with the right `404` message
                throw $e;
            }

            return UserDetailsDto($user);
        }
    }

    class UserController
    {
        public function getUserDetailsAction(Request $request): JsonResponse
        {
            try {
                $userId = $request->get('id');
                $user = $this->userReadService->getUserById(UserId::fromString($userId));
            } catch (UserNotFound $e) { // we catch the exception again
                return JsonResponse::create($e->getMessage(), Http::NOT_FOUND);
            }

            return JsonResponse::create($user, Http::OK);
        }
    }
    </code>
</pre>

In this case, which I don't like and I'm not in favor of, we catch the `UserNotFound` exception twice, once in the `UserReadService` and another time in the `UserController` which of course is redundant for no reason. Also, it doesn't make any sense, to catch the exception in the `UserReadService` just to throw it again.
{:.section}

#### Repository returning `null`

If we change the `DoctrineUserRepository` implementation to be returning `null`, like below:

<pre>
    <code class="php">
    class DoctrineUserRepository extends EntityRepository implements UserInterface
    {
        /**
         * @inheritDoc
         */
        public function byId(UserId $userId): ?User
        {
            $user = $this->find((string) $userId);

            if (!$user) {
                return null;
            }

            return $user;
        }
    }
    </code>
</pre>

Then it becomes a simple decision for the repository is to return `null` when it couldn't find the `User` with the provided `Id`, rather to decide which appropriate `Exception` should be thrown, which I believe it falls out of the repository's responsibility. For me, when start thinking about what to do in case of.., it is automatically wired in my mind, that this is a policy and/or business rule, where it should fall either in the domain layer or the in this case, the application service, and definitely not inside a `Repository` meaning:

<pre>
    <code class="php">
    class UserReadService
    {
        public function getUserbyId(UserId $userId): UserDetailsDto
        {
            $user = $this->userRepository->byId($userId);

            if (!$user) {
                throw new UserNotFound('User with id: ' . (string) $userId . ', not found.');
            }

            return UserDetailsDto($user);
        }
    }

    class UserController
    {
        public function getUserDetailsAction(Request $request): JsonResponse
        {
            try {
                $userId = $request->get('id');
                $user = $this->userReadService->getUserById(UserId::fromString($userId));
            } catch (UserNotFound $e) {
                return JsonResponse::create($e->getMessage(), Http::NOT_FOUND);
            }

            return JsonResponse::create($user, Http::OK);
        }
    }
    </code>
</pre>

This privileges the application service layer, to be in more control on how to handle the data layer, and thus feels more that it is the right responsibilities to have, rather than making the repository responsible to throw the exceptions.
{:.section}

## Conclusion

In the end, it is a matter of choice. But for me, it is clear and makes sense, to pick sides with returning `null`, to make responsibilities of each layer separate, and make the repositories and the services leaner.

Also, if you write complicated service functions, it makes easier with less amount of code by eliminating the `try...catch` and just enough with checking for `null` values returned from the repositories.

This pragmatic approach to error handling mirrors the same philosophy I apply when [choosing between strict mode and simple mode in bash scripts]({{ site.baseurl }}{% post_url 2025-11-10-periodically-run-database-backup %}) - sometimes explicit is better than implicit, and practical reliability trumps theoretical "best practices."

If you think otherwise, or have a better way of doing things, I'm always open to learn from others, message me or leave a comment.

---

**Want to discuss software architecture patterns?** I offer [mentorship](/mentorship/) for engineers looking to improve their architectural decision-making and design patterns.
{:.section}
