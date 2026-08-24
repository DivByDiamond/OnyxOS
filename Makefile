.PHONY: all deps bootstrap build build-boot build-kernel build-shell build-compiller run clean

all: deps build

# === Dependencies ===

deps: .vent/vent
	./.vent/vent -j 4 Onyx.vent

bootstrap:
	bash scripts/bootstrap.sh

.vent/vent:
	mkdir -p .vent
	git clone https://github.com/grafmorkov/vent.git /tmp/vent-build 2>/dev/null || true
	cmake -B /tmp/vent-build/build /tmp/vent-build
	cmake --build /tmp/vent-build/build
	cp /tmp/vent-build/build/vent .vent/vent
	rm -rf /tmp/vent-build

# === Build ===

build: build-boot build-kernel build-shell build-compiller

build-boot:
	$(MAKE) -C .vent/repos/OnyxBoot

build-kernel:
	cargo build --release --manifest-path .vent/repos/OnyxKernel/Cargo.toml

build-shell:
	cd .vent/repos/OnyxShell && bash build.sh

build-compiller:
	$(MAKE) -C .vent/repos/OnyxCompiller host

# === Run ===

run:
	bash scripts/run-qemu.sh

# === Clean ===

clean:
	rm -rf .build
