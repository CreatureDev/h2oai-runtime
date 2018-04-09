VERSION ?= 1.0.25

ARCH := $(shell arch)

ARCH_SUBST = undefined
FROM_SUBST = undefined
ifeq ($(ARCH),x86_64)
    FROM_SUBST = nvidia\/cuda:$(MY_CUDA_VERSION)-cudnn$(MY_CUDNN_VERSION)-devel-centos7
    ARCH_SUBST = $(ARCH)
endif
ifeq ($(ARCH),ppc64le)
    FROM_SUBST = nvidia\/cuda-ppc64le:$(MY_CUDA_VERSION)-cudnn$(MY_CUDNN_VERSION)-devel-centos7
    ARCH_SUBST = $(ARCH)
endif

Dockerfile-h2oai-runtime-centos7.$(ARCH): Dockerfile-h2oai-runtime-centos7.in
	cat $< | sed 's/FROM_SUBST/$(FROM_SUBST)/'g | sed 's/ARCH_SUBST/$(ARCH_SUBST)/g' | sed 's/VERSION_SUBST/$(VERSION)/g' > $@

all: MY_CUDA_VERSION := 9.0
all: MY_CUDNN_VERSION := 7
all: Dockerfile-h2oai-runtime-centos7.$(ARCH)
	wget https://s3.amazonaws.com/artifacts.h2o.ai/releases/ai/h2o/dai/$(VERSION)/$(ARCH_SUBST)-centos7/dai-$(VERSION)-1.$(ARCH_SUBST).rpm
	docker build \
		-t opsh2oai/h2oai-runtime-centos7-$(ARCH)-cuda$(MY_CUDA_VERSION):$(VERSION) \
		-f Dockerfile-h2oai-runtime-centos7.$(ARCH) \
		.



dai-$(PLATFORM_SUBST): dai/values.yaml dai/Chart.yaml
	rm -rf dai-$(PLATFORM_SUBST)
	cp -r dai dai-$(PLATFORM_SUBST)
	cat dai/Chart.yaml | \
		sed 's/PLATFORM_SUBST/$(PLATFORM_SUBST)/g' | \
		sed 's/VERSION_SUBST/$(VERSION)/g' \
		> dai-$(PLATFORM_SUBST)/Chart.yaml
	cat dai/values.yaml | \
		sed 's/VERSION_SUBST/$(VERSION)/g' | \
		sed 's/GPU_SUBST/$(GPU_SUBST)/g' \
		> dai-$(PLATFORM_SUBST)/values.yaml

helm:
	helm package dai-$(PLATFORM_SUBST)

cpu: PLATFORM_SUBST := cpu
cpu: GPU_SUBST := 0
cpu: dai-$(PLATFORM_SUBST) helm
	echo 'done'

gpu: PLATFORM_SUBST := gpu
gpu: GPU_SUBST := 1
gpu: dai-$(PLATFORM_SUBST) helm
	echo 'done'

