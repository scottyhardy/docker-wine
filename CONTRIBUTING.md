# Contributing to docker-wine

:sparkles: :tada: Thank you for taking an interest in docker-wine and wanting to contribute! :tada: :sparkles:

## How you can help

The ways that you can contribute include:

* Reporting bugs, issues or just general feedback
* Requesting features and enhancements
* Submitting a pull request to merge changes and enhancements directly to the repository

If you're unsure where to start, check the [Issue register](https://github.com/scottyhardy/docker-wine/issues) for any tasks you may be able to contribute to.  I'd also really like to set up some automated testing to improve the CI/CD workflow and prevent bugs being introduced, so if that's an area you can help with then I'd like to hear from you!

## Reporting bugs and requesting features

Bugs and feature requests can be submitted by opening a [New Issue](https://github.com/scottyhardy/docker-wine/issues/new/choose).

## Pull requests

I'm keen to include any contributions to this project, but to maintain a high level of quality there's a few rules I'd like to adhere to:

* This image is meant to be as general as possible to cover a wide range of use cases. Don't introduce changes for niche use cases that won't benefit others
* Ensure all dependencies can be automatically determined so that weekly builds can continue without the need for manual intervention. Avoid including any version number or version codenames, instead use a script to detect what to use
* All shell scripts should pass `shellcheck` without needing to add `# shellcheck disable=...` comments
* Need to pass Travis CI checks (which is currently just a build of the image)

I generally like to use best practices where possible, but currently the `Dockerfile` is failing linters due to not pinning particular versions of the base image or installed packages. I'd originally started to use this practice but due to older package versions not being kept on Ubuntu sources for very long it meant that unless I continually updated the repository the image would fail to build for other users. Idempotent builds are great, but automating the build so it continues to work with newer versions without needing to touch the code is much more practical in my opinion.

I also prefer to use [Conventional Commits](https://www.conventionalcommits.org) but I'm not going to reject a pull request just because you may not use this method for your commit messages.

## Deployment of images

I currently use both [Docker Hub](https://hub.docker.com/r/scottyhardy/docker-wine/builds) and [Travis CI](https://travis-ci.com/github/scottyhardy/docker-wine) to perform automated builds.

### Docker Hub

Docker Hub only builds on pushes to the `master` branch and then tags and pushes the image with `latest` or with the release version number (e.g. docker-wine release v3.1.0 is tagged as `3.1.0`). The only reason I use Docker Hub automated builds is because it's the only way I've found to automatically sync my `README.md` from GitHub.

### Travis CI

Travis CI performs builds (without pushing to the Docker Hub registry) for every push to any branch and for pull requests, purely for automated testing. I've also set up a weekly cron schedule with Travis CI which builds and pushes the image with the tags `latest` and the version of Wine that was installed (e.g. `wine-stable-5.0.0`). My intention is that I should be able to leave the GitHub repository untouched and the `latest` image will always have the latest version of Wine installed as well as images of previous Wine versions for users who may want to specify a particular version for their downstream `Dockerfile`.

If you want to use Travis CI for your own forked repository, then for automated builds (without pushes) there is nothing special that needs to be set up other than linking Travis CI to your repository. To allow both builds and deployments there are 3 Environment Variables that need to be defined for the repository on the Travis CI Settings :

* `DOCKER_REPO`
* `DOCKER_USERNAME`
* `DOCKER_PASSWORD`

So, for example with `DOCKER_REPO` I use `docker-wine`, `DOCKER_USERNAME` is `scottyhardy` and for `DOCKER_PASSWORD` I use a [Docker Hub personal access token](https://docs.docker.com/docker-hub/access-tokens/). By substituting your own values for the above Environment Variables you can automate publishing your own images to Docker Hub.
