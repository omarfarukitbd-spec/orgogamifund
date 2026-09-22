package com.helptrickbd.myapplicationsomithierp.presentation.screens.loans

import androidx.compose.ui.platform.LocalConfiguration
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import com.helptrickbd.myapplicationsomithierp.core.ui.EmptyStateView
import com.helptrickbd.myapplicationsomithierp.core.util.CurrencyFormatter
import com.helptrickbd.myapplicationsomithierp.core.util.safeRound
import com.helptrickbd.myapplicationsomithierp.domain.model.Loan
import com.helptrickbd.myapplicationsomithierp.domain.model.LoanStatus
import com.helptrickbd.myapplicationsomithierp.ui.theme.MoneyDueAmber
import com.helptrickbd.myapplicationsomithierp.ui.theme.MoneyExpenseRed
import com.helptrickbd.myapplicationsomithierp.ui.theme.MoneyIncomeGreen
import java.text.SimpleDateFormat
import java.util.*

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun LoanListScreen(
    loans: List<Loan> = emptyList(),
    onIssueLoanClick: () -> Unit = {},
    onRepayInstallment: (loanId: String, amount: Double, method: String) -> Unit = { _, _, _ -> },
    onNavigateBack: () -> Unit = {}
) {
    val isBangla = LocalConfiguration.current.locales[0].language == "bn"
    var selectedTab by remember { mutableIntStateOf(0) } // 0: Active, 1: Paid Off
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
                        text = if (isBangla) "ঋণ ও দাদন ব্যবস্থাপনা" else "Loan Management",
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
                contentColor = Color.White,
                shape = RoundedCornerShape(16.dp)
            ) {
                Row(
                    modifier = Modifier.padding(horizontal = 16.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Icon(imageVector = Icons.Default.Add, contentDescription = null)
                    Spacer(modifier = Modifier.width(6.dp))
                    Text(if (isBangla) "নতুন ঋণ বিতরণ" else "Issue Loan", fontWeight = FontWeight.Bold)
                }
            }
        }
    ) { innerPadding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(innerPadding)
        ) {
            // Summary Cards Header
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
                        text = if (isBangla) "ঋণ সামগ্রিক স্থিতি" else "Overall Loan Overview",
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
                    text = { Text(if (isBangla) "চলতি ঋণ (${activeLoans.size})" else "Active Loans (${activeLoans.size})", fontWeight = FontWeight.Bold) }
                )
                Tab(
                    selected = selectedTab == 1,
                    onClick = { selectedTab = 1 },
                    text = { Text(if (isBangla) "পরিশোধিত ঋণ (${paidLoans.size})" else "Repaid Loans (${paidLoans.size})", fontWeight = FontWeight.Bold) }
                )
            }

            val displayedLoans = if (selectedTab == 0) activeLoans else paidLoans

            if (displayedLoans.isEmpty()) {
                EmptyStateView(
                    icon = Icons.Default.CreditCard,
                    title = if (selectedTab == 0) (if (isBangla) "কোনো চলতি ঋণ নেই" else "No Active Loans") else (if (isBangla) "কোনো পরিশোধিত ঋণ নেই" else "No Repaid Loans"),
                    description = if (selectedTab == 0) (if (isBangla) "সমিতির সদস্যদের মাঝে নতুন ঋণ প্রদান করতে নিচের বাটনে চাপ দিন।" else "Tap the button below to disburse a new loan to members.") else (if (isBangla) "পূর্বে বিতরণকৃত কোনো ঋণ এখনো সম্পূর্ণ পরিশোধ হয়নি।" else "Completed loan repayments will appear here."),
                    actionButtonText = if (selectedTab == 0) (if (isBangla) "নতুন ঋণ বিতরণ করুন" else "Issue New Loan") else null,
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
                        text = if (isBangla) "বকেয়া ব্যালেন্স: ${CurrencyFormatter.formatBDT(loan.outstandingBalance, toBanglaDigits = true)}" else "Outstanding Balance: ${CurrencyFormatter.formatBDT(loan.outstandingBalance, toBanglaDigits = false)}",
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

                    // Method Selector
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
fun LoanStatColumn(title: String, amount: Double, color: Color, isBangla: Boolean = true) {
    Column {
        Text(text = title, style = MaterialTheme.typography.labelSmall, color = MaterialTheme.colorScheme.outline)
        Spacer(modifier = Modifier.height(4.dp))
        Text(
            text = CurrencyFormatter.formatBDT(safeRound(amount), toBanglaDigits = isBangla),
            style = MaterialTheme.typography.titleMedium,
            fontWeight = FontWeight.Bold,
            color = color
        )
    }
}

@Composable
fun LoanCardItem(
    loan: Loan,
    isBangla: Boolean = true,
    onCollectInstallmentClick: () -> Unit
) {
    val dateFormat = remember(isBangla) { SimpleDateFormat("dd MMM, yyyy", if (isBangla) Locale("bn", "BD") else Locale.ENGLISH) }
    val dateStr = dateFormat.format(Date(loan.dateIssued))
    val progress = if (loan.totalPayable > 0) {
        (loan.totalRepaid / loan.totalPayable).toFloat().coerceIn(0f, 1f)
    } else 0f

    Card(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(16.dp),
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface),
        elevation = CardDefaults.cardElevation(defaultElevation = 2.dp)
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp)
        ) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Box(
                        modifier = Modifier
                            .size(38.dp)
                            .clip(CircleShape)
                            .background(
                                if (loan.status == LoanStatus.ACTIVE) MaterialTheme.colorScheme.primaryContainer
                                else MoneyIncomeGreen.copy(alpha = 0.15f)
                            ),
                        contentAlignment = Alignment.Center
                    ) {
                        Icon(
                            imageVector = if (loan.status == LoanStatus.ACTIVE) Icons.Default.CreditCard else Icons.Default.CheckCircle,
                            contentDescription = null,
                            tint = if (loan.status == LoanStatus.ACTIVE) MaterialTheme.colorScheme.primary else MoneyIncomeGreen,
                            modifier = Modifier.size(20.dp)
                        )
                    }
                    Spacer(modifier = Modifier.width(10.dp))
                    Column {
                        Text(
                            text = loan.memberName,
                            style = MaterialTheme.typography.titleSmall,
                            fontWeight = FontWeight.Bold
                        )
                        Text(
                            text = if (isBangla) "ইস্যু: $dateStr" else "Issued: $dateStr",
                            style = MaterialTheme.typography.labelSmall,
                            color = MaterialTheme.colorScheme.outline
                        )
                    }
                }

                Surface(
                    shape = RoundedCornerShape(8.dp),
                    color = if (loan.status == LoanStatus.ACTIVE) MoneyDueAmber.copy(alpha = 0.12f) else MoneyIncomeGreen.copy(alpha = 0.12f)
                ) {
                    Text(
                        text = if (loan.status == LoanStatus.ACTIVE) (if (isBangla) "চলতি" else "Active") else (if (isBangla) "পরিশোধিত" else "Repaid"),
                        modifier = Modifier.padding(horizontal = 8.dp, vertical = 4.dp),
                        style = MaterialTheme.typography.labelSmall,
                        color = if (loan.status == LoanStatus.ACTIVE) Color(0xFFD97706) else MoneyIncomeGreen,
                        fontWeight = FontWeight.Bold
                    )
                }
            }

            if (loan.reason.isNotEmpty()) {
                Spacer(modifier = Modifier.height(8.dp))
                Text(
                    text = if (isBangla) "উদ্দেশ্য: ${loan.reason}" else "Purpose: ${loan.reason}",
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }

            Spacer(modifier = Modifier.height(12.dp))

            // Progress Bar
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                Text(
                    text = if (isBangla) "আদায়: ${CurrencyFormatter.formatBDT(loan.totalRepaid, toBanglaDigits = true)}" else "Collected: ${CurrencyFormatter.formatBDT(loan.totalRepaid, toBanglaDigits = false)}",
                    style = MaterialTheme.typography.labelSmall,
                    color = MoneyIncomeGreen,
                    fontWeight = FontWeight.Bold
                )
                Text(
                    text = if (isBangla) "মোট দেনা: ${CurrencyFormatter.formatBDT(loan.totalPayable, toBanglaDigits = true)}" else "Total Payable: ${CurrencyFormatter.formatBDT(loan.totalPayable, toBanglaDigits = false)}",
                    style = MaterialTheme.typography.labelSmall,
                    color = MaterialTheme.colorScheme.outline
                )
            }

            Spacer(modifier = Modifier.height(6.dp))

            LinearProgressIndicator(
                progress = { progress },
                modifier = Modifier
                    .fillMaxWidth()
                    .height(8.dp)
                    .clip(RoundedCornerShape(4.dp)),
                color = MoneyIncomeGreen,
                trackColor = MaterialTheme.colorScheme.surfaceVariant
            )

            Spacer(modifier = Modifier.height(12.dp))

            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Column {
                    Text(
                        text = if (isBangla) "অবশিষ্ট বকেয়া" else "Outstanding Balance",
                        style = MaterialTheme.typography.labelSmall,
                        color = MaterialTheme.colorScheme.outline
                    )
                    Text(
                        text = CurrencyFormatter.formatBDT(loan.outstandingBalance, toBanglaDigits = isBangla),
                        style = MaterialTheme.typography.titleSmall,
                        fontWeight = FontWeight.Bold,
                        color = if (loan.outstandingBalance > 0) MoneyExpenseRed else MoneyIncomeGreen
                    )
                }

                if (loan.status == LoanStatus.ACTIVE) {
                    Button(
                        onClick = onCollectInstallmentClick,
                        shape = RoundedCornerShape(10.dp),
                        colors = ButtonDefaults.buttonColors(containerColor = MaterialTheme.colorScheme.primary)
                    ) {
                        Icon(imageVector = Icons.Default.Payments, contentDescription = null, modifier = Modifier.size(16.dp))
                        Spacer(modifier = Modifier.width(6.dp))
                        Text(if (isBangla) "কিস্তি জমা নিন" else "Collect Installment")
                    }
                }
            }
        }
    }
}
