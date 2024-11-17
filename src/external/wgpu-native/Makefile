WILDCARD_SOURCE:=$(wildcard src/*.rs)

GIT_TAG=$(shell git describe --abbrev=0 --tags)
GIT_TAG_FULL=$(shell git describe --tags)
OS_NAME=

EXTRA_BUILD_ARGS=
TARGET_DIR=target
ifdef TARGET
	EXTRA_BUILD_ARGS=--target $(TARGET)
	TARGET_DIR=target/$(TARGET)
endif

ifndef ARCHIVE_NAME
	ARCHIVE_NAME=wgpu-$(TARGET)
endif

ifeq ($(OS),Windows_NT)
	OS_NAME=windows
else
	UNAME_S:=$(shell uname -s)
	ifeq ($(UNAME_S),Linux)
		OS_NAME=linux
	endif
	ifeq ($(UNAME_S),Darwin)
		OS_NAME=macos
	endif
endif

MKDIR_CMD:=mkdir -p

ifeq ($(origin MSYSTEM),undefined) # MSYSTEM env var is defined on msys2
	ifeq ($(OS),Windows_NT)
		SHELL:=cmd
		MKDIR_CMD=powershell -Command md -Force
	endif
endif

.PHONY: check test doc clear \
	lib-native lib-native-release \
	example-capture example-compute example-triangle \
	example-capture-release example-compute-release example-triangle-release \
	run-example-capture run-example-compute run-example-triangle \
	run-example-capture-release run-example-compute-release run-example-triangle-release

package: lib-native lib-native-release
	mkdir -p dist
	echo "Zipping the binaries ..."
	echo "$(GIT_TAG_FULL)" > dist/wgpu-native-git-tag
	for RELEASE in debug release; do \
		ARCHIVEDIR=toarchive; \
		ARCHIVEFILE=$(ARCHIVE_NAME)-$$RELEASE.zip; \
		LIBDIR=$(TARGET_DIR)/$$RELEASE; \
		rm -r -f dist/$$ARCHIVEDIR; \
		rm -f dist/$$ARCHIVEFILE; \
		mkdir -p dist/$$ARCHIVEDIR/include/webgpu; \
		mkdir -p dist/$$ARCHIVEDIR/include/wgpu; \
		mkdir -p dist/$$ARCHIVEDIR/lib; \
		cp ./dist/wgpu-native-git-tag                 dist/$$ARCHIVEDIR; \
		cp ./ffi/webgpu-headers/webgpu.h              dist/$$ARCHIVEDIR/include/webgpu; \
		cp ./ffi/wgpu.h                               dist/$$ARCHIVEDIR/include/wgpu; \
		if [ $(OS_NAME) = linux ]; then \
			cp ./$$LIBDIR/libwgpu_native.so           dist/$$ARCHIVEDIR/lib; \
			cp ./$$LIBDIR/libwgpu_native.a            dist/$$ARCHIVEDIR/lib; \
		fi; \
		if [ $(OS_NAME) = macos ]; then \
			cp ./$$LIBDIR/libwgpu_native.dylib        dist/$$ARCHIVEDIR/lib; \
			cp ./$$LIBDIR/libwgpu_native.a            dist/$$ARCHIVEDIR/lib; \
		fi; \
		if [ $(OS_NAME) = windows ]; then \
			if [[ "$(TARGET)" == *"gnu"* ]]; then \
				cp ./$$LIBDIR/wgpu_native.dll         dist/$$ARCHIVEDIR/lib; \
				cp ./$$LIBDIR/libwgpu_native.a        dist/$$ARCHIVEDIR/lib; \
				cp ./$$LIBDIR/libwgpu_native.dll.a    dist/$$ARCHIVEDIR/lib; \
			else \
				cp ./$$LIBDIR/wgpu_native.dll         dist/$$ARCHIVEDIR/lib; \
				cp ./$$LIBDIR/wgpu_native.lib         dist/$$ARCHIVEDIR/lib; \
				cp ./$$LIBDIR/wgpu_native.dll.lib     dist/$$ARCHIVEDIR/lib; \
				cp ./$$LIBDIR/wgpu_native.pdb         dist/$$ARCHIVEDIR/lib; \
			fi;\
		fi; \
		cd dist/$$ARCHIVEDIR; \
		if [ $(OS_NAME) = windows ]; then \
			7z a -tzip ../$$ARCHIVEFILE *; \
		else \
			zip -r ../$$ARCHIVEFILE *; \
		fi; \
		cd ../..; \
		rm -r -f dist/$$ARCHIVEDIR; \
	done

clean:
	cargo clean
	rm -Rf examples/build

check:
	cargo check --all

test:
	cargo test --all

doc:
	cargo doc --all

clear:
	cargo clean

lib-native: Cargo.lock Cargo.toml Makefile $(WILDCARD_SOURCE)
	cargo build $(EXTRA_BUILD_ARGS)

lib-native-release: Cargo.lock Cargo.toml Makefile $(WILDCARD_SOURCE)
	cargo build --release $(EXTRA_BUILD_ARGS)

# Examples were removed.
