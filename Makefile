VERSION := $(shell git describe 2>/dev/null || echo "`date -u \"+%Y%m%d.%H%M%S\"`-`git describe --always`")
TAG := instedd/cdp

docker-image: clean-nndd nndd
	echo $(VERSION) > VERSION
	docker build --tag $(TAG):$(VERSION) .
	docker push $(TAG):$(VERSION)

clean-nndd:
	rm -rf public/nndd

nndd: public/nndd

public/nndd:
	docker pull instedd/nndd-builder:latest
	docker run --rm \
		-v $(shell pwd)/public/nndd:/nndd/dist/nndd \
		-v $(shell pwd)/etc/nndd/settings.local.json:/nndd/conf/settings.local.json \
		-v $(shell pwd)/etc/nndd/main.local.css:/nndd/conf/main.local.css \
		instedd/nndd-builder
