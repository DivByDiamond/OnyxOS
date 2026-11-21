.PHONY: all deps bootstrap build build-boot build-kernel build-shell build-compiller check-deps test smoke run clean

all: deps
	$(MAKE) build

# === Dependencies ===

deps:
	bash scripts/bootstrap.sh

bootstrap: deps

check-deps:
	python3 scripts/dependencies.py check

# === Build ===

# Unified ecosystem entry point. Full pipeline from locked checkouts:
# OnyxBoot, kernel, shell, onyxcc, desktop, apps and the boot disk
# image (scripts/build-all.sh bootstraps first if needed).
build:
	bash scripts/build-all.sh

# Per-component targets stay for partial rebuilds after bootstrap.
build-boot build-kernel build-shell build-compiller: | check-deps

build-boot:
	$(MAKE) -C .vent/repos/OnyxBoot

build-kernel:
	cd .vent/repos/OnyxKernel && cargo kbuild

build-shell:
	cd .vent/repos/OnyxShell && bash build.sh

build-compiller:
	$(MAKE) -C .vent/repos/OnyxCompiller

# === Test ===

# Meta-level checks only, mirroring the CI "OnyxOS meta" job: locked
# revision verification plus the lock resolver unit tests. A full boot
# smoke is a separate target because it needs a complete build and
# QEMU (make smoke after make build).
test: check-deps
	python3 -m unittest discover -s scripts/qa -p 'test_*.py'

smoke:
	bash scripts/qemu-smoke.sh

# === Run ===

run:
	bash scripts/run-qemu.sh

# === Clean ===

clean:
	rm -rf .build
