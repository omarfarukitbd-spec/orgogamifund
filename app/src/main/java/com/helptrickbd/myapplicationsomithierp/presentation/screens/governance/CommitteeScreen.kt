package com.helptrickbd.myapplicationsomithierp.presentation.screens.governance

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Groups
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.FloatingActionButton
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalConfiguration
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.helptrickbd.myapplicationsomithierp.core.ui.EmptyStateView
import com.helptrickbd.myapplicationsomithierp.domain.model.CommitteeMember
import com.helptrickbd.myapplicationsomithierp.presentation.screens.governance.components.AddCommitteeMemberDialog
import com.helptrickbd.myapplicationsomithierp.presentation.screens.governance.components.CommitteeHeaderCard
import com.helptrickbd.myapplicationsomithierp.presentation.screens.governance.components.CommitteeMemberCard

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun CommitteeScreen(
    committeeMembers: List<CommitteeMember> = emptyList(),
    isAdmin: Boolean = true,
    onAddCommitteeMember: (CommitteeMember) -> Unit = {},
    onRemoveCommitteeMember: (String) -> Unit = {},
    onNavigateBack: () -> Unit = {}
) {
    val isBangla = LocalConfiguration.current.locales[0].language == "bn"
    var showAddDialog by remember { mutableStateOf(false) }

    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    Text(
                        text = if (isBangla) "কার্যনির্বাহী কমিটি" else "Executive Committee",
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
                    Icon(imageVector = Icons.Default.Add, contentDescription = "Add Committee Member")
                }
            }
        }
    ) { innerPadding ->
        if (committeeMembers.isEmpty()) {
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(innerPadding),
                contentAlignment = Alignment.Center
            ) {
                EmptyStateView(
                    icon = Icons.Default.Groups,
                    title = if (isBangla) "কোনো কমিটির তথ্য নেই" else "No Committee Records Found",
                    description = if (isBangla) "কার্যনির্বাহী কমিটির সদস্য যুক্ত করতে নিচের + বাটনে চাপ দিন"
                    else "Tap the + button below to add an executive committee member",
                    actionButtonText = if (isAdmin) (if (isBangla) "কমিটি সদস্য যুক্ত করুন" else "Add Committee Member") else null,
                    onActionClick = { showAddDialog = true }
                )
            }
        } else {
            LazyColumn(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(innerPadding),
                contentPadding = PaddingValues(16.dp),
                verticalArrangement = Arrangement.spacedBy(14.dp)
            ) {
                item {
                    CommitteeHeaderCard(isBangla = isBangla)
                }

                items(committeeMembers) { member ->
                    CommitteeMemberCard(
                        member = member,
                        isAdmin = isAdmin,
                        isBangla = isBangla,
                        onDelete = { onRemoveCommitteeMember(member.id) }
                    )
                }
            }
        }

        if (showAddDialog) {
            AddCommitteeMemberDialog(
                isBangla = isBangla,
                onDismiss = { showAddDialog = false },
                onConfirm = { newMember ->
                    onAddCommitteeMember(newMember)
                    showAddDialog = false
                }
            )
        }
    }
}
