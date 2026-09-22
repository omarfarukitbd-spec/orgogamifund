package com.helptrickbd.myapplicationsomithierp.presentation.screens.members

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.automirrored.filled.Chat
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Call
import androidx.compose.material.icons.filled.Groups
import androidx.compose.material.icons.filled.Person
import androidx.compose.ui.platform.LocalConfiguration
import androidx.compose.material.icons.filled.Search
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.FloatingActionButton
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.OutlinedTextFieldDefaults
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Surface
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
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.helptrickbd.myapplicationsomithierp.R
import com.helptrickbd.myapplicationsomithierp.core.ui.EmptyStateView
import com.helptrickbd.myapplicationsomithierp.core.ui.shimmerEffect
import com.helptrickbd.myapplicationsomithierp.core.util.CurrencyFormatter
import com.helptrickbd.myapplicationsomithierp.domain.model.Member
import com.helptrickbd.myapplicationsomithierp.domain.model.MemberStatus
import com.helptrickbd.myapplicationsomithierp.ui.theme.MoneyDueAmber
import com.helptrickbd.myapplicationsomithierp.ui.theme.MoneyIncomeGreen

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
        val isBangla = LocalConfiguration.current.locales[0].language == "bn"
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
                        MemberCard(
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

@Composable
fun MemberCard(
    member: Member,
    isBangla: Boolean = true,
    onClick: () -> Unit,
    onCallClick: () -> Unit,
    onWhatsAppClick: () -> Unit
) {
    Card(
        modifier = Modifier
            .fillMaxWidth()
            .clickable(onClick = onClick),
        shape = RoundedCornerShape(16.dp),
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface),
        elevation = CardDefaults.cardElevation(defaultElevation = 2.dp)
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            // Member Avatar Box
            Box(
                modifier = Modifier
                    .size(50.dp)
                    .clip(CircleShape)
                    .background(MaterialTheme.colorScheme.primaryContainer),
                contentAlignment = Alignment.Center
            ) {
                Icon(
                    imageVector = Icons.Default.Person,
                    contentDescription = null,
                    tint = MaterialTheme.colorScheme.primary,
                    modifier = Modifier.size(28.dp)
                )
            }

            Spacer(modifier = Modifier.width(14.dp))

            Column(modifier = Modifier.weight(1f)) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Text(
                        text = member.name,
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.Bold,
                        color = MaterialTheme.colorScheme.onSurface
                    )
                    Spacer(modifier = Modifier.width(8.dp))
                    Surface(
                        shape = RoundedCornerShape(6.dp),
                        color = if (member.status == MemberStatus.ACTIVE) MoneyIncomeGreen.copy(alpha = 0.12f) else Color.Gray.copy(alpha = 0.12f)
                    ) {
                        Text(
                            text = if (member.status == MemberStatus.ACTIVE) (if (isBangla) "সক্রিয়" else "Active") else (if (isBangla) "অব্যাহতিপ্রাপ্ত" else "Left"),
                            modifier = Modifier.padding(horizontal = 6.dp, vertical = 2.dp),
                            style = MaterialTheme.typography.labelSmall,
                            color = if (member.status == MemberStatus.ACTIVE) MoneyIncomeGreen else Color.Gray,
                            fontWeight = FontWeight.SemiBold
                        )
                    }
                }

                Spacer(modifier = Modifier.height(3.dp))

                Text(
                    text = if (isBangla) "মোবাইল: ${member.phone}" else "Mobile: ${member.phone}",
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )

                if (member.outstandingDues > 0) {
                    Spacer(modifier = Modifier.height(2.dp))
                    Text(
                        text = if (isBangla) "বকেয়া: ${CurrencyFormatter.formatBDT(member.outstandingDues, toBanglaDigits = true)}" else "Due: ${CurrencyFormatter.formatBDT(member.outstandingDues, toBanglaDigits = false)}",
                        style = MaterialTheme.typography.labelSmall,
                        color = MoneyDueAmber,
                        fontWeight = FontWeight.Bold
                    )
                }
            }

            // Quick Call Action
            IconButton(
                onClick = onCallClick,
                modifier = Modifier
                    .size(38.dp)
                    .clip(CircleShape)
                    .background(MaterialTheme.colorScheme.primaryContainer.copy(alpha = 0.5f))
            ) {
                Icon(
                    imageVector = Icons.Default.Call,
                    contentDescription = "Call",
                    tint = MaterialTheme.colorScheme.primary,
                    modifier = Modifier.size(18.dp)
                )
            }

            Spacer(modifier = Modifier.width(6.dp))

            // Quick WhatsApp Action
            IconButton(
                onClick = onWhatsAppClick,
                modifier = Modifier
                    .size(38.dp)
                    .clip(CircleShape)
                    .background(MoneyIncomeGreen.copy(alpha = 0.15f))
            ) {
                Icon(
                    imageVector = Icons.AutoMirrored.Filled.Chat,
                    contentDescription = "WhatsApp",
                    tint = MoneyIncomeGreen,
                    modifier = Modifier.size(18.dp)
                )
            }
        }
    }
}

@Composable
fun MemberCardSkeleton() {
    Card(
        modifier = Modifier
            .fillMaxWidth()
            .height(82.dp),
        shape = RoundedCornerShape(16.dp),
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface)
    ) {
        Row(
            modifier = Modifier
                .fillMaxSize()
                .padding(16.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Box(
                modifier = Modifier
                    .size(50.dp)
                    .clip(CircleShape)
                    .shimmerEffect()
            )
            Spacer(modifier = Modifier.width(14.dp))
            Column(modifier = Modifier.weight(1f)) {
                Box(
                    modifier = Modifier
                        .fillMaxWidth(0.6f)
                        .height(16.dp)
                        .clip(RoundedCornerShape(4.dp))
                        .shimmerEffect()
                )
                Spacer(modifier = Modifier.height(8.dp))
                Box(
                    modifier = Modifier
                        .fillMaxWidth(0.4f)
                        .height(12.dp)
                        .clip(RoundedCornerShape(4.dp))
                        .shimmerEffect()
                )
            }
        }
    }
}
