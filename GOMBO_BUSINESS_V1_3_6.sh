#!/bin/bash

set -e

echo ""
echo "🚀 GOMBO BUSINESS V1.3.6 — Auto-remplissage enrichi & navigateur modernisé"
echo ""

PROJECT_NAME="GomboBusinessApp"
PACKAGE_NAME="com.gombobusiness.app"
PACKAGE_PATH="com/gombobusiness/app"
RES_DIR="$PROJECT_NAME/app/src/main/res"

# Date de build fixe du projet + date de mise à jour = date d'exécution de ce script
# (chaque nouvelle génération/modification du projet réécrit automatiquement cette date)
BUILD_DATE="22/06/2026"
UPDATE_DATE="$(date +%d/%m/%Y)"

echo "📁 Étape 1 : Nettoyage complet et initialisation de l'architecture..."
# On conserve un éventuel local.properties déjà configuré manuellement (chemin du SDK propre
# à cette machine) : il ne doit pas être perdu à chaque régénération du projet. La sauvegarde
# est placée à côté du projet (pas dans /tmp, indisponible tel quel sous Windows).
LOCAL_PROPERTIES_BACKUP="./.gombo_local_properties_backup"
if [ -f "$PROJECT_NAME/local.properties" ]; then
    cp "$PROJECT_NAME/local.properties" "$LOCAL_PROPERTIES_BACKUP" 2>/dev/null
fi
rm -rf "$PROJECT_NAME"

mkdir -p "$PROJECT_NAME/app/src/main/java/$PACKAGE_PATH/data/local"
mkdir -p "$PROJECT_NAME/app/src/main/java/$PACKAGE_PATH/data/remote"
mkdir -p "$PROJECT_NAME/app/src/main/java/$PACKAGE_PATH/data/repository"
mkdir -p "$PROJECT_NAME/app/src/main/java/$PACKAGE_PATH/domain/model"
mkdir -p "$PROJECT_NAME/app/src/main/java/$PACKAGE_PATH/domain/repository"
mkdir -p "$PROJECT_NAME/app/src/main/java/$PACKAGE_PATH/presentation/theme"
mkdir -p "$PROJECT_NAME/app/src/main/java/$PACKAGE_PATH/presentation/viewmodel"
mkdir -p "$PROJECT_NAME/app/src/main/java/$PACKAGE_PATH/presentation/ecrans"
mkdir -p "$PROJECT_NAME/app/src/main/java/$PACKAGE_PATH/presentation/navigation"
mkdir -p "$PROJECT_NAME/app/src/main/java/$PACKAGE_PATH/core"
mkdir -p "$RES_DIR/values"
mkdir -p "$RES_DIR/mipmap"
mkdir -p "$RES_DIR/xml"

echo "⚙️  Étape 2 : Configuration des scripts de build Gradle..."

cat << 'EOF' > "$PROJECT_NAME/gradle.properties"
org.gradle.jvmargs=-Xmx2048m -Dfile.encoding=UTF-8
android.useAndroidX=true
kotlin.code.style=official
android.nonTransitiveRClass=true
EOF

cat << 'EOF' > "$PROJECT_NAME/build.gradle.kts"
plugins {
id("com.android.application") version "8.3.2" apply false
id("org.jetbrains.kotlin.android") version "1.9.24" apply false
id("org.jetbrains.kotlin.plugin.serialization") version "1.9.24" apply false
}
EOF

cat << 'EOF' > "$PROJECT_NAME/settings.gradle.kts"
pluginManagement {
repositories {
google()
mavenCentral()
gradlePluginPortal()
}
}
dependencyResolutionManagement {
repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
repositories {
google()
mavenCentral()
}
}
rootProject.name = "GomboBusinessApp"
include(":app")
EOF

cat << 'EOF' > "$PROJECT_NAME/app/build.gradle.kts"
plugins {
id("com.android.application")
id("org.jetbrains.kotlin.android")
id("org.jetbrains.kotlin.plugin.serialization")
}

android {
namespace = "com.gombobusiness.app"
compileSdk = 34

defaultConfig {
    applicationId = "com.gombobusiness.app"
    minSdk = 24
    targetSdk = 34
    versionCode = 136
    versionName = "1.3.6"
    vectorDrawables { useSupportLibrary = true }
}

buildTypes {
    release {
        isMinifyEnabled = false
        proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
    }
}
compileOptions {
    sourceCompatibility = JavaVersion.VERSION_1_8
    targetCompatibility = JavaVersion.VERSION_1_8
}
kotlinOptions { jvmTarget = "1.8" }
buildFeatures { compose = true; buildConfig = true }
composeOptions { kotlinCompilerExtensionVersion = "1.5.14" }
packaging { resources { excludes += "/META-INF/{AL2.0,LGPL2.1}" } }
}

dependencies {
implementation("androidx.core:core-ktx:1.12.0")
implementation("androidx.lifecycle:lifecycle-runtime-ktx:2.7.0")
implementation("androidx.activity:activity-compose:1.8.2")
implementation(platform("androidx.compose:compose-bom:2024.04.01"))
implementation("androidx.compose.ui:ui")
implementation("androidx.compose.ui:ui-graphics")
implementation("androidx.compose.ui:ui-tooling-preview")
implementation("androidx.compose.material3:material3")
implementation("androidx.compose.material:material-icons-extended")
implementation("androidx.navigation:navigation-compose:2.7.7")
implementation("androidx.lifecycle:lifecycle-viewmodel-compose:2.7.0")

implementation("io.coil-kt:coil-compose:2.6.0")
implementation("io.coil-kt:coil-gif:2.6.0")
// V1.3 : nécessaire pour charger les icônes de contact (Email/WhatsApp/LinkedIn/GitHub)
// directement depuis internet au format vectoriel (SVG) sur l'écran "À propos de moi".
implementation("io.coil-kt:coil-svg:2.6.0")

implementation("com.squareup.retrofit2:retrofit:2.11.0")
implementation("com.jakewharton.retrofit:retrofit2-kotlinx-serialization-converter:1.0.0")
implementation("com.squareup.okhttp3:okhttp:4.12.0")
implementation("org.jetbrains.kotlinx:kotlinx-serialization-json:1.6.3")

// Navigateur intégré V1.3 : stockage chiffré pour l'auto-remplissage et le gestionnaire de mots de passe
implementation("androidx.security:security-crypto:1.1.0-alpha06")

// V1.4 : Custom Tabs, utilisées pour ouvrir les connexions Google/Apple dans un vrai
// navigateur (Chrome) — Google bloque volontairement ces connexions dans une WebView
// embarquée générique, quel que soit le user-agent utilisé.
implementation("androidx.browser:browser:1.8.0")

// V1.3.2 : androidx.webkit, nécessaire pour désactiver proprement (et de façon
// rétro-compatible, via WebViewFeature.isFeatureSupported) l'assombrissement
// algorithmique automatique du WebView — correctif du bug Delta (page qui n'affichait
// que son arrière-plan, sans logo/texte/icônes/boutons visibles).
implementation("androidx.webkit:webkit:1.11.0")
}
EOF

echo "📄 Étape 3 : Manifest & Ressources graphiques..."

cat << 'EOF' > "$PROJECT_NAME/app/src/main/AndroidManifest.xml"
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android">

    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
    <!-- V1.3.1 : nécessaire pour déclencher automatiquement l'écran d'installation natif
         de l'APK téléchargé (mise à jour in-app), sans jamais passer par un navigateur. -->
    <uses-permission android:name="android.permission.REQUEST_INSTALL_PACKAGES" />

    <application
        android:allowBackup="true"
        android:icon="@mipmap/ic_launcher"
        android:roundIcon="@mipmap/ic_launcher_round"
        android:label="@string/app_name"
        android:theme="@style/Theme.GomboBusiness"
        android:usesCleartextTraffic="false">

        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:theme="@style/Theme.GomboBusiness"
            android:windowSoftInputMode="adjustResize">
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
        </activity>

        <!-- V1.3.1 : FileProvider requis pour ouvrir l'écran d'installation natif Android
             sur l'APK téléchargé en arrière-plan (mise à jour in-app autonome). -->
        <provider
            android:name="androidx.core.content.FileProvider"
            android:authorities="com.gombobusiness.app.fileprovider"
            android:exported="false"
            android:grantUriPermissions="true">
            <meta-data
                android:name="android.support.FILE_PROVIDER_PATHS"
                android:resource="@xml/file_paths" />
        </provider>

    </application>
</manifest>
EOF

cat << 'EOF' > "$RES_DIR/xml/file_paths.xml"
<?xml version="1.0" encoding="utf-8"?>
<paths xmlns:android="http://schemas.android.com/apk/res/android">
    <!-- V1.3.1 : correspond au dossier utilisé par GestionnaireMiseAJour
         (context.getExternalFilesDir(Environment.DIRECTORY_DOWNLOADS)) pour stocker
         l'APK téléchargé avant de lancer l'installation. -->
    <external-files-path name="mise_a_jour" path="Download/" />
</paths>
EOF

cat << 'EOF' > "$RES_DIR/values/strings.xml"
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <string name="app_name">Gombo Business</string>
</resources>
EOF

cat << 'EOF' > "$RES_DIR/values/themes.xml"
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <style name="Theme.GomboBusiness" parent="android:Theme.Material.NoActionBar">
        <item name="android:windowNoTitle">true</item>
        <item name="android:windowActionBar">false</item>
        <item name="android:statusBarColor">#0A0A0C</item>
        <item name="android:navigationBarColor">#0A0A0C</item>
        <item name="android:windowBackground">#0A0A0C</item>
    </style>
</resources>
EOF

cat << 'EOF' > "$PROJECT_NAME/app/proguard-rules.pro"
# Règles vides, minification désactivée
EOF

cat << 'EOF' > "$RES_DIR/mipmap/ic_launcher.xml"
<?xml version="1.0" encoding="utf-8"?>
<vector xmlns:android="http://schemas.android.com/apk/res/android" android:width="108dp" android:height="108dp" android:viewportWidth="108" android:viewportHeight="108">
    <path android:pathData="M0,0h108v108h-108z" android:fillColor="#0A0A0C" />
    <path android:pathData="M54,24 C72.7,24 88,39.3 88,58 C88,76.7 72.7,92 54,92 C35.3,92 20,76.7 20,58 C20,39.3 35.3,24 54,24 Z M54,32 C39.6,32 28,43.6 28,58 C28,72.4 39.6,84 54,84 C68.4,84 80,72.4 80,58 C80,43.6 68.4,32 54,32 Z" android:fillColor="#00E676" />
    <path android:pathData="M44,66 L44,44 L50,44 L50,60 L64,44 L71,44 L57,60 L71,72 L64,72 L52,60 L50,62 L50,66 Z" android:fillColor="#00E676" />
</vector>
EOF

cat << 'EOF' > "$RES_DIR/mipmap/ic_launcher_round.xml"
<?xml version="1.0" encoding="utf-8"?>
<vector xmlns:android="http://schemas.android.com/apk/res/android" android:width="108dp" android:height="108dp" android:viewportWidth="108" android:viewportHeight="108">
    <path android:pathData="M54,0 C83.8,0 108,24.2 108,54 C108,83.8 83.8,108 54,108 C24.2,108 0,83.8 0,54 C0,24.2 24.2,0 54,0 Z" android:fillColor="#0A0A0C" />
    <path android:pathData="M54,24 C72.7,24 88,39.3 88,58 C88,76.7 72.7,92 54,92 C35.3,92 20,76.7 20,58 C20,39.3 35.3,24 54,24 Z M54,32 C39.6,32 28,43.6 28,58 C28,72.4 39.6,84 54,84 C68.4,84 80,72.4 80,58 C80,43.6 68.4,32 54,32 Z" android:fillColor="#00E676" />
    <path android:pathData="M44,66 L44,44 L50,44 L50,60 L64,44 L71,44 L57,60 L71,72 L64,72 L52,60 L50,62 L50,66 Z" android:fillColor="#00E676" />
</vector>
EOF

echo "🌍 Étape 4 : État Global & Préférences (Apparence avancée, Browser)..."

cat << 'EOF' > "$PROJECT_NAME/app/src/main/java/$PACKAGE_PATH/core/NetworkMonitor.kt"
package com.gombobusiness.app.core

import android.content.Context
import android.net.ConnectivityManager
import android.net.Network
import android.net.NetworkCapabilities
import android.net.NetworkRequest
import kotlinx.coroutines.channels.awaitClose
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.callbackFlow

class NetworkConnectivityObserver(context: Context) {
    private val connectivityManager = context.getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager

    val isOnline: Flow<Boolean> = callbackFlow {
        val callback = object : ConnectivityManager.NetworkCallback() {
            override fun onAvailable(network: Network) { trySend(true) }
            override fun onLost(network: Network) { trySend(false) }
        }
        val request = NetworkRequest.Builder().addCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET).build()
        connectivityManager.registerNetworkCallback(request, callback)

        val activeNetwork = connectivityManager.activeNetwork
        val isCurrentlyOnline = activeNetwork != null && connectivityManager.getNetworkCapabilities(activeNetwork)?.hasCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET) == true
        trySend(isCurrentlyOnline)

        awaitClose { connectivityManager.unregisterNetworkCallback(callback) }
    }
}
EOF

cat << 'EOF' > "$PROJECT_NAME/app/src/main/java/$PACKAGE_PATH/data/local/PreferencesManager.kt"
package com.gombobusiness.app.data.local
import android.content.Context
import android.content.SharedPreferences

class PreferencesManager(context: Context) {
private val prefs: SharedPreferences = context.getSharedPreferences("gombo_premium_prefs_v13", Context.MODE_PRIVATE)

fun getTheme(): String = prefs.getString("current_theme_v14", "Éclipse Totale") ?: "Éclipse Totale"
fun setTheme(theme: String) = prefs.edit().putString("current_theme_v14", theme).apply()

fun getLangue(): String = prefs.getString("langue_v13", "fr") ?: "fr"
fun setLangue(lang: String) = prefs.edit().putString("langue_v13", lang).apply()

fun getFontSize(): Float = prefs.getFloat("font_size_v13", 1.0f)
fun setFontSize(size: Float) = prefs.edit().putFloat("font_size_v13", size).apply()

fun getLayoutMode(): String = prefs.getString("layout_mode_v14", "Compacte") ?: "Compacte"
fun setLayoutMode(mode: String) = prefs.edit().putString("layout_mode_v14", mode).apply()

fun getCardShape(): String = prefs.getString("card_shape_v14", "Maximal") ?: "Maximal"
fun setCardShape(shape: String) = prefs.edit().putString("card_shape_v14", shape).apply()

fun getButtonShape(): String = prefs.getString("btn_shape_v14", "Pilule") ?: "Pilule"
fun setButtonShape(shape: String) = prefs.edit().putString("btn_shape_v14", shape).apply()

// V1.3.3 : animation de FOND choisie par l'utilisateur dans Paramètres > Apparence (5
// variantes). "Orbite Lumineuse" reste l'animation par défaut (ancien fond unique).
fun getBackgroundAnimation(): String = prefs.getString("background_animation_v133", "Orbite Lumineuse") ?: "Orbite Lumineuse"
fun setBackgroundAnimation(style: String) = prefs.edit().putString("background_animation_v133", style).apply()

fun getLastVersion(): String = prefs.getString("last_version_opened", "0.0") ?: "0.0"
fun setLastVersion(version: String) = prefs.edit().putString("last_version_opened", version).apply()
}
EOF

echo "🔐 Étape 4bis : Auto-remplissage & Gestionnaire de mots de passe (navigateur intégré)..."

cat << 'EOF' > "$PROJECT_NAME/app/src/main/java/$PACKAGE_PATH/data/local/SecureAutofillStore.kt"
package com.gombobusiness.app.data.local

import android.content.Context
import android.content.SharedPreferences
import androidx.security.crypto.EncryptedSharedPreferences
import androidx.security.crypto.MasterKey
import kotlinx.serialization.Serializable
import kotlinx.serialization.encodeToString
import kotlinx.serialization.decodeFromString
import kotlinx.serialization.json.Json

/**
 * V1.3 corrigée (point 4, sections D et E) : auto-remplissage intelligent + gestionnaire
 * de mots de passe pour le navigateur intégré.
 *
 * Toutes les données (profil et identifiants) sont stockées via EncryptedSharedPreferences,
 * chiffrées avec une clé gérée par l'Android Keystore (AES256-GCM). Rien n'est jamais
 * envoyé en clair ni stocké hors de ce fichier chiffré local à l'appareil.
 */
@Serializable
data class ProfilAutofill(
    val nomComplet: String = "", val nom: String = "", val prenom: String = "", val nomUtilisateur: String = "",
    val email: String = "", val telephone: String = "", val adresse: String = "",
    // V1.3.2 : indicatif téléphonique (ex : +228), auto-rempli sur les champs de type
    // "indicatif"/"dial code" des formulaires, et mot de passe par défaut, auto-rempli sur
    // les champs "mot de passe" ET "confirmation du mot de passe" lors d'une inscription
    // sur un nouveau site (tant qu'aucun mot de passe spécifique n'a déjà été enregistré
    // pour ce site précis, auquel cas ce dernier reste toujours prioritaire).
    val indicatifTelephone: String = "", val motDePasseParDefaut: String = "",
    // V1.3.4.1 : date de naissance, sélectionnée via un petit calendrier (jour/mois/année) et
    // stockée en interne au format ISO "AAAA-MM-JJ" — ce même format ISO est directement compris
    // par les champs <input type="date"> lors de l'auto-remplissage des formulaires web.
    val dateNaissance: String = "",
    // V1.3.6 : champs complémentaires fréquemment demandés par les formulaires d'inscription
    // (crypto, paris sportifs...) — ville, code postal, pays et genre, auto-remplis eux aussi.
    val ville: String = "", val codePostal: String = "", val pays: String = "", val sexe: String = ""
)

@Serializable
data class IdentifiantEnregistre(val domaine: String, val identifiant: String, val motDePasse: String)

class SecureAutofillStore(context: Context) {
    private val masterKey = MasterKey.Builder(context)
        .setKeyScheme(MasterKey.KeyScheme.AES256_GCM)
        .build()

    private val prefs: SharedPreferences = EncryptedSharedPreferences.create(
        context, "gombo_autofill_secure_v13", masterKey,
        EncryptedSharedPreferences.PrefKeyEncryptionScheme.AES256_SIV,
        EncryptedSharedPreferences.PrefValueEncryptionScheme.AES256_GCM
    )

    private val json = Json { ignoreUnknownKeys = true; encodeDefaults = true }

    fun getProfil(): ProfilAutofill {
        val raw = prefs.getString("profil_json", null) ?: return ProfilAutofill()
        return try { json.decodeFromString(raw) } catch (e: Exception) { ProfilAutofill() }
    }

    fun setProfil(profil: ProfilAutofill) {
        prefs.edit().putString("profil_json", json.encodeToString(profil)).apply()
    }

    fun getIdentifiants(): List<IdentifiantEnregistre> {
        val raw = prefs.getString("identifiants_json", null) ?: return emptyList()
        return try { json.decodeFromString(raw) } catch (e: Exception) { emptyList() }
    }

    private fun saveIdentifiants(liste: List<IdentifiantEnregistre>) {
        prefs.edit().putString("identifiants_json", json.encodeToString(liste)).apply()
    }

    fun getIdentifiantPour(domaine: String): IdentifiantEnregistre? =
        getIdentifiants().firstOrNull { it.domaine.equals(domaine, ignoreCase = true) }

    /** Enregistre un nouvel identifiant ou met à jour celui déjà présent pour ce domaine. */
    fun enregistrerOuMettreAJour(domaine: String, identifiant: String, motDePasse: String) {
        val liste = getIdentifiants().toMutableList()
        val indexExistant = liste.indexOfFirst { it.domaine.equals(domaine, ignoreCase = true) }
        val entree = IdentifiantEnregistre(domaine, identifiant, motDePasse)
        if (indexExistant >= 0) liste[indexExistant] = entree else liste.add(entree)
        saveIdentifiants(liste)
    }

    fun supprimerIdentifiant(domaine: String) {
        saveIdentifiants(getIdentifiants().filterNot { it.domaine.equals(domaine, ignoreCase = true) })
    }

    // V1.3.5 : verrouillage optionnel de la section Auto-remplissage & Mots de passe par un
    // code à 4 chiffres (données déjà chiffrées via EncryptedSharedPreferences ci-dessus ; le
    // code lui-même n'est jamais stocké en clair, seule son empreinte SHA-256 l'est).
    fun estVerrouActif(): Boolean = prefs.getBoolean("verrou_actif", false)

    private fun empreinte(code: String): String =
        java.security.MessageDigest.getInstance("SHA-256").digest(code.toByteArray())
            .joinToString("") { "%02x".format(it) }

    /** Active le verrou et enregistre le code (4 chiffres) choisi par l'utilisateur. */
    fun activerVerrou(code: String) {
        prefs.edit().putBoolean("verrou_actif", true).putString("verrou_code_hash", empreinte(code)).apply()
    }

    fun desactiverVerrou() {
        prefs.edit().putBoolean("verrou_actif", false).remove("verrou_code_hash").apply()
    }

    fun codeCorrect(code: String): Boolean {
        val hashEnregistre = prefs.getString("verrou_code_hash", null) ?: return false
        return hashEnregistre == empreinte(code)
    }
}
EOF

echo "🕘 Étape 4ter : Historique de navigation du navigateur intégré..."

cat << 'EOF' > "$PROJECT_NAME/app/src/main/java/$PACKAGE_PATH/data/local/HistoriqueNavigationStore.kt"
package com.gombobusiness.app.data.local

import android.content.Context
import android.content.SharedPreferences
import kotlinx.serialization.Serializable
import kotlinx.serialization.encodeToString
import kotlinx.serialization.decodeFromString
import kotlinx.serialization.json.Json

/**
 * V1.3 : historique de navigation du navigateur intégré. Conserve les pages les plus
 * récemment visitées (URL + titre + date) afin de permettre à l'utilisateur d'y revenir
 * facilement via le nouveau bouton d'historique de la barre de navigation interne.
 */
@Serializable
data class EntreeHistoriqueNavigation(val url: String, val titre: String, val dateVisite: String)

class HistoriqueNavigationStore(context: Context) {
    private val prefs: SharedPreferences = context.getSharedPreferences("gombo_historique_nav_v13", Context.MODE_PRIVATE)
    private val json = Json { ignoreUnknownKeys = true; encodeDefaults = true }
    private val limiteEntrees = 60

    fun getHistorique(): List<EntreeHistoriqueNavigation> {
        val raw = prefs.getString("historique_json", null) ?: return emptyList()
        return try { json.decodeFromString(raw) } catch (e: Exception) { emptyList() }
    }

    fun ajouter(url: String, titre: String) {
        if (url.isBlank()) return
        val horodatage = java.text.SimpleDateFormat("dd/MM/yyyy HH:mm", java.util.Locale.getDefault()).format(java.util.Date())
        val liste = getHistorique().filterNot { it.url == url }.toMutableList()
        liste.add(0, EntreeHistoriqueNavigation(url, titre.ifBlank { url }, horodatage))
        prefs.edit().putString("historique_json", json.encodeToString(liste.take(limiteEntrees))).apply()
    }

    fun effacer() { prefs.edit().remove("historique_json").apply() }
}
EOF

cat << 'EOF' > "$PROJECT_NAME/app/src/main/java/$PACKAGE_PATH/data/local/InteractionsStore.kt"
package com.gombobusiness.app.data.local

import android.content.Context
import android.content.SharedPreferences

/**
 * V1.3.4.2 : petit stockage local (indépendant du cache réseau) qui retient, par carte
 * (identifiée par son titre — les fichiers JSON distants n'ont pas d'identifiant unique dédié),
 * une information purement locale à l'appareil :
 * - "termines" : cartes marquées "fait" par l'utilisateur (peuvent ensuite être masquées).
 * Volontairement simple (SharedPreferences + Set<String>) : cette information n'a pas besoin
 * d'être synchronisée entre appareils ni de survivre à une désinstallation.
 * V1.3.4.3 : les favoris (cœur) ont été entièrement retirés (fonctions estFavori/toggleFavori
 * supprimées) — la fonctionnalité n'existait déjà plus dans l'interface, ce nettoyage retire
 * le code correspondant devenu inutile.
 * V1.3.5 : la pastille "NOUVEAU" (et son suivi "vus"/estNouveau/marquerVu) a été retirée sur
 * demande explicite.
 */
class InteractionsStore(context: Context) {
    private val prefs: SharedPreferences = context.getSharedPreferences("gombo_interactions_v1", Context.MODE_PRIVATE)

    private fun lire(cle: String): Set<String> = prefs.getStringSet(cle, emptySet()) ?: emptySet()
    private fun ecrire(cle: String, valeurs: Set<String>) { prefs.edit().putStringSet(cle, valeurs).apply() }

    fun estTermine(id: String): Boolean = lire("termines").contains(id)
    fun toggleTermine(id: String) { val s = lire("termines").toMutableSet(); if (!s.remove(id)) s.add(id); ecrire("termines", s) }
}
EOF

cat << 'EOF' > "$PROJECT_NAME/app/src/main/java/$PACKAGE_PATH/data/local/DonneesCacheStore.kt"
package com.gombobusiness.app.data.local

import android.content.Context
import android.content.SharedPreferences
import kotlinx.serialization.encodeToString
import kotlinx.serialization.decodeFromString
import kotlinx.serialization.json.Json

/**
 * V1.3.3 : cache local des données JSON synchronisées depuis GitHub (airdrops, wallet/
 * exchange, pronostics, inscriptions). Objectif double :
 * 1) Afficher INSTANTANÉMENT la dernière version connue de ces données au démarrage de
 *    l'application, avant même qu'une connexion internet ne soit établie ou confirmée,
 *    au lieu d'un écran vide le temps du premier chargement réseau.
 * 2) Ne plus jamais faire disparaître les données déjà affichées en cas de coupure réseau
 *    passagère (auparavant, un échec réseau retombait sur une liste vide).
 * Le rafraîchissement en arrière-plan (voir AppRepositoryImpl) écrase ce cache dès qu'un
 * chargement réseau réussit, afin de toujours converger vers les données les plus fraîches.
 */
class DonneesCacheStore(context: Context) {
    // V1.3.4 CORRIGÉ : les fonctions inline (nécessaires pour le "reified T" générique) ne
    // peuvent pas accéder à des membres "private" — Kotlin refuse de compiler une fonction
    // publique qui inlinerait une référence privée. @PublishedApi internal résout cela : les
    // deux propriétés restent invisibles en dehors du module, tout en étant utilisables par
    // les fonctions inline ci-dessous.
    @PublishedApi internal val prefs: SharedPreferences = context.getSharedPreferences("gombo_cache_donnees_v133", Context.MODE_PRIVATE)
    @PublishedApi internal val json = Json { ignoreUnknownKeys = true; encodeDefaults = true }

    inline fun <reified T> lire(cle: String): List<T> {
        val brut = prefs.getString(cle, null) ?: return emptyList()
        return try { json.decodeFromString<List<T>>(brut) } catch (e: Exception) { emptyList() }
    }

    inline fun <reified T> ecrire(cle: String, valeurs: List<T>) {
        if (valeurs.isEmpty()) return
        try { prefs.edit().putString(cle, json.encodeToString(valeurs)).apply() } catch (e: Exception) {}
    }

    // V1.3.4.2 : horodatage de la dernière synchronisation réussie avec GitHub — utilisé pour
    // afficher, en mode hors-ligne, la date des données actuellement affichées ("Mode
    // hors-ligne - Données du ...") plutôt qu'un simple message d'erreur vide.
    fun ecrireHorodatage() { try { prefs.edit().putLong("derniere_synchro", System.currentTimeMillis()).apply() } catch (e: Exception) {} }
    fun lireHorodatage(): Long = try { prefs.getLong("derniere_synchro", 0L) } catch (e: Exception) { 0L }
}
EOF

echo "⬇️  Étape 4quater : Système de mise à jour in-app (téléchargement & installation autonome)..."

cat << 'EOF' > "$PROJECT_NAME/app/src/main/java/$PACKAGE_PATH/core/GestionnaireMiseAJour.kt"
package com.gombobusiness.app.core

import android.app.DownloadManager
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Environment
import androidx.core.content.FileProvider
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import java.io.File

/**
 * V1.3.1 : gestionnaire de mise à jour in-app. Une fois l'utilisateur d'accord, l'APK
 * fourni par update.json est téléchargé directement en arrière-plan via le DownloadManager
 * natif d'Android (aucun navigateur, aucune page GitHub jamais visible à l'utilisateur),
 * avec une progression de 0 à 100 % exposée via [progression]. Une fois le téléchargement
 * terminé, l'écran d'installation natif d'Android est déclenché automatiquement grâce à un
 * FileProvider (compatible avec le stockage encadré/"scoped storage" de toutes les versions
 * d'Android prises en charge par l'application).
 */
class GestionnaireMiseAJour(private val context: Context) {

    // -1 = inactif, 0..99 = téléchargement en cours, 100 = terminé (installation lancée), -2 = échec
    private val _progression = MutableStateFlow(-1)
    val progression: StateFlow<Int> = _progression

    private var idTelechargementEnCours: Long = -1L

    fun telechargerEtInstaller(apkUrl: String, nomFichier: String = "gombo_business_update.apk") {
        if (apkUrl.isBlank()) return
        val gestionnaire = context.getSystemService(Context.DOWNLOAD_SERVICE) as DownloadManager
        val dossierDestination = context.getExternalFilesDir(Environment.DIRECTORY_DOWNLOADS)
        val fichierApk = File(dossierDestination, nomFichier)
        if (fichierApk.exists()) fichierApk.delete()

        val requete = DownloadManager.Request(Uri.parse(apkUrl))
            .setTitle("Gombo Business")
            .setDescription("Téléchargement de la mise à jour...")
            .setNotificationVisibility(DownloadManager.Request.VISIBILITY_VISIBLE_NOTIFY_COMPLETED)
            .setDestinationUri(Uri.fromFile(fichierApk))
            .setAllowedOverMetered(true)
            .setAllowedOverRoaming(true)

        idTelechargementEnCours = gestionnaire.enqueue(requete)
        _progression.value = 0
        surveillerProgression(gestionnaire, fichierApk)
    }

    /** Interroge périodiquement le DownloadManager (aucune diffusion native de progression). */
    private fun surveillerProgression(gestionnaire: DownloadManager, fichierApk: File) {
        Thread {
            var enCours = true
            while (enCours) {
                try {
                    val curseur = gestionnaire.query(DownloadManager.Query().setFilterById(idTelechargementEnCours))
                    if (curseur.moveToFirst()) {
                        val colStatut = curseur.getColumnIndex(DownloadManager.COLUMN_STATUS)
                        val colFait = curseur.getColumnIndex(DownloadManager.COLUMN_BYTES_DOWNLOADED_SO_FAR)
                        val colTotal = curseur.getColumnIndex(DownloadManager.COLUMN_TOTAL_SIZE_BYTES)
                        val statut = curseur.getInt(colStatut)
                        val octetsFaits = curseur.getLong(colFait)
                        val octetsTotal = curseur.getLong(colTotal)

                        if (octetsTotal > 0) {
                            _progression.value = ((octetsFaits * 100L) / octetsTotal).toInt().coerceIn(0, 99)
                        }
                        when (statut) {
                            DownloadManager.STATUS_SUCCESSFUL -> { _progression.value = 100; enCours = false; lancerInstallation(fichierApk) }
                            DownloadManager.STATUS_FAILED -> { _progression.value = -2; enCours = false }
                        }
                    } else { enCours = false }
                    curseur.close()
                } catch (e: Exception) { enCours = false; _progression.value = -2 }
                if (enCours) Thread.sleep(350)
            }
        }.start()
    }

    private fun lancerInstallation(fichierApk: File) {
        try {
            val uriApk = FileProvider.getUriForFile(context, "com.gombobusiness.app.fileprovider", fichierApk)
            val intentInstallation = Intent(Intent.ACTION_VIEW).apply {
                setDataAndType(uriApk, "application/vnd.android.package-archive")
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_GRANT_READ_URI_PERMISSION)
            }
            context.startActivity(intentInstallation)
        } catch (e: Exception) { _progression.value = -2 }
    }

    fun reinitialiser() { _progression.value = -1 }
}
EOF

cat << 'EOF' > "$PROJECT_NAME/app/src/main/java/$PACKAGE_PATH/core/GlobalState.kt"
package com.gombobusiness.app.core
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.widget.Toast
import androidx.compose.runtime.MutableState
import androidx.compose.runtime.compositionLocalOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.mutableStateListOf
import androidx.compose.runtime.mutableFloatStateOf
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import com.gombobusiness.app.data.local.SecureAutofillStore
import com.gombobusiness.app.data.local.HistoriqueNavigationStore
// V1.3.4.2 : favoris / cartes terminées / badge "nouveau".
import com.gombobusiness.app.data.local.InteractionsStore

val LocalAppTheme = compositionLocalOf { mutableStateOf("Éclipse Totale") }
val LocalLangue = compositionLocalOf { mutableStateOf("fr") }
// V1.3.2 : valeur par défaut prudente = hors ligne. Tant que l'état réseau réel n'a pas
// encore été déterminé (juste après le lancement de l'app), on considère qu'il n'y a PAS
// de connexion plutôt que l'inverse — cela évite de déclencher à tort une vérification de
// mise à jour (ou tout autre appel réseau automatique) avant même de savoir si l'appareil
// est réellement connecté à Internet.
val LocalIsOnline = compositionLocalOf { false }
val LocalFontSize = compositionLocalOf { mutableFloatStateOf(1.0f) }
val LocalLayoutMode = compositionLocalOf { mutableStateOf("Compacte") }
val LocalCardShape = compositionLocalOf { mutableStateOf("Maximal") }
val LocalButtonShape = compositionLocalOf { mutableStateOf("Pilule") }
// V1.3.3 : animations de transition entre écrans supprimées (navigation instantanée).
// V1.3.3 : style d'animation de FOND choisi par l'utilisateur dans Paramètres > Apparence,
// appliqué globalement par ConteneurNavigationPrincipal (voir AppNavigation.kt) au fond
// animé affiché derrière toute l'application.
val LocalBackgroundAnimation = compositionLocalOf { mutableStateOf("Orbite Lumineuse") }

/**
 * V1.3.3 CORRIGÉ : le Toast système Android.setGravity(TOP) ne garantit plus rien sur les
 * versions récentes d'Android (le système peut replacer le message vers le bas de l'écran
 * pour les applications ciblant les API récentes, quel que soit le gravity demandé) — c'est
 * ce qui faisait réapparaître les messages en bas, au-dessus de la barre de navigation,
 * malgré le correctif de la V1.3.2. Pour garantir un affichage TOUJOURS en haut de l'écran,
 * quel que soit l'appareil ou la version d'Android, les messages passent désormais par une
 * bannière recréée entièrement en Compose (voir GombobusinessToastHost + BanniereToast dans
 * AppNavigation.kt) plutôt que par le Toast natif du système, qui n'est plus utilisé du tout.
 */
data class MessageToastGombo(val texte: String, val id: Long = System.nanoTime())

object GombobusinessToastHost {
    private val _message = MutableStateFlow<MessageToastGombo?>(null)
    val message: StateFlow<MessageToastGombo?> = _message.asStateFlow()
    fun afficher(texte: String) { _message.value = MessageToastGombo(texte) }
}

fun toastEnHaut(context: Context, message: String, duree: Int = Toast.LENGTH_SHORT) {
    GombobusinessToastHost.afficher(message)
}

/**
 * V1.3.2 : liste des plateformes dont les liens doivent impérativement s'ouvrir dans leur
 * application native (YouTube, Play Store, App Store, WhatsApp, Telegram, réseaux sociaux)
 * plutôt que dans le navigateur intégré de l'application.
 */
fun estLienApplicationExterne(url: String): Boolean {
    val hotes = listOf(
        "play.google.com", "market://", "apps.apple.com",
        "youtube.com", "youtu.be", "m.youtube.com",
        "whatsapp.com", "wa.me", "api.whatsapp.com",
        "t.me", "telegram.me", "telegram.org",
        "instagram.com", "facebook.com", "fb.com", "m.facebook.com",
        "twitter.com", "x.com"
    )
    return hotes.any { url.contains(it, ignoreCase = true) }
}

/**
 * V1.3.2 : point d'entrée unique utilisé par tous les boutons "Rejoindre"/"Regarder"/
 * "S'inscrire" de l'application. Si le lien correspond à une plateforme native connue
 * (YouTube, Play Store, WhatsApp...), il s'ouvre directement dans l'application dédiée ;
 * sinon il s'ouvre dans le navigateur intégré, comme avant. Si l'application visée n'est
 * pas installée sur l'appareil, on se replie automatiquement sur le navigateur intégré
 * pour ne jamais laisser l'utilisateur bloqué.
 */
fun ouvrirLien(context: Context, browser: BrowserController, url: String?) {
    if (url.isNullOrBlank()) return
    if (estLienApplicationExterne(url)) {
        try {
            context.startActivity(Intent(Intent.ACTION_VIEW, Uri.parse(url)))
            return
        } catch (e: Exception) { /* application non installée : repli sur le navigateur intégré */ }
    }
    browser.open(url)
}

/** V1.3.2 : représente un onglet ouvert dans le navigateur intégré (titre + URL). */
data class OngletNavigateur(val id: String, var url: String, var titre: String = "")

class BrowserController(val url: MutableState<String>, val isVisible: MutableState<Boolean>) {
    // État "minimisé" distinct de la fermeture : la session (et la WebView) reste vivante
    // en arrière-plan tant que l'utilisateur ne ferme pas explicitement le navigateur.
    val isMinimized = mutableStateOf(false)

    // V1.3.2 : navigation par onglets. Une seule WebView physique est réutilisée (rechargée
    // à l'URL de l'onglet actif), mais chaque onglet ouvert précédemment reste mémorisé et
    // accessible via le sélecteur d'onglets, sans jamais être perdu tant qu'il n'est pas
    // explicitement fermé par l'utilisateur.
    val onglets = mutableStateListOf<OngletNavigateur>()
    val ongletActifId = mutableStateOf("")

    /** Ouvre un lien dans un NOUVEL onglet, en conservant les onglets déjà ouverts. */
    fun open(newUrl: String) {
        val nouvelId = "onglet_${System.currentTimeMillis()}_${onglets.size}"
        onglets.add(OngletNavigateur(nouvelId, newUrl))
        ongletActifId.value = nouvelId
        url.value = newUrl
        isVisible.value = true
        isMinimized.value = false
    }

    fun basculerVersOnglet(id: String) {
        val cible = onglets.firstOrNull { it.id == id } ?: return
        ongletActifId.value = id
        url.value = cible.url
        isVisible.value = true
        isMinimized.value = false
    }

    fun fermerOnglet(id: String) {
        onglets.removeAll { it.id == id }
        if (ongletActifId.value == id) {
            val suivant = onglets.lastOrNull()
            if (suivant != null) { ongletActifId.value = suivant.id; url.value = suivant.url }
            else { close() }
        }
    }

    /** Met à jour l'URL/titre mémorisés pour l'onglet actif, appelé après chaque chargement de page. */
    fun mettreAJourOngletActif(newUrl: String, titre: String) {
        val actif = onglets.firstOrNull { it.id == ongletActifId.value } ?: return
        if (newUrl.isNotBlank()) actif.url = newUrl
        if (titre.isNotBlank()) actif.titre = titre
    }

    fun close() { isVisible.value = false; isMinimized.value = false; url.value = ""; onglets.clear(); ongletActifId.value = "" }
    fun minimize() { isVisible.value = false; isMinimized.value = true }
    fun restore() { isVisible.value = true; isMinimized.value = false }
}
val LocalBrowserController = compositionLocalOf<BrowserController> { error("BrowserController non fourni") }
val LocalAutofillStore = compositionLocalOf<SecureAutofillStore> { error("SecureAutofillStore non fourni") }
val LocalHistoriqueNavStore = compositionLocalOf<HistoriqueNavigationStore> { error("HistoriqueNavigationStore non fourni") }
val LocalGestionnaireMiseAJour = compositionLocalOf<GestionnaireMiseAJour> { error("GestionnaireMiseAJour non fourni") }
// V1.3.4.2 : favoris / cartes terminées / badge "nouveau" (voir InteractionsStore).
val LocalInteractionsStore = compositionLocalOf<InteractionsStore> { error("InteractionsStore non fourni") }

/**
 * V1.3.5 CORRIGÉ : chaque carte (PremiumGlassCard) créait auparavant sa PROPRE animation
 * continue (rememberInfiniteTransition) pour son très léger balancement 3D — avec parfois
 * une dizaine de cartes visibles à l'écran, cela revenait à faire tourner une dizaine
 * d'animations indépendantes en permanence, ce qui ralentissait l'application. Une seule
 * animation partagée est désormais fournie ici (voir MainActivity) et simplement lue par
 * chaque carte — même rendu visuel, un seul calcul au lieu d'un par carte.
 */
val LocalBasculeIdleCarte = compositionLocalOf { 0f }

/** V1.3.5 CORRIGÉ : même principe que LocalBasculeIdleCarte ci-dessus, pour la respiration
 * des badges d'icônes (IconeBadge3D) — une seule animation partagée au lieu d'une par badge. */
val LocalRespirationBadge = compositionLocalOf { 1.0f }

object Traductions {
fun getString(cle: String, langue: String): String {
val dict = mapOf(
"fr" to mapOf(
"copier" to "Copier", "copie_ok" to "Copié", "rejoindre" to "Rejoindre", "sinscrire" to "S'inscrire",
"regarder" to "Regarder", "aucun_airdrop" to "Aucun airdrop", "aucun_prono" to "Aucun pronostic",
"aucune_inscr" to "Aucune offre", "nav_acc" to "Accueil", "nav_air" to "Airdrops", "nav_spo" to "Sports",
"nav_set" to "Paramètres", "onglet_insc" to "Inscriptions", "onglet_prono" to "Pronostics", "prono_titre" to "Prono : ",
"cote_titre" to "Cote : ", "score_titre" to "Score : ", "theme_title" to "Thèmes de couleur", "lang_title" to "Langue",
"size_title" to "Taille d'affichage", "search_airdrop" to "Rechercher un airdrop...", "effacer_recherche" to "Effacer la recherche",
"layout_title" to "Densité de l'interface", "apparence" to "Apparence", "nouveautes" to "Nouveautés de la version", "retour" to "Retour", "fermer" to "Fermer",
"card_shape_title" to "Forme des cartes", "btn_shape_title" to "Forme des boutons",
// V1.3.3 : animations de FOND sélectionnables (Paramètres > Apparence), en remplacement
// des anciennes animations de transition entre écrans (désormais supprimées).
"animation_title" to "Animations de fond",
// V1.3.3 : Wallet / Exchange redevient une sous-page d'Airdrops (au lieu d'un onglet
// séparé de la barre de navigation du bas).
"nav_wallet" to "Wallet", "search_wallet" to "Rechercher un wallet/exchange...", "aucun_wallet" to "Aucun wallet/exchange disponible",
"apropos" to "À propos de moi", "nom_label" to "Nom", "surnom_label" to "Surnom", "prenom_label" to "Prénom",
"nom_complet_label" to "Nom complet",
"build_label" to "Date de build du projet", "update_label" to "Dernière mise à jour", "version_label" to "Version",
"profil_desc" to "Découvrez un espace conçu pour vous aider à trouver les meilleures opportunités d'actifs gratuits grâce à des analyses approfondies, des informations pertinentes et un suivi régulier des tendances.\n\nAirdrops • Crypto • Statistiques sportives",
"apropos_bio" to "Passionné par les cryptomonnaies et les opportunités de gains gratuits. Mon but est de partager les meilleures découvertes pour aider chacun à démarrer.",
"section_profil" to "PROFIL", "section_apropos" to "À PROPOS", "section_contact" to "CONTACT",
"code_parrainage_titre" to "CODE DE PARRAINAGE", "copier_avant" to "Copiez le code avant de continuer",
"mdp_titre" to "Mots de passe enregistrés", "mdp_vide" to "Aucun identifiant enregistré",
"mdp_enregistrer_titre" to "Enregistrer ce mot de passe ?", "mdp_maj_titre" to "Mettre à jour le mot de passe ?",
"mdp_enregistrer" to "Enregistrer", "mdp_ignorer" to "Ignorer", "mdp_supprimer" to "Supprimer",
"profil_enregistre" to "Profil enregistré",
"nav_home_browser" to "Accueil", "nav_back_browser" to "Précédent", "nav_forward_browser" to "Suivant",
"nav_refresh_browser" to "Actualiser", "nav_stop_browser" to "Arrêter", "nav_ouvrir_externe" to "Ouvrir dans le navigateur externe", "autofill_titre" to "Auto-remplissage & Mots de passe",
"verrou_titre" to "Verrouiller cette section", "verrou_desc" to "Demander un code à 4 chiffres pour accéder à l'auto-remplissage et aux mots de passe.",
"verrou_creer_titre" to "Choisissez un code à 4 chiffres", "verrou_confirmer_titre" to "Confirmez le code", "verrou_entrer_titre" to "Code requis",
"verrou_entrer_desc" to "Entrez votre code à 4 chiffres pour continuer.", "verrou_desactiver_desc" to "Entrez votre code pour désactiver le verrou.",
"verrou_erreur" to "Code incorrect, réessayez.", "verrou_ne_correspond_pas" to "Les deux codes ne correspondent pas, réessayez.",
"verrou_valider" to "Valider", "verrou_continuer" to "Continuer", "verrou_active" to "Verrou activé", "verrou_desactive" to "Verrou désactivé", "annuler" to "Annuler",
"tuto_titre" to "Bienvenue sur Gombo Business", "tuto_desc" to "Découvrez en vidéo comment utiliser l'application et son objectif, en quelques minutes.",
"tuto_bouton" to "▶  Regarder le tutoriel", "continuer" to "Continuer", "historique_nav_titre" to "Historique de navigation",
"historique_nav_vide" to "Aucune page visitée récemment", "historique_effacer" to "Effacer l'historique",
"nouveautes_sous_titre" to "Historique complet des versions",
"verif_maj_txt" to "Vérification des mises à jour...", "maj_a_jour" to "L'application est à jour",
"maj_bouton" to "Mise à jour", "maj_disponible_titre" to "Mise à jour disponible",
"maj_mettre_a_jour" to "Mettre à jour", "maj_plus_tard" to "Plus tard",
"maj_telechargement_txt" to "Téléchargement en cours...", "maj_obligatoire_txt" to "Cette mise à jour est obligatoire pour continuer à utiliser l'application.",
"maj_echec_txt" to "Échec du téléchargement. Réessayez plus tard.",
"page_lente_txt" to "Cette page met du temps à s'afficher. Essayez de l'ouvrir dans le navigateur externe (icône en bas de l'écran).",
"apparence_desc" to "Design unique, opaque et épuré, appliqué à toute l'application pour une expérience cohérente et sans réglage à faire.",
// V1.3.4.1 : nouvel onglet "Infos" (lecture seule de infos.json) + champ date de naissance
// dans Auto-remplissage & Mots de passe.
"nav_info" to "Infos", "aucune_info" to "Aucune information disponible", "date_naissance_label" to "Date de naissance",
// V1.3.4.2 : nouvelles fonctionnalités (partage, hors-ligne, description repliable, conseil sécurité).
"lire_suite" to "Lire la suite", "reduire" to "Réduire", "partager" to "Partager", "voir_analyse" to "Voir l'analyse",
"hors_ligne_txt" to "Mode hors-ligne · Données du ", "conseil_securite" to "Rappel : n'investis jamais plus que ce que tu es prêt à perdre.",
"effort_debutant" to "Débutant", "effort_intermediaire" to "Intermédiaire", "effort_avance" to "Avancé"
),
"en" to mapOf(
"copier" to "Copy", "copie_ok" to "Copied", "rejoindre" to "Join", "sinscrire" to "Register",
"regarder" to "Watch", "aucun_airdrop" to "No airdrops", "aucun_prono" to "No predictions",
"aucune_inscr" to "No offers", "nav_acc" to "Home", "nav_air" to "Airdrops", "nav_spo" to "Sports",
"nav_set" to "Settings", "onglet_insc" to "Registrations", "onglet_prono" to "Predictions", "prono_titre" to "Pick: ",
"cote_titre" to "Odds: ", "score_titre" to "Score: ", "theme_title" to "Color Themes", "lang_title" to "Language",
"size_title" to "Display Size", "search_airdrop" to "Search airdrop...", "effacer_recherche" to "Clear search",
"layout_title" to "Interface Density", "apparence" to "Appearance", "nouveautes" to "What's New", "retour" to "Back", "fermer" to "Close",
"card_shape_title" to "Card Shapes", "btn_shape_title" to "Button Shapes",
// V1.3.3 : selectable BACKGROUND animations (Settings > Appearance), replacing the old
// screen transition animations (now removed).
"animation_title" to "Background Animations",
// V1.3.3 : Wallet / Exchange is a sub-page of Airdrops again (instead of its own bottom
// navigation tab).
"nav_wallet" to "Wallet", "search_wallet" to "Search wallet/exchange...", "aucun_wallet" to "No wallets/exchanges available",
"apropos" to "About Me", "nom_label" to "Name", "surnom_label" to "Nickname", "prenom_label" to "First name",
"nom_complet_label" to "Full name",
"build_label" to "Project build date", "update_label" to "Last update", "version_label" to "Version",
"profil_desc" to "Discover a space designed to help you find the best free asset opportunities through in-depth analysis, relevant information, and regular trend tracking.\n\nAirdrops • Crypto • Sports Analytics",
"apropos_bio" to "Passionate about cryptocurrencies and free earning opportunities. My goal is to share the best findings to help everyone get started.",
"section_profil" to "PROFILE", "section_apropos" to "ABOUT", "section_contact" to "CONTACT",
"code_parrainage_titre" to "REFERRAL CODE", "copier_avant" to "Copy the code before continuing",
"mdp_titre" to "Saved passwords", "mdp_vide" to "No saved credentials",
"mdp_enregistrer_titre" to "Save this password?", "mdp_maj_titre" to "Update the saved password?",
"mdp_enregistrer" to "Save", "mdp_ignorer" to "Ignore", "mdp_supprimer" to "Delete",
"profil_enregistre" to "Profile saved",
"nav_home_browser" to "Home", "nav_back_browser" to "Back", "nav_forward_browser" to "Forward",
"nav_refresh_browser" to "Refresh", "nav_stop_browser" to "Stop", "nav_ouvrir_externe" to "Open in external browser", "autofill_titre" to "Autofill & Passwords",
"verrou_titre" to "Lock this section", "verrou_desc" to "Require a 4-digit code to access autofill and passwords.",
"verrou_creer_titre" to "Choose a 4-digit code", "verrou_confirmer_titre" to "Confirm the code", "verrou_entrer_titre" to "Code required",
"verrou_entrer_desc" to "Enter your 4-digit code to continue.", "verrou_desactiver_desc" to "Enter your code to disable the lock.",
"verrou_erreur" to "Incorrect code, try again.", "verrou_ne_correspond_pas" to "The two codes don't match, try again.",
"verrou_valider" to "Confirm", "verrou_continuer" to "Continue", "verrou_active" to "Lock enabled", "verrou_desactive" to "Lock disabled", "annuler" to "Cancel",
"tuto_titre" to "Welcome to Gombo Business", "tuto_desc" to "Watch a short video to learn how to use the app and what it's for.",
"tuto_bouton" to "▶  Watch the tutorial", "continuer" to "Continue", "historique_nav_titre" to "Browsing history",
"historique_nav_vide" to "No recently visited pages", "historique_effacer" to "Clear history",
"nouveautes_sous_titre" to "Full version history",
"verif_maj_txt" to "Checking for updates...", "maj_a_jour" to "The app is up to date",
"maj_bouton" to "Update", "maj_disponible_titre" to "Update available",
"maj_mettre_a_jour" to "Update", "maj_plus_tard" to "Later",
"maj_telechargement_txt" to "Downloading...", "maj_obligatoire_txt" to "This update is mandatory to keep using the app.",
"maj_echec_txt" to "Download failed. Please try again later.",
"page_lente_txt" to "This page is taking a while to load. Try opening it in the external browser (icon at the bottom of the screen).",
"apparence_desc" to "A single, opaque, clean design applied across the whole app for a consistent experience — nothing to configure.",
// V1.3.4.1 : new "Infos" tab (read-only display of infos.json) + date of birth field in
// Autofill & Passwords.
"nav_info" to "Info", "aucune_info" to "No information available", "date_naissance_label" to "Date of birth",
// V1.3.4.2 : new features (sharing, offline, collapsible description, safety reminder).
"lire_suite" to "Read more", "reduire" to "Show less", "partager" to "Share", "voir_analyse" to "View analysis",
"hors_ligne_txt" to "Offline mode · Data from ", "conseil_securite" to "Reminder: never invest more than you're prepared to lose.",
"effort_debutant" to "Beginner", "effort_intermediaire" to "Intermediate", "effort_avance" to "Advanced"
)
)
return dict[langue]?.get(cle) ?: cle
}
}
EOF

echo "🎨 Étape 5 : Moteur de Thèmes..."

cat << 'EOF' > "$PROJECT_NAME/app/src/main/java/$PACKAGE_PATH/presentation/theme/Theme.kt"
package com.gombobusiness.app.presentation.theme

import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import com.gombobusiness.app.core.LocalLayoutMode
// V1.3.4.2 : bascule clair/sombre.
import com.gombobusiness.app.core.LocalAppTheme

data class GlassColors(
    val baseBackground: Color, val glassCardBackground: Color, val glassCardBorder: Color,
    val mainAccent: Color, val textPrimary: Color, val textSecondary: Color, val surfaceHighlight: Color,
    val buttonText: Color,
    // V1.3.3 : jetons dédiés au rendu "néomorphisme" choisi par l'utilisateur — cartes et
    // boutons en dégradé + double relief (bombé/creusé), plutôt qu'un simple aplat de couleur.
    val neuLight: Color, val neuDark: Color, val neuInsetLight: Color, val neuInsetDark: Color,
    val shadowDark: Color, val shadowLight: Color, val accentSoft: Color, val accentLight: Color, val mutedText: Color
)

object AeroGlassDesignSystem {
    private val T_WHITE = Color(0xFFFFFFFF)
    private val T_BLACK = Color(0xFF121212)

    // V1.3.3 : passage au NÉOMORPHISME choisi par l'utilisateur parmi 6 pistes de design
    // proposées — cartes/boutons en dégradé directionnel avec double relief (bombé pour les
    // éléments actifs, creusé/"gravé" pour les zones d'information et les boutons désactivés),
    // contour noir franc, et un accent VERT (clin d'œil au gombo, légume vert) plutôt que
    // le noir/blanc pur des versions précédentes. Un seul thème reste disponible — voir
    // MenuApparence.
    val EclipseTotale = GlassColors(
        baseBackground = Color(0xFFE4E9F1),
        glassCardBackground = Color(0xFFEEF2F8),
        glassCardBorder = Color(0xFF000000),
        mainAccent = Color(0xFF3457D5),
        textPrimary = Color(0xFF2E3A50),
        textSecondary = Color(0xFF6B7793),
        surfaceHighlight = Color(0x17111214),
        buttonText = T_WHITE,
        neuLight = Color(0xFFEEF2F8),
        neuDark = Color(0xFFD9E0EC),
        neuInsetLight = Color(0xFFEEF2F8),
        neuInsetDark = Color(0xFFDBE1EC),
        shadowDark = Color(0xFFC6CDDA),
        shadowLight = Color(0xFFFFFFFF),
        accentSoft = Color(0xFFDCE4FA),
        accentLight = Color(0xFFEEF2FC),
        mutedText = Color(0xFF9AA4BB)
    )

    /**
     * V1.3.4.3 : mode sombre remplacé par un NOIR PUR (le fond passe de #14171C à #000000,
     * demande explicite). Les cartes/bordures/ombres restent volontairement à quelques nuances
     * de gris très sombres (jamais #000000 pur elles aussi) : c'est ce qui permet au relief
     * néomorphisme (bombé/creusé) de rester visible sur un fond parfaitement noir — un noir sur
     * noir strict rendrait cartes et bordures totalement invisibles. Texte en blanc pur pour un
     * contraste maximal.
     * V1.3.5 CORRIGÉ : le vert d'accent (dans les deux thèmes) a été entièrement retiré et
     * remplacé par un bleu-indigo moderne — l'appli ne doit plus contenir AUCUN vert, à la
     * seule exception du repère "pronostic gagnant" (voir couleurCote dans EcranParisSportifs,
     * inchangé). La bordure des cartes a aussi été assombrie (elle pouvait donner une
     * impression de contour "argenté" sur fond noir pur), et les halos décoratifs du fond
     * (auparavant teintés avec l'accent, donc verts) sont désormais neutres en mode sombre
     * pour garantir un fond réellement noir pur, sans aucune teinte de couleur.
     */
    val EclipseSombre = GlassColors(
        baseBackground = Color(0xFF000000),
        glassCardBackground = Color(0xFF0D0D0D),
        glassCardBorder = Color(0xFF1A1A1A),
        mainAccent = Color(0xFF5B7FFF),
        textPrimary = Color(0xFFFFFFFF),
        textSecondary = Color(0xFFA0A0A6),
        surfaceHighlight = Color(0x14FFFFFF),
        buttonText = T_WHITE,
        neuLight = Color(0xFF161616),
        neuDark = Color(0xFF000000),
        neuInsetLight = Color(0xFF0D0D0D),
        neuInsetDark = Color(0xFF000000),
        shadowDark = Color(0xFF000000),
        shadowLight = Color(0xFF1E1E1E),
        accentSoft = Color(0xFF17203A),
        accentLight = Color(0xFF1B2646),
        mutedText = Color(0xFF4D4D52)
    )

    // V1.3.4.2 : bascule entre les deux palettes selon le réglage de l'utilisateur (Paramètres >
    // Apparence). "Sombre" est la seule valeur qui active EclipseSombre ; toute autre valeur
    // (y compris l'ancienne valeur historique "Éclipse Totale" déjà mémorisée sur les appareils
    // mis à jour) retombe sur le thème clair, par défaut.
    @Composable
    fun current(): GlassColors = if (LocalAppTheme.current.value == "Sombre") EclipseSombre else EclipseTotale
}

/**
 * V1.3.4.3 : le choix de police (Paramètres > Apparence) a été retiré — une seule police
 * reste utilisée dans toute l'application, celle qui était déjà le style par défaut
 * ("Impact (Lourd)" : sans-serif, graisse extra-forte). Fonctions conservées (même nom,
 * même signature) pour ne rien changer à leurs très nombreux points d'appel.
 */
@Composable
fun currentFontFamily(): FontFamily = FontFamily.SansSerif

@Composable
fun currentFontWeight(base: FontWeight): FontWeight = FontWeight.Black

/**
 * V1.4 corrigée : une seule densité d'interface reste disponible, "Compacte", définie
 * par défaut (0.7). Le multiplicateur reste appliqué instantanément aux paddings et
 * espacements des cartes, boutons et listes.
 */
fun densityScale(mode: String): Float = when (mode) {
    "Compacte" -> 0.7f
    else -> 0.7f
}

@Composable
fun currentDensityScale(): Float = densityScale(LocalLayoutMode.current.value)

@Composable
fun GomboBusinessTheme(content: @Composable () -> Unit) {
    val tokens = AeroGlassDesignSystem.current()
    val materialScheme = darkColorScheme(
        background = tokens.baseBackground, surface = tokens.glassCardBackground, primary = tokens.mainAccent,
        onBackground = tokens.textPrimary, onSurface = tokens.textPrimary
    )
    MaterialTheme(colorScheme = materialScheme, content = content)
}
EOF

echo "📦 Étape 6 : Données & Moteur API..."

cat << 'EOF' > "$PROJECT_NAME/app/src/main/java/$PACKAGE_PATH/domain/model/Modeles.kt"
package com.gombobusiness.app.domain.model
import kotlinx.serialization.Serializable

// V1.3.4.2 : trois champs optionnels ajoutés (100% rétro-compatibles avec airdrops.json existant,
// puisque nullables) — permettent d'afficher un temps estimé, un niveau de difficulté et un
// indicateur d'urgence sur chaque carte, uniquement quand ces informations sont renseignées côté
// fichier JSON distant.
@Serializable data class ElementAirdrop(
    val titre: String = "", val description: String = "", val codeInvitation: String? = null,
    val lienParrainage: String? = null, val lienVideoTuto: String? = null,
    val dureeEstimee: String? = null, val niveauDifficulte: String? = null,
    // Valeurs attendues : "actif" (point vert), "urgent" (point orange), "termine" (point gris).
    // Toute autre valeur ou absence de valeur : aucun point affiché.
    val statut: String? = null,
    // V1.3.4.2 : texte optionnel affiché derrière un bouton "Voir mon analyse" — permet
    // d'expliquer en quelques mots pourquoi ce projet est recommandé.
    val analysePersonnelle: String? = null
)
// V1.3.2 CORRIGÉ : modèle du fichier wallet_exchange.json (section "Wallet / Exchange",
// scindée depuis l'ancienne section Airdrops). Même structure que ElementAirdrop, afin de
// réutiliser le même type de contenu (code d'invitation, lien de parrainage, tuto vidéo).
@Serializable data class ElementWalletExchange(val titre: String = "", val description: String = "", val codeInvitation: String? = null, val lienParrainage: String? = null, val lienVideoTuto: String? = null)
// V1.3.3 CORRIGÉ : "cote" est en réalité une chaîne de caractères côté pronostics.json
// (ex : "1.96✅" ou "2.10❌"), avec l'émoji de statut (validé/perdu) directement inclus par
// la personne qui alimente le fichier. L'ancien typage en Double provoquait une erreur de
// lecture JSON silencieusement rattrapée par le repository (liste vide, "Aucun pronostic"
// affiché en permanence, même quand pronostics.json contenait bien des données valides).
// V1.3.5 : ajout d'un champ "score" optionnel (ex: "2 - 1"), rempli une fois le match terminé.
@Serializable data class ElementPronostic(val equipes: String = "", val ligue: String = "", val dateEtHeure: String = "", val pronosticChoisi: String = "", val cote: String = "", val score: String? = null)
@Serializable data class ElementInscription(val nomBookmaker: String = "", val description: String = "", val codePromo: String? = null, val lienInscription: String? = null)
// V1.3.4.1 : modèle du fichier infos.json (nouvel onglet "Infos" de la barre du bas). Volontairement
// minimal (un titre + un texte) : cet écran n'affiche jamais de bouton, uniquement du contenu
// informatif dans des cartes.
// V1.3.4.3 : ajout d'un champ "date" optionnel (chaîne libre, ex: "20/07/2026") — laissé vide
// par défaut pour rester rétro-compatible avec les entrées de infos.json qui n'en ont pas.
@Serializable data class ElementInfo(val titre: String = "", val texte: String = "", val date: String = "")

/**
 * V1.3.1 : modèle de données du fichier update.json hébergé sur GitHub, utilisé par le
 * système de mise à jour in-app pour savoir si une nouvelle version de l'APK est
 * disponible, quoi afficher (changelog) et si la mise à jour est obligatoire.
 */
@Serializable data class InfoMiseAJour(
    val versionCode: Int = 0,
    val versionName: String = "",
    val apkUrl: String = "",
    val changelog: List<String> = emptyList(),
    val forceUpdate: Boolean = false
)
EOF

cat << 'EOF' > "$PROJECT_NAME/app/src/main/java/$PACKAGE_PATH/data/remote/ApiService.kt"
package com.gombobusiness.app.data.remote
import com.gombobusiness.app.domain.model.*
import retrofit2.http.GET
import retrofit2.http.Url

interface GitHubConfigApi {
@GET suspend fun obtenirAirdropsDistants(@Url url: String): List<ElementAirdrop>
// V1.3.2 CORRIGÉ : endpoint dédié à la section "Wallet / Exchange" (wallet_exchange.json).
@GET suspend fun obtenirWalletExchangeDistants(@Url url: String): List<ElementWalletExchange>
@GET suspend fun obtenirPronosticsDistants(@Url url: String): List<ElementPronostic>
@GET suspend fun obtenirInscriptionsDistantes(@Url url: String): List<ElementInscription>
@GET suspend fun obtenirInfoMiseAJourDistante(@Url url: String): InfoMiseAJour
// V1.3.4.1 : lecture du fichier infos.json (nouvel onglet "Infos").
@GET suspend fun obtenirInfosDistantes(@Url url: String): List<ElementInfo>
}
EOF

cat << 'EOF' > "$PROJECT_NAME/app/src/main/java/$PACKAGE_PATH/domain/repository/AppRepository.kt"
package com.gombobusiness.app.domain.repository
import com.gombobusiness.app.domain.model.*

interface AppRepository {
suspend fun obtenirAirdrops(): Result<List<ElementAirdrop>>
// V1.3.2 CORRIGÉ : section "Wallet / Exchange" (wallet_exchange.json), distincte des Airdrops.
suspend fun obtenirWalletExchange(): Result<List<ElementWalletExchange>>
suspend fun obtenirPronostics(): Result<List<ElementPronostic>>
suspend fun obtenirInscriptions(): Result<List<ElementInscription>>
suspend fun obtenirMiseAJour(): Result<InfoMiseAJour>
// V1.3.4.1 : section "Infos" (infos.json), affichée dans le nouvel onglet du même nom.
suspend fun obtenirInfos(): Result<List<ElementInfo>>
// V1.3.4.2 : date/heure de la dernière synchronisation réussie avec GitHub (0 si aucune) —
// utilisé pour le message "Mode hors-ligne - Données du ..." affiché quand la connexion manque.
fun obtenirDerniereSynchro(): Long
}
EOF

cat << 'EOF' > "$PROJECT_NAME/app/src/main/java/$PACKAGE_PATH/data/repository/AppRepositoryImpl.kt"
package com.gombobusiness.app.data.repository
import com.gombobusiness.app.data.remote.*
import com.gombobusiness.app.domain.model.*
import com.gombobusiness.app.domain.repository.AppRepository
import com.gombobusiness.app.data.local.DonneesCacheStore
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

// V1.3.3 : le repository accepte désormais un DonneesCacheStore — chaque chargement réussi
// est immédiatement mis en cache, et chaque échec (pas d'internet, GitHub injoignable...)
// retombe sur la dernière version connue en cache plutôt que sur une liste vide.
class AppRepositoryImpl(private val gitHubApi: GitHubConfigApi, private val cache: DonneesCacheStore) : AppRepository {
private val URL_BASE = "https://raw.githubusercontent.com/Legombonistebiz/GOMBO-BUSINESS-APP/refs/heads/main/"
// V1.3.1 : URL exacte du fichier de mise à jour fournie par le backend GitHub.
private val URL_UPDATE_JSON = "https://raw.githubusercontent.com/Legombonistebiz/GOMBO-BUSINESS-APP/main/update.json"

override suspend fun obtenirAirdrops(): Result<List<ElementAirdrop>> = withContext(Dispatchers.IO) {
    try { val frais = gitHubApi.obtenirAirdropsDistants("${URL_BASE}airdrops.json"); cache.ecrire("cache_airdrops", frais); cache.ecrireHorodatage(); Result.success(frais) }
    catch (e: Exception) { Result.success(cache.lire("cache_airdrops")) }
}
// V1.3.4.2 : simple lecture synchrone (SharedPreferences), pas besoin de coroutine ici.
override fun obtenirDerniereSynchro(): Long = cache.lireHorodatage()
// V1.3.2 CORRIGÉ : la section "Wallet / Exchange" lit exclusivement wallet_exchange.json,
// via le même système de synchronisation GitHub (URL_BASE) déjà utilisé par les Airdrops.
override suspend fun obtenirWalletExchange(): Result<List<ElementWalletExchange>> = withContext(Dispatchers.IO) {
    try { val frais = gitHubApi.obtenirWalletExchangeDistants("${URL_BASE}wallet_exchange.json"); cache.ecrire("cache_wallet_exchange", frais); Result.success(frais) }
    catch (e: Exception) { Result.success(cache.lire("cache_wallet_exchange")) }
}
override suspend fun obtenirPronostics(): Result<List<ElementPronostic>> = withContext(Dispatchers.IO) {
    try { val frais = gitHubApi.obtenirPronosticsDistants("${URL_BASE}pronostics.json"); cache.ecrire("cache_pronostics", frais); Result.success(frais) }
    catch (e: Exception) { Result.success(cache.lire("cache_pronostics")) }
}
override suspend fun obtenirInscriptions(): Result<List<ElementInscription>> = withContext(Dispatchers.IO) {
    try { val frais = gitHubApi.obtenirInscriptionsDistantes("${URL_BASE}inscriptions.json"); cache.ecrire("cache_inscriptions", frais); Result.success(frais) }
    catch (e: Exception) { Result.success(cache.lire("cache_inscriptions")) }
}
override suspend fun obtenirMiseAJour(): Result<InfoMiseAJour> = withContext(Dispatchers.IO) { try { Result.success(gitHubApi.obtenirInfoMiseAJourDistante(URL_UPDATE_JSON)) } catch (e: Exception) { Result.failure(e) } }
// V1.3.4.1 : section "Infos" — même principe de synchronisation + cache que les autres sections.
override suspend fun obtenirInfos(): Result<List<ElementInfo>> = withContext(Dispatchers.IO) {
    try { val frais = gitHubApi.obtenirInfosDistantes("${URL_BASE}infos.json"); cache.ecrire("cache_infos", frais); Result.success(frais) }
    catch (e: Exception) { Result.success(cache.lire("cache_infos")) }
}
}
EOF

cat << 'EOF' > "$PROJECT_NAME/app/src/main/java/$PACKAGE_PATH/presentation/viewmodel/MainViewModel.kt"
package com.gombobusiness.app.presentation.viewmodel
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.gombobusiness.app.domain.model.*
import com.gombobusiness.app.domain.repository.AppRepository
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch

class MainViewModel(private val repository: AppRepository) : ViewModel() {
private val _airdrops = MutableStateFlow<List<ElementAirdrop>>(emptyList())
val airdrops: StateFlow<List<ElementAirdrop>> = _airdrops.asStateFlow()

// V1.3.2 CORRIGÉ : état dédié à la section "Wallet / Exchange", scindée des Airdrops.
private val _walletExchange = MutableStateFlow<List<ElementWalletExchange>>(emptyList())
val walletExchange: StateFlow<List<ElementWalletExchange>> = _walletExchange.asStateFlow()

private val _pronostics = MutableStateFlow<List<ElementPronostic>>(emptyList())
val pronostics: StateFlow<List<ElementPronostic>> = _pronostics.asStateFlow()

private val _inscriptions = MutableStateFlow<List<ElementInscription>>(emptyList())
val inscriptions: StateFlow<List<ElementInscription>> = _inscriptions.asStateFlow()

// V1.3.4.1 : état de la nouvelle section "Infos" (infos.json).
private val _infos = MutableStateFlow<List<ElementInfo>>(emptyList())
val infos: StateFlow<List<ElementInfo>> = _infos.asStateFlow()

// V1.3.4.2 : date/heure de la dernière synchronisation, affichée dans le bandeau "Mode
// hors-ligne" (voir ConteneurNavigationPrincipal).
private val _derniereSynchro = MutableStateFlow(0L)
val derniereSynchro: StateFlow<Long> = _derniereSynchro.asStateFlow()

// V1.3.4.2 : indicateur de chargement en cours, utilisé par le geste "Glisser pour
// actualiser" (Airdrops/Pronostics) pour afficher un petit indicateur pendant le rechargement.
private val _enChargement = MutableStateFlow(false)
val enChargement: StateFlow<Boolean> = _enChargement.asStateFlow()

// V1.3.3 : chargement lancé immédiatement à la création du ViewModel, avant même de savoir
// si une connexion internet est disponible. En cas de succès réseau, les données les plus
// fraîches s'affichent tout de suite ; en cas d'échec (pas de réseau au démarrage), le
// repository retombe automatiquement sur le cache local, qui s'affiche donc lui aussi
// instantanément plutôt que de laisser les écrans vides. Le rechargement se relance ensuite
// à chaque (re)détection d'internet via LaunchedEffect(isOnline) (ConteneurNavigationPrincipal).
init { chargerDonnees() }

fun chargerDonnees() {
    viewModelScope.launch {
        _enChargement.value = true
        val nouveauxAirdrops = repository.obtenirAirdrops().getOrDefault(emptyList())
        val nouveauWallet = repository.obtenirWalletExchange().getOrDefault(emptyList())
        val nouveauxPronostics = repository.obtenirPronostics().getOrDefault(emptyList())
        val nouvellesInscriptions = repository.obtenirInscriptions().getOrDefault(emptyList())
        val nouvellesInfos = repository.obtenirInfos().getOrDefault(emptyList())
        // V1.3.5 : on ne réassigne un StateFlow que si son contenu a réellement changé —
        // évite de redéclencher recomposition/défilement/animations quand un rafraîchissement
        // automatique (reconnexion réseau, glisser-actualiser) ramène des données identiques
        // à celles déjà affichées ("rafraîchissement uniquement s'il y a une nouvelle version").
        if (nouveauxAirdrops != _airdrops.value) _airdrops.value = nouveauxAirdrops
        if (nouveauWallet != _walletExchange.value) _walletExchange.value = nouveauWallet
        if (nouveauxPronostics != _pronostics.value) _pronostics.value = nouveauxPronostics
        if (nouvellesInscriptions != _inscriptions.value) _inscriptions.value = nouvellesInscriptions
        if (nouvellesInfos != _infos.value) _infos.value = nouvellesInfos
        _derniereSynchro.value = repository.obtenirDerniereSynchro()
        _enChargement.value = false
    }
}

/**
 * V1.3.1 : vérifie sur GitHub si une nouvelle version de l'application est disponible.
 * Compare le versionCode distant (update.json) au versionCode local de l'APK installé.
 * `surResultat` reçoit l'InfoMiseAJour si une mise à jour est disponible, ou null sinon
 * (site injoignable ou déjà à la dernière version) — c'est à l'appelant de distinguer
 * les deux cas s'il le souhaite (ex : afficher "Application à jour").
 */
fun verifierMiseAJour(versionCodeActuel: Int, surResultat: (InfoMiseAJour?) -> Unit) {
    viewModelScope.launch {
        val resultat = repository.obtenirMiseAJour().getOrNull()
        if (resultat != null && resultat.versionCode > versionCodeActuel) {
            surResultat(resultat)
        } else {
            surResultat(null)
        }
    }
}
}
EOF

echo "📋 Étape 7 : Rendu UI Premium (Nettoyé, WebView, Apparence structurée)..."

cat << 'EOF' > "$PROJECT_NAME/app/src/main/java/$PACKAGE_PATH/presentation/ecrans/EcransAdditionnels.kt"
package com.gombobusiness.app.presentation.ecrans

import android.content.Intent
import android.net.Uri
import android.webkit.*
import android.widget.Toast
import androidx.activity.compose.BackHandler
// V1.3.4.2 : "Glisser pour actualiser" (implémentation maison via NestedScrollConnection,
// des API Compose stables depuis longtemps — évite de dépendre de l'API PullToRefresh de
// Material3, encore expérimentale/instable selon les versions).
import androidx.compose.ui.input.nestedscroll.NestedScrollConnection
import androidx.compose.ui.input.nestedscroll.NestedScrollSource
import androidx.compose.ui.input.nestedscroll.nestedScroll
import androidx.compose.ui.unit.Velocity
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.Crossfade
import androidx.compose.animation.core.*
import androidx.compose.animation.fadeIn
// CORRECTIF BUILD : fadeOut n'est pas couvert par le wildcard animation.core.* (il vit dans
// androidx.compose.animation, pas .core) — nécessaire pour TirerPourActualiser.
import androidx.compose.animation.fadeOut
// V1.3.6 : accordéon de l'onglet Infos (chaque info repliée par défaut, dépliée via une flèche).
import androidx.compose.animation.expandVertically
import androidx.compose.animation.shrinkVertically
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.interaction.collectIsPressedAsState
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.lazy.itemsIndexed
// V1.3.4.2 : retour en haut de liste (second appui sur l'onglet actif).
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.*
import androidx.compose.material3.TabRowDefaults.tabIndicatorOffset
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.rounded.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.blur
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.clipToBounds
import androidx.compose.ui.draw.drawWithCache
import androidx.compose.ui.draw.rotate
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.RectangleShape
import androidx.compose.ui.graphics.Shadow
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.graphics.lerp
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalClipboardManager
import androidx.compose.ui.platform.LocalConfiguration
import androidx.compose.ui.platform.LocalContext
// V1.3.4.2 : retour haptique léger sur les boutons/onglets + troncature des descriptions
// longues ("Lire la suite").
import androidx.compose.ui.platform.LocalHapticFeedback
import androidx.compose.ui.hapticfeedback.HapticFeedbackType
import androidx.compose.ui.text.AnnotatedString
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.TextUnit
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.viewinterop.AndroidView
import androidx.compose.ui.window.Dialog
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.zIndex
import coil.compose.SubcomposeAsyncImage
import com.gombobusiness.app.core.*
import com.gombobusiness.app.domain.model.*
import com.gombobusiness.app.data.local.PreferencesManager
import com.gombobusiness.app.presentation.theme.AeroGlassDesignSystem
import com.gombobusiness.app.presentation.viewmodel.MainViewModel
import com.gombobusiness.app.BuildConfig
import kotlin.math.cos
import kotlin.math.sin
import com.gombobusiness.app.presentation.theme.GlassColors
import com.gombobusiness.app.presentation.theme.currentFontFamily
import com.gombobusiness.app.presentation.theme.currentFontWeight
import com.gombobusiness.app.presentation.theme.currentDensityScale
import kotlin.math.roundToInt

data class ReseauSocial(val iconUrl: String, val linkUrl: String)

/**
 * Placeholder "scintillement" (shimmer) affiché pendant le chargement d'une image distante.
 * Remplace l'ancien effet de "trou" sombre par une animation douce et professionnelle.
 */
@Composable
fun ShimmerPlaceholder(modifier: Modifier = Modifier) {
    val tokens = AeroGlassDesignSystem.current()
    val transition = rememberInfiniteTransition(label = "shimmer_transition")
    val translate by transition.animateFloat(
        initialValue = -300f, targetValue = 300f,
        animationSpec = infiniteRepeatable(animation = tween(1300, easing = LinearEasing), repeatMode = RepeatMode.Restart),
        label = "shimmer_translate"
    )
    val shimmerBrush = Brush.linearGradient(
        colors = listOf(
            tokens.glassCardBackground.copy(alpha = 0.9f),
            tokens.mainAccent.copy(alpha = 0.14f),
            tokens.glassCardBackground.copy(alpha = 0.9f)
        ),
        start = Offset(translate - 150f, 0f),
        end = Offset(translate + 150f, 300f)
    )
    Box(modifier = modifier.background(tokens.glassCardBackground).background(shimmerBrush))
}

/**
 * État "vide" élégant : utilisé quand une image ne se charge pas (erreur réseau, lien mort...).
 * V1.4 corrigée : ce composant ne dessine plus SA PROPRE forme de fond. Auparavant, il
 * peignait un second cercle plein par-dessus celui déjà fourni par le conteneur parent
 * (avatar, bulle sociale...) ; la superposition de deux cercles translucides identiques
 * assombrissait fortement le centre et donnait l'apparence d'une forme sombre en "octogone"
 * incrustée derrière l'icône. Désormais IconePlaceholderElegant est strictement transparent :
 * seul le cercle du conteneur parent reste visible, avec l'icône par-dessus, et les deux
 * continuent de s'adapter automatiquement aux couleurs du thème actif.
 */
@Composable
fun IconePlaceholderElegant(modifier: Modifier = Modifier, icone: ImageVector = Icons.Rounded.Image) {
    val tokens = AeroGlassDesignSystem.current()
    Box(modifier = modifier, contentAlignment = Alignment.Center) {
        Icon(imageVector = icone, contentDescription = null, tint = tokens.textSecondary.copy(alpha = 0.7f), modifier = Modifier.fillMaxSize(0.42f))
    }
}

@Composable
fun PremiumText(
    text: String, color: Color, size: Float, fontWeight: FontWeight = FontWeight.Normal,
    modifier: Modifier = Modifier, is3D: Boolean = false, textAlign: TextAlign? = null, lineHeight: Float = Float.NaN,
    // V1.3.4.2 : ré-active le réglage de taille de texte (voir MenuApparence > Taille du texte),
    // et ajoute maxLines/overflow (par défaut inchangés) pour permettre les descriptions
    // repliables ("Lire la suite") sans toucher aux appels existants.
    maxLines: Int = Int.MAX_VALUE, overflow: TextOverflow = TextOverflow.Clip
) {
    // V1.3.4.2 : la taille d'affichage suit désormais le réglage utilisateur (LocalFontSize,
    // persistant, réglable dans Paramètres > Apparence), au lieu d'être figée à 100 %.
    val scale = LocalFontSize.current.value
    val font = currentFontFamily()
    val weight = currentFontWeight(fontWeight)
    // V1.3.3 : ombre allégée pour le thème clair — l'ancien effet (ombre noire marquée,
    // pensée pour du texte blanc sur fond sombre) écrasait désormais un texte déjà sombre
    // sur carte blanche. Une ombre douce et discrète suffit à donner le léger relief "3D".
    val shadowDef = if (is3D) Shadow(Color(0x2E000000), Offset(0f, 2f), 6f) else null

    Text(
        text = text, color = color, fontSize = (size * scale).sp, fontWeight = weight,
        fontFamily = font, textAlign = textAlign, lineHeight = if (!lineHeight.isNaN()) (lineHeight * scale).sp else TextUnit.Unspecified,
        style = TextStyle(shadow = shadowDef), modifier = modifier, maxLines = maxLines, overflow = overflow
    )
}

/**
 * V1.3.3 : rayon réduit (18dp effectif) pour coller au style néomorphisme choisi — des coins
 * doux mais nettement moins ronds que l'ancien "Maximal" (36dp), pour un rendu plus carte/
 * plaquette que bulle.
 */
fun radiusPourFormeCarte(shapeType: String): Float = 24f

/**
 * V1.4 corrigée : une seule forme de bouton reste disponible, "Pilule", désormais
 * définie par défaut (angles complètement arrondis, 50dp de base).
 */
fun radiusPourFormeBouton(shapeType: String): Float = 50f

/**
 * V1.3.3 : simule un relief "creusé" (ombre interne) façon néomorphisme — Compose ne propose
 * pas d'ombre "inset" native comme CSS. On dessine deux dégradés radiaux discrets par-dessus
 * le fond déjà en place : un sombre partant du coin bas-droit, un clair partant du coin
 * haut-gauche, tous deux en dégradé vers transparent — l'effet lu est celui d'une zone
 * légèrement "gravée" dans la carte plutôt que posée dessus.
 * V1.3.5 CORRIGÉ : le reflet clair était un blanc pur (#FFFFFF) câblé en dur à 55% d'opacité,
 * quel que soit le thème — en mode noir pur, ce blanc très visible ressortait comme un reflet
 * "argenté" à l'intérieur des cadres (ex. le bloc "Code de parrainage"). Utilise maintenant
 * `tokens.shadowLight`, qui vaut un gris très sombre en mode noir pur (donc quasi invisible,
 * fond réellement noir) et reste blanc en thème clair (aucun changement visuel là-bas).
 */
fun Modifier.ombreCreusee(tokens: GlassColors): Modifier = this.drawWithCache {
    val sombre = Brush.radialGradient(colors = listOf(tokens.shadowDark.copy(alpha = 0.42f), Color.Transparent), center = Offset(size.width, size.height), radius = size.maxDimension * 0.85f)
    val clair = Brush.radialGradient(colors = listOf(tokens.shadowLight.copy(alpha = 0.55f), Color.Transparent), center = Offset(0f, 0f), radius = size.maxDimension * 0.75f)
    onDrawWithContent { drawContent(); drawRect(brush = sombre); drawRect(brush = clair) }
}

@Composable
fun PremiumGlassCard(modifier: Modifier = Modifier, paddingMult: Float = 1f, onClick: (() -> Unit)? = null, teinte: Color? = null, content: @Composable ColumnScope.() -> Unit) {
    val tokens = AeroGlassDesignSystem.current()
    val densite = currentDensityScale()
    val shapeType = LocalCardShape.current.value
    val paddingValue = (13.dp * densite * paddingMult)

    val cardShape = RoundedCornerShape(radiusPourFormeCarte(shapeType).dp * densite.coerceIn(0.75f, 1.15f))

    val interactionSource = remember { MutableInteractionSource() }
    val isPressed by interactionSource.collectIsPressedAsState()
    val scale by animateFloatAsState(if (isPressed) 0.98f else 1f, spring(dampingRatio = Spring.DampingRatioMediumBouncy))
    val elevation by animateDpAsState(if (isPressed) 3.dp else 12.dp, spring())
    // V1.3.1 : léger effet de bascule 3D/4D à l'appui (la carte "s'enfonce" légèrement
    // dans l'écran), en plus du zoom et de l'ombre déjà animés — donne une vraie sensation
    // de profondeur/relief sans jamais devenir exagéré.
    val basculeX by animateFloatAsState(if (isPressed) 4f else 0f, spring(dampingRatio = Spring.DampingRatioMediumBouncy))
    // V1.3.3 : très léger balancement 3D permanent (quelques dixièmes de degré, imperceptible
    // en fixe mais visible en mouvement), appliqué à TOUTES les cartes de l'application via
    // ce composant partagé — donne un rendu "vivant" et moderne à l'ensemble des écrans
    // (Airdrops, Wallet/Exchange, Pronostics, Inscriptions...) sans aucune modification à
    // faire écran par écran, et reste suffisamment subtil pour ne jamais gêner la lecture.
    // V1.3.5 CORRIGÉ : la carte lit désormais une seule animation partagée par toute
    // l'application (voir LocalBasculeIdleCarte) au lieu de créer la sienne — même rendu
    // visuel ("respiration" 3D très légère), un seul calcul au lieu d'un par carte visible.
    val basculeIdleY = LocalBasculeIdleCarte.current

    // V1.3.3 : NÉOMORPHISME — la carte combine désormais : un dégradé directionnel clair→
    // sombre (au lieu d'un aplat uni), un contour noir franc, une ombre "dure" décalée sans
    // flou (façon carte qui flotte légèrement au-dessus du fond, qui se rapproche à l'appui)
    // et une ombre douce ambiante en dessous. C'est le style choisi par l'utilisateur parmi
    // 6 pistes de design proposées (mockups HTML), reproduit ici composant par composant.
    val decalageOmbre by animateDpAsState(if (isPressed) 3.dp else 6.dp, spring())

    Box(modifier = modifier.graphicsLayer { scaleX = scale; scaleY = scale; rotationX = basculeX; rotationY = basculeIdleY; cameraDistance = 16f * density }) {
        // Couche 1 : ombre dure décalée (sans flou), donne l'effet "carte qui flotte".
        Box(Modifier.matchParentSize().offset(x = decalageOmbre, y = decalageOmbre).clip(cardShape).background(Color.Black.copy(alpha = 0.18f)))
        // Couche 2 : la carte elle-même — dégradé + ombre douce ambiante + contour noir.
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .shadow(elevation = elevation, shape = cardShape, ambientColor = tokens.shadowDark, spotColor = tokens.shadowDark)
                .clip(cardShape)
                .background(Brush.linearGradient(listOf(tokens.neuLight, tokens.neuDark)))
                // V1.3.4.2 : léger voile de couleur optionnel par catégorie (Airdrops, Wallet,
                // Pronostics, Inscriptions...), pour aider à identifier le type de contenu d'un
                // coup d'œil sans modifier le style néomorphisme existant.
                .then(if (teinte != null) Modifier.background(teinte.copy(alpha = 0.09f)) else Modifier)
                .border(3.dp, tokens.glassCardBorder, cardShape)
                .then(if (onClick != null) Modifier.clickable(interactionSource = interactionSource, indication = null, onClick = onClick) else Modifier)
                .padding(paddingValue),
            content = content
        )
    }
}

/**
 * V1.4 : bouton reconstruit sur un Box (plutôt que le Button() Material standard) afin
 * d'appliquer un dégradé vertical clair → sombre qui simule un bouton "pilule" 3D en relief
 * (embossé), tout en gardant les mêmes animations de pression et la même signature d'appel
 * que la version précédente. Les tons ajoutés restent proches de la couleur d'origine
 * (mélange à 18-20%) pour ne jamais produire d'éclat agressif à l'œil.
 */
/**
 * V1.3.3 : NÉOMORPHISME — bouton "bombé" (dégradé diagonal clair→sombre dérivé de la couleur
 * fournie + contour noir + ombre douce) à l'état actif ; bouton "creusé" (dégradé neutre
 * inversé, sans contour, texte atténué) à l'état désactivé — bien plus parlant qu'un simple
 * bouton grisé/estompé, et cohérent avec le reste de l'interface (cartes, champs...).
 */
@Composable
fun AnimatedButton(text: String, containerColor: Color, textColor: Color, modifier: Modifier = Modifier, enabled: Boolean = true, textSize: Float = 15f, onDisabledClick: (() -> Unit)? = null, onClick: () -> Unit) {
    val tokens = AeroGlassDesignSystem.current()
    val interactionSource = remember { MutableInteractionSource() }
    val isPressed by interactionSource.collectIsPressedAsState()
    val scale by animateFloatAsState(if (isPressed) 0.94f else 1f, spring())
    val densite = currentDensityScale()
    val shapeType = LocalButtonShape.current.value
    // V1.3.1 : léger effet de bascule 3D/4D à l'appui (le bouton "s'enfonce" légèrement),
    // en complément du zoom et de l'ombre déjà animés.
    val basculeX by animateFloatAsState(if (isPressed) 6f else 0f, spring())
    // V1.3.4.2 : très légère vibration de confirmation à l'appui.
    val hapticFeedback = LocalHapticFeedback.current

    val btnShape = RoundedCornerShape(radiusPourFormeBouton(shapeType).dp * densite.coerceIn(0.8f, 1.1f))
    val couleurClaire = lerp(containerColor, Color.White, 0.30f)
    val couleurSombre = lerp(containerColor, Color.Black, 0.10f)

    Box(
        contentAlignment = Alignment.Center,
        modifier = modifier
            .graphicsLayer { scaleX = scale; scaleY = scale; rotationX = basculeX; cameraDistance = 16f * density }
            .then(
                if (enabled) Modifier
                    .shadow(elevation = if (isPressed) 3.dp else 9.dp, shape = btnShape, ambientColor = tokens.shadowDark, spotColor = tokens.shadowDark)
                    .clip(btnShape)
                    .background(Brush.linearGradient(listOf(couleurClaire, couleurSombre)))
                    .border(2.dp, tokens.glassCardBorder, btnShape)
                else Modifier
                    .clip(btnShape)
                    .background(Brush.linearGradient(listOf(tokens.neuInsetDark, tokens.neuInsetLight)))
                    .ombreCreusee(tokens)
                    // V1.3.4.1 CORRIGÉ : le bouton désactivé se fondait complètement dans la
                    // carte (aucun contour, dégradé quasi identique au fond) et devenait donc
                    // invisible en tant que "bouton". Un contour discret suffit à le délimiter
                    // nettement, sans pour autant lui donner l'air actif/cliquable.
                    .border(1.5.dp, tokens.textSecondary.copy(alpha = 0.45f), btnShape)
            )
            // V1.3.3 CORRIGÉ : le bouton reste désormais tapable même "grisé" (enabled=false
            // au niveau visuel) afin de pouvoir réagir à l'appui — par exemple pour afficher
            // un message d'aide ("Copiez le code avant de continuer") uniquement au moment où
            // l'utilisateur essaie réellement d'appuyer dessus, plutôt qu'en permanence.
            .clickable(interactionSource = interactionSource, indication = null, enabled = true) {
                hapticFeedback.performHapticFeedback(HapticFeedbackType.LongPress)
                if (enabled) onClick() else onDisabledClick?.invoke()
            }
            .padding(vertical = (12.dp * densite), horizontal = (24.dp * densite.coerceIn(0.8f, 1.2f)))
    ) { PremiumText(text = text, color = if (enabled) textColor else tokens.mutedText, size = textSize, fontWeight = FontWeight.Bold, is3D = false) }
}

/**
 * V1.3.3 CORRIGÉ : bouton d'icône rond vraiment "3D", utilisé partout où une simple icône
 * cliquable (flèche retour, boutons du navigateur intégré...) restait trop plate/discrète.
 * Reprend le même langage "relief" que AnimatedButton : dégradé clair→sombre en bouton bombé,
 * contour visible, ombre qui se creuse à l'appui, et une légère animation de zoom/enfoncement
 * au clic pour un vrai retour tactile — appliqué à toute l'application, pas qu'au navigateur.
 */
/**
 * V1.3.3 : NÉOMORPHISME — bouton d'icône rond/carré en dégradé bombé (au repos) qui bascule
 * en version "creusée" (ombre interne, sans ombre portée) soit à l'appui, soit en continu
 * quand `active = true` (utilisé pour l'onglet actuellement sélectionné dans une barre de
 * navigation) — exactement le comportement du mockup HTML validé par l'utilisateur.
 * V1.3.5 CORRIGÉ : l'onglet actif ne s'élargit plus en pilule ovale — il s'affiche désormais
 * "enfoncé" dans la barre (comme un vrai bouton de télécommande qu'on maintient pressé),
 * teinté de la couleur d'accent pour rester bien visible parmi les autres boutons, sans ombre
 * portée (un élément enfoncé n'en projette pas). Le relief "bombé" des boutons au repos est
 * aussi renforcé (ombre et reflet plus marqués) pour un rendu 3D plus net, demande explicite.
 */
@Composable
fun IconeNavigateur3D(icon: ImageVector, description: String, enabled: Boolean = true, active: Boolean = false, taille: Dp = 44.dp, modifier: Modifier = Modifier, formeCirculaire: Boolean = false, couleurActive: Color? = null, onClick: () -> Unit) {
    val tokens = AeroGlassDesignSystem.current()
    val interactionSource = remember { MutableInteractionSource() }
    val isPressed by interactionSource.collectIsPressedAsState()
    // V1.3.5 CORRIGÉ : pour les boutons ronds de la barre de navigation (formeCirculaire),
    // l'état ne dépend plus que de "active" — bombé pour tous les boutons non sélectionnés,
    // enfoncé uniquement pour le bouton sélectionné. L'ancien effet "creux" temporaire à
    // l'appui (avant relâchement) n'a plus lieu d'être ici et créait une ambiguïté entre les
    // deux états ; il reste inchangé pour les autres usages de ce composant (flèche retour,
    // barre du navigateur intégré) où ce retour tactile momentané reste pertinent.
    val creuse = isPressed && !active && !formeCirculaire
    val scale by animateFloatAsState(if (isPressed) 0.9f else 1f, spring(dampingRatio = Spring.DampingRatioMediumBouncy))
    val tint = when { !enabled -> tokens.textSecondary.copy(alpha = 0.4f); active -> Color.White; else -> tokens.textSecondary }
    // V1.3.5 : forme parfaitement circulaire optionnelle (demandée pour la barre de navigation
    // du bas, façon boutons de télécommande) — inchangé (squircle) pour les autres usages de ce
    // composant (flèche retour, barre du navigateur intégré...).
    val formeIcone = if (formeCirculaire) CircleShape else RoundedCornerShape(taille * 0.32f)
    // V1.3.5 : chaque bouton peut avoir sa propre couleur "actif" (celle de son point-repère),
    // au lieu de l'unique couleur d'accent de l'app — demande explicite ("chaque page de
    // boutons affichée comme la couleur de son point"). Si non précisée, retombe sur l'accent.
    val couleurEnfoncee = couleurActive ?: tokens.mainAccent
    val hapticFeedback = LocalHapticFeedback.current

    Box(
        modifier = modifier
            .size(taille)
            .graphicsLayer { scaleX = scale; scaleY = scale }
            .then(
                if (active) Modifier
                    .clip(formeIcone)
                    // Dégradé inversé (sombre en haut, clair en bas) : à l'opposé du dégradé des
                    // boutons au repos (clair en haut) — c'est ce qui donne l'illusion d'un creux.
                    .background(Brush.linearGradient(listOf(lerp(couleurEnfoncee, Color.Black, 0.25f), lerp(couleurEnfoncee, Color.White, 0.08f))))
                    .drawWithCache {
                        val ombreInterne = Brush.radialGradient(colors = listOf(Color.Black.copy(alpha = 0.38f), Color.Transparent), center = Offset(size.width * 0.5f, 0f), radius = size.maxDimension * 0.95f)
                        onDrawWithContent { drawContent(); drawRect(brush = ombreInterne) }
                    }
                    .border(1.dp, Color.Black.copy(alpha = 0.18f), formeIcone)
                else Modifier
                    .then(if (!creuse && enabled) Modifier.shadow(elevation = if (formeCirculaire) 16.dp else 7.dp, shape = formeIcone, ambientColor = tokens.shadowDark, spotColor = tokens.shadowDark) else Modifier)
                    .clip(formeIcone)
                    .background(Brush.linearGradient(listOf(tokens.neuLight, tokens.neuDark)))
                    .then(if (formeCirculaire) Modifier.background(Brush.radialGradient(listOf(Color.White.copy(alpha = 0.32f), Color.Transparent), radius = taille.value * 1.3f)) else Modifier)
                    .then(if (formeCirculaire) Modifier.border(1.dp, Color.White.copy(alpha = 0.55f), formeIcone) else Modifier)
                    .then(if (creuse) Modifier.ombreCreusee(tokens) else Modifier)
            )
            .clickable(interactionSource = interactionSource, indication = null, enabled = enabled) {
                hapticFeedback.performHapticFeedback(HapticFeedbackType.LongPress)
                onClick()
            },
        contentAlignment = Alignment.Center
    ) {
        Icon(icon, description, tint = tint, modifier = Modifier.size(taille * 0.44f))
    }
}

/**
 * V1.3.4.2 : "Glisser pour actualiser" — l'utilisateur tire la liste vers le bas (uniquement
 * quand elle est déjà tout en haut) pour forcer un rechargement. Implémentation volontairement
 * simple et autonome via NestedScrollConnection (API stable) plutôt que l'API expérimentale
 * PullToRefresh de Material3, pour éviter tout risque d'incompatibilité de version.
 */
@Composable
fun TirerPourActualiser(enCours: Boolean, onRafraichir: () -> Unit, content: @Composable BoxScope.() -> Unit) {
    val tokens = AeroGlassDesignSystem.current()
    var distanceTraction by remember { mutableStateOf(0f) }
    val seuilDeclenchement = 100f
    var dejaDeclenche by remember { mutableStateOf(false) }

    val connexionDefilement = remember {
        object : NestedScrollConnection {
            override fun onPostScroll(consumed: Offset, available: Offset, source: NestedScrollSource): Offset {
                // La liste ne peut plus rien consommer (elle est déjà tout en haut) : le reste
                // du geste de traction vers le bas nous revient ici.
                if (source == NestedScrollSource.Drag && available.y > 0f) {
                    distanceTraction = (distanceTraction + available.y * 0.5f).coerceIn(0f, 170f)
                    return Offset(0f, available.y)
                }
                return Offset.Zero
            }
            override suspend fun onPreFling(available: Velocity): Velocity {
                if (distanceTraction > seuilDeclenchement && !dejaDeclenche && !enCours) {
                    dejaDeclenche = true
                    onRafraichir()
                }
                distanceTraction = 0f
                return Velocity.Zero
            }
        }
    }
    // Une fois le chargement terminé, on autorise un nouveau déclenchement par traction.
    LaunchedEffect(enCours) { if (!enCours) dejaDeclenche = false }

    Box(modifier = Modifier.nestedScroll(connexionDefilement)) {
        content()
        AnimatedVisibility(
            visible = distanceTraction > 16f || enCours,
            modifier = Modifier.align(Alignment.TopCenter).padding(top = 10.dp),
            enter = fadeIn(tween(150)), exit = fadeOut(tween(150))
        ) {
            Box(
                modifier = Modifier.size(38.dp)
                    .shadow(elevation = 6.dp, shape = CircleShape, ambientColor = tokens.shadowDark, spotColor = tokens.shadowDark)
                    .clip(CircleShape).background(tokens.glassCardBackground),
                contentAlignment = Alignment.Center
            ) {
                if (enCours) {
                    CircularProgressIndicator(modifier = Modifier.size(18.dp), color = tokens.mainAccent, strokeWidth = 2.5.dp)
                } else {
                    Icon(
                        Icons.Rounded.ArrowDownward, contentDescription = null, tint = tokens.mainAccent,
                        modifier = Modifier.size(17.dp).graphicsLayer { rotationZ = (distanceTraction / seuilDeclenchement * 180f).coerceIn(0f, 180f) }
                    )
                }
            }
        }
    }
}

/**
 * V1.3.4.2 : partage rapide d'un Airdrop/Pronostic sur WhatsApp (avec repli automatique vers
 * le sélecteur de partage générique si WhatsApp n'est pas installé sur l'appareil).
 */
fun partagerViaWhatsApp(contexte: android.content.Context, texte: String) {
    try {
        val intentWhatsApp = Intent(Intent.ACTION_SEND).apply { type = "text/plain"; putExtra(Intent.EXTRA_TEXT, texte); setPackage("com.whatsapp") }
        contexte.startActivity(intentWhatsApp)
    } catch (e: Exception) {
        try {
            val intentGenerique = Intent(Intent.ACTION_SEND).apply { type = "text/plain"; putExtra(Intent.EXTRA_TEXT, texte) }
            contexte.startActivity(Intent.createChooser(intentGenerique, null))
        } catch (e2: Exception) {}
    }
}

/**

 * V1.4 : badge circulaire en relief utilisé pour donner un rendu 3D cohérent à toutes les
 * icônes de premier plan (menus de paramètres, contact "À propos de moi"...). Le dégradé et
 * la bordure lumineuse restent subtils (alpha ≤ 0.28) pour ne jamais éblouir, tout en donnant
 * une vraie sensation de profondeur/relief à l'icône, qui reste teintée avec la couleur
 * d'accent du thème actif.
 */
@Composable
fun IconeBadge3D(icone: ImageVector, tokens: GlassColors, taille: androidx.compose.ui.unit.Dp = 42.dp, tailleIcone: androidx.compose.ui.unit.Dp = 21.dp) {
    // V1.3.1 : légère respiration animée en continu (alpha de la lueur + micro-zoom),
    // pour donner un rendu vivant "4D" à chaque badge, tout en restant très subtil.
    // V1.3.5 CORRIGÉ : lit désormais une seule animation partagée par toute l'application
    // (voir LocalRespirationBadge) au lieu d'en créer une par badge — même rendu visuel.
    val respiration = LocalRespirationBadge.current
    Box(
        modifier = Modifier
            .size(taille)
            .graphicsLayer { scaleX = respiration; scaleY = respiration }
            .shadow(elevation = 10.dp, shape = CircleShape, ambientColor = tokens.mainAccent.copy(alpha = 0.28f), spotColor = tokens.mainAccent.copy(alpha = 0.4f))
            .clip(CircleShape)
            .background(Brush.linearGradient(listOf(tokens.mainAccent.copy(alpha = 0.26f), tokens.mainAccent.copy(alpha = 0.06f))))
            .background(Brush.verticalGradient(listOf(Color.White.copy(alpha = 0.08f), Color.Transparent)))
            .border(1.dp, Brush.linearGradient(listOf(tokens.mainAccent.copy(alpha = 0.55f), tokens.glassCardBorder.copy(alpha = 0.25f))), CircleShape),
        contentAlignment = Alignment.Center
    ) { Icon(icone, contentDescription = null, tint = tokens.mainAccent, modifier = Modifier.size(tailleIcone)) }
}

/**
 * V1.3 : variante de IconeBadge3D affichant une icône chargée directement depuis internet
 * (icônes officielles des marques — Email, WhatsApp, LinkedIn, GitHub...) plutôt qu'une icône
 * Material locale.
 * V1.3.5 CORRIGÉ :
 * - le rond de fond était teinté avec le vert d'accent de l'appli, ce qui écrasait/dénaturait
 *   les couleurs de marque d'origine (rouge YouTube, bleu LinkedIn, etc.) — remplacé par un
 *   rond blanc neutre, sur lequel les couleurs d'origine ressortent correctement.
 * - l'icône ne remplissait qu'environ la moitié du rond ; elle est agrandie pour le remplir
 *   presque entièrement.
 * - si l'icône ne charge pas depuis cdn.simpleicons.org (ex. LinkedIn qui pouvait s'afficher
 *   comme un globe), une seconde tentative est faite automatiquement sur un serveur miroir
 *   (jsDelivr) avant d'abandonner sur l'icône générique de secours.
 */
@Composable
fun IconeBadge3DUrl(iconUrl: String, tokens: GlassColors, taille: androidx.compose.ui.unit.Dp = 42.dp, tailleIcone: androidx.compose.ui.unit.Dp = 30.dp) {
    val slug = remember(iconUrl) { iconUrl.substringAfterLast('/').substringBefore('?') }
    val urlMiroir = remember(slug) { "https://cdn.jsdelivr.net/npm/simple-icons@latest/icons/$slug.svg" }
    Box(
        modifier = Modifier
            .size(taille)
            .shadow(elevation = 8.dp, shape = CircleShape, ambientColor = Color.Black.copy(alpha = 0.18f), spotColor = Color.Black.copy(alpha = 0.24f))
            .clip(CircleShape)
            .background(Color.White)
            .border(1.dp, tokens.glassCardBorder.copy(alpha = 0.35f), CircleShape),
        contentAlignment = Alignment.Center
    ) {
        SubcomposeAsyncImage(
            model = iconUrl, contentDescription = null, contentScale = ContentScale.Fit,
            loading = { ShimmerPlaceholder(modifier = Modifier.size(tailleIcone).clip(CircleShape)) },
            error = {
                SubcomposeAsyncImage(
                    model = urlMiroir, contentDescription = null, contentScale = ContentScale.Fit,
                    loading = { ShimmerPlaceholder(modifier = Modifier.size(tailleIcone).clip(CircleShape)) },
                    error = { Icon(Icons.Rounded.Public, contentDescription = null, tint = tokens.mainAccent, modifier = Modifier.size(tailleIcone)) },
                    modifier = Modifier.size(tailleIcone)
                )
            },
            modifier = Modifier.size(tailleIcone)
        )
    }
}

/**
 * V1.3 corrigée (points 2 et 6) : bloc de code de parrainage mis en évidence.
 * Contrairement aux anciens panneaux sombres génériques (retirés partout ailleurs dans
 * l'appli), ce bloc est volontairement contrasté avec la couleur d'accent du thème :
 * c'est l'un des seuls éléments que l'utilisateur ne doit jamais pouvoir manquer.
 */
@Composable
fun BlocCodeParrainage(code: String, copie: Boolean, onCopie: () -> Unit) {
    val tokens = AeroGlassDesignSystem.current()
    val clipboard = LocalClipboardManager.current
    val contexte = LocalContext.current
    val langue = LocalLangue.current.value
    val shape = RoundedCornerShape(12.dp)

    // V1.3.3 : NÉOMORPHISME — le bloc devient une zone "creusée"/gravée dans la carte (fond en
    // dégradé inversé + ombre interne), avec le bouton COPIER qui, lui, reste bombé/en relief
    // — le contraste bombé/creusé rend la hiérarchie (donnée vs action) lisible d'un coup d'œil.
    // Le fond et l'ombre interne sont dans une couche séparée du contenu pour ne jamais
    // assombrir le texte ni le bouton posés par-dessus.
    Box(modifier = Modifier.fillMaxWidth()) {
        Box(Modifier.matchParentSize().clip(shape).background(Brush.linearGradient(listOf(tokens.neuInsetDark, tokens.neuInsetLight))).ombreCreusee(tokens))
        Column(modifier = Modifier.fillMaxWidth().padding(horizontal = 13.dp, vertical = 11.dp)) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Icon(Icons.Rounded.CardGiftcard, contentDescription = null, tint = tokens.textSecondary, modifier = Modifier.size(13.dp))
                Spacer(Modifier.width(6.dp))
                PremiumText(Traductions.getString("code_parrainage_titre", langue), color = tokens.textSecondary, size = 9.5f, fontWeight = FontWeight.ExtraBold)
            }
            Spacer(Modifier.height(6.dp))
            Row(modifier = Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
                PremiumText(code, color = tokens.textPrimary, size = 18f, fontWeight = FontWeight.Black, modifier = Modifier.weight(1f))
                Spacer(Modifier.width(10.dp))
                AnimatedButton(
                    text = if (copie) Traductions.getString("copie_ok", langue).uppercase() else Traductions.getString("copier", langue).uppercase(),
                    containerColor = tokens.accentSoft, textColor = tokens.mainAccent, textSize = 11.5f
                ) {
                    clipboard.setText(AnnotatedString(code))
                    toastEnHaut(contexte, Traductions.getString("copie_ok", langue))
                    onCopie()
                }
            }
        }
    }
}

/**
 * V1.3.4 : fond d'arrière-plan de l'application.
 * Toutes les animations de fond (rotation, dérive, particules, pulsation, balayage...)
 * ont été supprimées : le fond est désormais entièrement STATIQUE (aucun mouvement, aucun
 * scintillement), pour un rendu plus sobre et surtout pour garantir une meilleure
 * lisibilité de tous les textes affichés par-dessus. Le fond continue néanmoins de
 * s'adapter automatiquement à chaque thème puisqu'il est entièrement composé à partir des
 * couleurs (fond de base, accent, bordure) fournies par AeroGlassDesignSystem pour le
 * thème actuellement sélectionné — contrairement à un fond à teintes fixes, il change donc
 * bien d'aspect avec chaque thème choisi par l'utilisateur.
 */
@Composable
fun FondThemeStatique(modifier: Modifier = Modifier) {
    val tokens = AeroGlassDesignSystem.current()
    // V1.3.5 CORRIGÉ : en mode noir pur, ces halos décoratifs étaient teintés avec la couleur
    // d'accent (le vert à l'origine) — même à faible opacité, cela donnait l'impression que le
    // fond n'était pas un noir complet ("vert sombre" perçu au lieu d'un noir pur). Demande
    // explicite : le mode sombre doit être un noir plat, sans aucune teinte de couleur. Les
    // halos décoratifs restent donc réservés au thème clair ; en mode sombre, le fond est
    // uniquement `tokens.baseBackground` (#000000), sans rien par-dessus.
    val modeSombre = LocalAppTheme.current.value == "Sombre"
    BoxWithConstraints(modifier = modifier.fillMaxSize().clipToBounds().background(tokens.baseBackground)) {
        if (!modeSombre) {
            val largeur = maxWidth
            val hauteur = maxHeight

            // V1.3.5 CORRIGÉ : ces 3 halos utilisaient `Modifier.blur`, une opération coûteuse
            // à recalculer (surtout sur les appareils plus anciens) qui rendait l'application
            // moins fluide. Remplacés par des dégradés radiaux à plusieurs paliers de
            // transparence : rendu "doux sur les bords" conservé, sans coût de flou réel.
            // Halo doux et fixe en haut à gauche (aucune animation), pour éviter un fond
            // totalement plat tout en restant discret et reposant pour les yeux.
            Box(
                modifier = Modifier
                    .size(largeur * 1.1f)
                    .align(Alignment.TopStart)
                    .offset(x = -largeur * 0.25f, y = -hauteur * 0.12f)
                    .clip(CircleShape)
                    .background(Brush.radialGradient(colorStops = arrayOf(0.0f to tokens.mainAccent.copy(alpha = 0.20f), 0.5f to tokens.mainAccent.copy(alpha = 0.10f), 1.0f to Color.Transparent)))
            )
            // Halo doux et fixe en bas à droite (aucune animation).
            Box(
                modifier = Modifier
                    .size(largeur * 1.2f)
                    .align(Alignment.BottomEnd)
                    .offset(x = largeur * 0.22f, y = hauteur * 0.15f)
                    .clip(CircleShape)
                    .background(Brush.radialGradient(colorStops = arrayOf(0.0f to tokens.glassCardBorder.copy(alpha = 0.18f), 0.5f to tokens.glassCardBorder.copy(alpha = 0.09f), 1.0f to Color.Transparent)))
            )
            // Halo central très discret pour éviter un centre d'écran trop uniforme.
            Box(
                modifier = Modifier
                    .size(largeur * 0.6f)
                    .align(Alignment.Center)
                    .clip(CircleShape)
                    .background(Brush.radialGradient(colorStops = arrayOf(0.0f to tokens.mainAccent.copy(alpha = 0.10f), 0.5f to tokens.mainAccent.copy(alpha = 0.05f), 1.0f to Color.Transparent)))
            )
        }
    }
}

/**
 * V1.3.6 : remplace l'ancien halo diffus en haut de chaque page (V1.3.5, dégradé radial façon
 * "lueur" occupant toute la largeur) — demande explicite de ne plus avoir cet effet de halo,
 * tout en gardant un repère de couleur par page (Accueil, Airdrops, Sports, Infos, Paramètres),
 * repris de la couleur du bouton de navigation correspondant. Le nouveau rendu est un bandeau
 * capsule compact, net, avec un vrai relief 3D (reflet clair en surface, ombre portée dessous)
 * et une couleur bien plus vive/saturée — un repère graphique moderne au lieu d'une lueur.
 */
@Composable
fun BandeauAccentPage(couleur: Color, modifier: Modifier = Modifier) {
    Box(modifier = modifier.fillMaxWidth().padding(top = 14.dp, bottom = 4.dp), contentAlignment = Alignment.TopCenter) {
        Box(
            modifier = Modifier
                .width(64.dp)
                .height(6.dp)
                .shadow(elevation = 14.dp, shape = RoundedCornerShape(50), ambientColor = couleur.copy(alpha = 0.65f), spotColor = couleur.copy(alpha = 0.75f))
                .clip(RoundedCornerShape(50))
                .background(Brush.horizontalGradient(listOf(couleur.copy(alpha = 0.35f), couleur, couleur.copy(alpha = 0.35f))))
        ) {
            // Reflet supérieur, pour l'aspect "bombé" (3D) plutôt que plat.
            Box(
                modifier = Modifier
                    .fillMaxWidth(0.55f)
                    .height(2.dp)
                    .align(Alignment.TopCenter)
                    .clip(RoundedCornerShape(50))
                    .background(Color.White.copy(alpha = 0.55f))
            )
        }
    }
}

/**
 * V1.3.4 : ancien sélecteur d'animations de fond (Orbite Lumineuse, Vagues Douces,
 * Particules Flottantes, Pouls Central, Dérive Diagonale, Ruban Argenté), désormais
 * remplacé par un unique fond STATIQUE respectant le thème actif (voir FondThemeStatique
 * ci-dessus). Cette fonction est conservée (même nom, même signature) uniquement pour ne
 * rien changer à son point d'appel dans ConteneurNavigationPrincipal.
 */
@Composable
fun FondAnimeSelectionne(modifier: Modifier = Modifier) {
    FondThemeStatique(modifier)
}


/**
 * V1.3 : journal des modifications de CHAQUE version passée (et pas seulement de la
 * dernière). Ces logs restent stockés en dur dans l'application (donc conservés à chaque
 * régénération/mise à jour du projet) et sont affichés dans un historique complet et
 * dépliable depuis l'écran "Nouveautés de la version", accessible à tout moment.
 */
data class EntreeLogVersion(val version: String, val titre: String, val changements: List<String>)

// RÈGLE PERMANENTE : cet historique est lu par les utilisateurs finaux, pas par des
// développeurs. À CHAQUE nouvelle entrée ajoutée ici (à chaque mise à jour de l'app),
// rester volontairement simple : quelques phrases courtes, un langage courant, aucun
// terme technique (pas de nom de bug interne, pas de nom de fichier/librairie/protocole,
// pas de détail d'implémentation). Décrire uniquement ce que l'utilisateur voit ou gagne.
object HistoriqueVersions {
    val versions = listOf(
        EntreeLogVersion(
            version = "1.3.6",
            titre = "Version 1.3.6 — Auto-remplissage enrichi & navigateur modernisé",
            changements = listOf(
                "Nouveaux champs Ville, Code postal, Pays et Genre ajoutés au profil d'auto-remplissage.",
                "L'indicatif téléphonique se sélectionne désormais correctement dans les listes déroulantes des sites qui en proposent une.",
                "Chaque information de l'onglet Infos est repliée par défaut avec une flèche pour la dérouler.",
                "Le bouton Partager inclut maintenant le code d'invitation ou promo, en plus du lien.",
                "Halo de couleur en haut des pages remplacé par un repère plus moderne, sans effet flou.",
                "Interface du navigateur intégré modernisée, barre du bas mieux centrée et repositionnée."
            )
        ),
        EntreeLogVersion(
            version = "1.3.5",
            titre = "Version 1.3.5 — Corrections & mode noir",
            changements = listOf(
                "Correction d'un plantage au défilement dans Airdrops.",
                "Icônes des réseaux sociaux et des contacts à nouveau affichées dans leurs couleurs d'origine, en plus grand.",
                "Mode sombre remplacé par un vrai noir profond, sans aucune teinte de couleur en fond.",
                "Vert retiré de partout dans l'app (accent, bordures) sauf pour confirmer un pronostic gagnant.",
                "Réglages de police et de mode nuit automatique retirés, pour des Paramètres plus simples.",
                "Étiquette \"Nouveau\" et tous les emojis retirés de l'application.",
                "Correction du bouton retour dans les sous-pages des Paramètres.",
                "Verrouillage par code à 4 chiffres disponible pour la section Auto-remplissage & Mots de passe.",
                "Score du match affiché sur les pronostics quand disponible.",
                "Pronostics triés du plus récent au plus ancien.",
                "Bouton pour effacer la recherche, et chargement progressif des listes.",
                "Ajout d'une date sur les cartes de l'onglet Infos."
            )
        ),
        EntreeLogVersion(
            version = "1.3.4.2",
            titre = "Version 1.3.4.2 — Partage, apparence personnalisable & améliorations",
            changements = listOf(
                "Nouvel onglet visible clairement actif dans la barre de navigation (pilule colorée).",
                "Bouton de partage sur les Airdrops et les Pronostics, pour envoyer une opportunité à un ami en un tap.",
                "Réglages d'apparence enrichis : taille du texte et police ajustables dans Paramètres > Apparence.",
                "Mention du temps estimé et du niveau ajoutée sur les cartes Airdrops quand l'information est disponible.",
                "Descriptions longues désormais repliables (\"Lire la suite\" / \"Réduire\").",
                "Mode hors-ligne : un message discret indique désormais la date des dernières données disponibles.",
                "Petit rappel de prudence ajouté sur les pages Airdrops et Pronostics.",
                "Transition légère et douce entre les onglets de navigation.",
                "Petite vibration de confirmation lors d'un appui sur les boutons et onglets."
            )
        ),
        EntreeLogVersion(
            version = "1.3.4.1",
            titre = "Version 1.3.4.1 — Interface resserrée & navigateur affiné",
            changements = listOf(
                "Espacements réduits dans toute l'application : cartes, boutons, textes, Paramètres, Auto-remplissage... tout est plus compact.",
                "Titres des sous-pages et barre de recherche allégés.",
                "Barre de navigation principale : fond uni au lieu de transparent, icônes mieux espacées.",
                "Navigateur intégré : barres du haut et du bas affinées, icône des onglets remplacée par un simple compteur, icônes recentrées.",
                "Bouton grisé (\"S'inscrire\"/\"Rejoindre\") désormais visible même désactivé, grâce à un contour discret."
            )
        ),
        EntreeLogVersion(
            version = "1.3.4",
            titre = "Version 1.3.4 — Nouveau design & données mises en cache",
            changements = listOf(
                "Nouvelle apparence néomorphisme : cartes et boutons en relief (bombés/creusés), accent vert, contours nets partout dans l'application.",
                "Navigateur intégré entièrement relooké : barres du haut et du bas modernisées, boutons en relief, barre de progression assortie.",
                "Bouton \"S'inscrire\"/\"Rejoindre\" grisé : le message d'aide pour copier le code n'apparaît plus que lorsqu'on essaie vraiment d'appuyer dessus.",
                "Les airdrops, pronostics et inscriptions se chargent désormais plus vite et restent disponibles hors-ligne grâce à une mise en cache automatique."
            )
        ),
        EntreeLogVersion(
            version = "1.3.3",
            titre = "Version 1.3.3 — Pronostics corrigés & nouveau design épuré",
            changements = listOf(
                "Correction de l'onglet Pronostics, qui n'affichait plus les pronostics du jour.",
                "Statut de chaque pronostic (gagné ou perdu) désormais mis en couleur pour le repérer d'un coup d'œil.",
                "Messages d'information toujours affichés en haut de l'écran, de façon fiable sur tous les téléphones.",
                "Relief et profondeur légèrement renforcés sur les cartes et les boutons pour un rendu plus moderne.",
                "Nouveau design unique et épuré : cartes et champs entièrement opaques (fini l'effet transparent/délavé), sur fond clair.",
                "Simplification des réglages d'apparence : plus qu'un seul thème disponible, les réglages de densité, formes et taille de texte ont été retirés au profit d'une présentation fixe et optimisée.",
                "Navigateur intégré modernisé : nom du site affiché dans la barre du haut, icônes retravaillées."
            )
        ),
        EntreeLogVersion(
            version = "1.3.2",
            titre = "Version 1.3.2 — Nouvelle apparence & navigateur plus fiable",
            changements = listOf(
                "Nouveau fond animé personnalisable, avec plusieurs styles au choix dans Réglages > Apparence.",
                "Nouveaux thèmes sombres, plus élégants et plus reposants pour les yeux.",
                "Navigation dans l'application plus rapide et plus fluide.",
                "Wallet / Exchange regroupé directement dans la section Airdrops, plus simple à retrouver.",
                "Cartes et boutons mieux délimités, pour distinguer plus facilement chaque élément.",
                "Navigateur intégré plus fiable : moins de pages bloquées, et un bouton pour ouvrir une page dans un vrai navigateur si besoin.",
                "Les liens YouTube, WhatsApp, Play Store et réseaux sociaux s'ouvrent désormais directement dans leur application.",
                "Le mot de passe enregistré n'est plus redemandé à chaque connexion sur un site déjà connu.",
                "Nouveau fond animé « Ruban Argenté », gris et turquoise, en plus des styles déjà disponibles.",
                "Auto-remplissage des formulaires amélioré, y compris sur des sites qui posaient problème auparavant."
            )
        ),
        EntreeLogVersion(
            version = "1.3.1",
            titre = "Version 1.3.1 — Mise à jour automatique & nouvelle interface",
            changements = listOf(
                "L'application peut désormais se mettre à jour toute seule, sans passer par un site internet.",
                "Nouveau bouton dans les Réglages pour vérifier les mises à jour à tout moment.",
                "Barre de progression affichée pendant le téléchargement d'une mise à jour.",
                "Nouveau fond animé, plus lumineux et plus vivant.",
                "Quatre nouveaux thèmes de couleur ajoutés.",
                "Interface retravaillée avec un léger effet de relief sur les boutons et les cartes."
            )
        ),
        EntreeLogVersion(
            version = "1.3",
            titre = "Version 1.3 — Navigation & interface",
            changements = listOf(
                "Correction de l'auto-remplissage du nom d'utilisateur sur les sites.",
                "Nouveau fond animé, adapté aux couleurs du thème choisi.",
                "Nouveau bouton d'historique dans le navigateur intégré.",
                "Courte vidéo de présentation ajoutée à l'installation et à chaque mise à jour.",
                "Historique complet des versions désormais consultable.",
                "Interface harmonisée sur toute l'application."
            )
        ),
        EntreeLogVersion(
            version = "1.2",
            titre = "Version 1.2 — Navigateur intégré & sécurité",
            changements = listOf(
                "Auto-remplissage intelligent et mots de passe enregistrés en toute sécurité.",
                "Connexion Google/Apple ouverte dans un vrai navigateur pour éviter les blocages.",
                "Corrections de stabilité générale."
            )
        ),
        EntreeLogVersion(
            version = "1.1",
            titre = "Version 1.1 — Thèmes & apparence",
            changements = listOf(
                "Nouveaux thèmes, polices et formes de cartes/boutons.",
                "Interface affinée.",
                "Corrections diverses."
            )
        ),
        EntreeLogVersion(
            version = "1.0",
            titre = "Version 1.0 — Lancement",
            changements = listOf(
                "Première version de Gombo Business.",
                "Suivi des airdrops, pronostics sportifs et inscriptions bookmaker."
            )
        )
    )
}

/** V1.3 : dialogue affiché avant les nouveautés (première installation et chaque mise à jour). */
@Composable
fun DialogTutorielVideo(onContinuer: () -> Unit) {
    val tokens = AeroGlassDesignSystem.current()
    val langue = LocalLangue.current.value
    val contexte = LocalContext.current
    Dialog(onDismissRequest = onContinuer) {
        Box(Modifier.fillMaxWidth().clip(RoundedCornerShape(24.dp)).background(tokens.baseBackground).border(1.5.dp, tokens.glassCardBorder, RoundedCornerShape(24.dp)).padding(24.dp)) {
            Column(horizontalAlignment = Alignment.CenterHorizontally) {
                PremiumText(Traductions.getString("tuto_titre", langue), color = tokens.textPrimary, size = 18f, fontWeight = FontWeight.Black, is3D = true, textAlign = TextAlign.Center)
                Spacer(Modifier.height(10.dp))
                PremiumText(Traductions.getString("tuto_desc", langue), color = tokens.textSecondary, size = 13f, textAlign = TextAlign.Center, lineHeight = 19f)
                Spacer(Modifier.height(22.dp))
                // Le lien YouTube est volontairement "compressé" en un simple bouton d'action :
                // l'URL brute n'est jamais affichée à l'utilisateur.
                AnimatedButton(Traductions.getString("tuto_bouton", langue), Color(0xFFD32F2F), Color.White, Modifier.fillMaxWidth()) {
                    try { contexte.startActivity(Intent(Intent.ACTION_VIEW, Uri.parse("https://youtube.com/playlist?list=PLMbp2XstBa4A&si=s5Di4alo2ScUuKUX"))) } catch (e: Exception) {}
                }
                Spacer(Modifier.height(12.dp))
                AnimatedButton(Traductions.getString("continuer", langue), tokens.glassCardBackground, tokens.textPrimary, Modifier.fillMaxWidth(), onClick = onContinuer)
            }
        }
    }
}

@Composable
fun DialogNouveautes(onDismiss: () -> Unit) {
    val tokens = AeroGlassDesignSystem.current()
    val langue = LocalLangue.current.value
    var versionOuverte by remember { mutableStateOf(HistoriqueVersions.versions.firstOrNull()?.version) }
    Dialog(onDismissRequest = onDismiss) {
        Box(Modifier.fillMaxWidth().clip(RoundedCornerShape(24.dp)).background(tokens.baseBackground).border(1.5.dp, tokens.glassCardBorder, RoundedCornerShape(24.dp)).padding(24.dp)) {
            Column {
                PremiumText(Traductions.getString("nouveautes", langue), color = tokens.mainAccent, size = 20f, fontWeight = FontWeight.ExtraBold, is3D = true)
                Spacer(Modifier.height(4.dp))
                PremiumText(Traductions.getString("nouveautes_sous_titre", langue), color = tokens.textSecondary, size = 12f)
                Spacer(Modifier.height(16.dp))
                // V1.3 : historique complet, dépliable version par version (et plus seulement
                // la dernière mise à jour) — les logs de chaque version restent consultables ici.
                LazyColumn(modifier = Modifier.heightIn(max = 380.dp), verticalArrangement = Arrangement.spacedBy(10.dp)) {
                    items(HistoriqueVersions.versions) { log ->
                        val estOuvert = versionOuverte == log.version
                        PremiumGlassCard(modifier = Modifier.fillMaxWidth(), paddingMult = 0.75f, onClick = { versionOuverte = if (estOuvert) null else log.version }) {
                            Row(Modifier.fillMaxWidth(), Arrangement.SpaceBetween, Alignment.CenterVertically) {
                                PremiumText(log.titre, color = if (estOuvert) tokens.mainAccent else tokens.textPrimary, size = 14f, fontWeight = FontWeight.Bold, modifier = Modifier.weight(1f))
                                Icon(if (estOuvert) Icons.Rounded.ExpandLess else Icons.Rounded.ExpandMore, contentDescription = null, tint = tokens.mainAccent)
                            }
                            AnimatedVisibility(visible = estOuvert) {
                                Column(Modifier.padding(top = 10.dp)) {
                                    log.changements.forEach { item ->
                                        Row(Modifier.padding(bottom = 6.dp)) { PremiumText("• ", tokens.textSecondary, 13f); PremiumText(item, tokens.textPrimary, 13f, lineHeight = 18f) }
                                    }
                                }
                            }
                        }
                    }
                }
                Spacer(Modifier.height(24.dp))
                AnimatedButton(Traductions.getString("fermer", langue), tokens.mainAccent, tokens.buttonText, Modifier.fillMaxWidth(), onClick = onDismiss)
            }
        }
    }
}

/**
 * V1.3.1 : dialogue du système de mise à jour in-app. Trois états successifs gérés par la
 * progression exposée par [gestionnaire] : proposition (changelog + boutons), téléchargement
 * (barre de progression 0-100%, aucun bouton — l'installation se lance automatiquement à
 * 100%), et échec (bouton pour réessayer). Si `info.forceUpdate` est vrai, le bouton
 * "Plus tard" est masqué et le dialogue ne peut pas être fermé en tapant à côté.
 */
@Composable
fun DialogMiseAJour(info: InfoMiseAJour, gestionnaire: GestionnaireMiseAJour, onPlusTard: () -> Unit) {
    val tokens = AeroGlassDesignSystem.current()
    val langue = LocalLangue.current.value
    val progression by gestionnaire.progression.collectAsState()
    val telechargementLance = progression >= 0

    Dialog(onDismissRequest = { if (!info.forceUpdate && !telechargementLance) onPlusTard() }) {
        Box(Modifier.fillMaxWidth().clip(RoundedCornerShape(24.dp)).background(tokens.baseBackground).border(1.5.dp, tokens.glassCardBorder, RoundedCornerShape(24.dp)).padding(24.dp)) {
            Column {
                IconeBadge3D(Icons.Rounded.SystemUpdate, tokens, taille = 52.dp, tailleIcone = 26.dp)
                Spacer(Modifier.height(14.dp))
                PremiumText(Traductions.getString("maj_disponible_titre", langue), color = tokens.mainAccent, size = 19f, fontWeight = FontWeight.ExtraBold, is3D = true)
                Spacer(Modifier.height(4.dp))
                PremiumText("${Traductions.getString("version_label", langue)} ${info.versionName}", color = tokens.textSecondary, size = 13f)
                Spacer(Modifier.height(16.dp))

                if (progression == -2) {
                    PremiumText(Traductions.getString("maj_echec_txt", langue), color = tokens.textPrimary, size = 13.5f, lineHeight = 19f)
                    Spacer(Modifier.height(20.dp))
                    Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                        if (!info.forceUpdate) AnimatedButton(Traductions.getString("maj_plus_tard", langue), tokens.glassCardBackground, tokens.textPrimary, Modifier.weight(1f), onClick = onPlusTard)
                        AnimatedButton(Traductions.getString("maj_mettre_a_jour", langue), tokens.mainAccent, tokens.buttonText, Modifier.weight(1f)) { gestionnaire.reinitialiser(); gestionnaire.telechargerEtInstaller(info.apkUrl) }
                    }
                } else if (telechargementLance) {
                    PremiumText(Traductions.getString("maj_telechargement_txt", langue), color = tokens.textPrimary, size = 13.5f)
                    Spacer(Modifier.height(14.dp))
                    LinearProgressIndicator(
                        progress = { (progression.coerceIn(0, 100)) / 100f },
                        modifier = Modifier.fillMaxWidth().height(10.dp).clip(RoundedCornerShape(6.dp)),
                        color = tokens.mainAccent, trackColor = tokens.glassCardBorder
                    )
                    Spacer(Modifier.height(8.dp))
                    PremiumText("${progression.coerceIn(0, 100)}%", color = tokens.mainAccent, size = 13f, fontWeight = FontWeight.Bold)
                } else {
                    Column(modifier = Modifier.heightIn(max = 220.dp).verticalScroll(rememberScrollState())) {
                        info.changelog.forEach { item ->
                            Row(Modifier.padding(bottom = 6.dp)) { PremiumText("• ", tokens.textSecondary, 13f); PremiumText(item, tokens.textPrimary, 13f, lineHeight = 18f) }
                        }
                    }
                    if (info.forceUpdate) {
                        Spacer(Modifier.height(12.dp))
                        PremiumText(Traductions.getString("maj_obligatoire_txt", langue), color = tokens.mainAccent, size = 12.5f, fontWeight = FontWeight.SemiBold, lineHeight = 17f)
                    }
                    Spacer(Modifier.height(20.dp))
                    Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                        if (!info.forceUpdate) AnimatedButton(Traductions.getString("maj_plus_tard", langue), tokens.glassCardBackground, tokens.textPrimary, Modifier.weight(1f), onClick = onPlusTard)
                        AnimatedButton(Traductions.getString("maj_mettre_a_jour", langue), tokens.mainAccent, tokens.buttonText, Modifier.weight(1f)) { gestionnaire.telechargerEtInstaller(info.apkUrl) }
                    }
                }
            }
        }
    }
}

@Composable
fun EcranAccueil() {
    val contexte = LocalContext.current
    val langue = LocalLangue.current.value
    val isOnline = LocalIsOnline.current
    val tokens = AeroGlassDesignSystem.current()

    // V1.3.4.3 : icônes chargées depuis simpleicons.org dans leur couleur de marque
    // d'origine (le suffixe "/ffffff" qui les forçait en blanc a été retiré) — même traitement
    // que les icônes de contact de l'écran "À propos de moi" — au lieu des anciens logos
    // multicolores, pour une interface plus sobre et cohérente d'un écran à l'autre.
    val networks = listOf(
        ReseauSocial("https://cdn.simpleicons.org/whatsapp", "https://chat.whatsapp.com/D63xGJwNg7T3jqEnnYI1hE"),
        ReseauSocial("https://cdn.simpleicons.org/youtube", "https://www.youtube.com/@gombocrypto"),
        ReseauSocial("https://cdn.simpleicons.org/odysee", "https://odysee.com/@GomboCrypto1:c"),
        ReseauSocial("https://cdn.simpleicons.org/tiktok", "https://www.tiktok.com/@legomboniste"),
        ReseauSocial("https://cdn.simpleicons.org/facebook", "https://www.facebook.com/gombocrypto/"),
        ReseauSocial("https://cdn.simpleicons.org/instagram", "https://www.instagram.com/gombocrypto1/"),
        ReseauSocial("https://cdn.simpleicons.org/x", "https://x.com/gombocrypto")
    )

    var visible by remember { mutableStateOf(false) }
    LaunchedEffect(Unit) { visible = true }

    Box(modifier = Modifier.fillMaxSize()) {
        // V1.3.6 : bandeau bleu (même couleur que le bouton "Accueil" de la barre du bas) pour
        // différencier cette page visuellement, pas seulement son bouton de navigation.
        BandeauAccentPage(Color(0xFF00B0FF))
        AnimatedVisibility(visible = visible, enter = fadeIn(tween(800))) {
            Column(modifier = Modifier.fillMaxSize().verticalScroll(rememberScrollState()).padding(20.dp), horizontalAlignment = Alignment.CenterHorizontally) {
                Spacer(modifier = Modifier.height(20.dp))
                PremiumText("GOMBO BUSINESS", color = tokens.textPrimary, size = 28f, fontWeight = FontWeight.Black, is3D = true, modifier = Modifier.padding(bottom = 30.dp))

                Column(horizontalAlignment = Alignment.CenterHorizontally, modifier = Modifier.fillMaxWidth()) {
                    Box(modifier = Modifier.size(130.dp), contentAlignment = Alignment.Center) {
                        key(isOnline) {
                            SubcomposeAsyncImage(
                                model = "https://raw.githubusercontent.com/Legombonistebiz/GOMBO-BUSINESS-APP/refs/heads/main/logo_profil.png",
                                contentDescription = null,
                                contentScale = ContentScale.Crop,
                                loading = { ShimmerPlaceholder(modifier = Modifier.fillMaxSize()) },
                                error = { IconePlaceholderElegant(modifier = Modifier.fillMaxSize(), icone = Icons.Rounded.Storefront) },
                                modifier = Modifier.fillMaxSize().shadow(elevation = 24.dp, shape = CircleShape, ambientColor = tokens.mainAccent.copy(alpha = 0.3f), spotColor = tokens.mainAccent.copy(alpha = 0.4f)).clip(CircleShape).background(Brush.radialGradient(listOf(tokens.glassCardBackground, tokens.glassCardBackground.copy(alpha = 0.7f)))).background(Brush.verticalGradient(listOf(Color.White.copy(alpha = 0.06f), Color.Transparent))).border(4.dp, Brush.linearGradient(listOf(tokens.mainAccent, tokens.glassCardBorder)), CircleShape)
                            )
                        }
                    }
                    Spacer(modifier = Modifier.height(24.dp))
                    PremiumText(Traductions.getString("profil_desc", langue), color = tokens.textSecondary, size = 15f, textAlign = TextAlign.Center, lineHeight = 22f)
                }

                Spacer(modifier = Modifier.height(40.dp))
                PremiumText("Réseaux Sociaux", color = tokens.textPrimary, size = 18f, fontWeight = FontWeight.Bold, is3D = true, modifier = Modifier.align(Alignment.Start).padding(bottom = 20.dp, start = 8.dp))

                Column(horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(20.dp)) {
                    Row(horizontalArrangement = Arrangement.spacedBy(24.dp)) { networks.take(4).forEach { SocialIcon(it, contexte, isOnline) } }
                    Row(horizontalArrangement = Arrangement.spacedBy(24.dp)) { networks.drop(4).forEach { SocialIcon(it, contexte, isOnline) } }
                }
                Spacer(modifier = Modifier.height(130.dp))
            }
        }
    }
}

/**
 * V1.3.2 : réutilise désormais exactement le même badge d'icône que l'écran "À propos de
 * moi" (IconeBadge3DUrl — cercle en dégradé de l'accent du thème + icône monochrome
 * blanche) plutôt qu'un cercle neutre, pour une apparence cohérente sur toute l'application.
 */
@Composable
fun SocialIcon(net: ReseauSocial, context: android.content.Context, isOnline: Boolean) {
    val tokens = AeroGlassDesignSystem.current()
    val interactionSource = remember { MutableInteractionSource() }
    val isPressed by interactionSource.collectIsPressedAsState()
    val scale by animateFloatAsState(if (isPressed) 0.85f else 1f, spring())

    Box(
        modifier = Modifier.size(56.dp)
            .graphicsLayer { scaleX = scale; scaleY = scale }
            .clip(CircleShape)
            .clickable(interactionSource = interactionSource, indication = null) { context.startActivity(Intent(Intent.ACTION_VIEW, Uri.parse(net.linkUrl))) },
        contentAlignment = Alignment.Center
    ) {
        key(isOnline) { IconeBadge3DUrl(net.iconUrl, tokens, taille = 56.dp, tailleIcone = 38.dp) }
    }
}

/**
 * V1.3.3 : Wallet / Exchange redevient une SOUS-PAGE d'Airdrops (au lieu d'un onglet séparé
 * de la barre de navigation du bas). Exactement le même principe de TabRow que
 * EcranParisSportifs ci-dessous : un seul écran, deux sous-pages accessibles par onglet,
 * chacune alimentée par son propre fichier JSON distant (airdrops.json / wallet_exchange.json).
 * V1.3.3 : espacement entre les cartes nettement augmenté (22dp au lieu de 16dp de base)
 * pour qu'aucune carte ne semble "collée" à la suivante.
 */
@Composable
fun EcranAirdrops(items: List<ElementAirdrop>, walletItems: List<ElementWalletExchange>, enChargement: Boolean = false, onRafraichir: () -> Unit = {}, signalRetourHaut: Int = 0) {
    var onglet by remember { mutableStateOf(0) }
    val langue = LocalLangue.current.value
    val browser = LocalBrowserController.current
    val contexte = LocalContext.current
    val tokens = AeroGlassDesignSystem.current()
    val spacing = 14.dp * currentDensityScale()
    val onglets = listOf(Traductions.getString("nav_air", langue), Traductions.getString("nav_wallet", langue))
    // V1.3.4.2 : cartes terminées / badge "nouveau" (les favoris ont été retirés).
    val interactions = LocalInteractionsStore.current
    // V1.3.4.3 CORRIGÉ : les deux sous-pages (Airdrops / Wallet) partageaient auparavant le
    // MÊME LazyListState alors qu'elles affichent deux listes totalement différentes (nombre
    // d'éléments différent) — au défilement, Compose pouvait se retrouver à appliquer une
    // position de défilement mémorisée pour une liste à un autre LazyColumn ayant moins
    // d'éléments, provoquant une exception d'index hors limites et la fermeture brutale de
    // l'application. Chaque sous-page dispose désormais de son propre état de défilement.
    val etatListeAirdrops = rememberLazyListState()
    val etatListeWallet = rememberLazyListState()
    val etatListe = if (onglet == 1) etatListeWallet else etatListeAirdrops
    LaunchedEffect(signalRetourHaut) { if (signalRetourHaut > 0) etatListe.animateScrollToItem(0) }

    var searchQuery by remember(onglet) { mutableStateOf("") }
    var visible by remember { mutableStateOf(false) }
    LaunchedEffect(Unit) { visible = true }

    Box(modifier = Modifier.fillMaxSize()) {
        // V1.3.6 : bandeau rouge (même couleur que le bouton "Airdrops" de la barre du bas), pour
        // les deux sous-pages (Airdrops et Wallet, qui partagent ce même bouton).
        BandeauAccentPage(Color(0xFFFF1744))
        Column(modifier = Modifier.fillMaxSize()) {
        TabRow(selectedTabIndex = onglet, containerColor = Color.Transparent, contentColor = tokens.mainAccent, indicator = { TabRowDefaults.SecondaryIndicator(Modifier.tabIndicatorOffset(it[onglet]), color = tokens.mainAccent) }) {
            onglets.forEachIndexed { i, titre ->
                Tab(selected = onglet == i, onClick = { onglet = i }, modifier = Modifier.padding(vertical = 6.dp), text = {
                    PremiumText(titre, color = if (onglet == i) tokens.mainAccent else tokens.textSecondary, size = 14f, fontWeight = FontWeight.Bold, is3D = (onglet == i))
                })
            }
        }

        Column(modifier = Modifier.fillMaxSize().padding(horizontal = 20.dp)) {
            Spacer(Modifier.height(10.dp))
            OutlinedTextField(
                value = searchQuery, onValueChange = { searchQuery = it },
                placeholder = { PremiumText(Traductions.getString(if (onglet == 1) "search_wallet" else "search_airdrop", langue), tokens.textSecondary, 14f) },
                leadingIcon = { Icon(Icons.Rounded.Search, contentDescription = null, tint = tokens.textSecondary, modifier = Modifier.size(19.dp)) },
                // V1.3.5 : bouton pour effacer rapidement le texte de recherche, visible seulement s'il y a du texte.
                trailingIcon = {
                    if (searchQuery.isNotEmpty()) {
                        Icon(
                            Icons.Rounded.Close, contentDescription = Traductions.getString("effacer_recherche", langue), tint = tokens.textSecondary,
                            modifier = Modifier.size(18.dp).clickable(interactionSource = remember { MutableInteractionSource() }, indication = null) { searchQuery = "" }
                        )
                    }
                },
                singleLine = true,
                textStyle = androidx.compose.ui.text.TextStyle(fontSize = 14.sp),
                shape = RoundedCornerShape(16.dp),
                colors = OutlinedTextFieldDefaults.colors(focusedBorderColor = tokens.mainAccent, unfocusedBorderColor = tokens.glassCardBorder.copy(alpha = 0.9f), focusedTextColor = tokens.textPrimary, unfocusedTextColor = tokens.textPrimary, cursorColor = tokens.mainAccent),
                modifier = Modifier.fillMaxWidth().heightIn(min = 48.dp).clip(RoundedCornerShape(16.dp)).background(tokens.glassCardBackground)
            )
            Spacer(Modifier.height(8.dp))
            // V1.3.4.2 : petit rappel de prudence, fixe (ne défile pas avec la liste).
            // V1.3.5 : icône Material (au lieu d'un emoji dans le texte) pour l'avertissement.
            Row(verticalAlignment = Alignment.CenterVertically, modifier = Modifier.padding(bottom = 8.dp)) {
                Icon(Icons.Rounded.WarningAmber, contentDescription = null, tint = tokens.textSecondary, modifier = Modifier.size(12.dp))
                Spacer(Modifier.width(5.dp))
                PremiumText(Traductions.getString("conseil_securite", langue), color = tokens.textSecondary, size = 9.5f, fontWeight = FontWeight.Medium)
            }

            if (onglet == 1) {
                val filteredWallet = remember(walletItems, searchQuery) {
                    walletItems.filter { it.titre.contains(searchQuery, ignoreCase = true) }
                }
                if (filteredWallet.isEmpty()) {
                    Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) { PremiumText(Traductions.getString("aucun_wallet", langue), color = tokens.textSecondary, size = 18f, is3D = true) }
                } else {
                    AnimatedVisibility(visible = visible, enter = fadeIn(tween(600))) {
                        TirerPourActualiser(enCours = enChargement, onRafraichir = onRafraichir) {
                            LazyColumn(state = etatListeWallet, contentPadding = PaddingValues(bottom = 130.dp), verticalArrangement = Arrangement.spacedBy(spacing)) {
                                itemsIndexed(filteredWallet, key = { index, walletItem -> "${index}_${walletItem.titre}" }) { _, walletItem ->
                                    // Même règle que pour les Airdrops : le bouton "Rejoindre" reste
                                    // désactivé tant qu'un code d'invitation existe et n'a pas été copié.
                                    var codeCopie by remember(walletItem.codeInvitation) { mutableStateOf(false) }
                                    val rejoindreActif = walletItem.codeInvitation.isNullOrBlank() || codeCopie
                                    var estTermine by remember(walletItem.titre) { mutableStateOf(interactions.estTermine(walletItem.titre)) }
                                    var descriptionEtendue by remember(walletItem.titre) { mutableStateOf(false) }
                                    val depasseLimite = walletItem.description.length > 110

                                    PremiumGlassCard(teinte = Color(0xFFFF1744)) {
                                        Row(verticalAlignment = Alignment.CenterVertically, modifier = Modifier.fillMaxWidth()) {
                                            PremiumText(walletItem.titre, color = tokens.textPrimary, size = 17f, fontWeight = FontWeight.Black)
                                        }
                                        Spacer(Modifier.height(3.dp))
                                        PremiumText(walletItem.description, color = tokens.textSecondary, size = 11.5f, fontWeight = FontWeight.Bold, lineHeight = 15f, maxLines = if (descriptionEtendue) Int.MAX_VALUE else 2, overflow = TextOverflow.Ellipsis)
                                        if (depasseLimite) {
                                            PremiumText(
                                                Traductions.getString(if (descriptionEtendue) "reduire" else "lire_suite", langue), color = tokens.mainAccent, size = 11f, fontWeight = FontWeight.Bold,
                                                modifier = Modifier.padding(top = 4.dp).clickable(interactionSource = remember { MutableInteractionSource() }, indication = null) { descriptionEtendue = !descriptionEtendue }
                                            )
                                        }
                                        walletItem.codeInvitation?.let { code ->
                                            Spacer(Modifier.height(8.dp))
                                            BlocCodeParrainage(code = code, copie = codeCopie, onCopie = { codeCopie = true })
                                        }
                                        Spacer(Modifier.height(8.dp))
                                        Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(10.dp), verticalAlignment = Alignment.CenterVertically) {
                                            walletItem.lienParrainage?.let { lien ->
                                                AnimatedButton(Traductions.getString("rejoindre", langue), tokens.mainAccent, tokens.buttonText, Modifier.weight(1f), enabled = rejoindreActif, onDisabledClick = { toastEnHaut(contexte, Traductions.getString("copier_avant", langue)) }) { ouvrirLien(contexte, browser, lien) }
                                            }
                                            walletItem.lienVideoTuto?.let { AnimatedButton(Traductions.getString("regarder", langue), Color(0xFFD32F2F), Color.White, Modifier.weight(1f)) { ouvrirLien(contexte, browser, it) } }
                                            IconeNavigateur3D(Icons.Rounded.Share, Traductions.getString("partager", langue), taille = 40.dp) {
                                                // V1.3.6 : le code d'invitation/parrainage est désormais inclus dans le
                                                // texte partagé, en plus du lien — auparavant seul le lien y figurait.
                                                partagerViaWhatsApp(contexte, listOfNotNull(
                                                    walletItem.titre,
                                                    walletItem.description,
                                                    walletItem.codeInvitation?.takeIf { it.isNotBlank() }?.let { "${Traductions.getString("code_parrainage_titre", langue)} : $it" },
                                                    walletItem.lienParrainage?.takeIf { it.isNotBlank() }
                                                ).joinToString("\n"))
                                            }
                                        }
                                        CaseMarquerFait(estTermine, tokens) { interactions.toggleTermine(walletItem.titre); estTermine = !estTermine }
                                    }
                                }
                            }
                        }
                    }
                }
            } else {
                val filteredItems = remember(items, searchQuery) {
                    items.filter { it.titre.contains(searchQuery, ignoreCase = true) }
                }
                if (filteredItems.isEmpty()) {
                    Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) { PremiumText(Traductions.getString("aucun_airdrop", langue), color = tokens.textSecondary, size = 18f, is3D = true) }
                } else {
                    AnimatedVisibility(visible = visible, enter = fadeIn(tween(600))) {
                        TirerPourActualiser(enCours = enChargement, onRafraichir = onRafraichir) {
                            LazyColumn(state = etatListeAirdrops, contentPadding = PaddingValues(bottom = 130.dp), verticalArrangement = Arrangement.spacedBy(spacing)) {
                                itemsIndexed(filteredItems, key = { index, airdrop -> "${index}_${airdrop.titre}" }) { _, airdrop ->
                                    // Point 7 : tant qu'un code de parrainage existe et n'a pas été copié,
                                    // le bouton "Rejoindre" reste désactivé pour ce projet précis.
                                    var codeCopie by remember(airdrop.codeInvitation) { mutableStateOf(false) }
                                    val rejoindreActif = airdrop.codeInvitation.isNullOrBlank() || codeCopie
                                    var estTermine by remember(airdrop.titre) { mutableStateOf(interactions.estTermine(airdrop.titre)) }
                                    var descriptionEtendue by remember(airdrop.titre) { mutableStateOf(false) }
                                    var analyseOuverte by remember(airdrop.titre) { mutableStateOf(false) }
                                    val depasseLimite = airdrop.description.length > 110
                                    // V1.3.5 : plus aucun vert dans l'app hormis le repère "pronostic gagnant" —
                                    // le statut "actif" (auparavant vert) passe au bleu.
                                    val couleurStatut = when (airdrop.statut) { "actif" -> Color(0xFF3B9EFF); "urgent" -> Color(0xFFF59E0B); "termine" -> Color(0xFF9CA3AF); else -> null }

                                    PremiumGlassCard(teinte = Color(0xFFFF1744)) {
                                        Row(verticalAlignment = Alignment.CenterVertically) {
                                            couleurStatut?.let { Box(modifier = Modifier.size(8.dp).clip(CircleShape).background(it)); Spacer(Modifier.width(6.dp)) }
                                            PremiumText(airdrop.titre, color = tokens.textPrimary, size = 17f, fontWeight = FontWeight.Black)
                                        }
                                        if (airdrop.dureeEstimee != null || airdrop.niveauDifficulte != null) {
                                            Spacer(Modifier.height(4.dp))
                                            Row(horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                                                airdrop.dureeEstimee?.let { PetitBadge(it, tokens) }
                                                airdrop.niveauDifficulte?.let { PetitBadge(it, tokens) }
                                            }
                                        }
                                        Spacer(Modifier.height(6.dp))
                                        PremiumText(airdrop.description, color = tokens.textSecondary, size = 11.5f, fontWeight = FontWeight.Bold, lineHeight = 15f, maxLines = if (descriptionEtendue) Int.MAX_VALUE else 2, overflow = TextOverflow.Ellipsis)
                                        if (depasseLimite) {
                                            PremiumText(
                                                Traductions.getString(if (descriptionEtendue) "reduire" else "lire_suite", langue), color = tokens.mainAccent, size = 11f, fontWeight = FontWeight.Bold,
                                                modifier = Modifier.padding(top = 4.dp).clickable(interactionSource = remember { MutableInteractionSource() }, indication = null) { descriptionEtendue = !descriptionEtendue }
                                            )
                                        }
                                        airdrop.analysePersonnelle?.let { analyse ->
                                            Spacer(Modifier.height(6.dp))
                                            PremiumText(
                                                Traductions.getString(if (analyseOuverte) "reduire" else "voir_analyse", langue), color = tokens.mainAccent, size = 11.5f, fontWeight = FontWeight.Bold,
                                                modifier = Modifier.clickable(interactionSource = remember { MutableInteractionSource() }, indication = null) { analyseOuverte = !analyseOuverte }
                                            )
                                            if (analyseOuverte) { Spacer(Modifier.height(4.dp)); PremiumText(analyse, color = tokens.textSecondary, size = 11.5f, fontWeight = FontWeight.Medium, lineHeight = 15f) }
                                        }
                                        airdrop.codeInvitation?.let { code ->
                                            Spacer(Modifier.height(8.dp))
                                            BlocCodeParrainage(code = code, copie = codeCopie, onCopie = { codeCopie = true })
                                        }
                                        Spacer(Modifier.height(8.dp))
                                        Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(10.dp), verticalAlignment = Alignment.CenterVertically) {
                                            airdrop.lienParrainage?.let { lien ->
                                                // V1.3.2 : les liens vers une application native (Play Store,
                                                // YouTube, WhatsApp...) s'ouvrent directement dans cette
                                                // application plutôt que dans le navigateur intégré.
                                                AnimatedButton(Traductions.getString("rejoindre", langue), tokens.mainAccent, tokens.buttonText, Modifier.weight(1f), enabled = rejoindreActif, onDisabledClick = { toastEnHaut(contexte, Traductions.getString("copier_avant", langue)) }) { ouvrirLien(contexte, browser, lien) }
                                            }
                                            airdrop.lienVideoTuto?.let { AnimatedButton(Traductions.getString("regarder", langue), Color(0xFFD32F2F), Color.White, Modifier.weight(1f)) { ouvrirLien(contexte, browser, it) } }
                                            // V1.3.4.2 : partage rapide sur WhatsApp — "meilleur moyen de faire
                                            // de la publicité gratuite pour l'application", selon les mots mêmes
                                            // de la demande.
                                            IconeNavigateur3D(Icons.Rounded.Share, Traductions.getString("partager", langue), taille = 40.dp) {
                                                // V1.3.6 : le code d'invitation/parrainage est désormais inclus dans le
                                                // texte partagé, en plus du lien — auparavant seul le lien y figurait.
                                                partagerViaWhatsApp(contexte, listOfNotNull(
                                                    airdrop.titre,
                                                    airdrop.description,
                                                    airdrop.codeInvitation?.takeIf { it.isNotBlank() }?.let { "${Traductions.getString("code_parrainage_titre", langue)} : $it" },
                                                    airdrop.lienParrainage?.takeIf { it.isNotBlank() }
                                                ).joinToString("\n"))
                                            }
                                        }
                                        CaseMarquerFait(estTermine, tokens) { interactions.toggleTermine(airdrop.titre); estTermine = !estTermine }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        }
    }
}

/** V1.3.4.2 : petit badge d'accompagnement (durée / niveau) sur les cartes Airdrops. */
@Composable
fun PetitBadge(texte: String, tokens: GlassColors) {
    Box(modifier = Modifier.clip(RoundedCornerShape(8.dp)).background(tokens.glassCardBorder.copy(alpha = 0.5f)).padding(horizontal = 7.dp, vertical = 3.dp)) {
        PremiumText(texte, color = tokens.textSecondary, size = 10f, fontWeight = FontWeight.Bold)
    }
}

/** V1.3.5 : la pastille "NOUVEAU" a été entièrement retirée sur demande. */

/** V1.3.4.2 : case à cocher "Marquer comme fait" présente en bas de chaque carte. */
@Composable
fun CaseMarquerFait(estTermine: Boolean, tokens: GlassColors, onToggle: () -> Unit) {
    Spacer(Modifier.height(8.dp))
    Row(
        verticalAlignment = Alignment.CenterVertically,
        modifier = Modifier.clickable(interactionSource = remember { MutableInteractionSource() }, indication = null, onClick = onToggle)
    ) {
        Icon(if (estTermine) Icons.Rounded.CheckBox else Icons.Rounded.CheckBoxOutlineBlank, contentDescription = null, tint = if (estTermine) tokens.mainAccent else tokens.textSecondary, modifier = Modifier.size(17.dp))
        Spacer(Modifier.width(6.dp))
        PremiumText("Marquer comme fait", color = if (estTermine) tokens.mainAccent else tokens.textSecondary, size = 11f, fontWeight = FontWeight.Medium)
    }
}

/**
 * V1.3.5 : convertit la date/heure texte d'un pronostic (ex: "09 Juillet 2026 - 20:00 GMT",
 * format utilisé dans pronostics.json) en un instant comparable, pour trier les pronostics du
 * plus récent au plus ancien. Analyse manuelle (plutôt que SimpleDateFormat + Locale.FRENCH,
 * dont la disponibilité des noms de mois varie selon les appareils) : robuste et sans
 * dépendance. En cas de format inattendu, retourne 0 (l'élément se retrouve en fin de liste
 * plutôt que de faire planter le tri).
 */
private val MOIS_FR_PRONOSTIC = mapOf(
    "janvier" to 1, "février" to 2, "fevrier" to 2, "mars" to 3, "avril" to 4, "mai" to 5, "juin" to 6,
    "juillet" to 7, "août" to 8, "aout" to 8, "septembre" to 9, "octobre" to 10, "novembre" to 11,
    "décembre" to 12, "decembre" to 12
)
private val REGEX_DATE_PRONOSTIC = Regex("""(\d{1,2})\s+(\p{L}+)\s+(\d{4})\s*-\s*(\d{1,2}):(\d{2})""")
fun instantDatePronostic(brut: String): Long {
    return try {
        val m = REGEX_DATE_PRONOSTIC.find(brut) ?: return 0L
        val (jour, mois, annee, heure, minute) = m.destructured
        val numeroMois = MOIS_FR_PRONOSTIC[mois.lowercase()] ?: return 0L
        val cal = java.util.Calendar.getInstance(java.util.TimeZone.getTimeZone("GMT"))
        cal.set(annee.toInt(), numeroMois - 1, jour.toInt(), heure.toInt(), minute.toInt(), 0)
        cal.set(java.util.Calendar.MILLISECOND, 0)
        cal.timeInMillis
    } catch (e: Exception) { 0L }
}

@Composable
fun EcranParisSportifs(pronostics: List<ElementPronostic>, inscriptions: List<ElementInscription>, enChargement: Boolean = false, onRafraichir: () -> Unit = {}, signalRetourHaut: Int = 0) {
    var onglet by remember { mutableStateOf(0) }
    val langue = LocalLangue.current.value
    val browser = LocalBrowserController.current
    val contexte = LocalContext.current
    val tokens = AeroGlassDesignSystem.current()
    // V1.3.3 : espacement augmenté (22dp au lieu de 15dp de base) pour que chaque carte
    // (pronostic ou inscription) reste clairement distincte de la suivante.
    val spacing = 14.dp * currentDensityScale()
    val onglets = listOf(Traductions.getString("onglet_insc", langue), Traductions.getString("onglet_prono", langue))
    // V1.3.4.2 : badge "nouveau" (les favoris ont été retirés).
    val interactions = LocalInteractionsStore.current
    // V1.3.5 : pronostics triés du plus récent au plus ancien (date/heure du match).
    val pronosticsTries = remember(pronostics) { pronostics.sortedByDescending { instantDatePronostic(it.dateEtHeure) } }
    // V1.3.4.3 CORRIGÉ : un LazyListState distinct par sous-page (Pronostics / Inscriptions) —
    // voir la même correction et son explication dans EcranAirdrops ci-dessus.
    val etatListePronostics = rememberLazyListState()
    val etatListeInscriptions = rememberLazyListState()
    val etatListe = if (onglet == 1) etatListePronostics else etatListeInscriptions
    LaunchedEffect(signalRetourHaut) { if (signalRetourHaut > 0) etatListe.animateScrollToItem(0) }

    Box(modifier = Modifier.fillMaxSize()) {
        // V1.3.6 : bandeau indigo (même couleur que le bouton "Sports" de la barre du bas), pour
        // les deux sous-pages (Pronostics et Inscriptions, qui partagent ce même bouton).
        BandeauAccentPage(Color(0xFF3D5AFE))
        Column(modifier = Modifier.fillMaxSize()) {
        TabRow(selectedTabIndex = onglet, containerColor = Color.Transparent, contentColor = tokens.mainAccent, indicator = { TabRowDefaults.SecondaryIndicator(Modifier.tabIndicatorOffset(it[onglet]), color = tokens.mainAccent) }) {
            onglets.forEachIndexed { i, titre ->
                Tab(selected = onglet == i, onClick = { onglet = i }, modifier = Modifier.padding(vertical = 12.dp), text = {
                    PremiumText(titre, color = if(onglet == i) tokens.mainAccent else tokens.textSecondary, size = 14f, fontWeight = FontWeight.Bold, is3D = (onglet == i))
                })
            }
        }
        // V1.3.4.2 : petit rappel de prudence, fixe (ne défile pas avec la liste) — ce
        // sont précisément les deux sections concernées (pronostics et parrainages).
        // V1.3.5 : icône Material (au lieu d'un emoji dans le texte) pour l'avertissement.
        Row(verticalAlignment = Alignment.CenterVertically, modifier = Modifier.padding(start = 20.dp, top = 6.dp, end = 20.dp, bottom = 2.dp)) {
            Icon(Icons.Rounded.WarningAmber, contentDescription = null, tint = tokens.textSecondary, modifier = Modifier.size(12.dp))
            Spacer(Modifier.width(5.dp))
            PremiumText(Traductions.getString("conseil_securite", langue), color = tokens.textSecondary, size = 9.5f, fontWeight = FontWeight.Medium)
        }
        if (onglet == 1) {
            if (pronostics.isEmpty()) { Box(Modifier.fillMaxSize(), Alignment.Center) { PremiumText(Traductions.getString("aucun_prono", langue), color = tokens.textSecondary, size = 18f, is3D = true) } }
            else {
                TirerPourActualiser(enCours = enChargement, onRafraichir = onRafraichir) {
                    LazyColumn(state = etatListePronostics, contentPadding = PaddingValues(20.dp, 16.dp, 20.dp, 130.dp), verticalArrangement = Arrangement.spacedBy(spacing)) {
                        itemsIndexed(pronosticsTries, key = { index, prono -> "${index}_${prono.equipes}_${prono.dateEtHeure}" }) { _, prono ->
                            // V1.3.3 : la cote contient elle-même l'émoji de statut du match
                            // (✅ validé / ❌ perdu), ajouté à la main dans pronostics.json.
                            // On colore la cote en conséquence (vert/rouge/jaune) afin que le
                            // statut saute aux yeux — sans jamais afficher l'émoji lui-même.
                            // V1.3.5 CORRIGÉ : l'émoji brut apparaissait auparavant tel quel dans
                            // le texte affiché ; il est maintenant retiré de l'affichage (et du
                            // partage WhatsApp) tout en restant utilisé pour la détection du
                            // statut. En attente (aucun émoji) s'affiche désormais en jaune.
                            val estValide = prono.cote.contains("✅")
                            val estPerdu = prono.cote.contains("❌")
                            val coteAffichee = prono.cote.replace("✅", "").replace("❌", "").trim()
                            val couleurCote = when { estValide -> Color(0xFF2ECC71); estPerdu -> Color(0xFFE74C3C); else -> Color(0xFFE8B93F) }

                            PremiumGlassCard(teinte = Color(0xFF3D5AFE)) {
                                Row(Modifier.fillMaxWidth(), Arrangement.SpaceBetween) { PremiumText(prono.ligue, color = tokens.textSecondary, size = 12f, fontWeight = FontWeight.Bold); PremiumText(prono.dateEtHeure, color = tokens.textSecondary, size = 11f) }
                                Spacer(Modifier.height(10.dp))
                                Row(Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
                                    PremiumText(prono.equipes, color = tokens.textPrimary, size = 17f, fontWeight = FontWeight.Black, is3D = true, modifier = Modifier.weight(1f))
                                }
                                // V1.3.5 : score du match, affiché seulement s'il est renseigné dans pronostics.json.
                                if (!prono.score.isNullOrBlank()) {
                                    Spacer(Modifier.height(4.dp))
                                    PremiumText(Traductions.getString("score_titre", langue) + prono.score, color = tokens.textSecondary, size = 12.5f, fontWeight = FontWeight.Bold)
                                }
                                Spacer(Modifier.height(12.dp))
                                Row(Modifier.fillMaxWidth(), Arrangement.SpaceBetween, Alignment.CenterVertically) { PremiumText(Traductions.getString("prono_titre", langue) + prono.pronosticChoisi, color = tokens.mainAccent, fontWeight = FontWeight.Bold, size = 14f); PremiumText(Traductions.getString("cote_titre", langue) + coteAffichee, color = couleurCote, fontWeight = FontWeight.Bold, size = 15f, is3D = estValide || estPerdu) }
                                Spacer(Modifier.height(8.dp))
                                Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.End) {
                                    // V1.3.4.2 : partage rapide du pronostic sur WhatsApp.
                                    IconeNavigateur3D(Icons.Rounded.Share, Traductions.getString("partager", langue), taille = 36.dp) {
                                        partagerViaWhatsApp(contexte, "${prono.equipes}\n${Traductions.getString("prono_titre", langue)}${prono.pronosticChoisi}\n${Traductions.getString("cote_titre", langue)}${coteAffichee}")
                                    }
                                }
                            }
                        }
                    }
                }
            }
        } else {
            if (inscriptions.isEmpty()) { Box(Modifier.fillMaxSize(), Alignment.Center) { PremiumText(Traductions.getString("aucune_inscr", langue), color = tokens.textSecondary, size = 18f, is3D = true) } }
            else {
                TirerPourActualiser(enCours = enChargement, onRafraichir = onRafraichir) {
                    LazyColumn(state = etatListeInscriptions, contentPadding = PaddingValues(20.dp, 16.dp, 20.dp, 130.dp), verticalArrangement = Arrangement.spacedBy(spacing)) {
                        itemsIndexed(inscriptions, key = { index, insc -> "${index}_${insc.nomBookmaker}" }) { _, insc ->
                            var codeCopie by remember(insc.codePromo) { mutableStateOf(false) }
                            val inscriptionActive = insc.codePromo.isNullOrBlank() || codeCopie
                            var descriptionEtendue by remember(insc.nomBookmaker) { mutableStateOf(false) }
                            val depasseLimite = insc.description.length > 110

                            PremiumGlassCard(teinte = Color(0xFF3D5AFE)) {
                                Row(Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
                                    PremiumText(insc.nomBookmaker, color = tokens.textPrimary, size = 17f, fontWeight = FontWeight.Black, modifier = Modifier.weight(1f))
                                }
                                Spacer(Modifier.height(3.dp))
                                PremiumText(insc.description, color = tokens.textSecondary, size = 11.5f, fontWeight = FontWeight.Bold, lineHeight = 15f, maxLines = if (descriptionEtendue) Int.MAX_VALUE else 2, overflow = TextOverflow.Ellipsis)
                                if (depasseLimite) {
                                    PremiumText(
                                        Traductions.getString(if (descriptionEtendue) "reduire" else "lire_suite", langue), color = tokens.mainAccent, size = 11f, fontWeight = FontWeight.Bold,
                                        modifier = Modifier.padding(top = 4.dp).clickable(interactionSource = remember { MutableInteractionSource() }, indication = null) { descriptionEtendue = !descriptionEtendue }
                                    )
                                }
                                insc.codePromo?.let { code ->
                                    Spacer(Modifier.height(8.dp))
                                    BlocCodeParrainage(code = code, copie = codeCopie, onCopie = { codeCopie = true })
                                }
                                Spacer(Modifier.height(8.dp))
                                Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(10.dp), verticalAlignment = Alignment.CenterVertically) {
                                    insc.lienInscription?.let { lien ->
                                        AnimatedButton(Traductions.getString("sinscrire", langue), tokens.mainAccent, tokens.buttonText, Modifier.weight(1f), enabled = inscriptionActive, onDisabledClick = { toastEnHaut(contexte, Traductions.getString("copier_avant", langue)) }) { ouvrirLien(contexte, browser, lien) }
                                    }
                                    IconeNavigateur3D(Icons.Rounded.Share, Traductions.getString("partager", langue), taille = 40.dp) {
                                        // V1.3.6 : le code promo est désormais inclus dans le texte partagé, en
                                        // plus du lien d'inscription — auparavant seul le lien y figurait.
                                        partagerViaWhatsApp(contexte, listOfNotNull(
                                            insc.nomBookmaker,
                                            insc.description,
                                            insc.codePromo?.takeIf { it.isNotBlank() }?.let { "${Traductions.getString("code_parrainage_titre", langue)} : $it" },
                                            insc.lienInscription?.takeIf { it.isNotBlank() }
                                        ).joinToString("\n"))
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        }
    }
}

/**
 * V1.3.4.1 : nouvel onglet "Infos" de la barre de navigation du bas. Alimenté par le fichier
 * infos.json hébergé sur GitHub (même mécanisme de synchronisation + cache hors-ligne que les
 * Airdrops/Pronostics/Inscriptions), mais volontairement dépourvu de tout bouton — chaque carte
 * n'affiche qu'un titre et un texte, à la différence des autres sections.
 */
@Composable
fun EcranInfos(items: List<ElementInfo>, signalRetourHaut: Int = 0) {
    val langue = LocalLangue.current.value
    val tokens = AeroGlassDesignSystem.current()
    val spacing = 14.dp * currentDensityScale()

    var visible by remember { mutableStateOf(false) }
    LaunchedEffect(Unit) { visible = true }
    // V1.3.4.2 : second appui sur l'onglet "Infos" déjà actif → retour en haut de la liste.
    val etatListe = rememberLazyListState()
    LaunchedEffect(signalRetourHaut) { if (signalRetourHaut > 0) etatListe.animateScrollToItem(0) }

    Box(modifier = Modifier.fillMaxSize()) {
        // V1.3.6 : bandeau jaune (même couleur que le bouton "Infos" de la barre du bas).
        BandeauAccentPage(Color(0xFFFFD600))
        Column(modifier = Modifier.fillMaxSize().padding(horizontal = 20.dp)) {
        PremiumText(Traductions.getString("nav_info", langue).uppercase(), color = tokens.textPrimary, size = 20f, fontWeight = FontWeight.Black, is3D = true, modifier = Modifier.padding(bottom = 14.dp, top = 20.dp))

        if (items.isEmpty()) {
            Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) { PremiumText(Traductions.getString("aucune_info", langue), color = tokens.textSecondary, size = 18f, is3D = true) }
        } else {
            AnimatedVisibility(visible = visible, enter = fadeIn(tween(600))) {
                LazyColumn(state = etatListe, contentPadding = PaddingValues(bottom = 130.dp), verticalArrangement = Arrangement.spacedBy(spacing)) {
                    itemsIndexed(items, key = { index, info -> "${index}_${info.titre}" }) { _, info ->
                        // V1.3.6 : chaque information est désormais repliée par défaut — seuls
                        // le titre et la date restent visibles — avec une flèche pour la dérouler.
                        var etendu by remember(info.titre) { mutableStateOf(false) }
                        val rotationFleche by animateFloatAsState(if (etendu) 180f else 0f, label = "fleche_info")
                        PremiumGlassCard(teinte = Color(0xFFFFD600), onClick = { etendu = !etendu }) {
                            Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween, verticalAlignment = Alignment.CenterVertically) {
                                Column(modifier = Modifier.weight(1f)) {
                                    PremiumText(info.titre, color = tokens.textPrimary, size = 17f, fontWeight = FontWeight.Black)
                                    // V1.3.4.3 : date affichée seulement si présente dans infos.json.
                                    if (info.date.isNotBlank()) {
                                        Spacer(Modifier.height(3.dp))
                                        PremiumText(info.date, color = tokens.textSecondary, size = 11f, fontWeight = FontWeight.SemiBold)
                                    }
                                }
                                Spacer(Modifier.width(8.dp))
                                Icon(
                                    Icons.Rounded.KeyboardArrowDown,
                                    contentDescription = Traductions.getString(if (etendu) "reduire" else "lire_suite", langue),
                                    tint = Color(0xFFFFD600),
                                    modifier = Modifier.size(24.dp).rotate(rotationFleche)
                                )
                            }
                            AnimatedVisibility(
                                visible = etendu,
                                enter = fadeIn(tween(220)) + expandVertically(tween(220)),
                                exit = fadeOut(tween(180)) + shrinkVertically(tween(180))
                            ) {
                                Column {
                                    Spacer(Modifier.height(8.dp))
                                    PremiumText(info.texte, color = tokens.textSecondary, size = 13f, fontWeight = FontWeight.Medium, lineHeight = 19f)
                                }
                            }
                        }
                    }
                }
            }
        }
        }
    }
}

@Composable
fun EcranParametres(prefs: PreferencesManager, viewModel: MainViewModel) {
    var vueActuelle by remember { mutableStateOf("principal") }
    // V1.3.5 CORRIGÉ : un appui sur le bouton retour matériel du téléphone alors qu'une
    // sous-page des Paramètres (Apparence / À propos / Mots de passe) était ouverte fermait
    // tout l'écran Paramètres et renvoyait directement à l'Accueil, au lieu de revenir
    // simplement au menu principal des Paramètres. Le bouton retour est maintenant intercepté
    // pour revenir d'abord à la liste principale des Paramètres.
    BackHandler(enabled = vueActuelle != "principal") { vueActuelle = "principal" }
    Box(modifier = Modifier.fillMaxSize()) {
        // V1.3.6 : bandeau violet (même couleur que le bouton "Paramètres" de la barre du bas),
        // présent sur le menu principal et toutes ses sous-pages.
        BandeauAccentPage(Color(0xFFD500F9))
        Crossfade(targetState = vueActuelle, animationSpec = tween(400)) { screen ->
            when(screen) {
                "principal" -> MenuPrincipalParametres(prefs, viewModel, onNavigate = { vueActuelle = it })
                "apparence" -> MenuApparence(prefs, onBack = { vueActuelle = "principal" })
                "apropos" -> MenuAPropos(onBack = { vueActuelle = "principal" })
                "mdp" -> MenuMotsDePasse(onBack = { vueActuelle = "principal" })
            }
        }
    }
}

@Composable
fun LigneInfoApropos(label: String, valeur: String, tokens: GlassColors) {
    Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween, verticalAlignment = Alignment.CenterVertically) {
        PremiumText(label, color = tokens.textSecondary, size = 13f, fontWeight = FontWeight.Medium)
        PremiumText(valeur, color = tokens.textPrimary, size = 14f, fontWeight = FontWeight.Bold)
    }
}

/**
 * V1.4 : ligne de contact cliquable (Email, WhatsApp, LinkedIn, GitHub...), utilisée sur
 * l'écran "À propos de moi". Chaque ligne porte son propre badge d'icône 3D (teinté avec
 * l'accent du thème) et ouvre le lien correspondant via l'application la plus adaptée
 * (client mail, WhatsApp, navigateur...).
 */
@Composable
fun LigneContactApropos(iconUrl: String, label: String, valeur: String, tokens: GlassColors, onClick: () -> Unit) {
    Row(
        modifier = Modifier.fillMaxWidth()
            .clickable(interactionSource = remember { MutableInteractionSource() }, indication = null, onClick = onClick),
        verticalAlignment = Alignment.CenterVertically
    ) {
        IconeBadge3DUrl(iconUrl, tokens, taille = 40.dp, tailleIcone = 27.dp)
        Spacer(Modifier.width(14.dp))
        Column(modifier = Modifier.weight(1f)) {
            PremiumText(label, color = tokens.textSecondary, size = 11.5f, fontWeight = FontWeight.Medium)
            PremiumText(valeur, color = tokens.textPrimary, size = 14f, fontWeight = FontWeight.SemiBold)
        }
        Icon(Icons.Rounded.ChevronRight, contentDescription = null, tint = tokens.textSecondary.copy(alpha = 0.5f), modifier = Modifier.size(18.dp))
    }
}

/**
 * V1.4 corrigée : écran "À propos de moi" restructuré pour suivre exactement la maquette
 * fournie — avatar + nom/surnom, puis trois sections distinctes (Profil, À propos, Contact),
 * chaque ligne de contact étant directement cliquable.
 */
@Composable
fun MenuAPropos(onBack: () -> Unit) {
    val langue = LocalLangue.current.value
    val tokens = AeroGlassDesignSystem.current()
    val contexte = LocalContext.current

    fun ouvrir(url: String) { try { contexte.startActivity(Intent(Intent.ACTION_VIEW, Uri.parse(url))) } catch (e: Exception) {} }

    Column(modifier = Modifier.fillMaxSize().verticalScroll(rememberScrollState()).padding(20.dp)) {
        Row(verticalAlignment = Alignment.CenterVertically, modifier = Modifier.padding(bottom = 12.dp, top = 2.dp)) {
            IconeNavigateur3D(Icons.Rounded.ArrowBack, "Retour", taille = 36.dp, modifier = Modifier.padding(end = 10.dp)) { onBack() }
            PremiumText(Traductions.getString("apropos", langue).uppercase(), color = tokens.textPrimary, size = 19f, fontWeight = FontWeight.Black, is3D = true)
        }

        Column(horizontalAlignment = Alignment.CenterHorizontally, modifier = Modifier.fillMaxWidth().padding(bottom = 28.dp)) {
            Box(
                modifier = Modifier.size(92.dp)
                    .shadow(elevation = 20.dp, shape = CircleShape, ambientColor = tokens.mainAccent.copy(alpha = 0.3f), spotColor = tokens.mainAccent.copy(alpha = 0.4f))
                    .clip(CircleShape)
                    .background(Brush.linearGradient(listOf(tokens.mainAccent, tokens.glassCardBorder)))
                    .background(Brush.verticalGradient(listOf(Color.White.copy(alpha = 0.14f), Color.Transparent)))
                    .border(2.dp, tokens.glassCardBorder, CircleShape),
                contentAlignment = Alignment.Center
            ) { PremiumText("LG", color = tokens.buttonText, size = 28f, fontWeight = FontWeight.Black) }
            Spacer(Modifier.height(14.dp))
            PremiumText("GBADAMASSI El-Sayed", color = tokens.textPrimary, size = 18f, fontWeight = FontWeight.Bold, is3D = true)
            PremiumText("LeGomboniste", color = tokens.mainAccent, size = 14f, fontWeight = FontWeight.SemiBold)
        }

        PremiumText(Traductions.getString("section_profil", langue), color = tokens.textSecondary, size = 12f, fontWeight = FontWeight.Bold, modifier = Modifier.padding(bottom = 8.dp, start = 4.dp))
        PremiumGlassCard(modifier = Modifier.fillMaxWidth(), paddingMult = 0.9f) {
            LigneInfoApropos(Traductions.getString("nom_label", langue), "GBADAMASSI El-Sayed", tokens)
            Spacer(Modifier.height(14.dp))
            LigneInfoApropos(Traductions.getString("surnom_label", langue), "LeGomboniste", tokens)
        }
        Spacer(Modifier.height(20.dp))

        PremiumText(Traductions.getString("section_apropos", langue), color = tokens.textSecondary, size = 12f, fontWeight = FontWeight.Bold, modifier = Modifier.padding(bottom = 8.dp, start = 4.dp))
        PremiumGlassCard(modifier = Modifier.fillMaxWidth(), paddingMult = 0.9f) {
            PremiumText(Traductions.getString("apropos_bio", langue), color = tokens.textPrimary, size = 14f, lineHeight = 21f)
        }
        Spacer(Modifier.height(20.dp))

        PremiumText(Traductions.getString("section_contact", langue), color = tokens.textSecondary, size = 12f, fontWeight = FontWeight.Bold, modifier = Modifier.padding(bottom = 8.dp, start = 4.dp))
        PremiumGlassCard(modifier = Modifier.fillMaxWidth(), paddingMult = 0.9f) {
            // V1.3.4.3 : icônes officielles en couleur d'origine chargées directement
            // depuis internet (service simpleicons.org) plutôt que des icônes Material génériques.
            LigneContactApropos("https://cdn.simpleicons.org/gmail", "Email", "gbadamassielsayedbiz@gmail.com", tokens) { ouvrir("mailto:gbadamassielsayedbiz@gmail.com") }
            Spacer(Modifier.height(16.dp))
            LigneContactApropos("https://cdn.simpleicons.org/whatsapp", "WhatsApp", "(+228)70206403", tokens) { ouvrir("https://wa.me/22870206403") }
            Spacer(Modifier.height(16.dp))
            LigneContactApropos("https://cdn.simpleicons.org/linkedin", "LinkedIn", "/in/gombobusiness", tokens) { ouvrir("https://www.linkedin.com/in/gombobusiness") }
            Spacer(Modifier.height(16.dp))
            LigneContactApropos("https://cdn.simpleicons.org/github", "GitHub", "/Legombonistebiz", tokens) { ouvrir("https://github.com/Legombonistebiz") }
        }
        Spacer(Modifier.height(24.dp))

        PremiumText(
            "${Traductions.getString("version_label", langue)} 1.3.6 • __GOMBO_BUILD_DATE__ • __GOMBO_UPDATE_DATE__",
            color = tokens.textSecondary.copy(alpha = 0.6f), size = 11f, textAlign = TextAlign.Center,
            modifier = Modifier.fillMaxWidth()
        )
        Spacer(modifier = Modifier.height(130.dp))
    }
}

@Composable
fun ChampProfilAutofill(label: String, valeur: String, tokens: GlassColors, estMotDePasse: Boolean = false, onValueChange: (String) -> Unit) {
    // V1.3.2 : champ mot de passe masqué par défaut, avec bouton pour basculer l'affichage.
    var motDePasseVisible by remember { mutableStateOf(false) }
    OutlinedTextField(
        value = valeur, onValueChange = onValueChange, singleLine = true,
        label = { PremiumText(label, tokens.textSecondary, 12f) },
        visualTransformation = if (estMotDePasse && !motDePasseVisible) androidx.compose.ui.text.input.PasswordVisualTransformation() else androidx.compose.ui.text.input.VisualTransformation.None,
        trailingIcon = if (estMotDePasse) {
            {
                Icon(
                    if (motDePasseVisible) Icons.Rounded.VisibilityOff else Icons.Rounded.Visibility,
                    contentDescription = null, tint = tokens.textSecondary,
                    modifier = Modifier.size(20.dp).clickable(interactionSource = remember { MutableInteractionSource() }, indication = null) { motDePasseVisible = !motDePasseVisible }
                )
            }
        } else null,
        shape = RoundedCornerShape(14.dp),
        // V1.3.3 CORRIGÉ : couleur de remplissage ("container") ajoutée explicitement — un
        // OutlinedTextField Material3 est TRANSPARENT par défaut tant qu'on ne fixe pas
        // focusedContainerColor/unfocusedContainerColor, ce qui laissait les champs du
        // formulaire d'auto-remplissage totalement translucides (le fond de l'écran se
        // voyait à travers), malgré un contour bien visible. C'était la vraie source de
        // "transparence" restante repérée dans l'application.
        colors = OutlinedTextFieldDefaults.colors(
            focusedBorderColor = tokens.mainAccent, unfocusedBorderColor = tokens.glassCardBorder,
            focusedTextColor = tokens.textPrimary, unfocusedTextColor = tokens.textPrimary, cursorColor = tokens.mainAccent,
            focusedContainerColor = tokens.glassCardBackground, unfocusedContainerColor = tokens.glassCardBackground, disabledContainerColor = tokens.glassCardBackground,
            focusedLabelColor = tokens.mainAccent, unfocusedLabelColor = tokens.textSecondary
        ),
        modifier = Modifier.fillMaxWidth().clip(RoundedCornerShape(14.dp))
    )
}

/**
 * V1.3.4.1 : champ "Date de naissance" du profil d'auto-remplissage. Contrairement aux autres
 * champs (texte libre), celui-ci n'accepte aucune saisie clavier : un simple appui ouvre un
 * petit calendrier (DatePicker Material3) pour choisir jour/mois/année. La valeur est conservée
 * en interne au format ISO "AAAA-MM-JJ" (valeurIso) mais toujours affichée à l'utilisateur au
 * format JJ/MM/AAAA — le format ISO permet de réutiliser directement cette même valeur pour
 * remplir les champs <input type="date"> rencontrés dans le navigateur intégré.
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ChampDateNaissance(label: String, valeurIso: String, tokens: GlassColors, onValueChange: (String) -> Unit) {
    var showPicker by remember { mutableStateOf(false) }
    val texteAffiche = remember(valeurIso) {
        val parts = valeurIso.split("-")
        if (parts.size == 3) "${parts[2]}/${parts[1]}/${parts[0]}" else ""
    }

    Box(modifier = Modifier.fillMaxWidth()) {
        OutlinedTextField(
            value = texteAffiche, onValueChange = {}, readOnly = true, singleLine = true,
            label = { PremiumText(label, tokens.textSecondary, 12f) },
            placeholder = { PremiumText("JJ/MM/AAAA", tokens.textSecondary.copy(alpha = 0.5f), 12f) },
            trailingIcon = { Icon(Icons.Rounded.CalendarMonth, contentDescription = null, tint = tokens.textSecondary, modifier = Modifier.size(20.dp)) },
            shape = RoundedCornerShape(14.dp),
            colors = OutlinedTextFieldDefaults.colors(
                focusedBorderColor = tokens.mainAccent, unfocusedBorderColor = tokens.glassCardBorder,
                focusedTextColor = tokens.textPrimary, unfocusedTextColor = tokens.textPrimary, cursorColor = tokens.mainAccent,
                focusedContainerColor = tokens.glassCardBackground, unfocusedContainerColor = tokens.glassCardBackground, disabledContainerColor = tokens.glassCardBackground,
                focusedLabelColor = tokens.mainAccent, unfocusedLabelColor = tokens.textSecondary
            ),
            modifier = Modifier.fillMaxWidth().clip(RoundedCornerShape(14.dp))
        )
        // Superposition invisible qui capte l'appui pour ouvrir le calendrier — le champ texte
        // en dessous reste "readOnly" et n'affiche donc jamais le clavier.
        Box(
            modifier = Modifier.matchParentSize().clip(RoundedCornerShape(14.dp))
                .clickable(interactionSource = remember { MutableInteractionSource() }, indication = null) { showPicker = true }
        )
    }

    if (showPicker) {
        val etatDatePicker = rememberDatePickerState()
        DatePickerDialog(
            onDismissRequest = { showPicker = false },
            confirmButton = {
                TextButton(onClick = {
                    etatDatePicker.selectedDateMillis?.let { millis ->
                        val cal = java.util.Calendar.getInstance(java.util.TimeZone.getTimeZone("UTC"))
                        cal.timeInMillis = millis
                        val annee = cal.get(java.util.Calendar.YEAR)
                        val mois = cal.get(java.util.Calendar.MONTH) + 1
                        val jour = cal.get(java.util.Calendar.DAY_OF_MONTH)
                        onValueChange(String.format(java.util.Locale.US, "%04d-%02d-%02d", annee, mois, jour))
                    }
                    showPicker = false
                }) { PremiumText("OK", tokens.mainAccent, 14f, FontWeight.Bold) }
            },
            dismissButton = {
                TextButton(onClick = { showPicker = false }) { PremiumText(Traductions.getString("fermer", LocalLangue.current.value), tokens.textSecondary, 14f) }
            }
        ) {
            DatePicker(state = etatDatePicker)
        }
    }
}

/**
 * V1.3.5 : petit écran de saisie d'un code à 4 chiffres, réutilisé pour trois usages dans
 * MenuMotsDePasse — déverrouiller la section, choisir un nouveau code lors de l'activation du
 * verrou, et confirmer le code avant de le désactiver. Le bouton "Valider" ne s'active qu'une
 * fois les 4 chiffres saisis ; un message d'erreur optionnel s'affiche sous le champ.
 */
@Composable
fun EcranCodePin(titre: String, description: String, messageErreur: String?, tokens: GlassColors, onAnnuler: (() -> Unit)? = null, onValider: (String) -> Unit) {
    val langue = LocalLangue.current.value
    var code by remember { mutableStateOf("") }
    val focusRequester = remember { FocusRequester() }
    LaunchedEffect(Unit) { focusRequester.requestFocus() }

    Column(
        modifier = Modifier.fillMaxWidth().padding(vertical = 36.dp),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Box(modifier = Modifier.size(64.dp).clip(CircleShape).background(tokens.mainAccent.copy(alpha = 0.15f)), contentAlignment = Alignment.Center) {
            Icon(Icons.Rounded.Lock, contentDescription = null, tint = tokens.mainAccent, modifier = Modifier.size(30.dp))
        }
        Spacer(Modifier.height(16.dp))
        PremiumText(titre, color = tokens.textPrimary, size = 17f, fontWeight = FontWeight.Black)
        Spacer(Modifier.height(6.dp))
        PremiumText(description, color = tokens.textSecondary, size = 13f, modifier = Modifier.padding(horizontal = 24.dp))
        Spacer(Modifier.height(20.dp))
        OutlinedTextField(
            value = code,
            onValueChange = { nouveau -> if (nouveau.length <= 4 && nouveau.all { it.isDigit() }) code = nouveau },
            singleLine = true,
            textStyle = TextStyle(textAlign = TextAlign.Center, letterSpacing = 14.sp, fontSize = 22.sp, color = tokens.textPrimary),
            keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.NumberPassword),
            visualTransformation = androidx.compose.ui.text.input.PasswordVisualTransformation('•'),
            shape = RoundedCornerShape(14.dp),
            colors = OutlinedTextFieldDefaults.colors(
                focusedBorderColor = tokens.mainAccent, unfocusedBorderColor = tokens.glassCardBorder,
                focusedTextColor = tokens.textPrimary, unfocusedTextColor = tokens.textPrimary, cursorColor = tokens.mainAccent,
                focusedContainerColor = tokens.glassCardBackground, unfocusedContainerColor = tokens.glassCardBackground
            ),
            modifier = Modifier.width(150.dp).focusRequester(focusRequester)
        )
        if (messageErreur != null) {
            Spacer(Modifier.height(8.dp))
            PremiumText(messageErreur, color = Color(0xFFE74C3C), size = 12.5f, fontWeight = FontWeight.Bold)
        }
        Spacer(Modifier.height(20.dp))
        AnimatedButton(Traductions.getString("verrou_valider", langue), tokens.mainAccent, tokens.buttonText, Modifier.width(180.dp), enabled = code.length == 4) {
            onValider(code)
            code = ""
        }
        if (onAnnuler != null) {
            Spacer(Modifier.height(14.dp))
            PremiumText(
                Traductions.getString("annuler", langue), color = tokens.textSecondary, size = 13f, fontWeight = FontWeight.Bold,
                modifier = Modifier.clickable(interactionSource = remember { MutableInteractionSource() }, indication = null) { onAnnuler() }
            )
        }
    }
}

/**
 * V1.3 corrigée (point 4, sections D et E) : écran de gestion de l'auto-remplissage
 * (profil réutilisable sur tous les formulaires) et du gestionnaire de mots de passe
 * (consultation, modification implicite via ré-enregistrement, suppression).
 */
@Composable
fun MenuMotsDePasse(onBack: () -> Unit) {
    val langue = LocalLangue.current.value
    val tokens = AeroGlassDesignSystem.current()
    val store = LocalAutofillStore.current
    val contexte = LocalContext.current

    var profil by remember { mutableStateOf(store.getProfil()) }
    var identifiants by remember { mutableStateOf(store.getIdentifiants()) }

    // V1.3.5 : verrou optionnel par code à 4 chiffres — cette section contient des données
    // sensibles (profil auto-rempli, mots de passe enregistrés). "deverrouille" repart de zéro
    // à chaque nouvelle entrée dans cet écran (re-verrouillage automatique en quittant).
    var verrouActif by remember { mutableStateOf(store.estVerrouActif()) }
    var deverrouille by remember { mutableStateOf(!store.estVerrouActif()) }
    var etapeVerrou by remember { mutableStateOf<String?>(null) } // "creer1" | "creer2" | "desactiver"
    var codeTemporaire by remember { mutableStateOf("") }
    var messageErreurVerrou by remember { mutableStateOf<String?>(null) }

    Column(modifier = Modifier.fillMaxSize().verticalScroll(rememberScrollState()).padding(20.dp)) {
        Row(verticalAlignment = Alignment.CenterVertically, modifier = Modifier.padding(bottom = 12.dp, top = 2.dp)) {
            IconeNavigateur3D(Icons.Rounded.ArrowBack, "Retour", taille = 36.dp, modifier = Modifier.padding(end = 10.dp)) { onBack() }
            PremiumText(Traductions.getString("autofill_titre", langue).uppercase(), color = tokens.textPrimary, size = 19f, fontWeight = FontWeight.Black, is3D = true)
        }

        if (verrouActif && !deverrouille) {
            // Section verrouillée : uniquement l'écran de saisie du code, rien de sensible affiché.
            EcranCodePin(
                titre = Traductions.getString("verrou_entrer_titre", langue),
                description = Traductions.getString("verrou_entrer_desc", langue),
                messageErreur = messageErreurVerrou,
                tokens = tokens
            ) { code ->
                if (store.codeCorrect(code)) { deverrouille = true; messageErreurVerrou = null }
                else messageErreurVerrou = Traductions.getString("verrou_erreur", langue)
            }
        } else if (etapeVerrou == "creer1") {
            EcranCodePin(
                titre = Traductions.getString("verrou_creer_titre", langue), description = "",
                messageErreur = messageErreurVerrou, tokens = tokens,
                onAnnuler = { etapeVerrou = null; messageErreurVerrou = null }
            ) { code -> codeTemporaire = code; messageErreurVerrou = null; etapeVerrou = "creer2" }
        } else if (etapeVerrou == "creer2") {
            EcranCodePin(
                titre = Traductions.getString("verrou_confirmer_titre", langue), description = "",
                messageErreur = messageErreurVerrou, tokens = tokens,
                onAnnuler = { etapeVerrou = null; messageErreurVerrou = null }
            ) { code ->
                if (code == codeTemporaire) {
                    store.activerVerrou(code); verrouActif = true; etapeVerrou = null; messageErreurVerrou = null
                    toastEnHaut(contexte, Traductions.getString("verrou_active", langue))
                } else {
                    messageErreurVerrou = Traductions.getString("verrou_ne_correspond_pas", langue)
                    codeTemporaire = ""; etapeVerrou = "creer1"
                }
            }
        } else if (etapeVerrou == "desactiver") {
            EcranCodePin(
                titre = Traductions.getString("verrou_entrer_titre", langue),
                description = Traductions.getString("verrou_desactiver_desc", langue),
                messageErreur = messageErreurVerrou, tokens = tokens,
                onAnnuler = { etapeVerrou = null; messageErreurVerrou = null }
            ) { code ->
                if (store.codeCorrect(code)) {
                    store.desactiverVerrou(); verrouActif = false; etapeVerrou = null; messageErreurVerrou = null
                    toastEnHaut(contexte, Traductions.getString("verrou_desactive", langue))
                } else {
                    messageErreurVerrou = Traductions.getString("verrou_erreur", langue)
                }
            }
        } else {
        // V1.3.5 : bascule d'activation du verrou, tout en haut de la section (avant les
        // données sensibles elles-mêmes).
        PremiumGlassCard(modifier = Modifier.fillMaxWidth().padding(bottom = 12.dp), paddingMult = 0.9f) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Box(modifier = Modifier.size(46.dp).clip(CircleShape).background(tokens.mainAccent.copy(alpha = 0.15f)), contentAlignment = Alignment.Center) {
                    Icon(Icons.Rounded.Lock, contentDescription = null, tint = tokens.mainAccent, modifier = Modifier.size(22.dp))
                }
                Spacer(modifier = Modifier.width(14.dp))
                Column(modifier = Modifier.weight(1f)) {
                    PremiumText(Traductions.getString("verrou_titre", langue), color = tokens.textPrimary, size = 15f, fontWeight = FontWeight.Bold)
                    Spacer(modifier = Modifier.height(2.dp))
                    PremiumText(Traductions.getString("verrou_desc", langue), color = tokens.textSecondary, size = 12.5f)
                }
                Spacer(modifier = Modifier.width(8.dp))
                Switch(
                    checked = verrouActif,
                    onCheckedChange = { active ->
                        if (active) { codeTemporaire = ""; messageErreurVerrou = null; etapeVerrou = "creer1" }
                        else { messageErreurVerrou = null; etapeVerrou = "desactiver" }
                    },
                    colors = SwitchDefaults.colors(checkedThumbColor = tokens.baseBackground, checkedTrackColor = tokens.mainAccent, uncheckedThumbColor = tokens.textSecondary, uncheckedTrackColor = tokens.glassCardBorder)
                )
            }
        }

        PremiumGlassCard(modifier = Modifier.fillMaxWidth().padding(bottom = 12.dp), paddingMult = 0.9f) {
            Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                ChampProfilAutofill(Traductions.getString("nom_complet_label", langue), profil.nomComplet, tokens) { profil = profil.copy(nomComplet = it) }
                ChampProfilAutofill(Traductions.getString("nom_label", langue), profil.nom, tokens) { profil = profil.copy(nom = it) }
                ChampProfilAutofill(Traductions.getString("prenom_label", langue), profil.prenom, tokens) { profil = profil.copy(prenom = it) }
                ChampProfilAutofill("Nom d'utilisateur", profil.nomUtilisateur, tokens) { profil = profil.copy(nomUtilisateur = it) }
                ChampProfilAutofill("Email", profil.email, tokens) { profil = profil.copy(email = it) }
                Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                    // V1.3.2 : indicatif téléphonique ajouté, dans son propre champ séparé.
                    Box(modifier = Modifier.weight(0.34f)) { ChampProfilAutofill("Indicatif", profil.indicatifTelephone, tokens) { profil = profil.copy(indicatifTelephone = it) } }
                    Box(modifier = Modifier.weight(0.66f)) { ChampProfilAutofill("Téléphone", profil.telephone, tokens) { profil = profil.copy(telephone = it) } }
                }
                ChampProfilAutofill("Adresse", profil.adresse, tokens) { profil = profil.copy(adresse = it) }
                // V1.3.6 : champs complémentaires (ville, code postal, pays, genre) — courants
                // sur les formulaires d'inscription des sites de crypto et de paris sportifs,
                // auto-remplis eux aussi lors de la navigation.
                Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                    Box(modifier = Modifier.weight(0.55f)) { ChampProfilAutofill("Ville", profil.ville, tokens) { profil = profil.copy(ville = it) } }
                    Box(modifier = Modifier.weight(0.45f)) { ChampProfilAutofill("Code postal", profil.codePostal, tokens) { profil = profil.copy(codePostal = it) } }
                }
                Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                    Box(modifier = Modifier.weight(0.6f)) { ChampProfilAutofill("Pays", profil.pays, tokens) { profil = profil.copy(pays = it) } }
                    Box(modifier = Modifier.weight(0.4f)) { ChampProfilAutofill("Genre", profil.sexe, tokens) { profil = profil.copy(sexe = it) } }
                }
                // V1.3.4.1 : date de naissance, sélectionnée via un petit calendrier plutôt que
                // tapée au clavier — auto-remplie sur les champs de type date des formulaires.
                ChampDateNaissance(Traductions.getString("date_naissance_label", langue), profil.dateNaissance, tokens) { profil = profil.copy(dateNaissance = it) }
                // V1.3.2 : mot de passe par défaut, auto-rempli sur les cases "mot de passe" ET
                // "confirmation" lors d'une inscription sur un nouveau site.
                ChampProfilAutofill("Mot de passe (auto-remplissage)", profil.motDePasseParDefaut, tokens, estMotDePasse = true) { profil = profil.copy(motDePasseParDefaut = it) }
                AnimatedButton(Traductions.getString("mdp_enregistrer", langue), tokens.mainAccent, tokens.buttonText, Modifier.fillMaxWidth()) {
                    store.setProfil(profil)
                    toastEnHaut(contexte, Traductions.getString("profil_enregistre", langue))
                }
            }
        }

        PremiumText(Traductions.getString("mdp_titre", langue), color = tokens.textSecondary, size = 13f, fontWeight = FontWeight.Bold, modifier = Modifier.padding(bottom = 6.dp, start = 4.dp))

        if (identifiants.isEmpty()) {
            PremiumGlassCard(modifier = Modifier.fillMaxWidth()) {
                PremiumText(Traductions.getString("mdp_vide", langue), color = tokens.textSecondary, size = 14f)
            }
        } else {
            Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                identifiants.forEach { cred ->
                    var motDePasseVisible by remember(cred.domaine) { mutableStateOf(false) }
                    PremiumGlassCard(modifier = Modifier.fillMaxWidth(), paddingMult = 0.8f) {
                        Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween, verticalAlignment = Alignment.CenterVertically) {
                            Column {
                                PremiumText(cred.domaine, color = tokens.mainAccent, size = 14f, fontWeight = FontWeight.Bold)
                                Spacer(Modifier.height(4.dp))
                                PremiumText(cred.identifiant, color = tokens.textPrimary, size = 13f)
                                PremiumText(if (motDePasseVisible) cred.motDePasse else "••••••••", color = tokens.textSecondary, size = 12f)
                            }
                            Row {
                                IconButton(onClick = { motDePasseVisible = !motDePasseVisible }) {
                                    Icon(if (motDePasseVisible) Icons.Rounded.VisibilityOff else Icons.Rounded.Visibility, contentDescription = null, tint = tokens.textSecondary)
                                }
                                IconButton(onClick = {
                                    store.supprimerIdentifiant(cred.domaine)
                                    identifiants = store.getIdentifiants()
                                }) {
                                    Icon(Icons.Rounded.Delete, contentDescription = Traductions.getString("mdp_supprimer", langue), tint = Color(0xFFD32F2F))
                                }
                            }
                        }
                    }
                }
            }
        }
        Spacer(modifier = Modifier.height(130.dp))
        }
    }
}

@Composable
fun MenuPrincipalParametres(prefs: PreferencesManager, viewModel: MainViewModel, onNavigate: (String) -> Unit) {
    val langue = LocalLangue.current
    val tokens = AeroGlassDesignSystem.current()
    val contexte = LocalContext.current
    val gestionnaireMiseAJour = LocalGestionnaireMiseAJour.current
    var showChangelog by remember { mutableStateOf(false) }
    var verificationMajEnCours by remember { mutableStateOf(false) }
    var infoMajManuelle by remember { mutableStateOf<InfoMiseAJour?>(null) }
    var showMiseAJourManuelle by remember { mutableStateOf(false) }

    if (showChangelog) { DialogNouveautes { showChangelog = false } }
    if (showMiseAJourManuelle && infoMajManuelle != null) {
        DialogMiseAJour(infoMajManuelle!!, gestionnaireMiseAJour, onPlusTard = { showMiseAJourManuelle = false })
    }

    fun verifierMiseAJourManuellement() {
        if (verificationMajEnCours) return
        verificationMajEnCours = true
        toastEnHaut(contexte, Traductions.getString("verif_maj_txt", langue.value))
        viewModel.verifierMiseAJour(BuildConfig.VERSION_CODE) { info ->
            verificationMajEnCours = false
            if (info != null) { infoMajManuelle = info; showMiseAJourManuelle = true }
            else { toastEnHaut(contexte, Traductions.getString("maj_a_jour", langue.value)) }
        }
    }

    Column(modifier = Modifier.fillMaxSize().verticalScroll(rememberScrollState()).padding(20.dp)) {
        PremiumText(Traductions.getString("nav_set", langue.value).uppercase(), color = tokens.textPrimary, size = 20f, fontWeight = FontWeight.Black, is3D = true, modifier = Modifier.padding(bottom = 14.dp, top = 4.dp))

        PremiumGlassCard(modifier = Modifier.fillMaxWidth(), paddingMult = 0.8f, onClick = { onNavigate("apparence") }) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                IconeBadge3D(Icons.Rounded.Palette, tokens)
                Spacer(Modifier.width(14.dp))
                PremiumText(Traductions.getString("apparence", langue.value), color = tokens.textPrimary, size = 16f, fontWeight = FontWeight.Bold)
            }
        }
        Spacer(modifier = Modifier.height(8.dp))

        // V1.3.1 : vérification manuelle de mise à jour, à tout moment.
        PremiumGlassCard(modifier = Modifier.fillMaxWidth(), paddingMult = 0.8f, onClick = { verifierMiseAJourManuellement() }) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                IconeBadge3D(Icons.Rounded.SystemUpdate, tokens)
                Spacer(Modifier.width(14.dp))
                PremiumText(Traductions.getString("maj_bouton", langue.value), color = tokens.textPrimary, size = 16f, fontWeight = FontWeight.Bold)
            }
        }
        Spacer(modifier = Modifier.height(8.dp))

        PremiumGlassCard(modifier = Modifier.fillMaxWidth(), paddingMult = 0.8f, onClick = { showChangelog = true }) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                IconeBadge3D(Icons.Rounded.NewReleases, tokens)
                Spacer(Modifier.width(14.dp))
                PremiumText(Traductions.getString("nouveautes", langue.value), color = tokens.textPrimary, size = 16f, fontWeight = FontWeight.Bold)
            }
        }
        Spacer(modifier = Modifier.height(14.dp))

        PremiumText(Traductions.getString("lang_title", langue.value), color = tokens.textSecondary, size = 13f, fontWeight = FontWeight.Bold, modifier = Modifier.padding(bottom = 6.dp, start = 4.dp))
        PremiumGlassCard(modifier = Modifier.fillMaxWidth(), paddingMult = 0.8f) {
            Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween, verticalAlignment = Alignment.CenterVertically) {
                PremiumText(if (langue.value == "fr") "Français" else "English", color = tokens.textPrimary, size = 15f, fontWeight = FontWeight.Medium)
                Switch(checked = langue.value == "en", onCheckedChange = { langue.value = if(it) "en" else "fr"; prefs.setLangue(langue.value) }, colors = SwitchDefaults.colors(checkedThumbColor = tokens.baseBackground, checkedTrackColor = tokens.mainAccent, uncheckedThumbColor = tokens.textSecondary, uncheckedTrackColor = tokens.glassCardBorder))
            }
        }
        Spacer(modifier = Modifier.height(8.dp))

        PremiumGlassCard(modifier = Modifier.fillMaxWidth(), paddingMult = 0.8f, onClick = { onNavigate("mdp") }) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                IconeBadge3D(Icons.Rounded.Lock, tokens)
                Spacer(Modifier.width(14.dp))
                PremiumText(Traductions.getString("autofill_titre", langue.value), color = tokens.textPrimary, size = 16f, fontWeight = FontWeight.Bold)
            }
        }
        Spacer(modifier = Modifier.height(8.dp))

        PremiumGlassCard(modifier = Modifier.fillMaxWidth(), paddingMult = 0.8f, onClick = { onNavigate("apropos") }) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                IconeBadge3D(Icons.Rounded.Person, tokens)
                Spacer(Modifier.width(14.dp))
                PremiumText(Traductions.getString("apropos", langue.value), color = tokens.textPrimary, size = 16f, fontWeight = FontWeight.Bold)
            }
        }
    }
}

@Composable
fun MenuApparence(prefs: PreferencesManager, onBack: () -> Unit) {
    val langue = LocalLangue.current.value
    val tokens = AeroGlassDesignSystem.current()
    // V1.3.4.2 : taille de texte et police ré-activées — ces deux états sont partagés avec
    // toute l'application via les CompositionLocal déjà fournis dans MainActivity
    // (LocalFontSize), donc toute modification ici s'applique immédiatement
    // partout, et reste mémorisée d'une session à l'autre via PreferencesManager.
    val etatTaille = LocalFontSize.current
    // V1.3.4.3 : thème clair/sombre (le mode nuit automatique a été retiré).
    val etatTheme = LocalAppTheme.current

    Column(modifier = Modifier.fillMaxSize().padding(20.dp).verticalScroll(rememberScrollState())) {
        Row(verticalAlignment = Alignment.CenterVertically, modifier = Modifier.padding(bottom = 12.dp, top = 2.dp)) {
            IconeNavigateur3D(Icons.Rounded.ArrowBack, "Retour", taille = 36.dp, modifier = Modifier.padding(end = 10.dp)) { onBack() }
            PremiumText(Traductions.getString("apparence", langue).uppercase(), color = tokens.textPrimary, size = 19f, fontWeight = FontWeight.Black, is3D = true)
        }

        // V1.3.4.2 : thème clair/sombre, réactivé sur demande explicite (voir EclipseSombre
        // dans Theme.kt). Palette dédiée, pas un simple assombrissement automatique.
        PremiumGlassCard(modifier = Modifier.fillMaxWidth().padding(bottom = 12.dp), paddingMult = 0.9f) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Box(modifier = Modifier.size(46.dp).clip(CircleShape).background(tokens.mainAccent), contentAlignment = Alignment.Center) {
                    Icon(if (etatTheme.value == "Sombre") Icons.Rounded.DarkMode else Icons.Rounded.LightMode, contentDescription = null, tint = tokens.buttonText, modifier = Modifier.size(22.dp))
                }
                Spacer(modifier = Modifier.width(14.dp))
                Column(modifier = Modifier.weight(1f)) {
                    PremiumText(Traductions.getString("theme_title", langue) + " : " + (if (etatTheme.value == "Sombre") "Sombre" else "Clair"), color = tokens.textPrimary, size = 15f, fontWeight = FontWeight.Bold)
                    Spacer(modifier = Modifier.height(2.dp))
                    PremiumText(Traductions.getString("apparence_desc", langue), color = tokens.textSecondary, size = 12.5f)
                }
                Spacer(modifier = Modifier.width(8.dp))
                Switch(
                    checked = etatTheme.value == "Sombre",
                    onCheckedChange = { estSombre ->
                        val nouvelle = if (estSombre) "Sombre" else "Clair"
                        etatTheme.value = nouvelle
                        prefs.setTheme(nouvelle)
                    },
                    colors = SwitchDefaults.colors(checkedThumbColor = tokens.baseBackground, checkedTrackColor = tokens.mainAccent, uncheckedThumbColor = tokens.textSecondary, uncheckedTrackColor = tokens.glassCardBorder)
                )
            }
        }

        // V1.3.4.2 : taille du texte réglable — utile notamment pour les utilisateurs ayant
        // des difficultés visuelles.
        PremiumText(Traductions.getString("size_title", langue), color = tokens.textSecondary, size = 13f, fontWeight = FontWeight.Bold, modifier = Modifier.padding(bottom = 6.dp, start = 4.dp))
        PremiumGlassCard(modifier = Modifier.fillMaxWidth().padding(bottom = 12.dp), paddingMult = 0.9f) {
            PremiumText("Aa", color = tokens.mainAccent, size = 22f * etatTaille.value, fontWeight = FontWeight.Black, modifier = Modifier.padding(bottom = 10.dp))
            Slider(
                value = etatTaille.value, onValueChange = { etatTaille.value = it; prefs.setFontSize(it) },
                valueRange = 0.85f..1.3f,
                colors = SliderDefaults.colors(thumbColor = tokens.mainAccent, activeTrackColor = tokens.mainAccent, inactiveTrackColor = tokens.glassCardBorder)
            )
        }
        Spacer(modifier = Modifier.height(40.dp))
    }
}
EOF

# Injection des dates réelles (build fixe + mise à jour dynamique) dans la section "À propos de moi"
sed -i "s#__GOMBO_BUILD_DATE__#${BUILD_DATE}#g; s#__GOMBO_UPDATE_DATE__#${UPDATE_DATE}#g" \
    "$PROJECT_NAME/app/src/main/java/$PACKAGE_PATH/presentation/ecrans/EcransAdditionnels.kt"

echo "🧭 Étape 8 : Navigation & Overlay Browser..."

cat << 'EOF' > "$PROJECT_NAME/app/src/main/java/$PACKAGE_PATH/presentation/navigation/AppNavigation.kt"
package com.gombobusiness.app.presentation.navigation

import android.content.Intent
import android.net.Uri
import android.os.Message
import android.webkit.*
import android.widget.Toast
import androidx.activity.compose.BackHandler
import androidx.browser.customtabs.CustomTabsIntent
// V1.3.2 : CORRECTIF DELTA — API rétro-compatible (androidx.webkit) permettant de
// désactiver proprement l'assombrissement algorithmique automatique du WebView.
import androidx.webkit.WebSettingsCompat
import androidx.webkit.WebViewFeature
import androidx.compose.animation.core.animateDpAsState
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.spring
import androidx.compose.animation.core.Spring
// V1.3.3 : les animations de transition entre écrans ont été supprimées (navigation
// instantanée). Seuls EnterTransition/ExitTransition restent importés, pour désactiver
// explicitement toute transition sur le NavHost ci-dessous.
import androidx.compose.animation.EnterTransition
import androidx.compose.animation.ExitTransition
// V1.3.3 : animations de la nouvelle bannière "toast" en haut d'écran (voir BanniereToast).
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
// CORRECTIF BUILD : tween() vit dans androidx.compose.animation.core, pas dans .animation —
// nécessaire pour la transition en fondu du NavHost.
import androidx.compose.animation.core.tween
// V1.3.4.2 : signal "retour en haut" par onglet (second appui sur l'onglet déjà actif).
import androidx.compose.runtime.mutableStateMapOf
import androidx.compose.animation.slideInVertically
import androidx.compose.animation.slideOutVertically
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.interaction.collectIsPressedAsState
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.rounded.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.graphics.lerp
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.viewinterop.AndroidView
import androidx.compose.ui.window.Dialog
import androidx.compose.ui.zIndex
import androidx.navigation.NavGraph.Companion.findStartDestination
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.currentBackStackEntryAsState
import androidx.navigation.compose.rememberNavController
import com.gombobusiness.app.presentation.ecrans.*
import com.gombobusiness.app.presentation.viewmodel.MainViewModel
import com.gombobusiness.app.core.*
import com.gombobusiness.app.domain.model.*
import com.gombobusiness.app.data.local.PreferencesManager
import com.gombobusiness.app.presentation.theme.AeroGlassDesignSystem
import com.gombobusiness.app.BuildConfig
import kotlinx.coroutines.delay

// V1.3.3 : les animations de transition entre écrans (Fade, Slide, Zoom, Scale, Material
// Motion) ont été entièrement supprimées — la navigation entre les écrans est désormais
// instantanée (EnterTransition.None / ExitTransition.None sur le NavHost ci-dessous).

/**
 * V1.3.3 : bannière "toast" maison, affichée en superposition tout en haut de l'écran.
 * Remplace le Toast système (voir toastEnHaut dans GlobalState.kt) pour garantir un
 * positionnement fiable en haut, quel que soit le téléphone ou la version d'Android — le
 * style reprend le même langage visuel "verre + relief 3D" que le reste de l'application.
 */
@Composable
fun BanniereToast() {
    val tokens = AeroGlassDesignSystem.current()
    val messageActuel by GombobusinessToastHost.message.collectAsState()
    var messageAffiche by remember { mutableStateOf<MessageToastGombo?>(null) }

    LaunchedEffect(messageActuel) {
        val recu = messageActuel ?: return@LaunchedEffect
        messageAffiche = recu
        delay(2600)
        // On ne masque que si aucun nouveau message n'est arrivé entre-temps, pour ne
        // jamais couper l'affichage d'un message plus récent.
        if (GombobusinessToastHost.message.value?.id == recu.id) { messageAffiche = null }
    }

    Box(modifier = Modifier.fillMaxSize().padding(top = 26.dp), contentAlignment = Alignment.TopCenter) {
        AnimatedVisibility(
            visible = messageAffiche != null,
            enter = slideInVertically(initialOffsetY = { -it * 2 }) + fadeIn(),
            exit = slideOutVertically(targetOffsetY = { -it * 2 }) + fadeOut()
        ) {
            Box(
                modifier = Modifier
                    .padding(horizontal = 28.dp)
                    .shadow(elevation = 18.dp, shape = RoundedCornerShape(20.dp), ambientColor = tokens.mainAccent.copy(alpha = 0.32f), spotColor = tokens.mainAccent.copy(alpha = 0.42f))
                    .clip(RoundedCornerShape(20.dp))
                    .background(tokens.glassCardBackground)
                    .background(Brush.verticalGradient(listOf(tokens.shadowLight.copy(alpha = 0.07f), Color.Transparent)))
                    .border(1.2.dp, tokens.glassCardBorder.copy(alpha = 0.55f), RoundedCornerShape(20.dp))
                    .padding(horizontal = 22.dp, vertical = 14.dp)
            ) {
                PremiumText(text = messageAffiche?.texte.orEmpty(), color = tokens.textPrimary, size = 14f, fontWeight = FontWeight.Bold, textAlign = TextAlign.Center)
            }
        }
    }
}

/**
 * V1.3.5 : un élément de la barre de navigation du bas — route, titre (accessibilité), icône,
 * et une couleur distincte affichée en petit point sous l'icône, pour identifier chaque
 * section d'un coup d'œil (référence : maquette "polymère doux & géométrie douce").
 */
private data class NavItem(val route: String, val titre: String, val icone: ImageVector, val couleur: Color)

@Composable
fun ConteneurNavigationPrincipal(viewModel: MainViewModel, prefs: PreferencesManager) {
    val navController = rememberNavController()
    // V1.3.4.2 : un second appui sur l'onglet déjà actif remonte sa liste tout en haut —
    // chaque route a son propre compteur, incrémenté à chaque second appui, que les écrans
    // concernés (Airdrops, Sports, Infos) observent via LaunchedEffect pour déclencher le
    // défilement.
    val signauxDefilement = remember { mutableStateMapOf<String, Int>() }
    val langue = LocalLangue.current.value
    val isOnline = LocalIsOnline.current
    val browserController = LocalBrowserController.current
    val tokens = AeroGlassDesignSystem.current()
    val contexte = LocalContext.current
    val gestionnaireMiseAJour = LocalGestionnaireMiseAJour.current

    val airdrops by viewModel.airdrops.collectAsState()
    // V1.3.3 : Wallet / Exchange redevient une sous-page d'Airdrops (voir EcranAirdrops
    // ci-dessous, qui affiche désormais un TabRow Airdrops / Wallet-Exchange).
    val walletExchange by viewModel.walletExchange.collectAsState()
    val pronostics by viewModel.pronostics.collectAsState()
    val inscriptions by viewModel.inscriptions.collectAsState()
    // V1.3.4.1 : contenu du nouvel onglet "Infos" (infos.json).
    val infos by viewModel.infos.collectAsState()
    // V1.3.4.2 : date/heure de la dernière synchronisation, pour le bandeau hors-ligne.
    val derniereSynchro by viewModel.derniereSynchro.collectAsState()
    // V1.3.4.2 : indicateur de chargement, pour le geste "Glisser pour actualiser".
    val enChargement by viewModel.enChargement.collectAsState()

    LaunchedEffect(isOnline) { if (isOnline) { viewModel.chargerDonnees() } }

    // V1.3 : à chaque installation ou mise à jour (version différente de la dernière
    // ouverte), on affiche d'abord le tutoriel vidéo, PUIS l'historique des nouveautés.
    val estNouvelleVersion = prefs.getLastVersion() != "1.3.6"
    var showTutoriel by remember { mutableStateOf(estNouvelleVersion) }
    var showNouveautes by remember { mutableStateOf(false) }

    // V1.3.1 : une fois le tutoriel/les nouveautés refermés (ou immédiatement si aucun des
    // deux n'est dû), on vérifie automatiquement sur GitHub si une mise à jour est
    // disponible — un court message texte s'affiche pendant la vérification, sans jamais
    // montrer GitHub ni ouvrir de navigateur à l'utilisateur.
    var verificationMajFaite by remember { mutableStateOf(false) }
    var infoMajAuto by remember { mutableStateOf<InfoMiseAJour?>(null) }
    var showMiseAJourAuto by remember { mutableStateOf(false) }

    LaunchedEffect(showTutoriel, showNouveautes, isOnline) {
        if (!showTutoriel && !showNouveautes && !verificationMajFaite && isOnline) {
            verificationMajFaite = true
            toastEnHaut(contexte, Traductions.getString("verif_maj_txt", langue))
            viewModel.verifierMiseAJour(BuildConfig.VERSION_CODE) { info ->
                if (info != null) { infoMajAuto = info; showMiseAJourAuto = true }
                // V1.3.2 : corrige l'absence de message après vérification automatique — si
                // aucune mise à jour n'est disponible, l'utilisateur voit désormais bien
                // "L'application est à jour ✓", comme c'était déjà le cas pour la vérification
                // manuelle depuis les Paramètres.
                else { toastEnHaut(contexte, Traductions.getString("maj_a_jour", langue)) }
            }
        }
    }

    Box(modifier = Modifier.fillMaxSize()) {
        // V1.3.3 : le fond animé affiché dépend désormais du choix de l'utilisateur dans
        // Paramètres > Apparence (5 variantes) au lieu d'un fond unique fixe.
        FondAnimeSelectionne()

        // V1.3.4.2 : une très légère transition en fondu a été réintroduite entre les onglets
        // (demande explicite : navigation plus fluide), à la place de la navigation strictement
        // instantanée de la V1.3.3 — la durée reste volontairement courte pour ne jamais donner
        // d'impression de lenteur.
        NavHost(
            navController, startDestination = "accueil", modifier = Modifier.fillMaxSize(),
            enterTransition = { fadeIn(tween(180)) },
            exitTransition = { fadeOut(tween(140)) },
            popEnterTransition = { fadeIn(tween(180)) },
            popExitTransition = { fadeOut(tween(140)) }
        ) {
            composable("accueil") { EcranAccueil() }
            // V1.3.3 : Wallet / Exchange n'est plus un onglet séparé de la barre du bas —
            // c'est désormais une sous-page à l'intérieur d'Airdrops (TabRow interne).
            // V1.3.4.2 : + pull-to-refresh + signal "retour en haut" (second appui sur l'onglet).
            composable("airdrops") { EcranAirdrops(airdrops, walletExchange, enChargement, { viewModel.chargerDonnees() }, signauxDefilement["airdrops"] ?: 0) }
            composable("sports") { EcranParisSportifs(pronostics, inscriptions, enChargement, { viewModel.chargerDonnees() }, signauxDefilement["sports"] ?: 0) }
            // V1.3.4.1 : nouvel onglet "Infos" — lecture seule de infos.json, sans aucun bouton.
            composable("infos") { EcranInfos(infos, signauxDefilement["infos"] ?: 0) }
            composable("parametres") { EcranParametres(prefs, viewModel) }
        }

        if (showTutoriel) {
            DialogTutorielVideo(onContinuer = { showTutoriel = false; showNouveautes = true })
        } else if (showNouveautes) {
            DialogNouveautes(onDismiss = { showNouveautes = false; prefs.setLastVersion("1.3.6") })
        } else if (showMiseAJourAuto && infoMajAuto != null) {
            DialogMiseAJour(infoMajAuto!!, gestionnaireMiseAJour, onPlusTard = { showMiseAJourAuto = false })
        }

        // V1.3.4.2 : bandeau discret affiché en haut de l'écran lorsque l'application est
        // hors-ligne ET qu'au moins une synchronisation a déjà eu lieu par le passé — indique
        // clairement que les données visibles sont celles de la dernière connexion, avec leur
        // date, plutôt que de laisser l'utilisateur deviner s'il regarde des données à jour.
        if (!isOnline && derniereSynchro > 0L) {
            val formateur = remember { java.text.SimpleDateFormat("dd/MM 'à' HH:mm", java.util.Locale.getDefault()) }
            val texteHorodatage = remember(derniereSynchro) { formateur.format(java.util.Date(derniereSynchro)) }
            Box(modifier = Modifier.fillMaxWidth().padding(top = 12.dp).zIndex(80f), contentAlignment = Alignment.TopCenter) {
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    modifier = Modifier
                        .shadow(elevation = 10.dp, shape = RoundedCornerShape(50.dp), ambientColor = tokens.shadowDark, spotColor = tokens.shadowDark)
                        .clip(RoundedCornerShape(50.dp))
                        .background(Color.Black.copy(alpha = 0.82f))
                        .padding(horizontal = 16.dp, vertical = 8.dp)
                ) {
                    Icon(Icons.Rounded.CloudOff, contentDescription = null, tint = Color.White, modifier = Modifier.size(14.dp))
                    Spacer(Modifier.width(8.dp))
                    PremiumText(Traductions.getString("hors_ligne_txt", langue) + texteHorodatage, color = Color.White, size = 11.5f, fontWeight = FontWeight.SemiBold)
                }
            }
        }

        InAppBrowserOverlay(browserController)

        // V1.3.3 : NÉOMORPHISME — la barre de navigation devient un simple contour noir
        // (fond transparent, largeur ajustée au contenu, centrée), chaque icône étant un
        // bouton bombé indépendant (IconeNavigateur3D) qui se "creuse" pour l'onglet actif —
        // reproduit exactement le mockup HTML validé par l'utilisateur (plus de libellés
        // texte sous les icônes, plus de bandeau plein rempli derrière).
        // V1.3.5 CORRIGÉ : le fond de la barre était toujours noir, quel que soit le thème actif
        // — sur le thème clair, cela tranchait beaucoup trop et ne correspondait plus au rendu
        // doux/mat souhaité (référence : maquette "polymère doux"). Le fond suit maintenant la
        // couleur des cartes du thème actif, et chaque icône affiche un petit point de couleur
        // distinct en dessous, pour bien identifier chaque section d'un coup d'œil.
        Box(
            modifier = Modifier
                .align(Alignment.BottomCenter)
                .padding(bottom = 20.dp)
                .clip(RoundedCornerShape(32.dp))
                .background(tokens.glassCardBackground)
                .border(width = 2.dp, color = tokens.glassCardBorder, shape = RoundedCornerShape(32.dp))
                .padding(horizontal = 14.dp, vertical = 10.dp)
        ) {
            val backStackEntry by navController.currentBackStackEntryAsState()
            val routeActuelle = backStackEntry?.destination?.route

            // V1.3.5 : couleurs plus vives (demande explicite), reprenant le code couleur de la
            // maquette de référence (bleu, rose, indigo, jaune, violet — vert évité, réservé au
            // seul repère "pronostic gagnant" ailleurs dans l'app).
            val items = listOf(
                NavItem("accueil", Traductions.getString("nav_acc", langue), Icons.Rounded.Home, Color(0xFF00B0FF)),
                // V1.3.3 : Wallet / Exchange n'a plus son propre onglet — c'est désormais
                // une sous-page accessible depuis l'onglet Airdrops (voir TabRow interne).
                NavItem("airdrops", Traductions.getString("nav_air", langue), Icons.Rounded.CardGiftcard, Color(0xFFFF1744)),
                NavItem("sports", Traductions.getString("nav_spo", langue), Icons.Rounded.SportsSoccer, Color(0xFF3D5AFE)),
                // V1.3.4.1 : 5e bouton de la barre du bas, icône "i" — ouvre le nouvel onglet
                // "Infos" (lecture seule de infos.json, sans aucun bouton dans ses cartes).
                NavItem("infos", Traductions.getString("nav_info", langue), Icons.Rounded.Info, Color(0xFFFFD600)),
                NavItem("parametres", Traductions.getString("nav_set", langue), Icons.Rounded.Settings, Color(0xFFD500F9))
            )

            Row(horizontalArrangement = Arrangement.spacedBy(14.dp), verticalAlignment = Alignment.CenterVertically) {
                items.forEach { item ->
                    val selected = routeActuelle == item.route
                    Column(horizontalAlignment = Alignment.CenterHorizontally) {
                        // V1.3.5 : boutons parfaitement ronds (formeCirculaire = true), façon
                        // boutons de télécommande — voir maquette de référence.
                        IconeNavigateur3D(icon = item.icone, description = item.titre, active = selected, taille = 46.dp, formeCirculaire = true, couleurActive = item.couleur) {
                            if (selected) {
                                // V1.3.4.2 : onglet déjà actif → on remonte la liste en haut au lieu
                                // de re-naviguer (qui n'aurait de toute façon aucun effet visible).
                                signauxDefilement[item.route] = (signauxDefilement[item.route] ?: 0) + 1
                            } else {
                                navController.navigate(item.route) { popUpTo(navController.graph.findStartDestination().id); launchSingleTop = true }
                            }
                        }
                        Spacer(Modifier.height(5.dp))
                        // V1.3.5 CORRIGÉ : seul le point du bouton actif garde sa couleur vive
                        // (en relief façon perle 3D) — les points des autres boutons se grisent,
                        // pour que le repère de couleur ne serve qu'à signaler la page active.
                        val couleurPoint = if (selected) item.couleur else tokens.mutedText
                        Box(
                            modifier = Modifier
                                .size(6.dp)
                                .then(if (selected) Modifier.shadow(elevation = 3.dp, shape = CircleShape, ambientColor = couleurPoint.copy(alpha = 0.7f), spotColor = couleurPoint.copy(alpha = 0.9f)) else Modifier)
                                .clip(CircleShape)
                                .background(if (selected) Brush.radialGradient(listOf(lerp(couleurPoint, Color.White, 0.45f), couleurPoint)) else Brush.radialGradient(listOf(couleurPoint.copy(alpha = 0.6f), couleurPoint.copy(alpha = 0.4f))))
                        )
                    }
                }
            }
        }

        // V1.3.3 : bannière de messages ("toast") maison, dessinée en dernier afin de
        // toujours s'afficher au-dessus de tout le reste (navigateur intégré, dialogues,
        // barre de navigation) — voir BanniereToast ci-dessus.
        BanniereToast()
    }
}

@Composable
fun InAppBrowserOverlay(controller: BrowserController) {
    val context = LocalContext.current
    val tokens = AeroGlassDesignSystem.current()
    val autofillStore = LocalAutofillStore.current
    val historiqueStore = LocalHistoriqueNavStore.current
    var webViewRef by remember { mutableStateOf<WebView?>(null) }
    var popupWebView by remember { mutableStateOf<WebView?>(null) }

    // Point 4-A : progression de chargement de la page (0-100).
    var progression by remember { mutableStateOf(100) }
    // Point 4-B : état de la toolbar de navigation (Précédent / Suivant).
    var peutRevenir by remember { mutableStateOf(false) }
    var peutAvancer by remember { mutableStateOf(false) }
    // Point 4-E : identifiants détectés lors d'une soumission de formulaire, en attente de confirmation.
    var identifiantsEnAttente by remember { mutableStateOf<Triple<String, String, String>?>(null) }
    // V1.3 : affichage du panneau d'historique de navigation.
    var showHistorique by remember { mutableStateOf(false) }
    var historique by remember { mutableStateOf(historiqueStore.getHistorique()) }
    // V1.3.2 : affichage du sélecteur d'onglets.
    var showOnglets by remember { mutableStateOf(false) }

    // La session (et donc la WebView) reste vivante tant qu'une URL est chargée,
    // qu'elle soit affichée au premier plan ou simplement minimisée.
    val hasSession = controller.url.value.isNotEmpty()
    val isVisible = controller.isVisible.value
    val isMinimized = controller.isMinimized.value

    // V1.3.2 : certains sites (JS très lourd, redirections d'application non installée...)
    // peuvent rester bloqués sur une page qui ne termine jamais de charger (par exemple un
    // fond uni sans contenu). Si le chargement n'est pas terminé après quelques secondes, on
    // suggère à l'utilisateur d'ouvrir la page dans un vrai navigateur externe via le nouveau
    // bouton dédié de la barre du bas, plutôt que de le laisser bloqué sans solution.
    // CORRECTIF : LocalLangue.current doit être lu ici, dans le contexte @Composable, et non
    // à l'intérieur du LaunchedEffect (fonction "suspend" classique, pas @Composable) — le
    // lire là-bas provoquait l'erreur de compilation "invocations can only happen from the
    // context of a @Composable function".
    val langueActuelle = LocalLangue.current.value
    LaunchedEffect(controller.url.value, isVisible) {
        if (isVisible && controller.url.value.isNotEmpty()) {
            delay(9000)
            if (progression in 1..99) {
                toastEnHaut(context, Traductions.getString("page_lente_txt", langueActuelle))
            }
        }
    }

    BackHandler(enabled = isVisible) {
        if (webViewRef?.canGoBack() == true) webViewRef?.goBack() else controller.minimize()
    }

    // Point 4-E : dialogue de proposition d'enregistrement / mise à jour du mot de passe.
    identifiantsEnAttente?.let { (site, user, pass) ->
        val dejaEnregistre = remember(site) { autofillStore.getIdentifiantPour(site) }
        val estUneMiseAJour = dejaEnregistre != null && dejaEnregistre.motDePasse != pass
        Dialog(onDismissRequest = { identifiantsEnAttente = null }) {
            Box(Modifier.fillMaxWidth().clip(RoundedCornerShape(20.dp)).background(tokens.baseBackground).border(1.5.dp, tokens.glassCardBorder, RoundedCornerShape(20.dp)).padding(22.dp)) {
                Column {
                    Icon(Icons.Rounded.Lock, contentDescription = null, tint = tokens.mainAccent, modifier = Modifier.size(28.dp))
                    Spacer(Modifier.height(12.dp))
                    PremiumText(if (estUneMiseAJour) Traductions.getString("mdp_maj_titre", LocalLangue.current.value) else Traductions.getString("mdp_enregistrer_titre", LocalLangue.current.value), color = tokens.textPrimary, size = 17f, fontWeight = FontWeight.Bold)
                    Spacer(Modifier.height(6.dp))
                    PremiumText(site, color = tokens.textSecondary, size = 13f)
                    Spacer(Modifier.height(6.dp))
                    PremiumText(user, color = tokens.mainAccent, size = 14f, fontWeight = FontWeight.SemiBold)
                    Spacer(Modifier.height(20.dp))
                    Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                        AnimatedButton(Traductions.getString("mdp_ignorer", LocalLangue.current.value), tokens.glassCardBackground, tokens.textPrimary, Modifier.weight(1f)) { identifiantsEnAttente = null }
                        AnimatedButton(Traductions.getString("mdp_enregistrer", LocalLangue.current.value), tokens.mainAccent, tokens.buttonText, Modifier.weight(1f)) {
                            autofillStore.enregistrerOuMettreAJour(site, user, pass)
                            identifiantsEnAttente = null
                        }
                    }
                }
            }
        }
    }

    if (hasSession) {
        // Glissement manuel (au lieu d'AnimatedVisibility) : la WebView n'est jamais
        // détruite/recomposée tant que la session est active, seule sa position change.
        val offsetY by animateDpAsState(
            targetValue = if (isVisible) 0.dp else 3000.dp,
            animationSpec = spring(dampingRatio = Spring.DampingRatioNoBouncy),
            label = "browser_offset"
        )

        Column(
            modifier = Modifier
                .fillMaxSize()
                .zIndex(100f)
                .offset(y = offsetY)
                // V1.3.3 : le navigateur intégré utilise un fond blanc pur (et non le gris très
                // clair du reste de l'application) — repris tel quel du mockup HTML dédié au
                // navigateur, validé séparément de l'écran principal.
                .background(Color.White)
        ) {
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .height(52.dp)
                    // V1.3.6 : la barre du haut garde son fond blanc uni (validé au mockup), mais
                    // gagne désormais une fine ombre portée en pied de barre pour se détacher
                    // nettement du contenu web affiché juste en dessous — rendu plus "net" et
                    // moderne qu'un simple aplat sans aucune séparation visuelle.
                    .shadow(elevation = 5.dp, shape = RectangleShape, ambientColor = Color.Black.copy(alpha = 0.12f), spotColor = Color.Black.copy(alpha = 0.12f))
                    .background(Color.White)
                    // Corrige la propagation des clics : la barre d'outils intercepte désormais
                    // tous les événements tactiles et ne les laisse plus traverser vers l'écran
                    // situé derrière le navigateur (zone vide entre le titre et les boutons incluse).
                    .clickable(interactionSource = remember { MutableInteractionSource() }, indication = null) { }
                    .padding(horizontal = 14.dp),
                verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.SpaceBetween
            ) {
                Row(verticalAlignment = Alignment.CenterVertically, modifier = Modifier.weight(1f)) {
                    // V1.3.3 : petit badge "cadenas" devant le titre, comme un vrai navigateur
                    // moderne signalant une navigation sécurisée — cohérent avec le nouveau
                    // rendu clair/opaque de la barre (voir AeroGlassDesignSystem.EclipseTotale).
                    // V1.3.6 : dégradé vif (au lieu d'un simple aplat sombre) + lueur de couleur,
                    // pour un rendu plus moderne/3D — tout en restant un indicateur neutre de
                    // sécurité (pas teinté de l'accent de l'appli, comme dans un vrai navigateur).
                    Box(
                        modifier = Modifier
                            .size(30.dp)
                            .shadow(elevation = 8.dp, shape = CircleShape, ambientColor = Color.Black.copy(alpha = 0.35f), spotColor = Color.Black.copy(alpha = 0.4f))
                            .clip(CircleShape)
                            .background(Brush.linearGradient(listOf(Color(0xFF2A2E37), Color(0xFF0A0B0D)))),
                        contentAlignment = Alignment.Center
                    ) {
                        Icon(Icons.Rounded.Lock, contentDescription = null, tint = Color.White, modifier = Modifier.size(14.dp))
                    }
                    Spacer(modifier = Modifier.width(9.dp))
                    Column {
                        PremiumText("Navigation Sécurisée", tokens.textPrimary, 13f, FontWeight.Bold)
                        // V1.3.3 : nom de domaine de la page affichée, en sous-titre — un repère
                        // visuel qu'ont tous les navigateurs modernes et qui manquait ici.
                        val domaine = remember(controller.url.value) {
                            try { Uri.parse(controller.url.value).host?.removePrefix("www.") ?: "" } catch (e: Exception) { "" }
                        }
                        if (domaine.isNotEmpty()) {
                            PremiumText(domaine, tokens.textSecondary, 10.5f, FontWeight.Medium, modifier = Modifier.padding(top = 1.dp))
                        }
                    }
                }
                Row(verticalAlignment = Alignment.CenterVertically) {
                    // V1.3.4.1 CORRIGÉ : l'icône "dossier/onglets" + badge n'était pas assez
                    // moderne — remplacée par un simple rond affichant directement le NOMBRE
                    // d'onglets ouverts (comme les navigateurs de référence), sans icône du tout.
                    // V1.3.6 : dégradé teinté par l'accent de l'appli (au lieu d'un gris neutre),
                    // plus vif et cohérent avec le reste de la modernisation du navigateur.
                    Box(
                        modifier = Modifier
                            .padding(end = 6.dp)
                            .size(34.dp)
                            .shadow(elevation = 8.dp, shape = CircleShape, ambientColor = tokens.mainAccent.copy(alpha = 0.4f), spotColor = tokens.mainAccent.copy(alpha = 0.45f))
                            .clip(CircleShape)
                            .background(Brush.linearGradient(listOf(tokens.mainAccent.copy(alpha = 0.85f), tokens.mainAccent.copy(alpha = 0.55f))))
                            .border(1.dp, Color.White.copy(alpha = 0.4f), CircleShape)
                            .clickable(interactionSource = remember { MutableInteractionSource() }, indication = null) { showOnglets = true },
                        contentAlignment = Alignment.Center
                    ) {
                        PremiumText("${controller.onglets.size}", color = tokens.buttonText, size = 13f, fontWeight = FontWeight.Black)
                    }
                    IconeNavigateur3D(Icons.Rounded.KeyboardArrowDown, "Réduire", taille = 34.dp, modifier = Modifier.padding(end = 6.dp)) { controller.minimize() }
                    IconeNavigateur3D(Icons.Rounded.Close, "Fermer", taille = 34.dp) { controller.close() }
                }
            }

            // Point 4-A : barre de progression du chargement, visible uniquement pendant le
            // chargement. V1.3.3 : piste "creusée" (néomorphisme) + remplissage en dégradé vert.
            if (progression in 1..99) {
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = 14.dp)
                        .padding(top = 2.dp, bottom = 6.dp)
                        .height(7.dp)
                        .clip(RoundedCornerShape(50))
                        .background(Brush.linearGradient(listOf(tokens.neuInsetDark, tokens.neuInsetLight)))
                        .ombreCreusee(tokens)
                ) {
                    Box(
                        modifier = Modifier
                            .fillMaxHeight()
                            .fillMaxWidth(fraction = (progression / 100f).coerceIn(0f, 1f))
                            .clip(RoundedCornerShape(50))
                            .background(Brush.verticalGradient(listOf(Color(0xFF22C98A), tokens.mainAccent)))
                    )
                }
            } else {
                Spacer(modifier = Modifier.fillMaxWidth().height(15.dp))
            }

            AndroidView(
                factory = { ctx ->
                    WebView(ctx).apply {
                        webViewRef = this
                        settings.apply {
                            javaScriptEnabled = true
                            domStorageEnabled = true
                            databaseEnabled = true
                            useWideViewPort = true
                            loadWithOverviewMode = true
                            // Requis pour laisser les flux d'authentification (Google/Apple) ouvrir
                            // une fenêtre de sélection de compte (popup) depuis la page chargée.
                            setSupportMultipleWindows(true)
                            javaScriptCanOpenWindowsAutomatically = true
                            // Un "user-agent" de navigateur mobile standard évite que Google ne
                            // bloque la connexion en détectant une WebView embarquée générique.
                            userAgentString = UA_CHROME_MOBILE
                            // V1.3.2 : contenu mixte autorisé au maximum et Safe Browsing désactivé —
                            // certains sites (ex : Delta) chargent des ressources qui restent
                            // bloquées avec les réglages par défaut, provoquant une page qui ne finit
                            // jamais de s'afficher (fond uni sans contenu).
                            mixedContentMode = WebSettings.MIXED_CONTENT_ALWAYS_ALLOW
                            safeBrowsingEnabled = false
                            mediaPlaybackRequiresUserGesture = false
                            // V1.3.2 : accès explicite au cache/stockage local — certains sites (Delta
                            // inclus) reposent sur un rendu applicatif (SPA) qui a besoin du cache
                            // navigateur standard pour terminer correctement son affichage.
                            cacheMode = WebSettings.LOAD_DEFAULT
                            allowContentAccess = true
                            allowFileAccess = true
                        }
                        // V1.3.2 : CORRECTIF DELTA — désactive complètement l'assombrissement
                        // algorithmique automatique ("Force Dark") que le WebView applique par
                        // défaut sur les appareils configurés en thème sombre système, dès lors
                        // qu'un site ne déclare pas explicitement son propre thème sombre. Ce
                        // mécanisme réinterprète les couleurs de la page sans que le site ne le
                        // demande et peut rendre invisibles logo, textes, icônes et boutons — ne
                        // laissant visible que la couleur de fond, exactement le symptôme observé
                        // sur https://www.delta.kim. On force donc systématiquement un rendu "tel
                        // qu'authored" par le site, identique à celui obtenu dans un navigateur
                        // classique (Chrome), quel que soit le thème système de l'appareil.
                        if (WebViewFeature.isFeatureSupported(WebViewFeature.ALGORITHMIC_DARKENING)) {
                            WebSettingsCompat.setAlgorithmicDarkeningAllowed(settings, false)
                        } else if (WebViewFeature.isFeatureSupported(WebViewFeature.FORCE_DARK)) {
                            @Suppress("DEPRECATION")
                            WebSettingsCompat.setForceDark(settings, WebSettingsCompat.FORCE_DARK_OFF)
                        }
                        // V1.3.2 : rendu accéléré matériellement de façon garantie — un rendu
                        // logiciel (software) peut laisser certains éléments (canvas, SVG, effets
                        // CSS modernes utilisés par Delta) ne jamais s'afficher correctement.
                        setLayerType(android.view.View.LAYER_TYPE_HARDWARE, null)
                        CookieManager.getInstance().setAcceptCookie(true)
                        CookieManager.getInstance().setAcceptThirdPartyCookies(this, true)

                        // Point 4-D/E : pont JS pour l'auto-remplissage et la capture des identifiants soumis.
                        addJavascriptInterface(
                            CaptureIdentifiantsBridge { site, user, pass ->
                                // V1.3.4 : vérification silencieuse en arrière-plan (aucune notification,
                                // aucun blocage de l'interface) — si l'identifiant ET le mot de passe
                                // soumis sont rigoureusement identiques à ceux déjà enregistrés pour ce
                                // site, on ne propose plus jamais de les ré-enregistrer. Le dialogue ne
                                // s'affiche désormais QUE si le site est nouveau (aucun identifiant
                                // enregistré pour ce domaine) ou si les coordonnées ont changé (nouvel
                                // identifiant et/ou nouveau mot de passe).
                                val existant = autofillStore.getIdentifiantPour(site)
                                val estIdentique = existant != null && existant.identifiant == user && existant.motDePasse == pass
                                if (!estIdentique) {
                                    identifiantsEnAttente = Triple(site, user, pass)
                                }
                            },
                            "AndroidAutofillBridge"
                        )

                        webViewClient = object : WebViewClient() {
                            override fun shouldOverrideUrlLoading(view: WebView?, request: WebResourceRequest?): Boolean {
                                // V1.3.2 : toute la logique de détection (connexions externes,
                                // liens "intent://", applications natives type Play Store/YouTube...)
                                // est désormais centralisée dans gererNavigationExterne, réutilisée
                                // aussi par la fenêtre pop-up ci-dessous — voir son commentaire pour
                                // le détail des bugs corrigés (TikCoin notamment). On lui transmet
                                // désormais la requête complète (pour savoir si la navigation provient
                                // bien d'un vrai geste utilisateur) ainsi que l'URL de la page
                                // actuellement affichée (pour identifier les sites, comme TikCoin, dont
                                // les redirections automatiques vers le Play Store doivent être bloquées).
                                return gererNavigationExterne(ctx, request, view?.url)
                            }

                            override fun onPageStarted(view: WebView?, url: String?, favicon: android.graphics.Bitmap?) {
                                peutRevenir = view?.canGoBack() ?: false
                                peutAvancer = view?.canGoForward() ?: false
                            }

                            override fun onPageFinished(view: WebView?, url: String?) {
                                peutRevenir = view?.canGoBack() ?: false
                                peutAvancer = view?.canGoForward() ?: false
                                progression = 100
                                CookieManager.getInstance().flush()

                                // V1.3 : enregistrement de la page dans l'historique de navigation.
                                if (!url.isNullOrBlank()) {
                                    historiqueStore.ajouter(url, view?.title ?: "")
                                    historique = historiqueStore.getHistorique()
                                    // V1.3.2 : garde l'onglet actif à jour (titre + URL courante),
                                    // affiché dans le sélecteur d'onglets.
                                    controller.mettreAJourOngletActif(url, view?.title ?: "")
                                }

                                // Point 4-D : auto-remplissage des champs courants avec le profil enregistré.
                                val profil = autofillStore.getProfil()
                                val hote = try { Uri.parse(url).host ?: "" } catch (e: Exception) { "" }
                                val identifiantSauvegarde = if (hote.isNotEmpty()) autofillStore.getIdentifiantPour(hote) else null
                                view?.evaluateJavascript(
                                    JS_AUTOFILL
                                        .replace("__EMAIL__", jsEscape(profil.email))
                                        .replace("__TEL__", jsEscape(profil.telephone))
                                        .replace("__INDICATIF__", jsEscape(profil.indicatifTelephone))
                                        .replace("__NOMCOMPLET__", jsEscape(profil.nomComplet))
                                        .replace("__PRENOM__", jsEscape(profil.prenom))
                                        .replace("__NOM__", jsEscape(profil.nom))
                                        .replace("__USERNAME__", jsEscape(identifiantSauvegarde?.identifiant ?: profil.nomUtilisateur))
                                        .replace("__ADRESSE__", jsEscape(profil.adresse))
                                        // V1.3.4.1 : date de naissance, déjà stockée au format ISO
                                        // (AAAA-MM-JJ), directement compatible avec les champs
                                        // <input type="date"> des formulaires.
                                        .replace("__DATENAISSANCE__", jsEscape(profil.dateNaissance))
                                        // V1.3.6 : champs complémentaires (ville, code postal, pays, genre).
                                        .replace("__VILLE__", jsEscape(profil.ville))
                                        .replace("__CODEPOSTAL__", jsEscape(profil.codePostal))
                                        .replace("__PAYS__", jsEscape(profil.pays))
                                        .replace("__SEXE__", jsEscape(profil.sexe))
                                        // V1.3.2 : si aucun mot de passe n'est déjà enregistré pour ce site précis
                                        // (première visite / inscription), on utilise le mot de passe par défaut du
                                        // profil pour remplir à la fois la case "mot de passe" et "confirmation".
                                        .replace("__PASSWORD__", jsEscape(identifiantSauvegarde?.motDePasse ?: profil.motDePasseParDefaut)),
                                    null
                                )
                                // Point 4-E : écoute des soumissions de formulaire pour proposer l'enregistrement.
                                view?.evaluateJavascript(JS_CAPTURE_SUBMIT, null)
                            }
                        }
                        // Gère l'ouverture des pop-ups requises par les connexions Google/Apple (SSO).
                        webChromeClient = object : WebChromeClient() {
                            override fun onProgressChanged(view: WebView?, newProgress: Int) {
                                progression = newProgress
                            }
                            override fun onCreateWindow(view: WebView?, isDialog: Boolean, isUserGesture: Boolean, resultMsg: Message?): Boolean {
                                // V1.3.2 : URL de la page ayant demandé l'ouverture de cette fenêtre
                                // pop-up (ex : tikcoin.info) — transmise à gererNavigationExterne pour
                                // qu'elle puisse bloquer les redirections automatiques vers le Play
                                // Store propres à certains sites (voir HOTES_SANS_REDIRECTION_STORE).
                                val urlPageOrigine = view?.url
                                val popup = WebView(ctx).apply {
                                    settings.javaScriptEnabled = true
                                    settings.domStorageEnabled = true
                                    settings.setSupportMultipleWindows(true)
                                    settings.userAgentString = UA_CHROME_MOBILE
                                    settings.mixedContentMode = WebSettings.MIXED_CONTENT_ALWAYS_ALLOW
                                    settings.safeBrowsingEnabled = false
                                    settings.databaseEnabled = true
                                    settings.useWideViewPort = true
                                    settings.loadWithOverviewMode = true
                                    // V1.3.2 : même correctif Delta que la WebView principale — pas
                                    // d'assombrissement algorithmique automatique dans les pop-ups non plus.
                                    if (WebViewFeature.isFeatureSupported(WebViewFeature.ALGORITHMIC_DARKENING)) {
                                        WebSettingsCompat.setAlgorithmicDarkeningAllowed(settings, false)
                                    } else if (WebViewFeature.isFeatureSupported(WebViewFeature.FORCE_DARK)) {
                                        @Suppress("DEPRECATION")
                                        WebSettingsCompat.setForceDark(settings, WebSettingsCompat.FORCE_DARK_OFF)
                                    }
                                    CookieManager.getInstance().setAcceptThirdPartyCookies(this, true)
                                    webViewClient = object : WebViewClient() {
                                        override fun shouldOverrideUrlLoading(popupView: WebView?, request: WebResourceRequest?): Boolean {
                                            // V1.3.2 : CORRECTIF CRITIQUE — cette fenêtre pop-up (ouverte par
                                            // "window.open()"/cible _blank, exactement le mécanisme utilisé par
                                            // TikCoin pour rediriger vers le Play Store) ne gérait auparavant QUE
                                            // les connexions Google/Apple. Les liens "intent://play.google.com/..."
                                            // qu'elle recevait n'étaient donc jamais interceptés et la WebView
                                            // tentait de les charger elle-même comme une page web normale — d'où
                                            // l'erreur "net::ERR_UNKNOWN_URL_SCHEME" observée. Elle réutilise
                                            // désormais la même fonction gererNavigationExterne que la WebView
                                            // principale (décodage correct du format "intent://", ouverture
                                            // native du Play Store/YouTube/WhatsApp..., et blocage définitif des
                                            // redirections automatiques vers le Play Store pour TikCoin).
                                            val gere = gererNavigationExterne(ctx, request, popupView?.url ?: urlPageOrigine)
                                            if (gere) { popupWebView?.destroy(); popupWebView = null }
                                            return gere
                                        }
                                        override fun onPageFinished(popupView: WebView?, url: String?) {
                                            CookieManager.getInstance().flush()
                                        }
                                    }
                                    webChromeClient = object : WebChromeClient() {
                                        override fun onCloseWindow(window: WebView?) {
                                            popupWebView?.destroy()
                                            popupWebView = null
                                        }
                                    }
                                }
                                popupWebView = popup
                                val transport = resultMsg?.obj as? WebView.WebViewTransport
                                transport?.webView = popup
                                resultMsg?.sendToTarget()
                                return true
                            }
                        }
                        setDownloadListener { downloadUrl, _, _, _, _ ->
                            try { ctx.startActivity(Intent(Intent.ACTION_VIEW, Uri.parse(downloadUrl))) } catch (e: Exception) {}
                        }
                    }
                },
                update = { webView ->
                    if (controller.url.value.isNotEmpty() && controller.url.value != webView.url) {
                        webView.loadUrl(controller.url.value)
                    }
                },
                onRelease = { webView ->
                    webView.stopLoading()
                    webView.clearHistory()
                    webView.destroy()
                    webViewRef = null
                },
                modifier = Modifier.fillMaxSize().weight(1f)
            )

            // Point 4-B : toolbar de navigation (Précédent / Suivant / Actualiser-Arrêter / Accueil).
            // V1.3.4.1 CORRIGÉ : barre allégée (icônes et marges réduites) — la barre paraissait
            // trop épaisse, avec les icônes qui semblaient "remonter" dans l'espace en trop.
            // V1.3.6 : la barre n'avait aucune marge au-dessus d'elle (seulement en dessous), ce
            // qui la faisait paraître collée/remontée contre le contenu web juste au-dessus —
            // ajout d'une marge haute + repère visuel (ligne de séparation) pour bien l'ancrer
            // en bas d'écran. Recentrage explicite sur une largeur définie (au lieu d'un simple
            // wrap-content) pour garantir un centrage fiable quel que soit l'appareil, avec des
            // icônes réparties de façon régulière (Arrangement.SpaceEvenly) plutôt que tassées
            // d'un côté. Rendu aussi plus moderne : dégradé sombre en relief + liseré de couleur
            // vive (accent de l'appli) au lieu d'un simple aplat noir avec bordure grise plate.
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .background(Brush.verticalGradient(listOf(Color.Transparent, Color.Black.copy(alpha = 0.06f))))
                    .padding(top = 12.dp, bottom = 16.dp),
                contentAlignment = Alignment.Center
            ) {
                Row(
                    modifier = Modifier
                        .fillMaxWidth(0.94f)
                        .shadow(elevation = 20.dp, shape = RoundedCornerShape(28.dp), ambientColor = Color.Black.copy(alpha = 0.5f), spotColor = Color.Black.copy(alpha = 0.5f))
                        .clip(RoundedCornerShape(28.dp))
                        .background(Brush.verticalGradient(listOf(Color(0xFF1C1E24), Color(0xFF050506))))
                        .border(1.5.dp, Brush.linearGradient(listOf(tokens.mainAccent.copy(alpha = 0.55f), Color.White.copy(alpha = 0.12f))), RoundedCornerShape(28.dp))
                        .padding(horizontal = 10.dp, vertical = 8.dp),
                    horizontalArrangement = Arrangement.SpaceEvenly, verticalAlignment = Alignment.CenterVertically
                ) {
                    IconeNavigateur3D(Icons.Rounded.ArrowBack, Traductions.getString("nav_back_browser", LocalLangue.current.value), enabled = peutRevenir, taille = 38.dp) { webViewRef?.goBack() }
                    IconeNavigateur3D(Icons.Rounded.ArrowForward, Traductions.getString("nav_forward_browser", LocalLangue.current.value), enabled = peutAvancer, taille = 38.dp) { webViewRef?.goForward() }
                    if (progression in 1..99) {
                        IconeNavigateur3D(Icons.Rounded.Close, Traductions.getString("nav_stop_browser", LocalLangue.current.value), taille = 38.dp) { webViewRef?.stopLoading() }
                    } else {
                        IconeNavigateur3D(Icons.Rounded.Refresh, Traductions.getString("nav_refresh_browser", LocalLangue.current.value), taille = 38.dp) { webViewRef?.reload() }
                    }
                    IconeNavigateur3D(Icons.Rounded.Home, Traductions.getString("nav_home_browser", LocalLangue.current.value), taille = 38.dp) { if (controller.url.value.isNotEmpty()) webViewRef?.loadUrl(controller.url.value) }
                    // V1.3 : bouton d'historique de navigation, ouvre la liste des pages récemment visitées.
                    IconeNavigateur3D(Icons.Rounded.History, Traductions.getString("historique_nav_titre", LocalLangue.current.value), taille = 38.dp) { historique = historiqueStore.getHistorique(); showHistorique = true }
                    // V1.3.2 : bascule immédiate vers un vrai navigateur externe (Chrome...). Utile de
                    // secours pour les sites dont le rendu reste bloqué dans le navigateur intégré
                    // (ex : Delta, qui affiche un fond bleu uni sans jamais terminer de charger) —
                    // l'utilisateur avait déjà constaté que coller le lien dans Chrome fonctionnait.
                    IconeNavigateur3D(Icons.Rounded.OpenInBrowser, Traductions.getString("nav_ouvrir_externe", LocalLangue.current.value), taille = 38.dp) { if (controller.url.value.isNotEmpty()) ouvrirEnNavigateurExterne(context, controller.url.value) }
                }
            }
        }
    }

    // V1.3 : panneau d'historique de navigation (liste des pages récemment visitées).
    if (showHistorique) {
        Dialog(onDismissRequest = { showHistorique = false }) {
            Box(Modifier.fillMaxWidth().heightIn(max = 480.dp).clip(RoundedCornerShape(22.dp)).background(tokens.baseBackground).border(1.5.dp, tokens.glassCardBorder, RoundedCornerShape(22.dp)).padding(20.dp)) {
                Column {
                    Row(Modifier.fillMaxWidth(), Arrangement.SpaceBetween, Alignment.CenterVertically) {
                        PremiumText(Traductions.getString("historique_nav_titre", LocalLangue.current.value), color = tokens.mainAccent, size = 17f, fontWeight = FontWeight.ExtraBold, is3D = true)
                        IconeNavigateur3D(Icons.Rounded.Close, "Fermer", taille = 34.dp) { showHistorique = false }
                    }
                    Spacer(Modifier.height(14.dp))
                    if (historique.isEmpty()) {
                        PremiumText(Traductions.getString("historique_nav_vide", LocalLangue.current.value), color = tokens.textSecondary, size = 14f, modifier = Modifier.padding(vertical = 20.dp))
                    } else {
                        LazyColumn(modifier = Modifier.weight(1f, fill = false).heightIn(max = 330.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
                            items(historique) { entree ->
                                Row(
                                    modifier = Modifier.fillMaxWidth()
                                        .clip(RoundedCornerShape(12.dp))
                                        .background(tokens.glassCardBackground)
                                        .clickable(interactionSource = remember { MutableInteractionSource() }, indication = null) {
                                            controller.open(entree.url); showHistorique = false
                                        }
                                        .padding(12.dp),
                                    verticalAlignment = Alignment.CenterVertically
                                ) {
                                    Icon(Icons.Rounded.Public, contentDescription = null, tint = tokens.mainAccent, modifier = Modifier.size(18.dp))
                                    Spacer(Modifier.width(10.dp))
                                    Column(modifier = Modifier.weight(1f)) {
                                        PremiumText(entree.titre, color = tokens.textPrimary, size = 13.5f, fontWeight = FontWeight.SemiBold)
                                        PremiumText(entree.dateVisite, color = tokens.textSecondary, size = 11f)
                                    }
                                }
                            }
                        }
                        Spacer(Modifier.height(16.dp))
                        AnimatedButton(Traductions.getString("historique_effacer", LocalLangue.current.value), tokens.glassCardBackground, tokens.textPrimary, Modifier.fillMaxWidth()) {
                            historiqueStore.effacer(); historique = emptyList()
                        }
                    }
                }
            }
        }
    }

    // V1.3.2 : sélecteur d'onglets — permet de retrouver et de basculer vers un lien ouvert
    // précédemment (airdrop, inscription...) sans avoir eu à le refermer, et de fermer
    // individuellement chaque onglet devenu inutile.
    if (showOnglets) {
        Dialog(onDismissRequest = { showOnglets = false }) {
            Box(Modifier.fillMaxWidth().heightIn(max = 460.dp).clip(RoundedCornerShape(22.dp)).background(tokens.baseBackground).border(1.5.dp, tokens.glassCardBorder.copy(alpha = 0.9f), RoundedCornerShape(22.dp)).padding(20.dp)) {
                Column {
                    Row(Modifier.fillMaxWidth(), Arrangement.SpaceBetween, Alignment.CenterVertically) {
                        PremiumText("Onglets ouverts (${controller.onglets.size})", color = tokens.mainAccent, size = 17f, fontWeight = FontWeight.ExtraBold, is3D = true)
                        IconeNavigateur3D(Icons.Rounded.Close, "Fermer", taille = 34.dp) { showOnglets = false }
                    }
                    Spacer(Modifier.height(14.dp))
                    LazyColumn(modifier = Modifier.weight(1f, fill = false).heightIn(max = 330.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
                        items(controller.onglets, key = { it.id }) { onglet ->
                            val actif = onglet.id == controller.ongletActifId.value
                            Row(
                                modifier = Modifier.fillMaxWidth()
                                    .clip(RoundedCornerShape(14.dp))
                                    .background(if (actif) tokens.mainAccent.copy(alpha = 0.16f) else tokens.glassCardBackground)
                                    .border(1.dp, if (actif) tokens.mainAccent.copy(alpha = 0.6f) else tokens.glassCardBorder.copy(alpha = 0.8f), RoundedCornerShape(14.dp))
                                    .clickable(interactionSource = remember { MutableInteractionSource() }, indication = null) {
                                        controller.basculerVersOnglet(onglet.id); showOnglets = false
                                    }
                                    .padding(12.dp),
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                Icon(Icons.Rounded.Public, contentDescription = null, tint = tokens.mainAccent, modifier = Modifier.size(18.dp))
                                Spacer(Modifier.width(10.dp))
                                Column(modifier = Modifier.weight(1f)) {
                                    PremiumText(onglet.titre.ifBlank { onglet.url }, color = tokens.textPrimary, size = 13.5f, fontWeight = FontWeight.SemiBold)
                                }
                                Icon(Icons.Rounded.Close, contentDescription = "Fermer l'onglet", tint = tokens.textSecondary, modifier = Modifier.size(18.dp).clickable(interactionSource = remember { MutableInteractionSource() }, indication = null) { controller.fermerOnglet(onglet.id) })
                            }
                        }
                    }
                }
            }
        }
    }

    // Bulle de reprise : permet de rouvrir le navigateur minimisé sans perdre la page en cours.
    if (hasSession && isMinimized) {
        Box(modifier = Modifier.fillMaxSize().zIndex(90f), contentAlignment = Alignment.BottomEnd) {
            Row(
                verticalAlignment = Alignment.CenterVertically,
                modifier = Modifier
                    .padding(bottom = 110.dp, end = 20.dp)
                    .shadow(elevation = 16.dp, shape = RoundedCornerShape(50.dp), ambientColor = tokens.mainAccent.copy(alpha = 0.4f), spotColor = tokens.mainAccent.copy(alpha = 0.5f))
                    .clip(RoundedCornerShape(50.dp))
                    .background(tokens.glassCardBackground)
                    .border(1.dp, tokens.glassCardBorder, RoundedCornerShape(50.dp))
                    .clickable(interactionSource = remember { MutableInteractionSource() }, indication = null) { controller.restore() }
                    .padding(horizontal = 16.dp, vertical = 12.dp)
            ) {
                Icon(Icons.Rounded.Public, contentDescription = "Reprendre la navigation", tint = tokens.mainAccent, modifier = Modifier.size(20.dp))
                Spacer(Modifier.width(8.dp))
                PremiumText("Reprendre", color = tokens.textPrimary, size = 13f, fontWeight = FontWeight.Bold)
                Spacer(Modifier.width(10.dp))
                Icon(
                    Icons.Rounded.Close, contentDescription = "Fermer", tint = tokens.textSecondary,
                    modifier = Modifier.size(16.dp).clickable(interactionSource = remember { MutableInteractionSource() }, indication = null) { controller.close() }
                )
            }
        }
    }

    // Fenêtre pop-up des connexions tierces (Google / Apple / Facebook...).
    popupWebView?.let { popup ->
        Box(modifier = Modifier.fillMaxSize().zIndex(200f).background(tokens.baseBackground)) {
            Column(modifier = Modifier.fillMaxSize()) {
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(56.dp)
                        .background(tokens.glassCardBackground)
                        .border(1.dp, tokens.glassCardBorder)
                        .clickable(interactionSource = remember { MutableInteractionSource() }, indication = null) { }
                        .padding(horizontal = 16.dp),
                    verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.SpaceBetween
                ) {
                    PremiumText("Connexion sécurisée", tokens.mainAccent, 14f, FontWeight.Bold)
                    Icon(
                        Icons.Rounded.Close, contentDescription = "Fermer", tint = tokens.textPrimary,
                        modifier = Modifier.size(24.dp).clickable(interactionSource = remember { MutableInteractionSource() }, indication = null) {
                            popup.destroy(); popupWebView = null
                        }
                    )
                }
                AndroidView(factory = { popup }, modifier = Modifier.fillMaxSize().weight(1f))
            }
        }
    }
}

/** User-agent Chrome mobile standard : évite le blocage des connexions Google dans une WebView embarquée. */
private const val UA_CHROME_MOBILE = "Mozilla/5.0 (Linux; Android 13; Pixel 7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Mobile Safari/537.36"

/**
 * V1.4 : détecte les URLs de connexion tierce (Google, Apple, Facebook, Microsoft) que
 * Google et consorts refusent volontairement d'afficher dans une WebView embarquée
 * générique — quel que soit le user-agent renseigné, la politique "disallowed_useragent"
 * bloque l'accès au sélecteur de comptes. C'est une restriction imposée par ces
 * fournisseurs eux-mêmes, pas un bug de l'application : la seule solution qui fonctionne
 * réellement est d'ouvrir ces pages précises dans un vrai navigateur.
 */
private fun estUrlAuthentificationExterne(url: String): Boolean {
    val hotesBloques = listOf(
        "accounts.google.com", "accounts.youtube.com", "appleid.apple.com",
        "login.microsoftonline.com", "www.facebook.com/dialog", "m.facebook.com/dialog"
    )
    return hotesBloques.any { url.contains(it, ignoreCase = true) }
}

/** Ouvre une URL dans un vrai navigateur (Custom Tabs si possible, sinon navigateur par défaut). */
private fun ouvrirEnNavigateurExterne(ctx: android.content.Context, url: String) {
    try {
        CustomTabsIntent.Builder().build().launchUrl(ctx, Uri.parse(url))
    } catch (e: Exception) {
        try { ctx.startActivity(Intent(Intent.ACTION_VIEW, Uri.parse(url))) } catch (e2: Exception) {}
    }
}

/**
 * V1.3.2 : liste des domaines dont les liens vers un store d'applications (Play Store,
 * market://, App Store) ne doivent JAMAIS être suivis automatiquement — quel que soit leur
 * format (URL directe ou encapsulée dans un lien "intent://"). TikCoin en fait partie : ce
 * site déclenche dès le chargement de la page (donc sans aucune action de l'utilisateur)
 * une bannière "ouvrir l'application" qui ouvrait par erreur le Play Store à la place du
 * site lui-même. Le bouton "Rejoindre" de TikCoin doit toujours rester sur
 * https://tikcoin.info/?invitationCode=GRP-28EBV1PU, affiché dans le navigateur intégré.
 */
private val HOTES_SANS_REDIRECTION_STORE = listOf("tikcoin.info")

/** V1.3.2 : détecte tout lien pointant vers un store d'applications (Play Store/market/App Store). */
private fun estLienVersStore(url: String): Boolean =
    url.contains("play.google.com", ignoreCase = true) ||
    url.contains("market://", ignoreCase = true) ||
    url.startsWith("market:", ignoreCase = true) ||
    url.contains("apps.apple.com", ignoreCase = true)

/**
 * V1.3.2 : point d'entrée UNIQUE pour toute navigation qui doit sortir de la page
 * actuellement affichée dans le navigateur intégré — utilisé à la fois par la WebView
 * principale et par la fenêtre pop-up interne (voir plus haut pour le contexte du bug
 * corrigé). Trois problèmes réels étaient auparavant présents :
 *  1) Les liens au format "intent://" (utilisés par de nombreux sites, dont TikCoin, pour
 *     rediriger vers le Play Store si l'application n'est pas installée) étaient soit
 *     ignorés (fenêtre pop-up), soit mal interprétés (ouverture directe de l'URI brute au
 *     lieu de décoder l'Intent qu'elle contient) — ce qui provoquait l'erreur
 *     "net::ERR_UNKNOWN_URL_SCHEME" affichée à l'utilisateur au lieu d'ouvrir le Play Store.
 *  2) Cette gestion des liens applicatifs n'existait tout simplement pas dans la fenêtre
 *     pop-up, seulement dans la WebView principale.
 *  3) CORRECTIF DÉFINITIF TIKCOIN : même une fois l'erreur ci-dessus corrigée, TikCoin
 *     continuait d'ouvrir le Play Store car sa bannière "ouvrir l'application" se déclenche
 *     automatiquement en JavaScript dès le chargement de la page, sans le moindre clic de
 *     l'utilisateur. On distingue désormais ce cas grâce à `request.hasGesture()` (qui
 *     indique si la navigation provient réellement d'une action de l'utilisateur ou d'un
 *     script) : toute tentative d'ouverture d'un store qui n'est pas un vrai geste de
 *     l'utilisateur — ou qui provient d'une page listée dans HOTES_SANS_REDIRECTION_STORE,
 *     quoi qu'il arrive — est désormais purement et simplement ignorée : la page continue de
 *     s'afficher normalement dans le navigateur intégré au lieu d'être remplacée par le
 *     Play Store.
 * Ces trois points sont désormais corrigés et centralisés ici.
 */
private fun gererNavigationExterne(ctx: android.content.Context, request: WebResourceRequest?, urlPageActuelle: String?): Boolean {
    if (request == null) return false
    val uri = request.url ?: return false
    val urlStr = uri.toString()
    val scheme = uri.scheme?.lowercase(java.util.Locale.ROOT) ?: ""
    val hotePage = try { Uri.parse(urlPageActuelle)?.host?.lowercase(java.util.Locale.ROOT) ?: "" } catch (e: Exception) { "" }
    val pageBloqueeContreStore = HOTES_SANS_REDIRECTION_STORE.any { hotePage.contains(it) }
    // Redirection vers un store autorisée uniquement si l'utilisateur a réellement cliqué
    // ET si la page en cours n'est pas explicitement bloquée (TikCoin).
    val redirectionStoreAutorisee = request.hasGesture() && !pageBloqueeContreStore

    // 1) Connexions tierces (Google/Apple/Facebook) : toujours vers un vrai navigateur.
    if (estUrlAuthentificationExterne(urlStr)) {
        ouvrirEnNavigateurExterne(ctx, urlStr)
        return true
    }

    // 2) CORRECTIF TIKCOIN : lien direct (http/https) ou schéma "market://" vers un store
    // d'applications, non déclenché par un vrai geste utilisateur ou provenant d'une page
    // bloquée : on l'ignore silencieusement, la page actuelle reste affichée telle quelle.
    if ((estLienVersStore(urlStr) || scheme == "market") && !redirectionStoreAutorisee) {
        return true
    }

    // 3) Liens "intent://" (format Chrome) : on décode le véritable Intent embarqué au lieu
    // de tenter de charger l'URI "intent://" telle quelle, avec repli sur son URL de secours
    // ("browser_fallback_url", typiquement une fiche Play Store) si l'app visée est absente.
    if (scheme == "intent") {
        try {
            val intent = Intent.parseUri(urlStr, Intent.URI_INTENT_SCHEME)
            try {
                ctx.startActivity(intent)
            } catch (e: Exception) {
                val secours = intent.getStringExtra("browser_fallback_url")
                // CORRECTIF TIKCOIN : si le lien de secours pointe lui aussi vers un store et
                // que la redirection n'est pas autorisée, on ne l'ouvre pas non plus.
                if (!secours.isNullOrBlank() && !(estLienVersStore(secours) && !redirectionStoreAutorisee)) {
                    try { ctx.startActivity(Intent(Intent.ACTION_VIEW, Uri.parse(secours))) } catch (e2: Exception) {}
                }
            }
        } catch (e: Exception) { /* URI intent malformée : on l'ignore silencieusement */ }
        return true
    }

    // 4) Tout autre schéma non-Web (whatsapp://, tg://, tel:, mailto:, sms:...) :
    // c'est toujours un lien destiné à une autre application, jamais une page à afficher ici.
    if (scheme.isNotEmpty() && scheme != "http" && scheme != "https") {
        try { ctx.startActivity(Intent(Intent.ACTION_VIEW, uri)) } catch (e: Exception) {}
        return true
    }

    // 5) Liens http(s) vers une plateforme native connue (Play Store, YouTube, WhatsApp,
    // Telegram, réseaux sociaux...) ou vers un fichier téléchargeable : Android l'ouvre
    // directement dans l'application installée plutôt que dans le navigateur intégré. Les
    // liens vers un store déjà bloqués au point 2 (redirection non autorisée) ne parviennent
    // jamais jusqu'ici — seuls les clics explicites et légitimes de l'utilisateur y arrivent.
    if (urlStr.endsWith(".apk") || urlStr.endsWith(".pdf") || urlStr.endsWith(".zip") || com.gombobusiness.app.core.estLienApplicationExterne(urlStr)) {
        return try { ctx.startActivity(Intent(Intent.ACTION_VIEW, uri)); true } catch (e: Exception) { false }
    }

    return false
}

private fun jsEscape(valeur: String): String =
    valeur.replace("\\", "\\\\").replace("\"", "\\\"").replace("\n", " ").replace("'", "\\'")

/**
 * Point 4-D : auto-remplissage des champs de formulaire les plus courants (détection par type/nom/autocomplete).
 * V1.3.4 corrigée : certains sites refusaient de "prendre" les valeurs injectées. Deux causes
 * distinctes ont été traitées ici :
 *  1) Les frameworks JS modernes (React/Vue/Angular...) gardent leur propre état interne du
 *     champ et ignorent une simple assignation de "value" si l'évènement envoyé ne ressemble
 *     pas à une saisie réelle : on envoie désormais un InputEvent plus complet (avec inputType)
 *     et on ajoute un évènement "blur", en plus de "input"/"change" déjà présents.
 *  2) Beaucoup de ces mêmes sites construisent leur formulaire après coup (SPA, étapes en
 *     plusieurs temps, connexion en Web Components/Shadow DOM) : le remplissage n'avait donc
 *     aucune chance de trouver les champs lors du seul passage déclenché à la fin du chargement
 *     de la page. On recherche désormais aussi dans les Shadow DOM, et on observe le DOM pendant
 *     les secondes qui suivent pour retenter automatiquement dès qu'un nouveau champ apparaît.
 */
private const val JS_AUTOFILL = """
(function() {
  var DONNEES = {
    password: "__PASSWORD__", username: "__USERNAME__", email: "__EMAIL__", tel: "__TEL__",
    indicatif: "__INDICATIF__", nomComplet: "__NOMCOMPLET__", prenom: "__PRENOM__",
    nom: "__NOM__", adresse: "__ADRESSE__", dateNaissance: "__DATENAISSANCE__",
    // V1.3.6 : champs complémentaires (ville, code postal, pays, genre).
    ville: "__VILLE__", codePostal: "__CODEPOSTAL__", pays: "__PAYS__", sexe: "__SEXE__"
  };

  // V1.3.6 : table de correspondance indicatif téléphonique -> noms de pays (FR/EN), utilisée
  // pour retrouver la bonne option dans les listes déroulantes "indicatif" des formulaires qui
  // en proposent une (au lieu d'un simple champ texte). Volontairement centrée sur l'Afrique
  // francophone et les pays les plus courants, avec repli sur une recherche par chiffres bruts
  // pour les autres cas.
  var INDICATIFS_PAYS = {
    '1': ['etats-unis', 'united states', 'usa', 'canada'],
    '33': ['france'],
    '32': ['belgique', 'belgium'],
    '41': ['suisse', 'switzerland'],
    '44': ['royaume-uni', 'united kingdom'],
    '49': ['allemagne', 'germany'],
    '212': ['maroc', 'morocco'],
    '213': ['algerie', 'algérie', 'algeria'],
    '216': ['tunisie', 'tunisia'],
    '221': ['senegal', 'sénégal'],
    '223': ['mali'],
    '224': ['guinee', 'guinée', 'guinea'],
    '225': ['ivoire', "côte d'ivoire", 'ivory coast'],
    '226': ['burkina'],
    '227': ['niger'],
    '228': ['togo'],
    '229': ['benin', 'bénin'],
    '233': ['ghana'],
    '234': ['nigeria'],
    '237': ['cameroun', 'cameroon'],
    '241': ['gabon'],
    '242': ['congo-brazzaville'],
    '243': ['congo', 'rdc'],
    '261': ['madagascar']
  };

  function setVal(el, value) {
    if (!el || !value || el.value || el.disabled || el.readOnly) return;
    try {
      var proto = window.HTMLInputElement.prototype;
      var setter = Object.getOwnPropertyDescriptor(proto, 'value').set;
      setter.call(el, value);
    } catch (e) { try { el.value = value; } catch (e2) { return; } }
    // Évènement "input" le plus proche possible d'une vraie saisie utilisateur, pour que
    // les frameworks qui suivent leur propre état (React/Vue/Angular) acceptent la valeur.
    try {
      el.dispatchEvent(new InputEvent('input', { bubbles: true, cancelable: true, inputType: 'insertText', data: value }));
    } catch (e) {
      el.dispatchEvent(new Event('input', { bubbles: true }));
    }
    el.dispatchEvent(new Event('change', { bubbles: true }));
    el.dispatchEvent(new Event('blur', { bubbles: true }));
  }

  function matches(el, needles) {
    var hay = ((el.name || '') + ' ' + (el.id || '') + ' ' + (el.autocomplete || '') + ' ' + (el.placeholder || '')).toLowerCase();
    for (var i = 0; i < needles.length; i++) { if (hay.indexOf(needles[i]) !== -1) return true; }
    return false;
  }

  // Recherche récursive de tous les <input> ET <select>, y compris à l'intérieur des Shadow
  // DOM (Web Components), invisibles à un simple document.querySelectorAll classique.
  // V1.3.6 : les <select> sont désormais inclus (auparavant seuls les <input> l'étaient), pour
  // gérer les listes déroulantes d'indicatif téléphonique — voir selectionnerIndicatif ci-dessous.
  function tousLesChamps(racine, resultat) {
    resultat = resultat || [];
    var champs = racine.querySelectorAll('input, select');
    for (var i = 0; i < champs.length; i++) resultat.push(champs[i]);
    var tous = racine.querySelectorAll('*');
    for (var j = 0; j < tous.length; j++) {
      if (tous[j].shadowRoot) tousLesChamps(tous[j].shadowRoot, resultat);
    }
    return resultat;
  }

  function chiffresSeulement(valeur) { return (valeur || '').replace(/[^0-9]/g, ''); }

  // V1.3.6 : contrairement à un champ texte, un <select> ne peut pas recevoir n'importe quelle
  // valeur — il faut choisir, parmi les options déjà proposées par le site, celle qui correspond
  // à l'indicatif enregistré. On essaie d'abord une correspondance exacte sur les chiffres (ex :
  // option value="+228" ou texte "Togo (+228)"), puis par nom de pays connu, puis en dernier
  // recours une simple recherche des chiffres n'importe où dans l'option.
  function selectionnerIndicatif(select, indicatifBrut) {
    if (!select || select.disabled || select.value) return;
    var codePur = chiffresSeulement(indicatifBrut);
    if (!codePur) return;
    var noms = INDICATIFS_PAYS[codePur] || [];
    var options = select.options;
    if (!options || !options.length) return;
    var meilleur = -1;
    for (var i = 0; i < options.length; i++) {
      var opt = options[i];
      var texte = (opt.text || '').toLowerCase();
      var val = (opt.value || '').toLowerCase();
      var chiffresOpt = chiffresSeulement(opt.value) || chiffresSeulement(opt.text);
      var ressembleAUnCode = texte.indexOf('+') !== -1 || val.indexOf('+') !== -1 || /^[0-9]+$/.test(opt.value || '');
      if (chiffresOpt && chiffresOpt === codePur && ressembleAUnCode) { meilleur = i; break; }
    }
    if (meilleur === -1) {
      for (var n = 0; n < noms.length && meilleur === -1; n++) {
        for (var i2 = 0; i2 < options.length; i2++) {
          if ((options[i2].text || '').toLowerCase().indexOf(noms[n]) !== -1) { meilleur = i2; break; }
        }
      }
    }
    if (meilleur === -1) {
      for (var k = 0; k < options.length; k++) {
        var repere = (options[k].text || '') + ' ' + (options[k].value || '');
        if (repere.indexOf(codePur) !== -1) { meilleur = k; break; }
      }
    }
    if (meilleur === -1 || select.selectedIndex === meilleur) return;
    select.selectedIndex = meilleur;
    try { select.dispatchEvent(new Event('input', { bubbles: true })); } catch (e) {}
    select.dispatchEvent(new Event('change', { bubbles: true }));
  }

  function remplirTout() {
    var inputs = tousLesChamps(document);
    for (var i = 0; i < inputs.length; i++) {
      var el = inputs[i];
      // V1.3.6 : une liste déroulante (<select>) ne se remplit pas comme un champ texte — on
      // essaie de lui faire sélectionner la bonne option d'indicatif si elle en propose une ;
      // les autres <select> du formulaire (pays, genre...) ne sont volontairement pas touchés.
      if (el.tagName === 'SELECT') {
        if (matches(el, ['indicatif', 'dial-code', 'dial_code', 'dialcode', 'country-code', 'country_code', 'countrycode', 'phone-code', 'phone_code', 'phonecode'])) {
          selectionnerIndicatif(el, DONNEES.indicatif);
        }
        continue;
      }
      if (el.value) continue;
      var type = (el.type || '').toLowerCase();
      // V1.3 corrigée : le champ "nom d'utilisateur" (username/login/pseudo) DOIT être
      // testé avant les motifs génériques de nom complet/prénom/nom de famille. Auparavant,
      // un champ "username" tombait par erreur dans le motif "name" (puisque "username"
      // contient bien la sous-chaîne "name"), et se retrouvait rempli avec le nom complet
      // de l'utilisateur au lieu de son pseudo/identifiant. L'ordre ci-dessous, plus le
      // recours à autocomplete="username" en priorité, corrige définitivement ce problème :
      // les cases "username" des sites sont désormais remplies avec le nom d'utilisateur
      // enregistré dans l'application (ou l'identifiant déjà sauvegardé pour ce site).
      if (type === 'password') { setVal(el, DONNEES.password); }
      else if ((el.autocomplete || '').toLowerCase() === 'username') { setVal(el, DONNEES.username); }
      // V1.3.2 : le champ "indicatif téléphonique" (dial code/country code) DOIT être testé
      // avant le motif générique "tel/phone", sinon un champ comme "phone_code" tombait par
      // erreur dans le motif téléphone et recevait le numéro complet au lieu de l'indicatif.
      else if (matches(el, ['indicatif', 'dial-code', 'dial_code', 'dialcode', 'country-code', 'country_code', 'countrycode', 'phone-code', 'phone_code', 'phonecode'])) { setVal(el, DONNEES.indicatif); }
      else if (type === 'email' || matches(el, ['email', 'mail'])) { setVal(el, DONNEES.email); }
      else if (type === 'tel' || matches(el, ['tel', 'phone', 'telephone'])) { setVal(el, DONNEES.tel); }
      else if (matches(el, ['username', 'user-name', 'user_name', 'login', 'pseudo', 'identifiant'])) { setVal(el, DONNEES.username); }
      else if (matches(el, ['fullname', 'full-name', 'nom-complet', 'nomcomplet'])) { setVal(el, DONNEES.nomComplet); }
      else if (matches(el, ['firstname', 'first-name', 'prenom', 'given-name'])) { setVal(el, DONNEES.prenom); }
      else if (matches(el, ['lastname', 'last-name', 'family-name', 'surname'])) { setVal(el, DONNEES.nom); }
      else if (matches(el, ['address', 'adresse'])) { setVal(el, DONNEES.adresse); }
      // V1.3.6 : champs complémentaires (ville, code postal, pays, genre), courants sur les
      // formulaires d'inscription des sites de crypto et de paris sportifs.
      else if (matches(el, ['ville', 'city', 'town'])) { setVal(el, DONNEES.ville); }
      else if (matches(el, ['codepostal', 'code-postal', 'code_postal', 'postal', 'zipcode', 'zip-code', 'zip_code', 'postcode'])) { setVal(el, DONNEES.codePostal); }
      else if (matches(el, ['pays', 'country', 'nation'])) { setVal(el, DONNEES.pays); }
      else if (matches(el, ['genre', 'gender', 'sexe', 'sex'])) { setVal(el, DONNEES.sexe); }
      // V1.3.4.1 : champ "date de naissance" — testé avant le motif générique "name" (sinon
      // "birthname"/"date_naissance" pourrait être happé par erreur par ce dernier).
      else if (type === 'date' || matches(el, ['birthday', 'birthdate', 'date-of-birth', 'dateofbirth', 'dob', 'date-naissance', 'date_naissance', 'datenaissance', 'naissance', 'birth'])) { setVal(el, DONNEES.dateNaissance); }
      else if (/(^|[^a-z])name([^a-z]|$)/.test(((el.name || '') + ' ' + (el.id || '') + ' ' + (el.placeholder || '')).toLowerCase())) { setVal(el, DONNEES.nomComplet); }
    }
  }

  remplirTout();

  // V1.3.4 : certains sites (SPA en React/Vue/Angular, formulaires affichés après une
  // étape intermédiaire, champs ajoutés dynamiquement...) ne possèdent pas encore leurs
  // champs au moment de ce premier passage. On observe donc le DOM pendant les 8 secondes
  // qui suivent le chargement de la page et on retente automatiquement à chaque changement,
  // sans jamais écraser une valeur déjà saisie manuellement par l'utilisateur (voir le test
  // "if (el.value) continue" ci-dessus, qui protège toujours la saisie de l'utilisateur).
  if (!window.__gomboAutofillObserverActif) {
    window.__gomboAutofillObserverActif = true;
    var observeur = new MutationObserver(function() { remplirTout(); });
    observeur.observe(document.documentElement, { childList: true, subtree: true });
    setTimeout(function() {
      observeur.disconnect();
      window.__gomboAutofillObserverActif = false;
    }, 8000);
  }
})();
"""

/**
 * Point 4-E : écoute la soumission des mots de passe pour proposer leur enregistrement.
 * V1.4 corrigée : en plus de l'événement 'submit' natif (qui ne se déclenche jamais sur les
 * sites qui gèrent la connexion en JavaScript pur, sans balise <form>), on capture désormais
 * aussi : le clic sur un bouton de connexion/soumission (avant que la page ne change), et le
 * moment où la page se ferme ou se recharge (beforeunload/pagehide) — dernier instant où un
 * mot de passe saisi manuellement est encore présent dans le DOM juste avant une redirection
 * de connexion réussie. C'est cette absence de filet de sécurité qui empêchait l'enregistrement
 * des mots de passe sur de nombreux sites modernes.
 */
private const val JS_CAPTURE_SUBMIT = """
(function() {
  if (window.__gomboCaptureInstalled) return;
  window.__gomboCaptureInstalled = true;

  function champsIdentifiants() {
    var user = '';
    var pass = '';
    var inputs = document.querySelectorAll('input');
    for (var i = 0; i < inputs.length; i++) {
      var el = inputs[i];
      var type = (el.type || '').toLowerCase();
      if (type === 'password' && el.value) { pass = el.value; }
      else if ((type === 'email' || type === 'text' || type === 'tel' || type === '') && el.value && !user) { user = el.value; }
    }
    return { user: user, pass: pass };
  }

  function envoyer(pass, user) {
    if (!pass) return;
    try {
      AndroidAutofillBridge.onFormSubmit(JSON.stringify({ site: window.location.hostname, user: user, pass: pass }));
    } catch (e) {}
  }

  function collecter(form) {
    var user = '';
    var pass = '';
    var inputs = form.querySelectorAll('input');
    for (var i = 0; i < inputs.length; i++) {
      var el = inputs[i];
      var type = (el.type || '').toLowerCase();
      if (type === 'password' && el.value) { pass = el.value; }
      else if ((type === 'email' || type === 'text') && el.value && !user) { user = el.value; }
    }
    envoyer(pass, user);
  }

  // 1) Soumission native d'un <form> (fonctionne même si le site appelle preventDefault()).
  document.addEventListener('submit', function(ev) {
    if (ev.target && ev.target.tagName === 'FORM') collecter(ev.target);
  }, true);

  // 2) Clic sur un bouton de connexion/soumission, pour les sites 100% JavaScript sans <form>.
  document.addEventListener('click', function(ev) {
    var cible = ev.target;
    var bouton = cible && cible.closest ? cible.closest('button, input[type="submit"], [role="button"]') : null;
    if (!bouton) return;
    var texte = ((bouton.innerText || bouton.value || '') + '').toLowerCase();
    var type = (bouton.type || '').toLowerCase();
    if (type === 'submit' || texte.indexOf('connex') !== -1 || texte.indexOf('login') !== -1 ||
        texte.indexOf('sign in') !== -1 || texte.indexOf('se connecter') !== -1 || texte.indexOf('valider') !== -1) {
      var champs = champsIdentifiants();
      if (champs.pass) envoyer(champs.pass, champs.user);
    }
  }, true);

  // 3) Dernier filet : juste avant de quitter la page (redirection de connexion réussie),
  // si un mot de passe est toujours présent dans le DOM, on le capture.
  function surSortie() {
    var champs = champsIdentifiants();
    if (champs.pass) envoyer(champs.pass, champs.user);
  }
  window.addEventListener('pagehide', surSortie, true);
  window.addEventListener('beforeunload', surSortie, true);
})();
"""

/** Pont JavaScript <-> Kotlin : reçoit les identifiants détectés lors d'une soumission de formulaire. */
class CaptureIdentifiantsBridge(private val onCapture: (site: String, user: String, pass: String) -> Unit) {
    private val handler = android.os.Handler(android.os.Looper.getMainLooper())

    @JavascriptInterface
    fun onFormSubmit(json: String) {
        try {
            val obj = org.json.JSONObject(json)
            val site = obj.optString("site")
            val user = obj.optString("user")
            val pass = obj.optString("pass")
            if (pass.isNotBlank() && site.isNotBlank()) {
                handler.post { onCapture(site, user, pass) }
            }
        } catch (e: Exception) { /* payload invalide, on ignore silencieusement */ }
    }
}
EOF

echo "⚙️  Étape 9 : Point d'entrée MainActivity..."

cat << 'EOF' > "$PROJECT_NAME/app/src/main/java/$PACKAGE_PATH/MainActivity.kt"
package com.gombobusiness.app

import android.os.Build
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.mutableFloatStateOf
import androidx.compose.runtime.remember
import androidx.compose.animation.core.rememberInfiniteTransition
import androidx.compose.animation.core.animateFloat
import androidx.compose.animation.core.infiniteRepeatable
import androidx.compose.animation.core.tween
import androidx.compose.animation.core.LinearEasing
import androidx.compose.animation.core.RepeatMode
import coil.Coil
import coil.ImageLoader
import coil.decode.GifDecoder
import coil.decode.ImageDecoderDecoder
import coil.decode.SvgDecoder
import com.gombobusiness.app.core.*
import com.gombobusiness.app.data.local.PreferencesManager
import com.gombobusiness.app.data.local.SecureAutofillStore
import com.gombobusiness.app.data.local.HistoriqueNavigationStore
import com.gombobusiness.app.data.local.DonneesCacheStore
// V1.3.4.2 : favoris / cartes terminées / badge "nouveau".
import com.gombobusiness.app.data.local.InteractionsStore
import com.gombobusiness.app.data.remote.GitHubConfigApi
import com.gombobusiness.app.data.repository.AppRepositoryImpl
import com.gombobusiness.app.presentation.navigation.ConteneurNavigationPrincipal
import com.gombobusiness.app.presentation.theme.GomboBusinessTheme
import com.gombobusiness.app.presentation.viewmodel.MainViewModel
import com.jakewharton.retrofit2.converter.kotlinx.serialization.asConverterFactory
import kotlinx.serialization.json.Json
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.OkHttpClient
import retrofit2.Retrofit
import java.util.concurrent.TimeUnit

class MainActivity : ComponentActivity() {
override fun onCreate(savedInstanceState: Bundle?) {
super.onCreate(savedInstanceState)

    val imageLoader = ImageLoader.Builder(this)
        .components {
            if (Build.VERSION.SDK_INT >= 28) add(ImageDecoderDecoder.Factory())
            else add(GifDecoder.Factory())
            // V1.3 : nécessaire pour afficher les icônes de contact (Email/WhatsApp/LinkedIn/
            // GitHub) chargées depuis internet au format vectoriel (SVG).
            add(SvgDecoder.Factory())
        }
        // V1.3.2 : toutes les icônes/logos chargés depuis internet (réseaux sociaux, contact,
        // photo de profil...) sont désormais téléchargés puis conservés en cache disque de
        // façon permanente dès leur premier affichage, afin de continuer à s'afficher
        // normalement même sans connexion par la suite. "respectCacheHeaders(false)" force
        // la mise en cache même pour les hébergeurs (CDN d'icônes...) qui ne renvoient pas
        // d'en-têtes de cache HTTP explicites.
        .respectCacheHeaders(false)
        .diskCachePolicy(coil.request.CachePolicy.ENABLED)
        .memoryCachePolicy(coil.request.CachePolicy.ENABLED)
        .networkCachePolicy(coil.request.CachePolicy.ENABLED)
        .diskCache {
            coil.disk.DiskCache.Builder()
                .directory(cacheDir.resolve("gombo_icones_cache"))
                .maxSizeBytes(100L * 1024 * 1024)
                .build()
        }
        .build()
    Coil.setImageLoader(imageLoader)

    val jsonConfig = Json { ignoreUnknownKeys = true; isLenient = true; coerceInputValues = true }
    // V1.3.5 CORRIGÉ : l'application ne devait recharger les fichiers JSON (airdrops, wallet,
    // pronostics, inscriptions, infos) que lorsqu'ils ont réellement changé côté GitHub, et
    // rester rapide/fluide sinon. Un cache HTTP est ajouté au client réseau : GitHub renvoie un
    // ETag pour chaque fichier, qu'OkHttp compare automatiquement à chaque vérification —
    // si rien n'a changé, la réponse (très légère) confirme l'absence de changement et le
    // contenu déjà en cache est réutilisé tel quel (aucun retéléchargement) ; si le fichier a
    // changé, le nouveau contenu est téléchargé et remplace l'ancien. Ce mécanisme est géré
    // nativement par OkHttp, de façon transparente, sans code supplémentaire à écrire ni à
    // maintenir. En l'absence totale de réseau, c'est le cache local de secours de l'application
    // (DonneesCacheStore, déjà en place) qui prend le relais pour un fonctionnement hors-ligne.
    val cacheReseauJson = okhttp3.Cache(directory = java.io.File(cacheDir, "gombo_json_http_cache"), maxSize = 5L * 1024 * 1024)
    // V1.3.3 : délais volontairement courts (au lieu des 10 s par défaut d'OkHttp) — le but
    // est de détecter au plus vite une absence de connexion pour basculer sur le cache local
    // plutôt que de faire attendre l'utilisateur ; sur une connexion correcte, ces délais
    // sont largement suffisants pour charger de petits fichiers JSON.
    val clientRapide = OkHttpClient.Builder()
        .connectTimeout(6, TimeUnit.SECONDS)
        .readTimeout(8, TimeUnit.SECONDS)
        .writeTimeout(8, TimeUnit.SECONDS)
        .cache(cacheReseauJson)
        .build()
    val retrofitEmpty = Retrofit.Builder().baseUrl("https://placeholder.com/").client(clientRapide).addConverterFactory(jsonConfig.asConverterFactory("application/json".toMediaType())).build()

    val donneesCacheStore = DonneesCacheStore(this)
    val repository = AppRepositoryImpl(retrofitEmpty.create(GitHubConfigApi::class.java), donneesCacheStore)
    val mainViewModel = MainViewModel(repository)
    val prefs = PreferencesManager(this)
    val autofillStore = SecureAutofillStore(this)
    val historiqueNavStore = HistoriqueNavigationStore(this)
    val gestionnaireMiseAJour = GestionnaireMiseAJour(this)
    val networkObserver = NetworkConnectivityObserver(this)
    // V1.3.4.2 : favoris / cartes terminées / badge "nouveau".
    val interactionsStore = InteractionsStore(this)

    setContent {
        val etatTheme = remember { mutableStateOf(prefs.getTheme()) }
        val etatLangue = remember { mutableStateOf(prefs.getLangue()) }
        val etatSize = remember { mutableFloatStateOf(prefs.getFontSize()) }
        val etatLayout = remember { mutableStateOf(prefs.getLayoutMode()) }
        val etatCardShape = remember { mutableStateOf(prefs.getCardShape()) }
        val etatBtnShape = remember { mutableStateOf(prefs.getButtonShape()) }
        // V1.3.3 : animation de FOND, persistée puis appliquée globalement (voir
        // LocalBackgroundAnimation fourni ci-dessous et FondAnimeSelectionne). Remplace
        // l'ancienne animation de transition entre écrans (désormais supprimée).
        val etatAnimationFond = remember { mutableStateOf(prefs.getBackgroundAnimation()) }
        // V1.3.2 : "initial = false" (et non plus "true"). Avant cette correction, l'app
        // supposait être en ligne dès le premier instant du démarrage, le temps que l'état
        // réseau réel soit déterminé par NetworkConnectivityObserver. Résultat : sans
        // connexion Internet, la vérification automatique de mise à jour se déclenchait
        // quand même une fraction de seconde après le lancement (avec son Toast), échouait
        // silencieusement, puis affichait à tort "L'application est à jour ✓" — un message
        // trompeur puisqu'aucune vérification réelle n'avait eu lieu. En partant de "false",
        // aucune vérification (ni aucun autre appel réseau automatique) ne démarre tant que
        // la connectivité réelle n'a pas été confirmée ; dès qu'une connexion est réellement
        // détectée (immédiatement si déjà présente, ou plus tard si le Wi-Fi/la donnée
        // mobile est activé(e) après coup), la vérification démarre normalement.
        val isOnline by networkObserver.isOnline.collectAsState(initial = false)
        
        val browserUrl = remember { mutableStateOf("") }
        val browserVisible = remember { mutableStateOf(false) }
        val browserController = remember { BrowserController(browserUrl, browserVisible) }

        // V1.3.5 CORRIGÉ : une seule animation de "respiration" 3D pour TOUTES les cartes de
        // l'app (au lieu d'une par carte, voir LocalBasculeIdleCarte) — corrige un vrai
        // ralentissement perçu par l'utilisateur.
        val respirationCartePartagee = rememberInfiniteTransition(label = "carte_respiration_3d_globale")
        val basculeIdleYPartagee by respirationCartePartagee.animateFloat(
            initialValue = -1.2f, targetValue = 1.2f,
            animationSpec = infiniteRepeatable(tween(4200, easing = LinearEasing), RepeatMode.Reverse),
            label = "carte_bascule_idle_globale"
        )
        val respirationBadgePartagee by respirationCartePartagee.animateFloat(
            initialValue = 0.97f, targetValue = 1.05f,
            animationSpec = infiniteRepeatable(tween(2600, easing = LinearEasing), RepeatMode.Reverse),
            label = "badge_scale_globale"
        )

        CompositionLocalProvider(
            LocalAppTheme provides etatTheme,
            LocalLangue provides etatLangue,
            LocalFontSize provides etatSize,
            LocalLayoutMode provides etatLayout,
            LocalCardShape provides etatCardShape,
            LocalButtonShape provides etatBtnShape,
            LocalBackgroundAnimation provides etatAnimationFond,
            LocalIsOnline provides isOnline,
            LocalBrowserController provides browserController,
            LocalAutofillStore provides autofillStore,
            LocalHistoriqueNavStore provides historiqueNavStore,
            LocalGestionnaireMiseAJour provides gestionnaireMiseAJour,
            LocalInteractionsStore provides interactionsStore,
            LocalBasculeIdleCarte provides basculeIdleYPartagee,
            LocalRespirationBadge provides respirationBadgePartagee
        ) {
            GomboBusinessTheme {
                ConteneurNavigationPrincipal(mainViewModel, prefs)
            }
        }
    }
}
}
EOF

echo "🧩 Étape 10 : Détection du SDK Android (local.properties)..."

# V1.4 corrigée : on restaure d'abord un éventuel local.properties sauvegardé au tout début
# du script (Étape 1), avant même de tenter une nouvelle détection automatique. Sans cette
# étape, le fichier de configuration propre à la machine de l'utilisateur était sauvegardé
# puis... jamais réinjecté, et donc perdu à chaque régénération du projet.
if [ -f "$LOCAL_PROPERTIES_BACKUP" ] && [ ! -f "$PROJECT_NAME/local.properties" ]; then
    cp "$LOCAL_PROPERTIES_BACKUP" "$PROJECT_NAME/local.properties" 2>/dev/null
fi
rm -f "$LOCAL_PROPERTIES_BACKUP" 2>/dev/null

# Gradle a besoin de connaître l'emplacement du SDK Android via
# local.properties (ou la variable d'environnement ANDROID_HOME), sinon la compilation
# échoue avec "SDK location not found" dès la première commande gradlew. On tente ici de
# détecter automatiquement ce chemin puis on l'écrit avec des slashs normaux ("/"), un
# format accepté aussi bien par Gradle sous Windows que sous macOS/Linux et qui évite tout
# problème d'échappement des antislashs dans le fichier .properties (bug corrigé en V1.4 :
# l'ancienne version pouvait produire un chemin corrompu quand le SDK était déjà détecté
# avec des antislashs Windows). On ne touche jamais à un local.properties déjà présent.
normaliser_chemin_sdk() {
    local chemin="$1"
    # Antislash Windows -> slash normal (ex: C:\Users\Huss\...  ->  C:/Users/Huss/...)
    chemin="${chemin//\\//}"
    # Chemin POSIX de type Git Bash (/c/Users/Huss/...) -> format Windows (C:/Users/Huss/...)
    if [[ "$chemin" =~ ^/([a-zA-Z])/(.*)$ ]]; then
        chemin="${BASH_REMATCH[1]}:/${BASH_REMATCH[2]}"
    fi
    echo "$chemin"
}

if [ ! -f "$PROJECT_NAME/local.properties" ]; then
    SDK_PATH=""
    if [ -n "$ANDROID_HOME" ] && [ -d "$ANDROID_HOME" ]; then
        SDK_PATH="$ANDROID_HOME"
    elif [ -n "$ANDROID_SDK_ROOT" ] && [ -d "$ANDROID_SDK_ROOT" ]; then
        SDK_PATH="$ANDROID_SDK_ROOT"
    else
        CANDIDATS=(
            "$HOME/Library/Android/sdk"
            "$HOME/Android/Sdk"
            "$LOCALAPPDATA/Android/Sdk"
            "$USERPROFILE/AppData/Local/Android/Sdk"
            "$HOME/AppData/Local/Android/Sdk"
        )
        # Cas WSL : l'utilisateur travaille sous Windows mais exécute ce script dans WSL,
        # où $USERPROFILE/$LOCALAPPDATA ne sont généralement pas exportés. On sonde alors
        # directement les profils Windows montés sous /mnt/c/Users/*.
        if [ -d "/mnt/c/Users" ]; then
            for profil in /mnt/c/Users/*/AppData/Local/Android/Sdk; do
                [ -d "$profil" ] && CANDIDATS+=("$profil")
            done
        fi
        for c in "${CANDIDATS[@]}"; do
            if [ -n "$c" ] && [ -d "$c" ]; then
                SDK_PATH="$c"
                break
            fi
        done
    fi

    if [ -n "$SDK_PATH" ]; then
        SDK_PATH_NORMALISE="$(normaliser_chemin_sdk "$SDK_PATH")"
        echo "sdk.dir=$SDK_PATH_NORMALISE" > "$PROJECT_NAME/local.properties"
        echo "✅ SDK détecté automatiquement : $SDK_PATH_NORMALISE"
    else
        echo "⚠️  SDK Android introuvable automatiquement sur cette machine."
        echo "   → Le plus simple : ouvre le dossier $PROJECT_NAME dans Android Studio,"
        echo "     il détectera/installera le SDK et créera local.properties tout seul."
        echo "   → Sinon, crée toi-même le fichier $PROJECT_NAME/local.properties avec :"
        echo "     sdk.dir=C:/Users/TonNomUtilisateur/AppData/Local/Android/Sdk"
        echo "     (remplace le chemin par celui affiché dans Android Studio > Settings >"
        echo "     Languages & Frameworks > Android SDK > 'Android SDK Location')."
    fi
else
    echo "ℹ️  local.properties déjà présent, conservé tel quel."
fi

echo ""
echo "🎯 VERSION 1.3.3 FINALE GÉNÉRÉE AVEC SUCCÈS"
echo ""