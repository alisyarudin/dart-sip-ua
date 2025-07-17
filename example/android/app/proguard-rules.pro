# --- FIX for jackson databind (used by okhttp/retrofit etc) ---
-keepattributes *Annotation*
-keep class com.fasterxml.jackson.databind.** { *; }
-keep class com.fasterxml.jackson.core.** { *; }
-keep class com.fasterxml.jackson.annotation.** { *; }

# --- FIX for javax.annotation.Nullable used by okhttp ---
-dontwarn javax.annotation.Nullable
-keep class javax.annotation.Nullable

# --- FIX for java.beans.* used by Jackson Java7SupportImpl ---
-dontwarn java.beans.**
-keep class java.beans.** { *; }

# --- FIX for conscrypt provider (used in okhttp platform detection) ---
-dontwarn org.conscrypt.**
-keep class org.conscrypt.** { *; }

# --- FIX for DOMImplementationRegistry (used by jackson XML) ---
-dontwarn org.w3c.dom.bootstrap.**
-keep class org.w3c.dom.bootstrap.** { *; }

# --- OPTIONAL: keep kotlin reflection & annotations if needed ---
-keep class kotlin.Metadata { *; }
-dontwarn kotlin.**
