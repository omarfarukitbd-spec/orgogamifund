package com.helptrickbd.myapplicationsomithierp.presentation.screens.members

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Groups
import androidx.compose.material.icons.filled.Search
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.FloatingActionButton
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.OutlinedTextFieldDefaults
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Tab
import androidx.compose.material3.TabRow
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalConfiguration
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.helptrickbd.myapplicationsomithierp.R
import com.helptrickbd.myapplicationsomithierp.core.ui.EmptyStateView
import com.helptrickbd.myapplicationsomithierp.domain.model.Member
import com.helptrickbd.myapplicationsomithierp.domain.model.MemberStatus
import com.helptrickbd.myapplicationsomithierp.presentation.screens.members.components.MemberCardSkeleton
import com.helptrickbd.myapplicationsomithierp.presentation.screens.members.components.MemberListItemCard

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun MemberListScreen(
    members: List<Member> = emptyList(),
    isLoading: Boolean = false,
    onMemberClick: (memberId: String) -> Unit = {},
    onAddMemberClick: () -> Unit = {},
    onCallClick: (phone: String) -> Unit = {},
    onWhatsAppClick: (phone: String) -> Unit = {},
    onNavigateBack: () -> Unit = {}
) {
    var searchQuery by remember { mutableStateOf("") }
    var selectedTabIndex by remember { mutableIntStateOf(0) } // 0: Active, 1: Left
    val isBangla = LocalConfiguration.current.locales[0].language == "bn"

    val filteredMembers = members.filter { member ->
        val matchesStatus = if (selectedTabIndex == 0) member.status == MemberStatus.ACTIVE else member.status == MemberStatus.LEFT
        val matchesSearch = member.name.contains(searchQuery, ignoreCase = true) || member.phone.contains(searchQuery)
        matchesStatus && matchesSearch
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    Text(
                        text = stringResource(R.string.nav_members),
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.Bold
                    )
                },
                navigationIcon = {
                    IconButton(onClick = onNavigateBack) {
                        Icon(imageVector = Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "Back")
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(containerColor = MaterialTheme.colorScheme.surface)
            )
        },
        floatingActionButton = {
            FloatingActionButton(
                onClick = onAddMemberClick,
                containerColor = MaterialTheme.colorScheme.primary,
                contentColor = MaterialTheme.colorScheme.onPrimary,
                shape = RoundedCornerShape(16.dp)
            ) {
                Icon(imageVector = Icons.Default.Add, contentDescription = "Add Member")
            }
        }
    ) { innerPadding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(innerPadding)
        ) {
            // Search Input
            OutlinedTextField(
                value = searchQuery,
                onValueChange = { searchQuery = it },
                placeholder = { Text(if (isBangla) "সদস্যের নাম বা মোবাইল নম্বর দিয়ে খুঁজুন..." else "Search by member name or phone...") },
                leadingIcon = {
                    Icon(
                        imageVector = Icons.Default.Search,
                        contentDescription = null,
                        tint = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                },
                singleLine = true,
                shape = RoundedCornerShape(14.dp),
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 16.dp, vertical = 8.dp),
                colors = OutlinedTextFieldDefaults.colors(
                    focusedBorderColor = MaterialTheme.colorScheme.primary,
                    unfocusedBorderColor = MaterialTheme.colorScheme.outline
                )
            )

            // Status Tabs (Active vs Left)
            TabRow(
                selectedTabIndex = selectedTabIndex,
                containerColor = MaterialTheme.colorScheme.surface
            ) {
                Tab(
                    selected = selectedTabIndex == 0,
                    onClick = { selectedTabIndex = 0 },
                    text = { Text(if (isBangla) "সক্রিয় সদস্য (${members.count { it.status == MemberStatus.ACTIVE }})" else "Active Members (${members.count { it.status == MemberStatus.ACTIVE }})") }
                )
                Tab(
                    selected = selectedTabIndex == 1,
                    onClick = { selectedTabIndex = 1 },
                    text = { Text(if (isBangla) "অব্যাহতিপ্রাপ্ত (${members.count { it.status == MemberStatus.LEFT }})" else "Left/Resigned (${members.count { it.status == MemberStatus.LEFT }})") }
                )
            }

            if (isLoading) {
                LazyColumn(
                    modifier = Modifier.fillMaxSize(),
                    contentPadding = PaddingValues(16.dp),
                    verticalArrangement = Arrangement.spacedBy(12.dp)
                ) {
                    items(6) {
                        MemberCardSkeleton()
                    }
                }
            } else if (filteredMembers.isEmpty()) {
                EmptyStateView(
                    icon = Icons.Default.Groups,
                    title = if (selectedTabIndex == 0) (if (isBangla) "কোনো সক্রিয় সদস্য নেই" else "No Active Members") else (if (isBangla) "কোনো অব্যাহতিপ্রাপ্ত সদস্য নেই" else "No Resigned Members"),
                    description = if (selectedTabIndex == 0) (if (isBangla) "নতুন সদস্য যোগ করতে নিচের বাটনে ক্লিক করুন" else "Tap button below to add a new member") else (if (isBangla) "পদত্যাগকৃত সদস্যদের হিস্ট্রি এখানে সংরক্ষিত থাকবে" else "History of resigned members will appear here"),
                    actionButtonText = if (selectedTabIndex == 0) stringResource(R.string.btn_add_member) else null,
                    onActionClick = if (selectedTabIndex == 0) onAddMemberClick else null,
                    modifier = Modifier.fillMaxSize()
                )
            } else {
                LazyColumn(
                    modifier = Modifier.fillMaxSize(),
                    contentPadding = PaddingValues(16.dp),
                    verticalArrangement = Arrangement.spacedBy(12.dp)
                ) {
                    items(filteredMembers) { member ->
                        MemberListItemCard(
                            member = member,
                            isBangla = isBangla,
                            onClick = { onMemberClick(member.id) },
                            onCallClick = { onCallClick(member.phone) },
                            onWhatsAppClick = { onWhatsAppClick(member.phone) }
                        )
                    }
                }
            }
        }
    }
}
