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