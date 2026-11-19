import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("com.google.gms.google-services")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// M1: রিলিজ সইয়ের চাবি — android/key.properties থেকে পড়া হয়
// (ফাইলটা .gitignore-এ আছে, রিপোতে যায় না)। ফাইল না থাকলে
// রিলিজ ডিবাগ চাবি দিয়ে সই হয় (শুধু নিজের পরীক্ষার জন্য) —
// Play Store-এ দেওয়ার APK সবসময় আসল চাবি দিয়ে সই করতে হবে।
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    FileInputStream(keystorePropertiesFile).use { keystoreProperties.load(it) }
} else {
    // Phase 5 (fix-introduced gap): ডিবাগ-সই ফলব্যাক রাখা
    // হয়েছে — এটাই key.properties/সিক্রেট ছাড়া পরীক্ষার
    // পথ। কিন্তু সতর্কবার্তাটা আর চাপা warn লাইন নয়: বিল্ড
    // লগে চোখে পড়ার মতো ব্যানার, যাতে কেউ ভুল করে
    // ডিবাগ-সই করা APK Play Store-এ না পাঠায়।
    logger.lifecycle(
        "\n" +
            "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n" +
            "!!!  WARNING: key.properties NOT FOUND — the release APK  !!!\n" +
            "!!!  will be signed with the DEBUG key. This build is     !!!\n" +
            "!!!  for local testing ONLY. Never upload it to the       !!!\n" +
            "!!!  Play Store. See android/key.properties.example.     !!!\n" +
            "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n"
    )
}

fun keystoreProp(name: String): String =
    keystoreProperties[name] as? String
        ?: throw GradleException(
            "key.properties is missing '$name' — " +
                "see android/key.properties.example"
        )

android {
    // পুরোনো Kotlin অ্যাপের প্যাকেজ নাম — Firebase-এ এই নামেই
    // Android অ্যাপ নিবন্ধিত আছে (google-services.json দেখুন)।
    namespace = "com.helptrickbd.ogrogamifund"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // নতুন ও স্বতন্ত্র প্যাকেজ নাম — আগের যে কোনো প্যাকেজের কনফ্লিক্ট এড়ানোর জন্য
        applicationId = "com.helptrickbd.ogrogami.app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 24
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        // ডিবাগ সই: AGP-র ডিফল্ট ~/.android/debug.keystore ব্যবহার
        // হয় — রিপোতে কমিট করা debug.keystore আর নেই (M1)।
        if (keystorePropertiesFile.exists()) {
            create("release") {
                keyAlias = keystoreProp("keyAlias")
                keyPassword = keystoreProp("keyPassword")
                storeFile = file(keystoreProp("storeFile"))
                storePassword = keystoreProp("storePassword")
            }
        }
    }

    lint {
        // 04-m21: রিলিজ lint বন্ধই রাখা হয়েছে — Android SDK
        // ছাড়া ./gradlew :app:lintRelease চালিয়ে যাচাই করা
        // যায়নি; অন্ধভাবে চালু করলে বিল্ড আটকে যেতে পারে।
        // ব্যবহারকারীর মেশিনে lintRelease চালিয়ে ঠিক করে
        // তারপর চালু করা যাবে।
        checkReleaseBuilds = false
        abortOnError = false
    }

    buildTypes {
        release {
            isMinifyEnabled = false
            isShrinkResources = false
            // key.properties থাকলে আসল রিলিজ চাবি, না থাকলে
            // ডিবাগ চাবি (শুধু স্থানীয় পরীক্ষার জন্য)।
            signingConfig = signingConfigs.findByName("release")
                ?: signingConfigs.getByName("debug")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
