allprojects {
    repositories {
        maven { url = uri("https://storage.googleapis.com/download.flutter.io") }
        maven { url = uri("https://maven.aliyun.com/repository/public") }
        maven { url = uri("https://maven.aliyun.com/repository/google") }
        maven { url = uri("https://maven.aliyun.com/repository/gradle-plugin") }
        maven { url = uri("https://maven.aliyun.com/repository/central") }
        maven { url = uri("https://repo.huaweicloud.com/repository/maven/") }
        maven { url = uri("https://mirrors.cloud.tencent.com/nexus/repository/maven-public/") }

        google()
        mavenCentral()
    }

    configurations.all {
        resolutionStrategy {
            // home_widget uses glance-appwidget:1.+ which recently resolved
            // to 1.3.0-alpha01 (requires AGP 9.1+ / compileSdk 37).
            // Force pin to last stable version compatible with AGP 8.x.
            force("androidx.glance:glance-appwidget:1.1.1")
        }
    }
}

allprojects {
    afterEvaluate {
        project.repositories.removeIf { repo ->
            repo is MavenArtifactRepository &&
            repo.url.toString().contains("maven.aliyun.com/repository/content/groups/public")
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

// 统一所有模块的 Kotlin/JVM 目标为 21：
subprojects {
    tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
        compilerOptions.jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_21)
    }
    tasks.withType<org.gradle.api.tasks.compile.JavaCompile>().configureEach {
        sourceCompatibility = "21"
        targetCompatibility = "21"
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

tasks.register("printRepos") {
    doLast {
        rootProject.allprojects.forEach { p ->
            println("Project: ${p.name}")
            p.repositories.forEach { repo ->
                if (repo is MavenArtifactRepository) {
                    println("  ${repo.url}")
                }
            }
        }
    }
}