package com.helptrickbd.myapplicationsomithierp.presentation.screens.onboarding

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.core.animateDpAsState
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.pager.HorizontalPager
import androidx.compose.foundation.pager.rememberPagerState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowForward
import androidx.compose.material.icons.automirrored.filled.ReceiptLong
import androidx.compose.material.icons.automirrored.filled.TrendingUp
import androidx.compose.material.icons.filled.AccountBalance
import androidx.compose.material.icons.filled.Badge
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.CloudDone
import androidx.compose.material.icons.filled.Print
import androidx.compose.material.icons.filled.Security
import androidx.compose.material.icons.filled.Sync
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.helptrickbd.myapplicationsomithierp.R
import com.helptrickbd.myapplicationsomithierp.core.datastore.AppThemeMode
import com.helptrickbd.myapplicationsomithierp.presentation.screens.onboarding.components.OnboardingFeaturePageContent
import com.helptrickbd.myapplicationsomithierp.presentation.screens.onboarding.components.OnboardingPageData
import com.helptrickbd.myapplicationsomithierp.presentation.screens.onboarding.components.PreferencesSetupPage
import kotlinx.coroutines.launch

@Composable
fun OnboardingScreen(
    currentLanguage: String = "bn",
    currentThemeMode: AppThemeMode = AppThemeMode.SYSTEM,
    onLanguageChange: (String) -> Unit = {},
    onThemeModeChange: (AppThemeMode) -> Unit = {},
    onFinish: () -> Unit
) {
    val totalPages = 4
    val pagerState = rememberPagerState(pageCount = { totalPages })
    val scope = rememberCoroutineScope()
    val isLastPage = pagerState.currentPage == totalPages - 1
    val isBangla = currentLanguage == "bn"

    val featurePages = listOf(
        OnboardingPageData(
            titleRes = R.string.onboarding_title_1,
            descRes = R.string.onboarding_desc_1,
            heroIcon = Icons.Filled.AccountBalance,
            badgeText = if (isBangla) "স্মার্ট সমিতি ইআরপি" else "Smart Somithi ERP",
            tagList = listOf(
                Icons.AutoMirrored.Filled.TrendingUp to if (isBangla) "স্বচ্ছ তহবিল ট্র্যাকিং" else "Fund Tracking",
                Icons.Filled.AccountBalance to if (isBangla) "সদস্য চাঁদা ও ঋণ হিসাব" else "Contributions & Loans"
            )
        ),
        OnboardingPageData(
            titleRes = R.string.onboarding_title_2,
            descRes = R.string.onboarding_desc_2,
            heroIcon = Icons.AutoMirrored.Filled.ReceiptLong,
            badgeText = if (isBangla) "তাত্ক্ষণিক ডকুমেন্ট" else "Instant Docs",
            tagList = listOf(
                Icons.Filled.Print to if (isBangla) "ডিজিটাল মানি রসিদ" else "Digital Receipts",
                Icons.Filled.Badge to if (isBangla) "২-সাইডেড আইডি কার্ড" else "2-Sided ID Cards"
            )
        ),
        OnboardingPageData(
            titleRes = R.string.onboarding_title_3,
            descRes = R.string.onboarding_desc_3,
            heroIcon = Icons.Filled.CloudDone,
            badgeText = if (isBangla) "অফলাইন ও সিকিউর" else "Offline & Secure",
            tagList = listOf(
                Icons.Filled.Sync to if (isBangla) "অটো ক্লাউড সিঙ্ক" else "Auto Cloud Sync",
                Icons.Filled.Security to if (isBangla) "বায়োমেট্রিক ও পিন সুরক্ষা" else "Biometric Security"
            )
        )
    )

    Scaffold(
        containerColor = MaterialTheme.colorScheme.background
    ) { innerPadding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(innerPadding)
                .padding(horizontal = 20.dp, vertical = 14.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            // Top Bar: Brand Badge and Skip Button
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .height(44.dp),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Surface(
                    shape = RoundedCornerShape(16.dp),
                    color = MaterialTheme.colorScheme.primaryContainer
                ) {
                    Text(
                        text = stringResource(R.string.app_name),
                        style = MaterialTheme.typography.labelMedium,
                        fontWeight = FontWeight.Bold,
                        color = MaterialTheme.colorScheme.onPrimaryContainer,
                        modifier = Modifier.padding(horizontal = 12.dp, vertical = 6.dp)
                    )
                }

                AnimatedVisibility(
                    visible = !isLastPage,
                    enter = fadeIn(),
                    exit = fadeOut()
                ) {
                    TextButton(onClick = onFinish) {
                        Text(
                            text = stringResource(R.string.onboarding_skip),
                            style = MaterialTheme.typography.bodyMedium,
                            fontWeight = FontWeight.SemiBold,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }
                }
            }

            Spacer(modifier = Modifier.height(12.dp))

            // Carousel Pager: Page 0 is Setup, Pages 1-3 are Feature highlights
            HorizontalPager(
                state = pagerState,
                modifier = Modifier
                    .weight(1f)
                    .fillMaxWidth()
            ) { pageIndex ->
                if (pageIndex == 0) {
                    PreferencesSetupPage(
                        currentLanguage = currentLanguage,
                        currentThemeMode = currentThemeMode,
                        onLanguageSelect = onLanguageChange,
                        onThemeModeSelect = onThemeModeChange
                    )
                } else {
                    OnboardingFeaturePageContent(data = featurePages[pageIndex - 1])
                }
            }

            Spacer(modifier = Modifier.height(20.dp))

            // Bottom Navigation: Indicator Dots + Next/Action Button
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(bottom = 12.dp),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                // Indicator Dots
                Row(
                    horizontalArrangement = Arrangement.spacedBy(8.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    repeat(totalPages) { index ->
                        val isSelected = pagerState.currentPage == index
                        val width by animateDpAsState(
                            targetValue = if (isSelected) 28.dp else 8.dp,
                            label = "dot_width"
                        )
                        Box(
                            modifier = Modifier
                                .height(8.dp)
                                .width(width)
                                .clip(CircleShape)
                                .background(
                                    if (isSelected) {
                                        MaterialTheme.colorScheme.primary
                                    } else {
                                        MaterialTheme.colorScheme.outlineVariant
                                    }
                                )
                        )
                    }
                }

                // Action Button (Next / Get Started)
                Button(
                    onClick = {
                        if (isLastPage) {
                            onFinish()
                        } else {
                            scope.launch {
                                pagerState.animateScrollToPage(pagerState.currentPage + 1)
                            }
                        }
                    },
                    shape = RoundedCornerShape(16.dp),
                    colors = ButtonDefaults.buttonColors(
                        containerColor = MaterialTheme.colorScheme.primary,
                        contentColor = MaterialTheme.colorScheme.onPrimary
                    ),
                    modifier = Modifier.height(50.dp)
                ) {
                    Row(
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(8.dp)
                    ) {
                        Text(
                            text = if (isLastPage) {
                                stringResource(R.string.onboarding_get_started)
                            } else {
                                stringResource(R.string.onboarding_next)
                            },
                            style = MaterialTheme.typography.titleMedium,
                            fontWeight = FontWeight.Bold
                        )
                        Icon(
                            imageVector = if (isLastPage) {
                                Icons.Filled.CheckCircle
                            } else {
                                Icons.AutoMirrored.Filled.ArrowForward
                            },
                            contentDescription = null,
                            modifier = Modifier.size(18.dp)
                        )
                    }
                }
            }
        }
    }
}
