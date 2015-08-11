VERSION := $(shell git describe 2>/dev/null || echo "`date -u \"+%Y%m%d.%H%M%S\"`-`git describe --always`")
TAG := instedd/cdp

docker-image:
	echo $(VERSION) > VERSION
	rm -rf public/nndd
	# Uncomment next line to update nndd to the latest version
	docker pull instedd/nndd-builder:latest
	docker run --rm \
    -v $(shell pwd)/public/nndd:/nndd/dist/nndd \
    -v $(shell pwd)/etc/nndd/settings.local.json:/nndd/conf/settings.local.json \
            -v $(shell pwd)/etc/nndd/custom.local.scss:/nndd/conf/custom.local.scss \
    instedd/nndd-builder

	docker build --tag $(TAG):$(VERSION) .
	docker push $(TAG):$(VERSION)
