help:
	@cat Makefile

SRC=/home/jim/software/keras
DATA=$(shell pwd)/projects
GPU?=0
DOCKER_FILE=Dockerfile
DOCKER=nvidia-docker
BACKEND=tensorflow
PYTHON_VERSION?=3.6
CUDA_VERSION?=9.0
CUDNN_VERSION?=7
TEST=tests/
USER_ID=$(shell id -u)
IMAGE=keras_$(shell id -un)

build:
	docker build -t $(IMAGE) --build-arg python_version=$(PYTHON_VERSION) --build-arg cuda_version=$(CUDA_VERSION) --build-arg cudnn_version=$(CUDNN_VERSION) --build-arg user_id=$(USER_ID) -f $(DOCKER_FILE) .

bash: build
	$(DOCKER) run -it -v $(SRC):/src/workspace -v $(DATA):/src/projects --env KERAS_BACKEND=$(BACKEND) $(IMAGE) bash

ipython: build
	$(DOCKER) run -it -v $(SRC):/src/workspace -v $(DATA):/src/projects --env KERAS_BACKEND=$(BACKEND) $(IMAGE) ipython

notebook: build
	$(DOCKER) run -it -v $(SRC):/src/workspace -v $(DATA):/src/projects --net=host --env KERAS_BACKEND=$(BACKEND) $(IMAGE)

test: build
	$(DOCKER) run -it -v $(SRC):/src/workspace -v $(DATA):/src/projects --env KERAS_BACKEND=$(BACKEND) $(IMAGE) py.test $(TEST)

