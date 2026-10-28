# HelloAndroid

A minimal Android app written in Java, built entirely from the command line on **Arch Linux (aarch64)** without Android Studio.

Google doesn't publish an arm64 Linux build of `aapt2`, so the Android Gradle Plugin's default download fails on this platform. This project works around that by building inside a Debian container, using Debian's own arm64 `aapt2` package. A Makefile wraps the whole process into one command.

## How it works

```
make
 ├─ podman build      one-time image: Debian + aapt2 + JDK
 ├─ podman run        ./gradlew assembleDebug inside the container,
 │                    with -Pandroid.aapt2FromMavenOverride=/usr/bin/aapt2
 ├─ adb install -r    install the APK on the phone (runs on the host)
 └─ adb shell am start   launch the app
```

The build runs in the container. `adb` runs on the host, because it needs direct access to USB and the network.

## Requirements

On the host (Arch Linux, aarch64):

```bash
sudo pacman -S podman make android-tools
```

- `podman` runs the build container (rootless is fine).
- `make` runs the build workflow.
- `android-tools` provides a native `adb`. Don't use the `adb` from the SDK's `platform-tools` folder, since it's an x86_64 binary and won't run on arm.

You also need an Android SDK at `~/Android/Sdk` (see below), and a phone with USB debugging or wireless debugging enabled.

## One-time SDK setup

The SDK contains Java-based tools and platform files that work on any architecture. Only a few native tools (like `aapt2`) are arch-specific, and the container supplies those.

1. Download the **Command line tools only** zip for Linux from <https://developer.android.com/studio> (scroll to the bottom of the page).

2. Unpack it into the layout `sdkmanager` expects:

   ```bash
   mkdir -p ~/Android/Sdk/cmdline-tools
   unzip commandlinetools-linux-*_latest.zip -d /tmp
   mv /tmp/cmdline-tools ~/Android/Sdk/cmdline-tools/latest
   ```

3. Add it to your PATH in `~/.zshrc` (or `~/.bashrc`):

   ```bash
   export ANDROID_HOME=$HOME/Android/Sdk
   export PATH=$PATH:$ANDROID_HOME/cmdline-tools/latest/bin
   ```

4. Install the platform and build tools, and accept the licenses (requires a JDK on the host, for example `jdk17-openjdk`):

   ```bash
   sdkmanager --licenses
   sdkmanager "platforms;android-34" "build-tools;34.0.0"
   ```

## Usage

From the project root:

```bash
make
```

This builds the debug APK, installs it on the phone, and launches the app. The first run takes a few minutes, because it builds the container image and downloads Gradle dependencies. Later runs reuse the image and a Gradle cache (`~/.cache/android-build-gradle`).

### Targets

| Command        | What it does                                         |
|----------------|------------------------------------------------------|
| `make`         | Build, install, and launch                           |
| `make build`   | Build the debug APK only                             |
| `make install` | Build and install on the phone                       |
| `make run`     | Launch the app on the phone                          |
| `make log`     | Show `logcat` output filtered to the `HelloApp` tag  |
| `make clean`   | Delete build outputs and the image stamp             |

The APK is written to `app/build/outputs/apk/debug/app-debug.apk`.

### Variables

| Variable       | Default                              | Purpose                              |
|----------------|--------------------------------------|--------------------------------------|
| `SDK`          | `~/Android/Sdk`                      | Android SDK location on the host     |
| `GRADLE_CACHE` | `~/.cache/android-build-gradle`      | Persistent Gradle cache for builds   |
| `SERIAL`       | unset                                | adb device to target                 |
| `PKG`          | `com.example.hello`                  | Package name used by `make run`      |

Example:

```bash
make SERIAL=<your-device-serial>
```

## Connecting the phone

1. On the phone, open **Settings → About phone** and tap **Build number** 7 times.
2. In **Developer options**, enable **USB debugging**, and optionally **Wireless debugging**.
3. Check the connection:

   ```bash
   adb devices
   ```

   You should see the device listed as `device`. If it says `unauthorized`, accept the prompt on the phone.

### "adb: more than one device/emulator"

The same phone can show up several times, for example once over USB and once over wireless debugging. Pick one:

```bash
adb devices
make SERIAL=<serial from the first column>
```

Or set a default for your shell:

```bash
export ANDROID_SERIAL=<serial>
make
```

To drop a wireless entry: `adb disconnect <ip>:<port>`.

## Project layout

```
.
├── Makefile                      one-command workflow
├── Containerfile                 Debian image with aapt2 and a JDK
├── settings.gradle
├── build.gradle                  Android Gradle Plugin version
├── gradle.properties
├── gradlew, gradle/              Gradle wrapper
└── app/
    ├── build.gradle              SDK versions and app ID
    └── src/main/
        ├── AndroidManifest.xml
        └── java/com/example/hello/MainActivity.java
```

## Troubleshooting

**`SDK location not found`**
`sdk.dir` is wrong or the SDK folder doesn't exist. The Makefile writes `sdk.dir=/sdk` to `local.properties` for the container run, so check that `SDK` points to a real folder.

**`cannot execute binary file` mentioning `aapt2`**
Gradle is using the x86_64 `aapt2` it downloaded from Maven. Make sure you build through `make`, which passes the override flag. Running `./gradlew` directly on the host will fail.

**Gradle complains about the `aapt2` version**
Debian's `aapt2` can be older than the one the Android Gradle Plugin expects. Switch to an older plugin version in the root `build.gradle`.

**Podman permission or user namespace errors**
Rootless Podman may need entries for your user in `/etc/subuid` and `/etc/subgid`.

**Build files owned by a strange UID**
Fix ownership with `sudo chown -R $USER: .`

**Phone not detected**
Use a data-capable USB cable and set the USB mode to File transfer. Install `android-udev` and add yourself to the `adbusers` group if needed, then log out and back in.

**`make run` says the activity can't be found**
`PKG` in the Makefile must match `applicationId` in `app/build.gradle`.

## Security notes

- Gradle build scripts run arbitrary code. Only build projects you wrote or trust.
- The container can only see the project folder, the SDK folder, and the Gradle cache, not the rest of your home directory. It does have network access.
- `aapt2` comes from Debian's package archive, not from third-party binaries.
- Keep wireless debugging off when you're not using it, and prefer a test phone over your daily one.
- Debug APKs are signed with a debug key. Never publish them. A release build needs your own keystore, which should be kept out of the repo and out of the container.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.
