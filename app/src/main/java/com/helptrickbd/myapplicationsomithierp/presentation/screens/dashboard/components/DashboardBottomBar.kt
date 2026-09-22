package com.helptrickbd.myapplicationsomithierp.presentation.screens.dashboard.components

import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Apartment
import androidx.compose.material.icons.filled.Badge
import androidx.compose.material.icons.filled.Home
import androidx.compose.material.icons.filled.Menu
import androidx.compose.material.icons.filled.Receipt
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.NavigationBarItemDefaults
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp

@Composable
fun DashboardBottomBar(
    currentRoute: String = "home",
    onNavigateHome: () -> Unit,
    onNavigateBranches: () -> Unit,
    onNavigatePayments: () -> Unit,
    onNavigateIdCard: () -> Unit,
    onOpenDrawer: () -> Unit
) {
    NavigationBar(
        tonalElevation = 8.dp,
        containerColor = MaterialTheme.colorScheme.surface
    ) {
        NavigationBarItem(
            selected = currentRoute == "home",
            onClick = onNavigateHome,
            icon = { Icon(Icons.Default.Home, contentDescription = "হোম") },
            label = { Text("হোম", fontWeight = FontWeight.SemiBold) },
            colors = NavigationBarItemDefaults.colors(
                selectedIconColor = MaterialTheme.colorScheme.primary,
                selectedTextColor = MaterialTheme.colorScheme.primary,
                indicatorColor = MaterialTheme.colorScheme.primaryContainer
            )
        )
        NavigationBarItem(
            selected = currentRoute == "branches",
            onClick = onNavigateBranches,
            icon = { Icon(Icons.Default.Apartment, contentDescription = "সমিতিসমূহ") },
            label = { Text("সমিতিসমূহ", fontWeight = FontWeight.SemiBold) },
            colors = NavigationBarItemDefaults.colors(
                selectedIconColor = MaterialTheme.colorScheme.primary,
                selectedTextColor = MaterialTheme.colorScheme.primary,
                indicatorColor = MaterialTheme.colorScheme.primaryContainer
            )
        )
        NavigationBarItem(
            selected = currentRoute == "payments",
            onClick = onNavigatePayments,
            icon = { Icon(Icons.Default.Receipt, contentDescription = "লেনদেন") },
            label = { Text("লেনদেন", fontWeight = FontWeight.SemiBold) },
            colors = NavigationBarItemDefaults.colors(
                selectedIconColor = MaterialTheme.colorScheme.primary,
                selectedTextColor = MaterialTheme.colorScheme.primary,
                indicatorColor = MaterialTheme.colorScheme.primaryContainer
            )
        )
        NavigationBarItem(
            selected = currentRoute == "id_card",
            onClick = onNavigateIdCard,
            icon = { Icon(Icons.Default.Badge, contentDescription = "আইডি কার্ড") },
            label = { Text("আইডি কার্ড", fontWeight = FontWeight.SemiBold) },
            colors = NavigationBarItemDefaults.colors(
                selectedIconColor = MaterialTheme.colorScheme.primary,
                selectedTextColor = MaterialTheme.colorScheme.primary,
                indicatorColor = MaterialTheme.colorScheme.primaryContainer
            )
        )
        NavigationBarItem(
            selected = false,
            onClick = onOpenDrawer,
            icon = { Icon(Icons.Default.Menu, contentDescription = "মেনু") },
            label = { Text("মেনু", fontWeight = FontWeight.SemiBold) },
            colors = NavigationBarItemDefaults.colors(
                unselectedIconColor = MaterialTheme.colorScheme.onSurfaceVariant,
                unselectedTextColor = MaterialTheme.colorScheme.onSurfaceVariant
            )
        )
    }
}
