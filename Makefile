.RECIPEPREFIX = >

SDK          ?= $(HOME)/Android/Sdk
GRADLE_CACHE ?= $(HOME)/.cache/android-build-gradle
IMAGE        := android-build
APK          := app/build/outputs/apk/debug/app-debug.apk
PKG          := com.example.hello
ADB          := adb $(if $(SERIAL),-s $(SERIAL))

.PHONY: all build install run log clean

all: install run

.image-stamp: Containerfile
> podman build -t $(IMAGE) -f Containerfile .
> touch $@

build: .image-stamp
> echo "sdk.dir=/sdk" > local.properties
> mkdir -p $(GRADLE_CACHE)
> podman run --rm \
>   -v "$(CURDIR)":/work:Z \
>   -v "$(SDK)":/sdk:Z \
>   -v "$(GRADLE_CACHE)":/root/.gradle:Z \
>   -w /work $(IMAGE) \
>   ./gradlew assembleDebug -Pandroid.aapt2FromMavenOverride=/usr/bin/aapt2

install: build
> $(ADB) install -r $(APK)

run:
> $(ADB) shell am start -n $(PKG)/.MainActivity

log:
> $(ADB) logcat -s HelloApp

clean:
> rm -rf build app/build .gradle .image-stamp
