
RUN EMULATOR

emulator -list-avds

Run a AVD from the list

emulator -avd {avd_name}
emulator -avd Medium_Phone_API_36.0

emulator -avd Pixel_5_API_34_-_Android_14

flutter build apk --release -t lib/main_prod.dart

upgrading Flutter to 3.32.5 from 3.22.3