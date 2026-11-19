allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
    // m21: compileSdk 36 শুধু flutter_plugin_android_lifecycle-এর
    // জন্য — ওই প্লাগইনটাই ≥36 চায়। আগে সব লাইব্রেরিতে জোর করে
    // বসানো হতো, যা ভবিষ্যতের প্লাগইন আপডেটে ভাঙতে পারে।
    // লিন্ট বন্ধ রাখা হয়েছে ইচ্ছাকৃতভাবে — আবার চালু করতে হলে
    // আগে ./gradlew :app:lintRelease চালিয়ে দেখতে হবে (এখানে
    // Android SDK নেই, তাই অন্ধভাবে চালু করলে রিলিজ বিল্ড
    // ভাঙতে পারে)।
    afterEvaluate {
        if (project.name == "flutter_plugin_android_lifecycle") {
            extensions.findByType<com.android.build.gradle.LibraryExtension>()
                ?.compileSdk = 36
        }
        tasks.findByName("lintVitalAnalyzeRelease")?.enabled = false
        tasks.findByName("lintVitalRelease")?.enabled = false
    }
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
