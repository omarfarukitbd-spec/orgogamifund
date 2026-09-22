package com.helptrickbd.myapplicationsomithierp.presentation.screens.members

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.Add
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalConfiguration
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.helptrickbd.myapplicationsomithierp.core.pdf.PaymentReceiptPdfGenerator
import com.helptrickbd.myapplicationsomithierp.domain.model.ApprovalStatus
import com.helptrickbd.myapplicationsomithierp.domain.model.Member
import com.helptrickbd.myapplicationsomithierp.domain.model.Payment
import com.helptrickbd.myapplicationsomithierp.presentation.screens.members.components.PassbookHeaderCard
import com.helptrickbd.myapplicationsomithierp.presentation.screens.members.components.PassbookLedgerItem
import com.helptrickbd.myapplicationsomithierp.presentation.screens.members.components.PassbookMonthlyMatrix
import com.helptrickbd.myapplicationsomithierp.presentation.screens.members.components.PassbookSummaryRow

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun MemberPassbookScreen(
    member: Member,
    branchName: String = "অগ্রগামী ফান্ড (দাখিল ব্যাচ ২০১৫)",
    payments: List<Payment> = emptyList(),
    onNavigateToDeposit: () -> Unit = {},
    onNavigateBack: () -> Unit = {}
) {
    val context = LocalContext.current
    val isBangla = LocalConfiguration.current.locales[0].language == "bn"

    var selectedYear by remember { mutableIntStateOf(2026) }
    var selectedFilterIndex by remember { mutableIntStateOf(0) } // 0: All, 1: Approved, 2: Pending

    val memberPayments = remember(payments, member.id) {
        payments.filter { it.memberId == member.id || it.memberName == member.name }
    }

    val approvedPayments = remember(memberPayments) {
        memberPayments.filter { it.approvalStatus == ApprovalStatus.APPROVED }
    }
    val totalSavings = remember(approvedPayments) {
        approvedPayments.sumOf { it.amount }
    }
    val pendingCount = remember(memberPayments) {
        memberPayments.count { it.approvalStatus == ApprovalStatus.PENDING }
    }

    val filteredList = remember(memberPayments, selectedFilterIndex) {
        when (selectedFilterIndex) {
            1 -> memberPayments.filter { it.approvalStatus == ApprovalStatus.APPROVED }
            2 -> memberPayments.filter { it.approvalStatus == ApprovalStatus.PENDING }
            else -> memberPayments
        }.sortedByDescending { it.date }
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    Column {
                        Text(
                            text = if (isBangla) "সদস্য ডিজিটাল পাসবই" else "Member Digital Passbook",
                            style = MaterialTheme.typography.titleMedium,
                            fontWeight = FontWeight.Bold
                        )
                        Text(
                            text = branchName,
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
        },
        floatingActionButton = {
            ExtendedFloatingActionButton(
                onClick = onNavigateToDeposit,
                containerColor = MaterialTheme.colorScheme.primary,
                contentColor = MaterialTheme.colorScheme.onPrimary,
                shape = RoundedCornerShape(16.dp),
                icon = { Icon(imageVector = Icons.Default.Add, contentDescription = null) },
                text = {
                    Text(
                        text = if (isBangla) "টাকা জমা দিন" else "Deposit Now",
                        fontWeight = FontWeight.Bold
                    )
                }
            )
        }
    ) { innerPadding ->
        LazyColumn(
            modifier = Modifier
                .fillMaxSize()
                .padding(innerPadding),
            contentPadding = PaddingValues(16.dp),
            verticalArrangement = Arrangement.spacedBy(14.dp)
        ) {
            // 1. Passbook Profile Header
            item {
                PassbookHeaderCard(
                    member = member,
                    branchName = branchName,
                    payments = memberPayments,
                    context = context,
                    isBangla = isBangla
                )
            }

            // 2. Financial Overview Cards
            item {
                PassbookSummaryRow(
                    totalSavings = totalSavings,
                    dues = member.outstandingDues,
                    loans = member.activeLoanBalance,
                    pendingDepositsCount = pendingCount,
                    isBangla = isBangla
                )
            }

            // 3. Year Selector Chips
            item {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text(
                        text = if (isBangla) "বছর নির্বাচন করুন" else "Select Year",
                        style = MaterialTheme.typography.titleSmall,
                        fontWeight = FontWeight.Bold,
                        color = MaterialTheme.colorScheme.onSurface
                    )

                    Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                        listOf(2025, 2026).forEach { yr ->
                            FilterChip(
                                selected = selectedYear == yr,
                                onClick = { selectedYear = yr },
                                label = { Text(if (isBangla) "$yr সাল" else "$yr", fontWeight = FontWeight.Bold) }
                            )
                        }
                    }
                }
            }

            // 4. Visual 12-Month Contribution Tracker Matrix
            item {
                PassbookMonthlyMatrix(
                    year = selectedYear,
                    payments = memberPayments,
                    isBangla = isBangla,
                    onReceiptClick = { pmt ->
                        val pdf = PaymentReceiptPdfGenerator.generateReceiptPdf(context, pmt, orgName = branchName)
                        PaymentReceiptPdfGenerator.printReceipt(context, pdf)
                    }
                )
            }

            // 5. Transaction Ledger Header & Filter Chips
            item {
                Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                    Text(
                        text = if (isBangla) "পাসবই লেনদেন খাতা (হিস্ট্রি)" else "Passbook Transaction Ledger",
                        style = MaterialTheme.typography.titleSmall,
                        fontWeight = FontWeight.Bold,
                        color = MaterialTheme.colorScheme.onSurface
                    )

                    Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                        val filters = if (isBangla) listOf("সকল", "অনুমোদিত", "অপেক্ষমাণ") else listOf("All", "Approved", "Pending")
                        filters.forEachIndexed { idx, label ->
                            FilterChip(
                                selected = selectedFilterIndex == idx,
                                onClick = { selectedFilterIndex = idx },
                                label = { Text(label) }
                            )
                        }
                    }
                }
            }

            // 6. Chronological Ledger Items
            if (filteredList.isEmpty()) {
                item {
                    Card(
                        modifier = Modifier.fillMaxWidth(),
                        shape = RoundedCornerShape(14.dp),
                        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.4f))
                    ) {
                        Box(modifier = Modifier.fillMaxWidth().padding(24.dp), contentAlignment = Alignment.Center) {
                            Text(
                                text = if (isBangla) "এই বিভাগে কোনো জমার রেকর্ড পাওয়া যায়নি" else "No payment records found in this category",
                                style = MaterialTheme.typography.bodyMedium,
                                color = MaterialTheme.colorScheme.onSurfaceVariant
                            )
                        }
                    }
                }
            } else {
                items(filteredList) { pmt ->
                    PassbookLedgerItem(
                        payment = pmt,
                        isBangla = isBangla,
                        onPrintReceipt = {
                            val pdf = PaymentReceiptPdfGenerator.generateReceiptPdf(context, pmt, orgName = branchName)
                            PaymentReceiptPdfGenerator.printReceipt(context, pdf)
                        }
                    )
                }
            }

            item {
                Spacer(modifier = Modifier.height(40.dp))
            }
        }
    }
}
