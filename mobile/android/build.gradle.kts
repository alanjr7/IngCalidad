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
}
subprojects {
    project.evaluationDependsOn(":app")
}

// Evita el error "Inconsistent JVM-target compatibility (Java X vs Kotlin Y)"
// en plugins de terceros que no declaran kotlinOptions.jvmTarget (p. ej.
// receive_sharing_intent), donde Kotlin termina apuntando a la versión del JDK
// (21) mientras Java usa el valor de compileOptions (1.8 por defecto en AGP).
//
// No se toca la tarea JavaCompile (AGP la cablea con el bootclasspath correcto
// de android.jar; sobre-escribirla rompe la resolución del SDK). En su lugar se
// alinea Kotlin al target de Java que cada módulo ya tiene, dejándolo
// internamente consistente. Se hace en projectsEvaluated para leer el valor ya
// finalizado por AGP.
gradle.projectsEvaluated {
    subprojects {
        val androidExt = extensions.findByName("android") as? com.android.build.gradle.BaseExtension
        val javaTarget = androidExt?.compileOptions?.targetCompatibility ?: JavaVersion.VERSION_1_8
        val kotlinJvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.fromTarget(javaTarget.toString())
        tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
            compilerOptions {
                jvmTarget.set(kotlinJvmTarget)
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
