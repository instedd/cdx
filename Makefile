VERSION := $(shell git describe 2>/dev/null || echo "`date -u \"+%Y%m%d.%H%M%S\"`-`git describe --always`")
TAG := instedd/cdp

docker-image:
	echo $(VERSION) > VERSION
	docker build --tag $(TAG):$(VERSION) .
	docker push $(TAG):$(VERSION)
