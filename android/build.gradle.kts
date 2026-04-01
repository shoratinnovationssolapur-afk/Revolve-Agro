// Add this at the VERY TOP of android/build.gradle.kts
//plugins {
//    // Remove the version numbers ("8.2.1", etc.)
//    id("com.android.application") apply false
//    id("com.android.library") apply false
//    id("org.jetbrains.kotlin.android") apply false
//    id("dev.flutter.flutter-gradle-plugin") apply false
//
//    // Keep the Google Services version as it's separate
//    id("com.google.gms.google-services") version "4.4.1" apply false
//}

// Keep your existing allprojects and buildDir logic below...
// ... (Keep your plugins and buildDir logic at the top)

allprojects {
    repositories {
        google()
        mavenCentral()
    }

    // ADD THIS BLOCK TO FIX THE VERSION ERRORS
    configurations.all {
        resolutionStrategy {
            force("androidx.browser:browser:1.8.0")
            force("androidx.core:core:1.13.1")
            force("androidx.core:core-ktx:1.13.1")
        }
    }
}

// ... (Keep the rest of your buildDir and tasks logic below)

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
