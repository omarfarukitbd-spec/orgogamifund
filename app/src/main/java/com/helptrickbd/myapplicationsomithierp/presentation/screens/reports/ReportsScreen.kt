package com.helptrickbd.myapplicationsomithierp.presentation.screens.reports

import androidx.compose.ui.platform.LocalConfiguration

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.helptrickbd.myapplicationsomithierp.core.pdf.ReportPdfGenerator
import com.helptrickbd.myapplicationsomithierp.core.util.CurrencyFormatter
import com.helptrickbd.myapplicationsomithierp.core.util.safeRound
import com.helptrickbd.myapplicationsomithierp.domain.model.Expense
import com.helptrickbd.myapplicationsomithierp.domain.model.Loan
import com.helptrickbd.myapplicationsomithierp.domain.model.Member
import com.helptrickbd.myapplicationsomithierp.domain.model.Payment
import com.helptrickbd.myapplicationsomithierp.ui.theme.MoneyDueAmber
import com.helptrickbd.myapplicationsomithierp.ui.theme.MoneyExpenseRed
import com.helptrickbd.myapplicationsomithierp.ui.theme.MoneyIncomeGreen

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ReportsScreen(
    members: List<Member> = emptyList(),
    payments: List<Payment> = emptyList(),
    expenses: List<Expense> = emptyList(),
    loans: List<Loan> = emptyList(),
    onNavigateBack: () -> Unit = {}
) {
    val context = LocalContext.current
    val isBangla = LocalConfiguration.current.locales[0].language == "bn"
    var selectedReportIndex by remember { mutableIntStateOf(0) }
    val reportTypes = remember(isBangla) {
        if (isBangla) listOf(
            "সারসংক্ষেপ বিবরণী",
            "খরচ রেজিস্টার",
            "ঋণ ও আদায়",
            "সদস্যদের লেজার"
        ) else listOf(
            "Executive Summary",
            "Expense Register",
            "Loans & Collections",
            "Member Ledger"
        )
    }

    val currentReportTitle = when (selectedReportIndex) {
        0 -> if (isBangla) "সমিতির সার্বিক মাসিক ও বার্ষিক সারসংক্ষেপ বিবরণী" else "Overall Society Financial Summary Statement"
        1 -> if (isBangla) "সমিতির খরচ ও ভাউচার রেজিস্টার বিবরণী" else "Society Expense & Voucher Register Statement"
        2 -> if (isBangla) "ঋণ বিতরণ ও কিস্তি আদায় বিবরণী" else "Loan Disbursement & Collection Statement"
        else -> if (isBangla) "সদস্যদের চাঁদা, সঞ্চয় ও বকেয়া লেজার বিবরণী" else "Member Contribution, Savings & Dues Ledger"
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    Text(
                        text = if (isBangla) "রিপোর্টস ও আর্থিক বিবরণী" else "Reports & Financial Statements",
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
        bottomBar = {
            Surface(
                tonalElevation = 6.dp,
                shadowElevation = 8.dp,
                color = MaterialTheme.colorScheme.surface
            ) {
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(16.dp),
                    horizontalArrangement = Arrangement.spacedBy(12.dp)
                ) {
                    OutlinedButton(
                        onClick = {
                            val pdf = ReportPdfGenerator.generateReportPdf(
                                context = context,
                                reportTitle = currentReportTitle,
                                members = members,
                                payments = payments,
                                expenses = expenses,
                                loans = loans
                            )
                            ReportPdfGenerator.shareReportPdf(context, pdf)
                        },
                        modifier = Modifier.weight(1f),
                        shape = RoundedCornerShape(12.dp)
                    ) {
                        Icon(imageVector = Icons.Default.Share, contentDescription = null, modifier = Modifier.size(18.dp))
                        Spacer(modifier = Modifier.width(6.dp))
                        Text(if (isBangla) "শেয়ার / PDF" else "Share / PDF")
                    }

                    Button(
                        onClick = {
                            val pdf = ReportPdfGenerator.generateReportPdf(
                                context = context,
                                reportTitle = currentReportTitle,
                                members = members,
                                payments = payments,
                                expenses = expenses,
                                loans = loans
                            )
                            ReportPdfGenerator.printReport(context, pdf)
                        },
                        modifier = Modifier.weight(1f),
                        shape = RoundedCornerShape(12.dp),
                        colors = ButtonDefaults.buttonColors(containerColor = MaterialTheme.colorScheme.primary)
                    ) {
                        Icon(imageVector = Icons.Default.Print, contentDescription = null, modifier = Modifier.size(18.dp))
                        Spacer(modifier = Modifier.width(6.dp))
                        Text(if (isBangla) "প্রিন্ট করুন" else "Print")
                    }
                }
            }
        }
    ) { innerPadding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(innerPadding)
        ) {
            // Report Tabs
            ScrollableTabRow(
                selectedTabIndex = selectedReportIndex,
                edgePadding = 16.dp
            ) {
                reportTypes.forEachIndexed { index, title ->
                    Tab(
                        selected = selectedReportIndex == index,
                        onClick = { selectedReportIndex = index },
                        text = { Text(title, fontWeight = if (selectedReportIndex == index) FontWeight.Bold else FontWeight.Normal) }
                    )
                }
            }

            // Report Preview Content
            when (selectedReportIndex) {
                0 -> SummaryReportPreview(members = members, payments = payments, expenses = expenses, loans = loans, isBangla = isBangla)
                1 -> ExpenseReportPreview(expenses = expenses, isBangla = isBangla)
                2 -> LoanReportPreview(loans = loans, isBangla = isBangla)
                3 -> MemberLedgerReportPreview(members = members, isBangla = isBangla)
            }
        }
    }
}

@Composable
fun SummaryReportPreview(
    members: List<Member>,
    payments: List<Payment>,
    expenses: List<Expense>,
    loans: List<Loan>,
    isBangla: Boolean = true
) {
    val totalCollections = safeRound(payments.sumOf { safeRound(it.amount) })
    val totalExpenses = safeRound(expenses.sumOf { safeRound(it.amount) })
    val totalActiveLoans = safeRound(loans.filter { it.status.name == "ACTIVE" }.sumOf { safeRound(it.outstandingBalance) })
    val totalDues = safeRound(members.sumOf { safeRound(it.outstandingDues) })
    val runningBalance = safeRound(1250000.0 + totalCollections - totalExpenses - totalActiveLoans)

    LazyColumn(
        modifier = Modifier.fillMaxSize(),
        contentPadding = PaddingValues(16.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        item {
            ReportHeaderCard(
                title = if (isBangla) "মাসিক ও বার্ষিক আর্থিক স্থিতি বিবরণী" else "Monthly & Annual Financial Position Statement",
                subtitle = if (isBangla) "সমিতির সকল চাঁদা, সঞ্চয়, খরচ এবং ঋণ পরিস্থিতির পূর্ণাঙ্গ হিসাব।" else "Comprehensive report of all contributions, savings, expenses and loans."
            )
        }

        item {
            ReportMetricCard(
                title = if (isBangla) "মোট সংগৃহীত চাঁদা ও সঞ্চয়" else "Total Collected Contributions & Savings",
                value = CurrencyFormatter.formatBDT(totalCollections, toBanglaDigits = isBangla),
                color = MoneyIncomeGreen,
                icon = Icons.Default.Payments
            )
        }

        item {
            ReportMetricCard(
                title = if (isBangla) "মোট নির্বাহকৃত খরচ" else "Total Expenses Incurred",
                value = CurrencyFormatter.formatBDT(totalExpenses, toBanglaDigits = isBangla),
                color = MoneyExpenseRed,
                icon = Icons.Default.MoneyOff
            )
        }

        item {
            ReportMetricCard(
                title = if (isBangla) "সদস্যদের মাঝে বিতরণকৃত ঋণ স্থিতি" else "Active Loan Balance Disbursed",
                value = CurrencyFormatter.formatBDT(totalActiveLoans, toBanglaDigits = isBangla),
                color = Color(0xFF0284C7),
                icon = Icons.Default.CreditCard
            )
        }

        item {
            ReportMetricCard(
                title = if (isBangla) "মোট অনাদায়ী বকেয়া চাঁদা" else "Total Outstanding Dues",
                value = CurrencyFormatter.formatBDT(totalDues, toBanglaDigits = isBangla),
                color = MoneyDueAmber,
                icon = Icons.Default.Warning
            )
        }

        item {
            Card(
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(16.dp),
                colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.primaryContainer.copy(alpha = 0.5f))
            ) {
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(18.dp),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Column {
                        Text(
                            text = if (isBangla) "বর্তমান নেট তহবিল স্থিতি (Running Balance)" else "Net Fund Balance (Running Balance)",
                            style = MaterialTheme.typography.titleSmall,
                            fontWeight = FontWeight.Bold
                        )
                        Text(
                            text = if (isBangla) "ব্যাংক ও ক্যাশে রক্ষিত মোট মূলধন" else "Total capital held in bank & cash",
                            style = MaterialTheme.typography.bodySmall,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }
                    Text(
                        text = CurrencyFormatter.formatBDT(runningBalance, toBanglaDigits = isBangla),
                        style = MaterialTheme.typography.headlineSmall,
                        fontWeight = FontWeight.ExtraBold,
                        color = MaterialTheme.colorScheme.primary
                    )
                }
            }
        }
    }
}

@Composable
fun ExpenseReportPreview(expenses: List<Expense>, isBangla: Boolean = true) {
    val totalExpense = safeRound(expenses.sumOf { safeRound(it.amount) })

    LazyColumn(
        modifier = Modifier.fillMaxSize(),
        contentPadding = PaddingValues(16.dp),
        verticalArrangement = Arrangement.spacedBy(10.dp)
    ) {
        item {
            ReportHeaderCard(
                title = if (isBangla) "খরচ ও ভাউচার রেজিস্টার বিবরণী" else "Expense & Voucher Register",
                subtitle = if (isBangla) "মোট খরচ: ${CurrencyFormatter.formatBDT(totalExpense, toBanglaDigits = true)} (${expenses.size} টি এন্ট্রি)" else "Total Expense: ${CurrencyFormatter.formatBDT(totalExpense, toBanglaDigits = false)} (${expenses.size} entries)"
            )
        }

        items(expenses, key = { it.id }) { expense ->
            Card(
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(12.dp),
                colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface),
                elevation = CardDefaults.cardElevation(defaultElevation = 1.dp)
            ) {
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(12.dp),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Column(modifier = Modifier.weight(1f)) {
                        Text(expense.category, style = MaterialTheme.typography.titleSmall, fontWeight = FontWeight.Bold)
                        if (expense.description.isNotEmpty()) {
                            Text(expense.description, style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
                        }
                    }
                    Text(
                        text = CurrencyFormatter.formatBDT(safeRound(expense.amount), toBanglaDigits = isBangla),
                        style = MaterialTheme.typography.titleSmall,
                        fontWeight = FontWeight.Bold,
                        color = MoneyExpenseRed
                    )
                }
            }
        }
    }
}

@Composable
fun LoanReportPreview(loans: List<Loan>, isBangla: Boolean = true) {
    val totalDisbursed = safeRound(loans.sumOf { safeRound(it.amount) })
    val totalRepaid = safeRound(loans.sumOf { safeRound(it.totalRepaid) })
    val totalDue = safeRound(loans.sumOf { safeRound(it.outstandingBalance) })

    LazyColumn(
        modifier = Modifier.fillMaxSize(),
        contentPadding = PaddingValues(16.dp),
        verticalArrangement = Arrangement.spacedBy(10.dp)
    ) {
        item {
            ReportHeaderCard(
                title = if (isBangla) "ঋণ ও কিস্তি আদায় বিবরণী" else "Loan Disbursement & Collection Statement",
                subtitle = if (isBangla) "মোট ঋণ: ${CurrencyFormatter.formatBDT(totalDisbursed, toBanglaDigits = true)} | আদায়: ${CurrencyFormatter.formatBDT(totalRepaid, toBanglaDigits = true)} | বকেয়া: ${CurrencyFormatter.formatBDT(totalDue, toBanglaDigits = true)}" else "Total Disbursed: ${CurrencyFormatter.formatBDT(totalDisbursed, toBanglaDigits = false)} | Collected: ${CurrencyFormatter.formatBDT(totalRepaid, toBanglaDigits = false)} | Outstanding: ${CurrencyFormatter.formatBDT(totalDue, toBanglaDigits = false)}"
            )
        }

        items(loans, key = { it.id }) { loan ->
            Card(
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(12.dp),
                colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface),
                elevation = CardDefaults.cardElevation(defaultElevation = 1.dp)
            ) {
                Column(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(14.dp)
                ) {
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween
                    ) {
                        Text(loan.memberName, style = MaterialTheme.typography.titleSmall, fontWeight = FontWeight.Bold)
                        Text(
                            text = if (isBangla) "বকেয়া: ${CurrencyFormatter.formatBDT(safeRound(loan.outstandingBalance), toBanglaDigits = true)}" else "Outstanding: ${CurrencyFormatter.formatBDT(safeRound(loan.outstandingBalance), toBanglaDigits = false)}",
                            style = MaterialTheme.typography.bodyMedium,
                            fontWeight = FontWeight.Bold,
                            color = MoneyExpenseRed
                        )
                    }
                    Spacer(modifier = Modifier.height(4.dp))
                    Text(
                        text = if (isBangla) "বিতরণ: ${CurrencyFormatter.formatBDT(safeRound(loan.amount), toBanglaDigits = true)} | আদায়: ${CurrencyFormatter.formatBDT(safeRound(loan.totalRepaid), toBanglaDigits = true)}" else "Disbursed: ${CurrencyFormatter.formatBDT(safeRound(loan.amount), toBanglaDigits = false)} | Repaid: ${CurrencyFormatter.formatBDT(safeRound(loan.totalRepaid), toBanglaDigits = false)}",
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
            }
        }
    }
}

@Composable
fun MemberLedgerReportPreview(members: List<Member>, isBangla: Boolean = true) {
    val totalContributed = safeRound(members.sumOf { safeRound(it.totalContributed) })
    val totalDues = safeRound(members.sumOf { safeRound(it.outstandingDues) })

    LazyColumn(
        modifier = Modifier.fillMaxSize(),
        contentPadding = PaddingValues(16.dp),
        verticalArrangement = Arrangement.spacedBy(10.dp)
    ) {
        item {
            ReportHeaderCard(
                title = if (isBangla) "সদস্য চাঁদা ও সঞ্চয় লেজার বিবরণী" else "Member Savings & Contribution Ledger",
                subtitle = if (isBangla) "মোট সদস্য: ${members.size} জন | মোট সঞ্চয়: ${CurrencyFormatter.formatBDT(totalContributed, toBanglaDigits = true)} | বকেয়া: ${CurrencyFormatter.formatBDT(totalDues, toBanglaDigits = true)}" else "Total Members: ${members.size} | Total Savings: ${CurrencyFormatter.formatBDT(totalContributed, toBanglaDigits = false)} | Dues: ${CurrencyFormatter.formatBDT(totalDues, toBanglaDigits = false)}"
            )
        }

        items(members, key = { it.id }) { member ->
            Card(
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(12.dp),
                colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface),
                elevation = CardDefaults.cardElevation(defaultElevation = 1.dp)
            ) {
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(14.dp),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Column(modifier = Modifier.weight(1f)) {
                        Text(member.name, style = MaterialTheme.typography.titleSmall, fontWeight = FontWeight.Bold)
                        Text(if (isBangla) "মোবাইল: ${member.phone}" else "Mobile: ${member.phone}", style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
                    }
                    Column(horizontalAlignment = Alignment.End) {
                        Text(
                            text = if (isBangla) "জমা: ${CurrencyFormatter.formatBDT(safeRound(member.totalContributed), toBanglaDigits = true)}" else "Deposit: ${CurrencyFormatter.formatBDT(safeRound(member.totalContributed), toBanglaDigits = false)}",
                            style = MaterialTheme.typography.titleSmall,
                            fontWeight = FontWeight.Bold,
                            color = MoneyIncomeGreen
                        )
                        if (member.outstandingDues > 0) {
                            Text(
                                text = if (isBangla) "বকেয়া: ${CurrencyFormatter.formatBDT(safeRound(member.outstandingDues), toBanglaDigits = true)}" else "Due: ${CurrencyFormatter.formatBDT(safeRound(member.outstandingDues), toBanglaDigits = false)}",
                                style = MaterialTheme.typography.labelSmall,
                                color = MoneyDueAmber,
                                fontWeight = FontWeight.Bold
                            )
                        }
                    }
                }
            }
        }
    }
}

@Composable
fun ReportHeaderCard(title: String, subtitle: String) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(14.dp),
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.primary.copy(alpha = 0.08f))
    ) {
        Column(modifier = Modifier.padding(14.dp)) {
            Text(text = title, style = MaterialTheme.typography.titleSmall, fontWeight = FontWeight.Bold, color = MaterialTheme.colorScheme.primary)
            Spacer(modifier = Modifier.height(2.dp))
            Text(text = subtitle, style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
        }
    }
}

@Composable
fun ReportMetricCard(
    title: String,
    value: String,
    color: Color,
    icon: androidx.compose.ui.graphics.vector.ImageVector
) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(14.dp),
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface),
        elevation = CardDefaults.cardElevation(defaultElevation = 1.dp)
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(14.dp),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Box(
                    modifier = Modifier
                        .size(40.dp)
                        .clip(CircleShape)
                        .background(color.copy(alpha = 0.12f)),
                    contentAlignment = Alignment.Center
                ) {
                    Icon(imageVector = icon, contentDescription = null, tint = color, modifier = Modifier.size(22.dp))
                }
                Spacer(modifier = Modifier.width(12.dp))
                Text(text = title, style = MaterialTheme.typography.bodyMedium, fontWeight = FontWeight.Medium)
            }
            Text(text = value, style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold, color = color)
        }
    }
}
