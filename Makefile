.PHONY: all deps bootstrap build build-boot build-kernel build-shell build-compiller check-deps run clean

all: deps
	$(MAKE) build

# === Dependencies ===

deps:
	bash scripts/bootstrap.sh

bootstrap: deps

check-deps:
	python3 scripts/dependencies.py check

# === Build ===

build: build-boot build-kernel build-shell build-compiller

build-boot build-kernel build-shell build-compiller: | check-deps

build-boot:
	$(MAKE) -C .vent/repos/OnyxBoot

build-kernel:
	cd .vent/repos/OnyxKernel && cargo kbuild

build-shell:
	cd .vent/repos/OnyxShell && bash build.sh

build-compiller:
	$(MAKE) -C .vent/repos/OnyxCompiller

# === Run ===

run:
	bash scripts/run-qemu.sh

# === Clean ===

clean:
	rm -rf .build
