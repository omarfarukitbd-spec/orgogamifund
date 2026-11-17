package com.helptrickbd.myapplicationsomithierp.presentation.screens.reports.components

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.CreditCard
import androidx.compose.material.icons.filled.MoneyOff
import androidx.compose.material.icons.filled.Payments
import androidx.compose.material.icons.filled.Warning
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.helptrickbd.myapplicationsomithierp.core.util.CurrencyFormatter
import com.helptrickbd.myapplicationsomithierp.core.util.safeRound
import com.helptrickbd.myapplicationsomithierp.domain.model.Expense
import com.helptrickbd.myapplicationsomithierp.domain.model.Loan
import com.helptrickbd.myapplicationsomithierp.domain.model.Member
import com.helptrickbd.myapplicationsomithierp.domain.model.Payment
import com.helptrickbd.myapplicationsomithierp.ui.theme.MoneyDueAmber
import com.helptrickbd.myapplicationsomithierp.ui.theme.MoneyExpenseRed
import com.helptrickbd.myapplicationsomithierp.ui.theme.MoneyIncomeGreen

@Composable
fun SummaryReportPreview(
    members: List<Member>,
    payments: List<Payment>,
    expenses: List<Expense>,
    loans: List<Loan>,
    isBangla: Boolean = true,
    modifier: Modifier = Modifier
) {
    val totalCollections = safeRound(payments.sumOf { safeRound(it.amount) })
    val totalExpenses = safeRound(expenses.sumOf { safeRound(it.amount) })
    val totalActiveLoans = safeRound(loans.filter { it.status.name == "ACTIVE" }.sumOf { safeRound(it.outstandingBalance) })
    val totalDues = safeRound(members.sumOf { safeRound(it.outstandingDues) })
    val runningBalance = safeRound(1250000.0 + totalCollections - totalExpenses - totalActiveLoans)

    LazyColumn(
        modifier = modifier.fillMaxSize(),
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
                color = MaterialTheme.colorScheme.primary,
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
                            fontWeight = FontWeight.Bold,
                            color = MaterialTheme.colorScheme.onPrimaryContainer
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
