# Day 2 Task - Quick Start Guide

## ✅ What We've Completed Today

1. **User Model** - Complete user data structure with roles (user/admin)
2. **Auth Repository** - Firebase Authentication with Firestore integration
3. **Auth Provider** - Riverpod state management for authentication
4. **Login Screen** - Updated with proper error handling and Firestore integration
5. **Splash Screen** - Auto-navigation based on auth state
6. **Main App** - Riverpod setup with routing

## 🚀 Setup Steps

### 1. Install Dependencies
```bash
cd /Users/admin/Documents/mobile_app/flutter_app
flutter pub get
```

### 2. Firebase Configuration
Follow the instructions in `FIREBASE_SETUP.md`

**Quick checklist:**
- [ ] Download `google-services.json` from Firebase Console
- [ ] Place it in `android/app/google-services.json`
- [ ] Update `android/build.gradle` (add google-services plugin)
- [ ] Update `android/app/build.gradle` (apply plugin, add dependencies)
- [ ] Get SHA-1 certificate and add to Firebase
- [ ] Enable Email/Password and Google Sign-In in Firebase Console
- [ ] Create Firestore database
- [ ] Add Firestore security rules

### 3. Run the App
```bash
flutter clean
flutter pub get
flutter run
```

## 📱 How It Works

### Authentication Flow:

1. **App Launch** → `SplashScreen`
   - Shows loading animation
   - Checks authentication state
   - Navigates to appropriate screen

2. **Not Authenticated** → `LoginScreen`
   - User can login with Email/Password
   - User can login with Google
   - On success: User data is stored in Firestore

3. **Authenticated** 
   - **Regular User** → Home Screen (placeholder)
   - **Admin** → Admin Dashboard (placeholder)

### Firestore Data Structure:

When a user logs in, their data is automatically created/updated in Firestore:

```
users/
  {userId}/
    email: "user@example.com"
    name: "John Doe"
    phone: null
    role: "user"
    photoURL: "https://..."
    provider: "google" | "email"
    createdAt: timestamp
    updatedAt: timestamp
```

## 🧪 Testing

### Test Email/Password Login:

1. **Create test user in Firebase Console:**
   - Go to Firebase Console → Authentication → Users
   - Click "Add User"
   - Email: `test@test.com`
   - Password: `test123456`

2. **Test in app:**
   - Open app
   - Enter email: `test@test.com`
   - Enter password: `test123456`
   - Click Login
   - ✅ Should navigate to Home Screen
   - ✅ Check Firestore - user document should be created

### Test Google Sign-In:

1. **Prerequisites:**
   - SHA-1 must be added to Firebase
   - Google Sign-In must be enabled
   - Support email must be configured

2. **Test in app:**
   - Click Google Sign-In button
   - Select Google account
   - ✅ Should navigate to Home Screen
   - ✅ Check Firestore - user document should be created with Google data

### Verify Firestore Data:

1. Go to Firebase Console → Firestore Database
2. You should see:
   ```
   users (collection)
     └── {user_uid} (document)
         ├── email: "user@example.com"
         ├── name: "John Doe"
         ├── role: "user"
         ├── provider: "google"
         └── ... other fields
   ```

## 🔧 Making a User Admin

To test admin features later:

1. Go to Firebase Console → Firestore
2. Find the user document in `users` collection
3. Edit the document
4. Change `role` from `"user"` to `"admin"`
5. Save
6. Restart the app
7. User will now navigate to Admin Dashboard

## 📁 File Structure Created

```
lib/
├── data/
│   ├── models/
│   │   └── user_model.dart          ✅ Created
│   ├── repositories/
│   │   └── auth_repository.dart     ✅ Created
│   └── providers/
│       └── auth_provider.dart       ✅ Created
├── presentation/
│   └── screens/
│       ├── auth/
│       │   └── login_screen.dart    ✅ Updated
│       └── splash_screen.dart       ✅ Created
└── main.dart                         ✅ Updated
```

## 🐛 Common Issues & Solutions

### Issue: "MissingPluginException"
**Solution:** 
```bash
flutter clean
flutter pub get
flutter run
```

### Issue: Google Sign-In not working
**Solution:**
1. Check SHA-1 is added in Firebase Console
2. Verify google-services.json is in `android/app/`
3. Make sure Google Sign-In is enabled in Firebase Authentication

### Issue: "Duplicate class" error
**Solution:**
```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
flutter run
```

### Issue: Firebase not initialized
**Solution:**
1. Check `google-services.json` exists in `android/app/`
2. Verify `apply plugin: 'com.google.gms.google-services'` is in `android/app/build.gradle`
3. Clean and rebuild

## ✨ Features Implemented

- ✅ Email/Password Authentication
- ✅ Google Sign-In Authentication
- ✅ Automatic Firestore user document creation
- ✅ User role management (user/admin)
- ✅ Auth state persistence
- ✅ Auto-navigation based on auth state
- ✅ Error handling with user-friendly messages
- ✅ Loading states
- ✅ Remember me checkbox (UI only - functionality can be added)

## 🎯 Next Steps (Day 3)

Tomorrow we'll work on:
1. Mall selection screen
2. Mall data structure in Firestore
3. Parking slots initialization
4. Real-time slot availability
5. User parking history

## 📞 Quick Commands

```bash
# Run the app
flutter run

# Run on specific device
flutter run -d <device_id>

# List devices
flutter devices

# Check for issues
flutter doctor

# View logs
flutter logs

# Hot reload in app
Press 'r'

# Hot restart in app
Press 'R'

# Quit
Press 'q'
```

## ✅ Day 2 Completion Checklist

- [ ] Dependencies installed
- [ ] Firebase configured
- [ ] google-services.json added
- [ ] SHA-1 added to Firebase
- [ ] Authentication methods enabled
- [ ] Firestore database created
- [ ] Security rules added
- [ ] App runs successfully
- [ ] Email login works
- [ ] Google login works
- [ ] User data appears in Firestore
- [ ] Splash screen shows
- [ ] Navigation works correctly

## 🎉 Success Criteria

Your Day 2 task is complete when:
1. ✅ App launches without errors
2. ✅ You can login with email/password
3. ✅ You can login with Google
4. ✅ User data is automatically created in Firestore
5. ✅ After login, user navigates to appropriate screen
6. ✅ You can see user document in Firestore Database

---

**Great job! 🚀 Day 2 Complete!**

Tomorrow we'll build the mall selection and parking slot features.
