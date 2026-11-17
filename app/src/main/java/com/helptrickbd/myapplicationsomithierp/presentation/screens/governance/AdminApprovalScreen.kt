package com.helptrickbd.myapplicationsomithierp.presentation.screens.governance

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.HourglassTop
import androidx.compose.material.icons.filled.VerifiedUser
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.PrimaryTabRow
import androidx.compose.material3.Scaffold
import androidx.compose.material3.SnackbarHost
import androidx.compose.material3.SnackbarHostState
import androidx.compose.material3.Surface
import androidx.compose.material3.Tab
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalConfiguration
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.helptrickbd.myapplicationsomithierp.domain.model.ApprovalStatus
import com.helptrickbd.myapplicationsomithierp.domain.model.Member
import com.helptrickbd.myapplicationsomithierp.domain.model.MemberApplication
import com.helptrickbd.myapplicationsomithierp.presentation.screens.governance.components.ApplicationCardItem
import com.helptrickbd.myapplicationsomithierp.presentation.screens.governance.components.RejectApplicationDialog
import com.helptrickbd.myapplicationsomithierp.ui.theme.MoneyDueAmber
import kotlinx.coroutines.launch

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun AdminApprovalScreen(
    applications: List<MemberApplication>,
    onApprove: (String) -> Member?,
    onReject: (String, String) -> Unit,
    onViewIdCard: (String) -> Unit = {},
    onCallApplicant: (String) -> Unit = {},
    onNavigateBack: () -> Unit = {}
) {
    val isBangla = LocalConfiguration.current.locales[0].language == "bn"
    var selectedTab by remember { mutableIntStateOf(0) }
    val snackbarHostState = remember { SnackbarHostState() }
    val scope = rememberCoroutineScope()

    var applicationToReject by remember { mutableStateOf<MemberApplication?>(null) }
    var rejectionReason by remember {
        mutableStateOf(
            if (isBangla) "জাতীয় পরিচয়পত্র বা প্রয়োজনীয় তথ্যে অসংগতি রয়েছে"
            else "Discrepancy found in National ID or required information"
        )
    }

    val pendingList = applications.filter { it.status == ApprovalStatus.PENDING }
    val approvedList = applications.filter { it.status == ApprovalStatus.APPROVED }
    val rejectedList = applications.filter { it.status == ApprovalStatus.REJECTED }

    val currentList = when (selectedTab) {
        0 -> pendingList
        1 -> approvedList
        else -> rejectedList
    }

    Scaffold(
        snackbarHost = { SnackbarHost(hostState = snackbarHostState) },
        topBar = {
            TopAppBar(
                title = {
                    Column {
                        Text(
                            text = if (isBangla) "মেম্বারশিপ আবেদন ও অনুমোদন" else "Membership Applications",
                            style = MaterialTheme.typography.titleMedium,
                            fontWeight = FontWeight.Bold
                        )
                        Text(
                            text = if (isBangla) "অগ্রগামী ফান্ড এডমিন প্যানেল" else "Ogrogami Fund Admin Panel",
                            style = MaterialTheme.typography.labelSmall,
                            color = MaterialTheme.colorScheme.primary
                        )
                    }
                },
                navigationIcon = {
                    IconButton(onClick = onNavigateBack) {
                        Icon(imageVector = Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "Back")
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(containerColor = MaterialTheme.colorScheme.surface)
            )
        }
    ) { innerPadding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(innerPadding)
        ) {
            // Tab Navigation
            PrimaryTabRow(
                selectedTabIndex = selectedTab,
                containerColor = MaterialTheme.colorScheme.surface
            ) {
                Tab(
                    selected = selectedTab == 0,
                    onClick = { selectedTab = 0 },
                    text = {
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            Text(if (isBangla) "অপেক্ষমাণ" else "Pending")
                            if (pendingList.isNotEmpty()) {
                                Spacer(modifier = Modifier.width(6.dp))
                                Surface(
                                    shape = CircleShape,
                                    color = MoneyDueAmber.copy(alpha = 0.2f),
                                    modifier = Modifier.size(20.dp)
                                ) {
                                    Box(contentAlignment = Alignment.Center) {
                                        Text(
                                            text = "${pendingList.size}",
                                            style = MaterialTheme.typography.labelSmall,
                                            fontWeight = FontWeight.Bold,
                                            color = MoneyDueAmber
                                        )
                                    }
                                }
                            }
                        }
                    }
                )
                Tab(
                    selected = selectedTab == 1,
                    onClick = { selectedTab = 1 },
                    text = { Text(if (isBangla) "অনুমোদিত (${approvedList.size})" else "Approved (${approvedList.size})") }
                )
                Tab(
                    selected = selectedTab == 2,
                    onClick = { selectedTab = 2 },
                    text = { Text(if (isBangla) "বাতিলকৃত (${rejectedList.size})" else "Rejected (${rejectedList.size})") }
                )
            }

            if (currentList.isEmpty()) {
                Box(
                    modifier = Modifier
                        .fillMaxSize()
                        .padding(24.dp),
                    contentAlignment = Alignment.Center
                ) {
                    Column(horizontalAlignment = Alignment.CenterHorizontally) {
                        Icon(
                            imageVector = when (selectedTab) {
                                0 -> Icons.Default.HourglassTop
                                1 -> Icons.Default.VerifiedUser
                                else -> Icons.Default.Close
                            },
                            contentDescription = null,
                            tint = MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.5f),
                            modifier = Modifier.size(64.dp)
                        )
                        Spacer(modifier = Modifier.height(12.dp))
                        Text(
                            text = when (selectedTab) {
                                0 -> if (isBangla) "কোনো অপেক্ষমাণ মেম্বারশিপ আবেদন নেই" else "No pending applications found"
                                1 -> if (isBangla) "এখনো কোনো আবেদন অনুমোদিত হয়নি" else "No approved applications yet"
                                else -> if (isBangla) "কোনো আবেদন বাতিল করা হয়নি" else "No rejected applications"
                            },
                            style = MaterialTheme.typography.bodyLarge,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }
                }
            } else {
                LazyColumn(
                    modifier = Modifier.fillMaxSize(),
                    contentPadding = PaddingValues(16.dp),
                    verticalArrangement = Arrangement.spacedBy(14.dp)
                ) {
                    items(currentList, key = { it.id }) { app ->
                        ApplicationCardItem(
                            application = app,
                            isBangla = isBangla,
                            onApprove = {
                                val createdMember = onApprove(app.id)
                                scope.launch {
                                    val memberId = createdMember?.id ?: ""
                                    snackbarHostState.showSnackbar(
                                        if (isBangla) "আবেদন অনুমোদিত! নতুন সদস্য আইডি: #$memberId তৈরি হয়েছে"
                                        else "Application approved! New member ID: #$memberId created"
                                    )
                                }
                            },
                            onReject = {
                                applicationToReject = app
                            },
                            onViewIdCard = {
                                onViewIdCard(app.id)
                            },
                            onCall = { onCallApplicant(app.phone) }
                        )
                    }
                }
            }
        }
    }

    // Reject Dialog
    if (applicationToReject != null) {
        RejectApplicationDialog(
            application = applicationToReject!!,
            rejectionReason = rejectionReason,
            onReasonChange = { rejectionReason = it },
            isBangla = isBangla,
            onConfirmReject = {
                val app = applicationToReject
                if (app != null) {
                    onReject(app.id, rejectionReason)
                    scope.launch {
                        snackbarHostState.showSnackbar(
                            if (isBangla) "আবেদনটি বাতিল করা হয়েছে" else "Application rejected"
                        )
                    }
                }
                applicationToReject = null
            },
            onDismiss = { applicationToReject = null }
        )
    }
}
