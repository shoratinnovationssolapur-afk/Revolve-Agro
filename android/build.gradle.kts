<<<<<<< HEAD
=======
plugins {
   id("com.android.application") apply false
   id("com.android.library") apply false
   id("org.jetbrains.kotlin.android") apply false
   id("dev.flutter.flutter-gradle-plugin") apply false
   id("com.google.gms.google-services") apply false
}

>>>>>>> 4de844c681abb2fbeb86804d77c2f9ebf4a02000
allprojects {
    repositories {
        google()
        mavenCentral()
    }

    configurations.all {
        resolutionStrategy {
            force("androidx.browser:browser:1.8.0")
            force("androidx.core:core:1.13.1")
            force("androidx.core:core-ktx:1.13.1")
        }
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
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
