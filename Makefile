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
	wget http://tomk.s3.amazonaws.com/alpha/449e758/h2oai-$(VERSION)-1.$(ARCH_SUBST).rpm
	docker build \
		-t opsh2oai/h2oai-runtime-centos7-$(ARCH)-cuda$(MY_CUDA_VERSION):$(VERSION) \
		-f Dockerfile-h2oai-runtime-centos7.$(ARCH) \
		.
