package com.helptrickbd.myapplicationsomithierp.presentation.screens.dashboard.components

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import coil.compose.AsyncImage
import coil.request.ImageRequest
import com.helptrickbd.myapplicationsomithierp.domain.model.UserRole
import com.helptrickbd.myapplicationsomithierp.presentation.screens.dashboard.DashboardUiState

@Composable
fun DashboardDrawer(
    state: DashboardUiState,
    onCloseDrawer: () -> Unit,
    onNavigateToBranches: () -> Unit,
    onNavigateToMembers: () -> Unit,
    onNavigateToPayments: () -> Unit,
    onNavigateToLoans: () -> Unit,
    onNavigateToExpenses: () -> Unit,
    onNavigateToNotices: () -> Unit,
    onNavigateToCommittee: () -> Unit,
    onNavigateToDividends: () -> Unit,
    onNavigateToReports: () -> Unit,
    onNavigateToAdminHub: () -> Unit,
    onNavigateToSettings: () -> Unit
) {
    val isBangla = androidx.compose.ui.platform.LocalConfiguration.current.locales[0].language == "bn"

    ModalDrawerSheet(
        modifier = Modifier
            .width(310.dp)
            .fillMaxHeight(),
        drawerContainerColor = MaterialTheme.colorScheme.surface
    ) {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .verticalScroll(rememberScrollState())
        ) {
            // Header Profile Card
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .background(MaterialTheme.colorScheme.primary)
                    .padding(20.dp)
            ) {
                Column {
                    if (!state.userPhotoUrl.isNullOrBlank()) {
                        AsyncImage(
                            model = ImageRequest.Builder(LocalContext.current)
                                .data(state.userPhotoUrl)
                                .crossfade(true)
                                .build(),
                            contentDescription = "Avatar",
                            modifier = Modifier
                                .size(56.dp)
                                .clip(CircleShape)
                                .border(2.dp, MaterialTheme.colorScheme.onPrimary, CircleShape),
                            contentScale = ContentScale.Crop
                        )
                    } else {
                        Box(
                            modifier = Modifier
                                .size(56.dp)
                                .clip(CircleShape)
                                .background(MaterialTheme.colorScheme.onPrimary.copy(alpha = 0.2f)),
                            contentAlignment = Alignment.Center
                        ) {
                            Icon(
                                imageVector = Icons.Default.Person,
                                contentDescription = null,
                                tint = MaterialTheme.colorScheme.onPrimary,
                                modifier = Modifier.size(32.dp)
                            )
                        }
                    }

                    Spacer(modifier = Modifier.height(10.dp))

                    val displayName = state.userName.ifBlank {
                        if (state.userRole == UserRole.SUPER_ADMIN) "মো: ওমর ফারুক"
                        else if (isBangla) "সম্মানিত সদস্য" else "Valued Member"
                    }
                    Text(
                        text = displayName,
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.Bold,
                        color = MaterialTheme.colorScheme.onPrimary
                    )

                    val displayEmail = state.userEmail.ifBlank {
                        if (state.userRole == UserRole.SUPER_ADMIN) "omarfaruktitbd@gmail.com"
                        else if (isBangla) "ইমেইল সংযুক্ত নেই" else "No email connected"
                    }
                    Text(
                        text = displayEmail,
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onPrimary.copy(alpha = 0.85f)
                    )

                    Spacer(modifier = Modifier.height(6.dp))

                    Surface(
                        shape = RoundedCornerShape(6.dp),
                        color = MaterialTheme.colorScheme.onPrimary.copy(alpha = 0.25f)
                    ) {
                        Text(
                            text = when (state.userRole) {
                                UserRole.SUPER_ADMIN -> if (isBangla) "সুপার এডমিন (কেন্দ্রীয়)" else "Super Admin (Central)"
                                UserRole.BRANCH_ADMIN -> if (isBangla) "শাখা ব্যবস্থাপক" else "Branch Admin"
                                UserRole.MEMBER -> if (isBangla) "অনুমোদিত সদস্য" else "Approved Member"
                            },
                            modifier = Modifier.padding(horizontal = 8.dp, vertical = 2.dp),
                            style = MaterialTheme.typography.labelSmall,
                            color = MaterialTheme.colorScheme.onPrimary,
                            fontWeight = FontWeight.Bold
                        )
                    }
                }
            }

            Spacer(modifier = Modifier.height(8.dp))

            // Navigation Items
            DrawerGroupTitle(if (isBangla) "মূল আর্থিক মডিউল" else "Core Financial Modules")
            DrawerNavItem(Icons.Default.Apartment, if (isBangla) "সমিতিসমূহ ও শাখাসমূহ" else "Somithis & Branches") { onCloseDrawer(); onNavigateToBranches() }
            DrawerNavItem(Icons.Default.Groups, if (isBangla) "সদস্য তালিকা" else "Member Directory") { onCloseDrawer(); onNavigateToMembers() }
            DrawerNavItem(Icons.Default.Receipt, if (isBangla) "চাঁদা ও সঞ্চয় জমা" else "Deposit Collection") { onCloseDrawer(); onNavigateToPayments() }
            DrawerNavItem(Icons.Default.CreditCard, if (isBangla) "ঋণ ও দাদন সেবা" else "Loans & Advances") { onCloseDrawer(); onNavigateToLoans() }
            DrawerNavItem(Icons.Default.MoneyOff, if (isBangla) "দৈনন্দিন খরচ রেজিস্টার" else "Expense Register") { onCloseDrawer(); onNavigateToExpenses() }

            Divider(modifier = Modifier.padding(vertical = 6.dp), color = MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.4f))

            DrawerGroupTitle(if (isBangla) "গভর্নেন্স ও নোটিশ" else "Governance & Notices")
            DrawerNavItem(Icons.Default.Campaign, if (isBangla) "সাধারণ নোটিশ বোর্ড" else "Notice Board") { onCloseDrawer(); onNavigateToNotices() }
            DrawerNavItem(Icons.Default.Star, if (isBangla) "কার্যনির্বাহী কমিটি" else "Executive Committee") { onCloseDrawer(); onNavigateToCommittee() }
            DrawerNavItem(Icons.Default.PieChart, if (isBangla) "বার্ষিক লভ্যাংশ বণ্টন" else "Dividend Distribution") { onCloseDrawer(); onNavigateToDividends() }
            DrawerNavItem(Icons.Default.Print, if (isBangla) "অডিট ও আর্থিক রিপোর্ট" else "Audit & Financial Reports") { onCloseDrawer(); onNavigateToReports() }

            Divider(modifier = Modifier.padding(vertical = 6.dp), color = MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.4f))
            DrawerGroupTitle(if (isBangla) "প্রশাসনিক নিয়ন্ত্রণ" else "Administrative Control")
            DrawerNavItem(Icons.Default.AdminPanelSettings, if (isBangla) "এডমিন কন্ট্রোল হাব" else "Admin Control Hub") { onCloseDrawer(); onNavigateToAdminHub() }

            Divider(modifier = Modifier.padding(vertical = 6.dp), color = MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.4f))

            DrawerNavItem(Icons.Default.Settings, if (isBangla) "সেটিংস ও নিরাপত্তা" else "Settings & Security") { onCloseDrawer(); onNavigateToSettings() }

            Spacer(modifier = Modifier.height(16.dp))
        }
    }
}

@Composable
private fun DrawerGroupTitle(title: String) {
    Text(
        text = title,
        style = MaterialTheme.typography.labelSmall,
        fontWeight = FontWeight.Bold,
        color = MaterialTheme.colorScheme.primary,
        modifier = Modifier.padding(horizontal = 20.dp, vertical = 6.dp)
    )
}

@Composable
private fun DrawerNavItem(
    icon: ImageVector,
    title: String,
    onClick: () -> Unit
) {
    NavigationDrawerItem(
        icon = { Icon(imageVector = icon, contentDescription = title, modifier = Modifier.size(20.dp)) },
        label = { Text(text = title, style = MaterialTheme.typography.bodyMedium, fontWeight = FontWeight.Medium) },
        selected = false,
        onClick = onClick,
        modifier = Modifier.padding(horizontal = 12.dp, vertical = 2.dp),
        shape = RoundedCornerShape(10.dp)
    )
}
