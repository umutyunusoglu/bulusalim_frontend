# bulusalim_app

To configure the project:

Run flutter pub get --> to install dependencies
dart pub global activate flutterfire_cli --> Activate flutterfire CLI
npm i -g firebase-tools --> install firebaase
firebase login --> login to the firebase account in which this project exists
flutterfire configure --> do NOT use the existing firebase.json file --> enable for ios and android (should already be selected but just in case) --> handles the project configs
flutter pub add firebase_core --> Add any missing dependencies
After these steps the application should build and run without issues
If you will be using xcode simulators, make sure your xcode is up to date
A new Flutter project.
