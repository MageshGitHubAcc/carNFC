# Firebase Setup Instructions

## Prerequisites
- Firebase Project: car-parking-NFC (Project ID: car-parking-nfc)
- Android App: com.vit.nfc (Package name)

## Step 1: Download google-services.json
1. Go to Firebase Console: https://console.firebase.google.com/
2. Select your project: car-parking-NFC
3. Go to Project Settings > Your Apps > Android app (carNfc)
4. Click "Download google-services.json"
5. Place the file in: `android/app/google-services.json`

## Step 2: Configure Android

### android/build.gradle
Add the following:

```gradle
buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath 'com.android.tools.build:gradle:8.1.0'
        classpath 'com.google.gms:google-services:4.4.0'  // Add this line
        classpath "org.jetbrains.kotlin:kotlin-gradle-plugin:1.9.0"
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}
```

### android/app/build.gradle
Add at the bottom of the file:

```gradle
apply plugin: 'com.google.gms.google-services'
```

And update the dependencies section:

```gradle
dependencies {
    implementation "org.jetbrains.kotlin:kotlin-stdlib-jdk7:$kotlin_version"
    implementation platform('com.google.firebase:firebase-bom:32.7.0')
    implementation 'com.google.firebase:firebase-analytics'
}
```

Set minSdkVersion to 21:

```gradle
defaultConfig {
    minSdkVersion 21  // Change from flutter.minSdkVersion
    targetSdkVersion flutter.targetSdkVersion
    versionCode flutterVersionCode.toInteger()
    versionName flutterVersionName
}
```

## Step 3: Configure Google Sign-In

### android/app/build.gradle
Add in dependencies:

```gradle
dependencies {
    // ... existing dependencies
    implementation 'com.google.android.gms:play-services-auth:20.7.0'
}
```

### Get SHA-1 Certificate Fingerprint
Run in terminal:

```bash
cd android
./gradlew signingReport
```

Copy the SHA-1 from the output and add it to Firebase:
1. Firebase Console > Project Settings
2. Your Apps > Android app
3. Add fingerprint

## Step 4: Enable Authentication Methods in Firebase

1. Go to Firebase Console > Authentication
2. Click "Get Started"
3. Enable the following sign-in methods:
   - Email/Password: Enable
   - Google: Enable (add support email)

## Step 5: Set up Firestore Database

1. Go to Firebase Console > Firestore Database
2. Click "Create Database"
3. Start in **Test Mode** (we'll add security rules later)
4. Choose a location (e.g., us-central)

## Step 6: Add Firestore Security Rules

Go to Firestore > Rules and paste:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    function isAuthenticated() {
      return request.auth != null;
    }
    
    function isAdmin() {
      return isAuthenticated() && 
             get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }
    
    function isOwner(userId) {
      return isAuthenticated() && request.auth.uid == userId;
    }
    
    match /users/{userId} {
      allow read: if isAuthenticated() && (isOwner(userId) || isAdmin());
      allow create: if isAuthenticated() && isOwner(userId);
      allow update: if isAuthenticated() && (isOwner(userId) || isAdmin());
      allow delete: if isAdmin();
    }
  }
}
```

## Step 7: Run Flutter Commands

```bash
# Get dependencies
flutter pub get

# Clean build
flutter clean

# Run the app
flutter run
```

## Troubleshooting

### If you get "Duplicate class" error:
Clean and rebuild:
```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
flutter run
```

### If Google Sign-In doesn't work:
1. Verify SHA-1 is added in Firebase Console
2. Check if google-services.json is in the correct location
3. Make sure Google Sign-In is enabled in Firebase Authentication

### If Firebase initialization fails:
1. Delete the app from device/emulator
2. Run: `flutter clean`
3. Verify google-services.json exists in android/app/
4. Rebuild and run

## Testing the Authentication

1. Run the app
2. It should show the splash screen, then navigate to login
3. Try Email/Password login (you need to create a test user in Firebase Console first)
4. Try Google Sign-In

### Create Test User in Firebase:
1. Firebase Console > Authentication > Users
2. Click "Add User"
3. Enter email: test@test.com
4. Enter password: test123456
5. Click "Add User"

## Next Steps
After successful authentication:
- User data is automatically stored in Firestore `/users/{uid}`
- User role defaults to "user"
- To make someone admin, manually update their document in Firestore:
  ```
  users/{uid}
    role: "admin"
  ```
