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

// ── 서드파티 라이브러리 AGP 8.x 호환 패치 ─────────────────────────────────────
// pub cache repair 후에도 유지됨 (pub cache를 직접 수정하지 않음)
subprojects {
    plugins.withId("com.android.library") {

        // 1. namespace 주입 — AGP가 읽기 전(평가 중)에 설정
        extensions.configure<com.android.build.gradle.LibraryExtension> {
            if (namespace == null) {
                namespace = group.toString()
            }
        }

        // 2. compileSdk 업그레이드 — finalizeDsl: DSL 고정 직전에 실행 (afterEvaluate는 너무 늦음)
        extensions.findByType<com.android.build.api.variant.LibraryAndroidComponentsExtension>()
            ?.finalizeDsl { ext ->
                if ((ext.compileSdk ?: 0) < 34) ext.compileSdk = 34
            }

        // 3. Kotlin JVM 타겟 동기화 — 모듈 Java targetCompatibility에 맞게 조정
        afterEvaluate {
            val javaTarget = (tasks.findByName("compileReleaseJavaWithJavac") as? JavaCompile)
                ?.targetCompatibility
            if (javaTarget != null) {
                val kotlinTarget =
                    if (JavaVersion.toVersion(javaTarget) >= JavaVersion.VERSION_17)
                        org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
                    else
                        org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_1_8
                tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
                    compilerOptions {
                        jvmTarget.set(kotlinTarget)
                    }
                }
            }
        }
    }
}

// 3. image_gallery_saver — Flutter v1 Registrar import 제거 (컴파일 오류 방지)
//    doFirst로 컴파일 직전에 소스를 패치하므로 pub cache를 영구 수정하지 않음
subprojects {
    if (name == "image_gallery_saver") {
        tasks.configureEach {
            if (name.startsWith("compile") && name.contains("Kotlin")) {
                doFirst {
                    val f = File(projectDir,
                        "src/main/kotlin/com/example/imagegallerysaver/ImageGallerySaverPlugin.kt")
                    if (f.exists()) {
                        val original = f.readText()
                        val patched = original.replace(
                            "import io.flutter.plugin.common.PluginRegistry.Registrar\n", "")
                        if (original != patched) f.writeText(patched)
                    }
                }
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
