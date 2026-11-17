package com.helptrickbd.myapplicationsomithierp.presentation.screens.notifications.components

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.DeleteSweep
import androidx.compose.material.icons.filled.DoneAll
import androidx.compose.material.icons.filled.MoreVert
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.platform.LocalConfiguration
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun NotificationTopBar(
    unreadCount: Int,
    onNavigateBack: () -> Unit,
    onMarkAllAsRead: () -> Unit,
    onPromptClearAll: () -> Unit
) {
    val isBangla = LocalConfiguration.current.locales[0].language == "bn"
    var showMenu by remember { mutableStateOf(false) }

    TopAppBar(
        title = {
            Column {
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    Text(
                        text = if (isBangla) "বিজ্ঞপ্তি ও বার্তা" else "Notifications",
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.Bold
                    )
                    if (unreadCount > 0) {
                        Box(
                            modifier = Modifier
                                .clip(CircleShape)
                                .background(MaterialTheme.colorScheme.primary)
                                .padding(horizontal = 7.dp, vertical = 2.dp)
                        ) {
                            Text(
                                text = if (isBangla) "$unreadCount টি নতুন" else "$unreadCount new",
                                style = MaterialTheme.typography.labelSmall.copy(fontSize = 10.sp),
                                fontWeight = FontWeight.Bold,
                                color = MaterialTheme.colorScheme.onPrimary
                            )
                        }
                    }
                }
                Text(
                    text = if (unreadCount > 0) {
                        if (isBangla) "আপনার সাম্প্রতিক লেনদেন ও নোটিশের বিবরণী"
                        else "Latest transactions & announcements"
                    } else {
                        if (isBangla) "সব বার্তা পড়া হয়েছে" else "All caught up"
                    },
                    style = MaterialTheme.typography.labelSmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
        },
        navigationIcon = {
            IconButton(onClick = onNavigateBack) {
                Icon(
                    imageVector = Icons.AutoMirrored.Filled.ArrowBack,
                    contentDescription = "Back"
                )
            }
        },
        actions = {
            if (unreadCount > 0) {
                IconButton(onClick = onMarkAllAsRead) {
                    Icon(
                        imageVector = Icons.Default.DoneAll,
                        contentDescription = if (isBangla) "সব পঠিত" else "Mark All Read",
                        tint = MaterialTheme.colorScheme.primary
                    )
                }
            }
            IconButton(onClick = { showMenu = !showMenu }) {
                Icon(
                    imageVector = Icons.Default.MoreVert,
                    contentDescription = "Options"
                )
            }
            DropdownMenu(
                expanded = showMenu,
                onDismissRequest = { showMenu = false }
            ) {
                DropdownMenuItem(
                    text = { Text(if (isBangla) "সবগুলো পঠিত মার্ক করুন" else "Mark All Read") },
                    leadingIcon = {
                        Icon(Icons.Default.DoneAll, contentDescription = null, tint = MaterialTheme.colorScheme.primary)
                    },
                    onClick = {
                        onMarkAllAsRead()
                        showMenu = false
                    }
                )
                DropdownMenuItem(
                    text = { Text(if (isBangla) "সব নোটিফিকেশন মুছুন" else "Clear All Notifications") },
                    leadingIcon = {
                        Icon(Icons.Default.DeleteSweep, contentDescription = null, tint = MaterialTheme.colorScheme.error)
                    },
                    onClick = {
                        showMenu = false
                        onPromptClearAll()
                    }
                )
            }
        },
        colors = TopAppBarDefaults.topAppBarColors(
            containerColor = MaterialTheme.colorScheme.surface
        )
    )
}
