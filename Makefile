# Makefile

# Set default values for Docker Hub username and image name
DOCKER_HUB_USERNAME ?= anto18
IMAGE_NAME ?= php-nginx-base-image
IMAGE_TAG ?= latest
TAG ?= latest

# Determine the Docker image tag based on GitLab CI/CD variables
ifeq ($(CI_COMMIT_BRANCH),)
  ifeq ($(CI_COMMIT_TAG),)
    # Use the default tag if not on a branch or tag
    TAG ?= latest
  else
    # Use the tag name for a tagged commit
    TAG ?= $(CI_COMMIT_TAG)
  endif
else
  # Use the branch name for a non-tagged commit
  TAG ?= $(CI_COMMIT_BRANCH)
endif

# Docker commands
DOCKER_BUILD = docker build -t $(DOCKER_HUB_USERNAME)/$(IMAGE_NAME):$(TAG) .
DOCKER_PUSH = docker push $(DOCKER_HUB_USERNAME)/$(IMAGE_NAME):$(TAG)


# Build and push the Docker image
build:
	$(DOCKER_BUILD)

push:
	$(DOCKER_PUSH)

# Login to Docker Hub
login:
	docker login

# Logout from Docker Hub
logout:
	docker logout

# Phony targets
.PHONY: build push login logout
