package com.helptrickbd.myapplicationsomithierp

import android.os.Bundle
import androidx.activity.enableEdgeToEdge
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.Surface
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.tooling.preview.Preview
import androidx.fragment.app.FragmentActivity
import androidx.activity.compose.setContent
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.platform.LocalConfiguration
import androidx.compose.ui.platform.LocalContext
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.helptrickbd.myapplicationsomithierp.core.datastore.UserPreferencesRepository
import com.helptrickbd.myapplicationsomithierp.core.security.BiometricAuthManager
import com.helptrickbd.myapplicationsomithierp.core.util.LocaleHelper
import com.helptrickbd.myapplicationsomithierp.presentation.navigation.AppNavigation
import com.helptrickbd.myapplicationsomithierp.ui.theme.ShomitiERPTheme

class MainActivity : FragmentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()

        // Initialize notification channels
        com.helptrickbd.myapplicationsomithierp.core.notification.NotificationHelper.createNotificationChannels(this)

        // Check and prompt biometric lock if available
        if (BiometricAuthManager.isBiometricAvailable(this)) {
            BiometricAuthManager.promptBiometricAuth(
                activity = this,
                title = getString(R.string.biometric_prompt_title),
                subtitle = getString(R.string.biometric_prompt_subtitle),
                onSuccess = { /* Unlocked successfully */ },
                onError = { _, _ -> /* Fallback to standard flow */ },
                onFailed = { /* Failed attempt */ }
            )
        }

        val initialRoute = intent.getStringExtra("EXTRA_NAV_ROUTE")

        setContent {
            val userPrefsRepo = remember { UserPreferencesRepository(this) }
            val preferences by userPrefsRepo.userPreferencesFlow.collectAsStateWithLifecycle(initialValue = null)
            val langCode = preferences?.language?.code ?: "bn"
            val localizedContext = remember(langCode) { LocaleHelper.setLocale(this, langCode) }
            val localizedConfig = remember(langCode) { LocaleHelper.getLocalizedConfiguration(this, langCode) }

            val themeMode = preferences?.themeMode ?: com.helptrickbd.myapplicationsomithierp.core.datastore.AppThemeMode.SYSTEM

            CompositionLocalProvider(
                LocalContext provides localizedContext,
                LocalConfiguration provides localizedConfig,
                androidx.activity.compose.LocalActivityResultRegistryOwner provides this
            ) {
                ShomitiERPTheme(themeMode = themeMode) {
                    Surface(modifier = Modifier.fillMaxSize()) {
                        AppNavigation(startDestination = initialRoute)
                    }
                }
            }
        }
    }
}

@Preview(showBackground = true)
@Composable
fun AppPreview() {
    ShomitiERPTheme {
        AppNavigation()
    }
}