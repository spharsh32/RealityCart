buildscript {
    repositories {
        google()
        mavenCentral()
    }

    dependencies {
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:1.9.23")
        classpath("com.android.tools.build:gradle:8.2.1") // Ensure AGP is explicitly defined for the script below
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Fix for "Namespace not specified" error in older plugins
subprojects {
    afterEvaluate {
        val android = project.extensions.findByName("android")
        if (android != null) {
            val baseExtension = android as com.android.build.gradle.BaseExtension
            if (baseExtension.namespace == null) {
                val newNamespace = "com.example.reality_cart.fix.${project.name.replace("-", "_")}"
                baseExtension.namespace = newNamespace
                println("Thinking: Fixed namespace for project ${project.name} to $newNamespace")
            }
        }
    }
}

rootProject.buildDir = File(rootProject.projectDir, "../build")
subprojects {
    project.buildDir = File(rootProject.buildDir, project.name)
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.buildDir)
}
