package com.helptrickbd.myapplicationsomithierp.ui.theme

import android.app.Activity
import android.os.Build
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.dynamicDarkColorScheme
import androidx.compose.material3.dynamicLightColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.ReadOnlyComposable
import androidx.compose.runtime.SideEffect
import androidx.compose.runtime.staticCompositionLocalOf
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalView
import androidx.core.view.WindowCompat
import com.helptrickbd.myapplicationsomithierp.core.datastore.AppThemeMode

private val ShomitiLightColorScheme = lightColorScheme(
    primary = EmeraldPrimaryLight,
    onPrimary = OnEmeraldPrimaryLight,
    primaryContainer = EmeraldContainerLight,
    onPrimaryContainer = OnEmeraldContainerLight,
    secondary = SlateSecondaryLight,
    onSecondary = OnSlateSecondaryLight,
    secondaryContainer = SlateContainerLight,
    onSecondaryContainer = OnSlateContainerLight,
    background = BackgroundLight,
    surface = SurfaceLight,
    onSurface = Color(0xFF0F172A),
    surfaceVariant = SurfaceVariantLight,
    onSurfaceVariant = Color(0xFF475569),
    outline = OutlineLight,
    outlineVariant = Color(0xFFE2E8F0)
)

private val ShomitiDarkColorScheme = darkColorScheme(
    primary = EmeraldPrimaryDark,
    onPrimary = OnEmeraldPrimaryDark,
    primaryContainer = EmeraldContainerDark,
    onPrimaryContainer = OnEmeraldContainerDark,
    secondary = SlateSecondaryDark,
    onSecondary = OnSlateSecondaryDark,
    secondaryContainer = SlateContainerDark,
    onSecondaryContainer = OnSlateContainerDark,
    background = BackgroundDark,
    surface = SurfaceDark,
    onSurface = Color(0xFFF1F5F9),
    surfaceVariant = SurfaceVariantDark,
    onSurfaceVariant = Color(0xFF94A3B8),
    outline = OutlineDark,
    outlineVariant = Color(0xFF334155)
)

data class FinancialColors(
    val income: Color,
    val onIncome: Color,
    val expense: Color,
    val onExpense: Color,
    val due: Color,
    val onDue: Color
)

val LocalFinancialColors = staticCompositionLocalOf {
    FinancialColors(
        income = MoneyIncomeGreen,
        onIncome = Color.White,
        expense = MoneyExpenseRed,
        onExpense = Color.White,
        due = MoneyDueAmber,
        onDue = Color.White
    )
}

val MaterialTheme.financialColors: FinancialColors
    @Composable
    @ReadOnlyComposable
    get() = LocalFinancialColors.current

@Composable
fun ShomitiERPTheme(
    themeMode: AppThemeMode = AppThemeMode.SYSTEM,
    darkTheme: Boolean = when (themeMode) {
        AppThemeMode.SYSTEM -> isSystemInDarkTheme()
        AppThemeMode.LIGHT -> false
        AppThemeMode.DARK -> true
    },
    dynamicColor: Boolean = false,
    content: @Composable () -> Unit
) {
    val colorScheme = when {
        dynamicColor && Build.VERSION.SDK_INT >= Build.VERSION_CODES.S -> {
            val context = LocalContext.current
            if (darkTheme) dynamicDarkColorScheme(context) else dynamicLightColorScheme(context)
        }
        darkTheme -> ShomitiDarkColorScheme
        else -> ShomitiLightColorScheme
    }

    val financialColors = if (darkTheme) {
        FinancialColors(
            income = MoneyIncomeGreenDark,
            onIncome = Color(0xFF003915),
            expense = MoneyExpenseRedDark,
            onExpense = Color(0xFF410002),
            due = MoneyDueAmberDark,
            onDue = Color(0xFF452B00)
        )
    } else {
        FinancialColors(
            income = MoneyIncomeGreen,
            onIncome = Color.White,
            expense = MoneyExpenseRed,
            onExpense = Color.White,
            due = MoneyDueAmber,
            onDue = Color.White
        )
    }

    val view = LocalView.current
    if (!view.isInEditMode) {
        SideEffect {
            val window = (view.context as? Activity)?.window
            if (window != null) {
                val insetsController = WindowCompat.getInsetsController(window, view)
                insetsController.isAppearanceLightStatusBars = !darkTheme
                insetsController.isAppearanceLightNavigationBars = !darkTheme
            }
        }
    }

    CompositionLocalProvider(
        LocalFinancialColors provides financialColors
    ) {
        MaterialTheme(
            colorScheme = colorScheme,
            typography = Typography,
            content = content
        )
    }
}

// Backward compatibility alias for preview references
@Composable
fun MyApplicationSomithiERPTheme(
    themeMode: AppThemeMode = AppThemeMode.SYSTEM,
    dynamicColor: Boolean = false,
    content: @Composable () -> Unit
) {
    ShomitiERPTheme(themeMode = themeMode, dynamicColor = dynamicColor, content = content)
}