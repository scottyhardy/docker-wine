# Changelog

## 1.1.0 (2019-05-06)

* Refactor `Dockerfile` to reduce number of layers and allow for choosing a different branch of Wine using build args
* Add small version of logo to `README.md`

## 1.0.0 (2019-04-30)

* Rename username `wine` to `wineuser` for clarity
* Use Ubuntu 18.04 for base image
* Add table of contents to `README.md`
* Add shields.io and microbadger.com badges to `README.md`
* Remove file `license.md` as preventing GitHub from identifying MIT license
* Create `README-short.txt`
* Set `WORKDIR` to `wineuser`'s home

## 0.7.0 (2019-04-29)

* Release improved logo
* Enable sound using host PulseAudio server and a bind mount to a shared UNIX socket
* Add instructions for using PulseAudio for sound to `README.md`
* Remove Winetricks cache download as it's extremely large and not always necessary

## 0.6.1 (2019-04-25)

* Add logo first draft
* Improve license formatting
* Add `license.md` with reference to `LICENSE`

## 0.6.0 (2019-04-25)

### Dockerfile

* Use wine-stable v4.0 instead of wine-staging for more consistent builds
* Remove multi-stages as not using any other targets for builds
* Add Open Container Initiative (OCI) labels
* Add build date and git revision arguments with build hook to generate values on each auto-build on Docker Hub

### Scripts

* Check for `.Xauthority` magic cookie file in both env and user home

### Documentation

* Add `CHANGELOG.md`
* Add `LICENSE`
* Reduce size of `README.md` and improve readability
* Various linting improvements
