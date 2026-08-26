import java.util.Properties
import org.gradle.api.Action
import org.gradle.api.execution.TaskExecutionGraph

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val signingPropertiesFile = rootProject.file("key.properties")
val signingProperties = Properties()
val hasLocalSigningProperties = signingPropertiesFile.exists()
val signingPropertiesLoadError = if (hasLocalSigningProperties) {
    try {
        signingPropertiesFile.inputStream().use { signingProperties.load(it) }
        null
    } catch (exception: Exception) {
        exception
    }
} else {
    null
}

val requiredSigningKeys = listOf("storeFile", "storePassword", "keyAlias", "keyPassword")
val propertySigningValues = requiredSigningKeys.associateWith { signingProperties.getProperty(it) }
val environmentSigningValues = mapOf(
    "storeFile" to System.getenv("ANDROID_SIGNING_STORE_FILE"),
    "storePassword" to System.getenv("ANDROID_SIGNING_STORE_PASSWORD"),
    "keyAlias" to System.getenv("ANDROID_SIGNING_KEY_ALIAS"),
    "keyPassword" to System.getenv("ANDROID_SIGNING_KEY_PASSWORD"),
)
val hasCompletePropertySigning = propertySigningValues.values.all { !it.isNullOrBlank() }
val hasCompleteEnvironmentSigning = environmentSigningValues.values.all { !it.isNullOrBlank() }
val releaseSigningValues = when {
    hasLocalSigningProperties && signingPropertiesLoadError == null &&
        hasCompletePropertySigning && !hasCompleteEnvironmentSigning ->
        propertySigningValues.mapValues { it.value!! }
    !hasLocalSigningProperties && hasCompleteEnvironmentSigning ->
        environmentSigningValues.mapValues { it.value!! }
    else -> null
}
val releaseSigningError = when {
    signingPropertiesLoadError != null ->
        "Release signing configuration could not read or parse ignored android/key.properties: ${signingPropertiesLoadError.message ?: signingPropertiesLoadError.javaClass.simpleName}"
    hasLocalSigningProperties && hasCompletePropertySigning && hasCompleteEnvironmentSigning ->
        "Release signing configuration is ambiguous. Configure exactly one source: ignored android/key.properties or CI signing environment variables."
    hasLocalSigningProperties ->
        "Release signing configuration is incomplete. Complete ignored android/key.properties; CI signing environment variables are not used while this file exists."
    else ->
        "Release signing configuration is incomplete. Configure ignored android/key.properties or CI signing environment variables."
}

android {
    namespace = "com.estacionamientocentral.mobile"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.estacionamientocentral.mobile"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 25
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (releaseSigningValues != null) {
            create("release") {
                storeFile = rootProject.file(releaseSigningValues.getValue("storeFile"))
                storePassword = releaseSigningValues.getValue("storePassword")
                keyAlias = releaseSigningValues.getValue("keyAlias")
                keyPassword = releaseSigningValues.getValue("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            if (releaseSigningValues != null) {
                signingConfig = signingConfigs.getByName("release")
            }
        }
    }
}

gradle.taskGraph.whenReady(Action<TaskExecutionGraph> {
    if (allTasks.any { it.name.contains("release", ignoreCase = true) }) {
        check(releaseSigningValues != null) { releaseSigningError }

        val storeFile = rootProject.file(releaseSigningValues.getValue("storeFile"))
        check(storeFile.isFile && storeFile.canRead()) {
            "Release signing keystore is not readable: ${storeFile.absolutePath}"
        }
    }
})

flutter {
    source = "../.."
}
