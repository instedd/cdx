VERSION := $(shell git describe --always)
TAG := instedd/cdp

docker-image:
	echo $(VERSION) > VERSION
	docker build --tag $(TAG):$(VERSION) .
	docker push $(TAG):$(VERSION)
