package com.helptrickbd.myapplicationsomithierp.presentation.screens.loans

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Handshake
import androidx.compose.material.icons.filled.Payments
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalConfiguration
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import com.helptrickbd.myapplicationsomithierp.core.ui.EmptyStateView
import com.helptrickbd.myapplicationsomithierp.core.util.CurrencyFormatter
import com.helptrickbd.myapplicationsomithierp.core.util.safeRound
import com.helptrickbd.myapplicationsomithierp.domain.model.Loan
import com.helptrickbd.myapplicationsomithierp.domain.model.LoanStatus
import com.helptrickbd.myapplicationsomithierp.presentation.screens.loans.components.LoanCardItem
import com.helptrickbd.myapplicationsomithierp.ui.theme.MoneyExpenseRed
import com.helptrickbd.myapplicationsomithierp.ui.theme.MoneyIncomeGreen

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun LoanListScreen(
    loans: List<Loan> = emptyList(),
    onIssueLoanClick: () -> Unit = {},
    onRepayInstallment: (loanId: String, amount: Double, method: String) -> Unit = { _, _, _ -> },
    onNavigateBack: () -> Unit = {}
) {
    val isBangla = LocalConfiguration.current.locales[0].language == "bn"
    var selectedTab by remember { mutableIntStateOf(0) }
    var loanToRepay by remember { mutableStateOf<Loan?>(null) }
    var repaymentAmountText by remember { mutableStateOf("") }
    var selectedMethod by remember { mutableStateOf("Cash") }

    val activeLoans = loans.filter { it.status == LoanStatus.ACTIVE }
    val paidLoans = loans.filter { it.status == LoanStatus.PAID_OFF }

    val totalDisbursed = safeRound(loans.sumOf { safeRound(it.amount) })
    val totalRepaid = safeRound(loans.sumOf { safeRound(it.totalRepaid) })
    val totalOutstanding = safeRound(activeLoans.sumOf { safeRound(it.outstandingBalance) })

    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    Text(
                        text = if (isBangla) "করযে হাসানা (সুদমুক্ত ঋণ)" else "Qard Hasan (Interest-Free)",
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
                onClick = onIssueLoanClick,
                containerColor = MaterialTheme.colorScheme.primary,
                contentColor = MaterialTheme.colorScheme.onPrimary,
                shape = RoundedCornerShape(16.dp)
            ) {
                Row(
                    modifier = Modifier.padding(horizontal = 16.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Icon(imageVector = Icons.Default.Add, contentDescription = null)
                    Spacer(modifier = Modifier.width(6.dp))
                    Text(if (isBangla) "করযে হাসানা প্রদান" else "Disburse Qard Hasan", fontWeight = FontWeight.Bold)
                }
            }
        }
    ) { innerPadding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(innerPadding)
        ) {
            // Overview Card
            Card(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(16.dp),
                shape = RoundedCornerShape(18.dp),
                colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface),
                elevation = CardDefaults.cardElevation(defaultElevation = 2.dp)
            ) {
                Column(modifier = Modifier.padding(16.dp)) {
                    Text(
                        text = if (isBangla) "করযে হাসানা সামগ্রিক স্থিতি" else "Qard Hasan Overview",
                        style = MaterialTheme.typography.labelMedium,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                    Spacer(modifier = Modifier.height(12.dp))
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween
                    ) {
                        LoanStatColumn(
                            title = if (isBangla) "মোট বিতরণ" else "Disbursed",
                            amount = totalDisbursed,
                            color = MaterialTheme.colorScheme.primary,
                            isBangla = isBangla
                        )
                        LoanStatColumn(
                            title = if (isBangla) "মোট আদায়" else "Collected",
                            amount = totalRepaid,
                            color = MoneyIncomeGreen,
                            isBangla = isBangla
                        )
                        LoanStatColumn(
                            title = if (isBangla) "মোট বকেয়া" else "Outstanding",
                            amount = totalOutstanding,
                            color = MoneyExpenseRed,
                            isBangla = isBangla
                        )
                    }
                }
            }

            // Tabs
            TabRow(selectedTabIndex = selectedTab) {
                Tab(
                    selected = selectedTab == 0,
                    onClick = { selectedTab = 0 },
                    text = { Text(if (isBangla) "চলতি (${activeLoans.size})" else "Active (${activeLoans.size})", fontWeight = FontWeight.Bold) }
                )
                Tab(
                    selected = selectedTab == 1,
                    onClick = { selectedTab = 1 },
                    text = { Text(if (isBangla) "পরিশোধিত (${paidLoans.size})" else "Repaid (${paidLoans.size})", fontWeight = FontWeight.Bold) }
                )
            }

            val displayedLoans = if (selectedTab == 0) activeLoans else paidLoans

            if (displayedLoans.isEmpty()) {
                EmptyStateView(
                    icon = Icons.Default.Handshake,
                    title = if (selectedTab == 0) (if (isBangla) "কোনো চলতি করযে হাসানা নেই" else "No Active Qard Hasan")
                    else (if (isBangla) "কোনো পরিশোধিত রেকর্ড নেই" else "No Repaid Records"),
                    description = if (selectedTab == 0)
                        (if (isBangla) "জরুরি সহায়তায় নতুন করযে হাসানা দিতে নিচের বাটনে চাপুন।" else "Tap below to disburse new interest-free aid.")
                    else (if (isBangla) "পরিশোধিত সকল করযে হাসানার হিসাব এখানে দেখা যাবে।" else "Completed repayments will appear here."),
                    actionButtonText = if (selectedTab == 0) (if (isBangla) "করযে হাসানা প্রদান করুন" else "Disburse Qard Hasan") else null,
                    onActionClick = onIssueLoanClick
                )
            } else {
                LazyColumn(
                    modifier = Modifier.fillMaxSize(),
                    contentPadding = PaddingValues(start = 16.dp, end = 16.dp, top = 16.dp, bottom = 80.dp),
                    verticalArrangement = Arrangement.spacedBy(12.dp)
                ) {
                    items(displayedLoans, key = { it.id }) { loan ->
                        LoanCardItem(
                            loan = loan,
                            isBangla = isBangla,
                            onCollectInstallmentClick = {
                                loanToRepay = loan
                                repaymentAmountText = ""
                            }
                        )
                    }
                }
            }
        }
    }

    // Installment Repayment Dialog
    loanToRepay?.let { loan ->
        AlertDialog(
            onDismissRequest = { loanToRepay = null },
            icon = {
                Icon(
                    imageVector = Icons.Default.Payments,
                    contentDescription = null,
                    tint = MoneyIncomeGreen,
                    modifier = Modifier.size(32.dp)
                )
            },
            title = {
                Text(
                    text = if (isBangla) "কিস্তি আদায় ও জমা" else "Record Installment Payment",
                    fontWeight = FontWeight.Bold,
                    style = MaterialTheme.typography.titleMedium
                )
            },
            text = {
                Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
                    Text(
                        text = if (isBangla) "সদস্য: ${loan.memberName}" else "Member: ${loan.memberName}",
                        style = MaterialTheme.typography.bodyMedium,
                        fontWeight = FontWeight.Bold
                    )
                    Text(
                        text = if (isBangla) "বকেয়া দেনা: ${CurrencyFormatter.formatBDT(loan.outstandingBalance, toBanglaDigits = true)}"
                        else "Remaining: ${CurrencyFormatter.formatBDT(loan.outstandingBalance, toBanglaDigits = false)}",
                        style = MaterialTheme.typography.bodySmall,
                        color = MoneyExpenseRed
                    )

                    OutlinedTextField(
                        value = repaymentAmountText,
                        onValueChange = { repaymentAmountText = it },
                        label = { Text(if (isBangla) "কিস্তির পরিমাণ (টাকা)" else "Installment Amount (BDT)") },
                        keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
                        singleLine = true,
                        modifier = Modifier.fillMaxWidth()
                    )

                    Text(if (isBangla) "পরিশোধের মাধ্যম:" else "Payment Method:", style = MaterialTheme.typography.labelSmall)
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.spacedBy(8.dp)
                    ) {
                        listOf("Cash", "bKash", "Bank").forEach { method ->
                            FilterChip(
                                selected = selectedMethod == method,
                                onClick = { selectedMethod = method },
                                label = { Text(method) }
                            )
                        }
                    }
                }
            },
            confirmButton = {
                Button(
                    onClick = {
                        val amount = safeRound(repaymentAmountText.toDoubleOrNull() ?: 0.0)
                        if (amount > 0) {
                            onRepayInstallment(loan.id, amount, selectedMethod)
                            loanToRepay = null
                        }
                    },
                    colors = ButtonDefaults.buttonColors(containerColor = MoneyIncomeGreen),
                    enabled = (safeRound(repaymentAmountText.toDoubleOrNull() ?: 0.0)) > 0
                ) {
                    Text(if (isBangla) "জমা নিশ্চিত করুন" else "Confirm Deposit")
                }
            },
            dismissButton = {
                TextButton(onClick = { loanToRepay = null }) {
                    Text(if (isBangla) "বাতিল" else "Cancel")
                }
            }
        )
    }
}

@Composable
private fun LoanStatColumn(title: String, amount: Double, color: Color, isBangla: Boolean = true) {
    Column {
        Text(text = title, style = MaterialTheme.typography.labelSmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
        Spacer(modifier = Modifier.height(4.dp))
        Text(
            text = CurrencyFormatter.formatBDT(safeRound(amount), toBanglaDigits = isBangla),
            style = MaterialTheme.typography.titleMedium,
            fontWeight = FontWeight.Bold,
            color = color
        )
    }
}
