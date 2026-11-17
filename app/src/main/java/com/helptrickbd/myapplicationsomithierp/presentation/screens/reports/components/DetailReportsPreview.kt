package com.helptrickbd.myapplicationsomithierp.presentation.screens.reports.components

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
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
import com.helptrickbd.myapplicationsomithierp.ui.theme.MoneyDueAmber
import com.helptrickbd.myapplicationsomithierp.ui.theme.MoneyExpenseRed
import com.helptrickbd.myapplicationsomithierp.ui.theme.MoneyIncomeGreen

@Composable
fun ExpenseReportPreview(
    expenses: List<Expense>,
    isBangla: Boolean = true,
    modifier: Modifier = Modifier
) {
    val totalExpense = safeRound(expenses.sumOf { safeRound(it.amount) })

    LazyColumn(
        modifier = modifier.fillMaxSize(),
        contentPadding = PaddingValues(16.dp),
        verticalArrangement = Arrangement.spacedBy(10.dp)
    ) {
        item {
            ReportHeaderCard(
                title = if (isBangla) "খরচ ও ভাউচার রেজিস্টার বিবরণী" else "Expense & Voucher Register",
                subtitle = if (isBangla) "মোট খরচ: ${CurrencyFormatter.formatBDT(totalExpense, toBanglaDigits = true)} (${expenses.size} টি এন্ট্রি)"
                else "Total Expense: ${CurrencyFormatter.formatBDT(totalExpense, toBanglaDigits = false)} (${expenses.size} entries)"
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
                        Text(expense.category, style = MaterialTheme.typography.titleSmall, fontWeight = FontWeight.Bold, color = MaterialTheme.colorScheme.onSurface)
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
fun LoanReportPreview(
    loans: List<Loan>,
    isBangla: Boolean = true,
    modifier: Modifier = Modifier
) {
    val totalDisbursed = safeRound(loans.sumOf { safeRound(it.amount) })
    val totalRepaid = safeRound(loans.sumOf { safeRound(it.totalRepaid) })
    val totalDue = safeRound(loans.sumOf { safeRound(it.outstandingBalance) })

    LazyColumn(
        modifier = modifier.fillMaxSize(),
        contentPadding = PaddingValues(16.dp),
        verticalArrangement = Arrangement.spacedBy(10.dp)
    ) {
        item {
            ReportHeaderCard(
                title = if (isBangla) "করযে হাসানা ও কিস্তি আদায় বিবরণী" else "Qard Hasan & Collection Statement",
                subtitle = if (isBangla) "মোট বিতরণ: ${CurrencyFormatter.formatBDT(totalDisbursed, toBanglaDigits = true)} | আদায়: ${CurrencyFormatter.formatBDT(totalRepaid, toBanglaDigits = true)} | বকেয়া: ${CurrencyFormatter.formatBDT(totalDue, toBanglaDigits = true)}"
                else "Total Disbursed: ${CurrencyFormatter.formatBDT(totalDisbursed, toBanglaDigits = false)} | Repaid: ${CurrencyFormatter.formatBDT(totalRepaid, toBanglaDigits = false)} | Outstanding: ${CurrencyFormatter.formatBDT(totalDue, toBanglaDigits = false)}"
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
                        Text(loan.memberName, style = MaterialTheme.typography.titleSmall, fontWeight = FontWeight.Bold, color = MaterialTheme.colorScheme.onSurface)
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
fun MemberLedgerReportPreview(
    members: List<Member>,
    isBangla: Boolean = true,
    modifier: Modifier = Modifier
) {
    val totalContributed = safeRound(members.sumOf { safeRound(it.totalContributed) })
    val totalDues = safeRound(members.sumOf { safeRound(it.outstandingDues) })

    LazyColumn(
        modifier = modifier.fillMaxSize(),
        contentPadding = PaddingValues(16.dp),
        verticalArrangement = Arrangement.spacedBy(10.dp)
    ) {
        item {
            ReportHeaderCard(
                title = if (isBangla) "সদস্য চাঁদা ও সঞ্চয় লেজার বিবরণী" else "Member Savings & Contribution Ledger",
                subtitle = if (isBangla) "মোট সদস্য: ${members.size} জন | মোট সঞ্চয়: ${CurrencyFormatter.formatBDT(totalContributed, toBanglaDigits = true)} | বকেয়া: ${CurrencyFormatter.formatBDT(totalDues, toBanglaDigits = true)}"
                else "Total Members: ${members.size} | Total Savings: ${CurrencyFormatter.formatBDT(totalContributed, toBanglaDigits = false)} | Dues: ${CurrencyFormatter.formatBDT(totalDues, toBanglaDigits = false)}"
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
                        Text(member.name, style = MaterialTheme.typography.titleSmall, fontWeight = FontWeight.Bold, color = MaterialTheme.colorScheme.onSurface)
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
