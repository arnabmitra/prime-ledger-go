val ktor_version: String by project
val kotlin_version: String by project
val logback_version: String by project
val exposed_version: String by project

plugins {
    kotlin("jvm") version "1.8.20"
    id("io.ktor.plugin") version "2.2.4"
    id("org.flywaydb.flyway") version "8.5.4"
}

group = "com.newco"
version = "0.0.1"
application {
    mainClass.set("io.ktor.server.netty.EngineMain")

    val isDevelopment: Boolean = project.ext.has("development")
    applicationDefaultJvmArgs = listOf("-Dio.ktor.development=$isDevelopment")
}

repositories {
    mavenCentral()
}

dependencies {
    implementation("io.ktor:ktor-server-core-jvm:$ktor_version")
    implementation("io.ktor:ktor-server-auth-jvm:$ktor_version")
    implementation("io.ktor:ktor-server-auth-jwt-jvm:$ktor_version")
    implementation("io.ktor:ktor-server-content-negotiation-jvm:$ktor_version")
    implementation("io.ktor:ktor-serialization-jackson-jvm:$ktor_version")
    implementation("io.ktor:ktor-server-netty-jvm:$ktor_version")
    implementation("ch.qos.logback:logback-classic:$logback_version")

    // postgresql support
    implementation("org.postgresql:postgresql:42.2.2")

// database pooling
    implementation("com.zaxxer:HikariCP:2.7.8")

// database migration
    implementation("org.flywaydb:flyway-core:6.5.2")

    implementation("org.jetbrains.exposed:exposed-core:$exposed_version")
    implementation("org.jetbrains.exposed:exposed-dao:$exposed_version")
    implementation("org.jetbrains.exposed:exposed-jdbc:$exposed_version")
    testImplementation("io.ktor:ktor-server-tests-jvm:$ktor_version")
    testImplementation("org.jetbrains.kotlin:kotlin-test-junit:$kotlin_version")
}

 // apply flyway configuration
flyway {
    url = "jdbc:postgresql://127.0.0.1:5432/ledgerdb"
    driver = "org.postgresql.Driver"
    user = "postgres"
    password = "password1"
    schemas = arrayOf("ledgerdb")
    locations = arrayOf("filesystem:${projectDir}/src/main/resources/migration")
}
