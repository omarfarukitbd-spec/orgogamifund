package com.helptrickbd.myapplicationsomithierp.core.ui

import androidx.compose.animation.core.FastOutSlowInEasing
import androidx.compose.animation.core.RepeatMode
import androidx.compose.animation.core.animateFloat
import androidx.compose.animation.core.infiniteRepeatable
import androidx.compose.animation.core.rememberInfiniteTransition
import androidx.compose.animation.core.tween
import androidx.compose.foundation.background
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.composed
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.layout.onGloballyPositioned
import androidx.compose.ui.unit.IntSize
import com.helptrickbd.myapplicationsomithierp.ui.theme.ShimmerBaseDark
import com.helptrickbd.myapplicationsomithierp.ui.theme.ShimmerBaseLight
import com.helptrickbd.myapplicationsomithierp.ui.theme.ShimmerHighlightDark
import com.helptrickbd.myapplicationsomithierp.ui.theme.ShimmerHighlightLight

/**
 * Reusable Shimmer effect modifier for skeleton loading states.
 * Guarantees a polished, premium UX without blank white loading screens.
 */
fun Modifier.shimmerEffect(): Modifier = composed {
    var size by remember { mutableStateOf(IntSize.Zero) }
    val transition = rememberInfiniteTransition(label = "shimmer_transition")
    val startOffsetX by transition.animateFloat(
        initialValue = -2 * size.width.toFloat(),
        targetValue = 2 * size.width.toFloat(),
        animationSpec = infiniteRepeatable(
            animation = tween(durationMillis = 1200, easing = FastOutSlowInEasing),
            repeatMode = RepeatMode.Restart
        ),
        label = "shimmer_offset"
    )

    val isDark = isSystemInDarkTheme()
    val baseColor = if (isDark) ShimmerBaseDark else ShimmerBaseLight
    val highlightColor = if (isDark) ShimmerHighlightDark else ShimmerHighlightLight

    background(
        brush = Brush.linearGradient(
            colors = listOf(baseColor, highlightColor, baseColor),
            start = Offset(startOffsetX, 0f),
            end = Offset(startOffsetX + size.width.toFloat(), size.height.toFloat())
        )
    ).onGloballyPositioned {
        size = it.size
    }
}
