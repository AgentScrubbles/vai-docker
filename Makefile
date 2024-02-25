.PHONY: help

HOSTNAME := $(shell hostname)
UID := $(shell id -u)
GID := $(shell id -g)
IMAGE := topaz-vai

# Change these two if you want to build a different version
VAI_VERSION := 4.0.7.0.b
VAI_SHA2 := e8567bf60e1dec961cf4b471cd93c7ac63629ab49e97aac5b9e561409224d990

TAG := $(shell echo ${VAI_VERSION} | sed 's/\.//g')

help:
	@egrep -h '\s##\s' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[1;32m%-10s\033[0m %s\n", $$1, $$2}'

build:    ## Build image capable of using fp16/32 models
	docker build -t $(IMAGE) \
	--build-arg "VAI_VERSION=$(VAI_VERSION)" \
	--build-arg "VAI_SHA2=$(VAI_SHA2)" .
	docker tag $(IMAGE) $(IMAGE):$(TAG)

build-no-cache:    ## Build image capable of using fp16/32 models
	docker build --no-cache -t $(IMAGE) \
	--build-arg "VAI_VERSION=$(VAI_VERSION)" \
	--build-arg "VAI_SHA2=$(VAI_SHA2)" .
	docker tag $(IMAGE) $(IMAGE):$(TAG)

login:    ## Refresh the auth.tpz license file
	docker run --net=host --gpus all --rm -ti --user $(UID):$(GID) -v $(PWD)/auth:/auth --name topaz-login --hostname $(HOSTNAME) $(IMAGE) login

test:     ## Run a smoke test doing a 2x upscale with Protheus
	docker run --rm -ti --gpus all --user $(UID):$(GID) --name vai-test --hostname $(HOSTNAME) \
		-v $(PWD)/models:/models \
		-v $(PWD)/auth/auth.tpz:/opt/TopazVideoAIBETA/models/auth.tpz \
		-v $(PWD):/workspace \
		$(IMAGE) \
		ffmpeg -v verbose -y -f lavfi -i testsrc=duration=12:size=320x180:rate=15 -pix_fmt yuv420p \
		-flush_packets 1 -sws_flags spline+accurate_rnd+full_chroma_int \
		-color_trc 2 -colorspace 2 -color_primaries 2 \
		-filter_complex "tvai_up=model=prob-3:scale=2:preblur=-0.6:noise=0:details=1:halo=0.03:blur=1:compression=0:estimate=20:blend=0.8:device=0:vram=1:instances=1" \
		-c:v h264_nvenc -profile:v high -preset medium -b:v 0 \
		sample_prob3_2x_upscaled.mp4

benchmark: ## Run a prob3 2x upscale benchmark
	docker run --rm -ti --gpus all --user $(UID):$(GID) --name vai-bench --hostname $(HOSTNAME) -v $(PWD)/models:/models $(IMAGE) \
		ffmpeg -v verbose -f lavfi -i testsrc=duration=60:size=640x480:rate=30 -pix_fmt yuv420p \
		-filter_complex "tvai_up=model=prob-3:scale=2:preblur=-0.6:noise=0:details=1:halo=0.03:blur=1:compression=0:blend=0.8:device=0:vram=1:instances=1" \
		-f null -

push:
	TAG=$(date '+%Y%m%d-%H%M')
	docker tag topaz-vai git.apps.clabough.tech/third-party/vai-docker:$(TAG)
	docker tag topaz-vai git.apps.clabough.tech/third-party/vai-docker:latest
	docker push git.apps.clabough.tech/third-party/vai-docker:$(TAG)
	docker push git.apps.clabough.tech/third-party/vai-docker:latest