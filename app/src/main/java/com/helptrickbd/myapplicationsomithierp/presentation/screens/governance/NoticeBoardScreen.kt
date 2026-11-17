package com.helptrickbd.myapplicationsomithierp.presentation.screens.governance

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Campaign
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.FloatingActionButton
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.PrimaryTabRow
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Tab
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalConfiguration
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.helptrickbd.myapplicationsomithierp.core.ui.EmptyStateView
import com.helptrickbd.myapplicationsomithierp.domain.model.Notice
import com.helptrickbd.myapplicationsomithierp.domain.model.NoticeType
import com.helptrickbd.myapplicationsomithierp.presentation.screens.governance.components.AddNoticeDialog
import com.helptrickbd.myapplicationsomithierp.presentation.screens.governance.components.NoticeItemCard

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun NoticeBoardScreen(
    notices: List<Notice> = emptyList(),
    isAdmin: Boolean = true,
    onPublishNotice: (Notice) -> Unit = {},
    onDeleteNotice: (String) -> Unit = {},
    onNavigateBack: () -> Unit = {}
) {
    val isBangla = LocalConfiguration.current.locales[0].language == "bn"
    var selectedTabIndex by remember { mutableIntStateOf(0) }
    val tabTitles = remember(isBangla) {
        if (isBangla) listOf("সব নোটিশ", "সাধারণ ঘোষণা", "সভার বিবরণী (AGM)")
        else listOf("All Notices", "Announcements", "Meeting Minutes (AGM)")
    }
    var showAddDialog by remember { mutableStateOf(false) }

    val filteredNotices = remember(notices, selectedTabIndex) {
        when (selectedTabIndex) {
            1 -> notices.filter { it.type == NoticeType.NOTICE }
            2 -> notices.filter { it.type == NoticeType.MEETING_MINUTES }
            else -> notices
        }
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    Text(
                        text = if (isBangla) "নোটিশ বোর্ড ও সভার বিবরণী" else "Notice Board & Meeting Minutes",
                        fontWeight = FontWeight.Bold,
                        style = MaterialTheme.typography.titleLarge
                    )
                },
                navigationIcon = {
                    IconButton(onClick = onNavigateBack) {
                        Icon(
                            imageVector = Icons.AutoMirrored.Filled.ArrowBack,
                            contentDescription = "Back"
                        )
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = MaterialTheme.colorScheme.surface
                )
            )
        },
        floatingActionButton = {
            if (isAdmin) {
                FloatingActionButton(
                    onClick = { showAddDialog = true },
                    containerColor = MaterialTheme.colorScheme.primary,
                    contentColor = MaterialTheme.colorScheme.onPrimary
                ) {
                    Icon(imageVector = Icons.Default.Add, contentDescription = "Publish Notice")
                }
            }
        }
    ) { innerPadding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(innerPadding)
        ) {
            PrimaryTabRow(
                selectedTabIndex = selectedTabIndex,
                containerColor = MaterialTheme.colorScheme.surface
            ) {
                tabTitles.forEachIndexed { index, title ->
                    Tab(
                        selected = selectedTabIndex == index,
                        onClick = { selectedTabIndex = index },
                        text = {
                            Text(
                                text = title,
                                fontWeight = if (selectedTabIndex == index) FontWeight.Bold else FontWeight.Normal
                            )
                        }
                    )
                }
            }

            if (filteredNotices.isEmpty()) {
                Box(
                    modifier = Modifier.fillMaxSize(),
                    contentAlignment = Alignment.Center
                ) {
                    EmptyStateView(
                        icon = Icons.Default.Campaign,
                        title = if (isBangla) "কোনো নোটিশ পাওয়া যায়নি" else "No notices found",
                        description = if (isBangla) "নতুন কোনো সিদ্ধান্ত বা সভার কার্যবিবরণী পোস্ট করা হলে এখানে প্রদর্শিত হবে।"
                        else "New resolutions or meeting minutes will be displayed here once posted.",
                        actionButtonText = if (isAdmin) (if (isBangla) "নতুন নোটিশ প্রকাশ করুন" else "Publish New Notice") else null,
                        onActionClick = { showAddDialog = true }
                    )
                }
            } else {
                LazyColumn(
                    modifier = Modifier.fillMaxSize(),
                    contentPadding = PaddingValues(16.dp),
                    verticalArrangement = Arrangement.spacedBy(14.dp)
                ) {
                    items(filteredNotices) { notice ->
                        NoticeItemCard(
                            notice = notice,
                            isAdmin = isAdmin,
                            isBangla = isBangla,
                            onDelete = { onDeleteNotice(notice.id) }
                        )
                    }
                }
            }
        }

        if (showAddDialog) {
            AddNoticeDialog(
                isBangla = isBangla,
                onDismiss = { showAddDialog = false },
                onConfirm = { newNotice ->
                    onPublishNotice(newNotice)
                    showAddDialog = false
                }
            )
        }
    }
}
