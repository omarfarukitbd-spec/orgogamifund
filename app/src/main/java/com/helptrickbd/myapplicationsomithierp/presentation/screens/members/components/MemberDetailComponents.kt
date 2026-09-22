package com.helptrickbd.myapplicationsomithierp.presentation.screens.members.components

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ExitToApp
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.helptrickbd.myapplicationsomithierp.core.util.CurrencyFormatter
import com.helptrickbd.myapplicationsomithierp.core.util.safeRound
import com.helptrickbd.myapplicationsomithierp.domain.model.Member
import com.helptrickbd.myapplicationsomithierp.ui.theme.MoneyDueAmber
import com.helptrickbd.myapplicationsomithierp.ui.theme.MoneyExpenseRed
import com.helptrickbd.myapplicationsomithierp.ui.theme.MoneyIncomeGreen

@Composable
fun MemberExitSettlementDialog(
    member: Member,
    isBangla: Boolean,
    selectedPayoutMethod: String,
    onPayoutMethodChange: (String) -> Unit,
    settlementNote: String,
    onNoteChange: (String) -> Unit,
    onConfirmExit: (payoutMethod: String, note: String) -> Unit,
    onDismiss: () -> Unit
) {
    val safeContributed = safeRound(member.totalContributed)
    val safeDues = safeRound(member.outstandingDues)
    val safeLoans = safeRound(member.activeLoanBalance)
    val netSettlement = safeRound((safeContributed - safeDues - safeLoans).coerceAtLeast(0.0))

    AlertDialog(
        onDismissRequest = onDismiss,
        icon = {
            Icon(
                imageVector = Icons.AutoMirrored.Filled.ExitToApp,
                contentDescription = null,
                tint = MaterialTheme.colorScheme.error,
                modifier = Modifier.size(32.dp)
            )
        },
        title = {
            Text(
                text = if (isBangla) "চূড়ান্ত হিসাব নিষ্পত্তি ও পদত্যাগ" else "Final Settlement & Resignation",
                fontWeight = FontWeight.Bold,
                style = MaterialTheme.typography.titleMedium
            )
        },
        text = {
            Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                Text(
                    text = if (isBangla) "সদস্য: ${member.name}" else "Member: ${member.name}",
                    style = MaterialTheme.typography.bodyMedium,
                    fontWeight = FontWeight.Bold
                )
                HorizontalDivider()
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween
                ) {
                    Text(if (isBangla) "মোট সঞ্চয়/জমা:" else "Total Savings:", style = MaterialTheme.typography.bodySmall)
                    Text(CurrencyFormatter.formatBDT(safeContributed, toBanglaDigits = isBangla), style = MaterialTheme.typography.bodySmall, fontWeight = FontWeight.Bold, color = MoneyIncomeGreen)
                }
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween
                ) {
                    Text(if (isBangla) "কর্তন - বকেয়া চাঁদা:" else "Deduction - Dues:", style = MaterialTheme.typography.bodySmall)
                    Text("- ${CurrencyFormatter.formatBDT(safeDues, toBanglaDigits = isBangla)}", style = MaterialTheme.typography.bodySmall, fontWeight = FontWeight.Bold, color = MoneyDueAmber)
                }
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween
                ) {
                    Text(if (isBangla) "কর্তন - অনাদায়ী ঋণ:" else "Deduction - Loans:", style = MaterialTheme.typography.bodySmall)
                    Text("- ${CurrencyFormatter.formatBDT(safeLoans, toBanglaDigits = isBangla)}", style = MaterialTheme.typography.bodySmall, fontWeight = FontWeight.Bold, color = MoneyExpenseRed)
                }
                HorizontalDivider()
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween
                ) {
                    Text(if (isBangla) "চূড়ান্ত পরিশোধযোগ্য চেক/ক্যাশ:" else "Net Payable Cash/Cheque:", style = MaterialTheme.typography.bodyMedium, fontWeight = FontWeight.Bold)
                    Text(
                        CurrencyFormatter.formatBDT(netSettlement, toBanglaDigits = isBangla),
                        style = MaterialTheme.typography.titleSmall,
                        fontWeight = FontWeight.ExtraBold,
                        color = MaterialTheme.colorScheme.primary
                    )
                }

                if (netSettlement > 0.0) {
                    Text(
                        text = if (isBangla) "কথায়: ${CurrencyFormatter.formatInWords(netSettlement, isBangla = true)}" else "In Words: ${CurrencyFormatter.formatInWords(netSettlement, isBangla = false)}",
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.primary,
                        fontWeight = FontWeight.Medium
                    )
                }

                Spacer(modifier = Modifier.height(4.dp))
                Text(if (isBangla) "পরিশোধের মাধ্যম:" else "Payout Method:", style = MaterialTheme.typography.labelSmall)
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    listOf("Cash", "bKash", "Bank Transfer").forEach { method ->
                        FilterChip(
                            selected = selectedPayoutMethod == method,
                            onClick = { onPayoutMethodChange(method) },
                            label = { Text(method) }
                        )
                    }
                }

                OutlinedTextField(
                    value = settlementNote,
                    onValueChange = onNoteChange,
                    label = { Text(if (isBangla) "পদত্যাগের কারণ / মন্তব্য" else "Resignation Reason / Note") },
                    singleLine = true,
                    modifier = Modifier.fillMaxWidth()
                )
            }
        },
        confirmButton = {
            Button(
                onClick = { onConfirmExit(selectedPayoutMethod, settlementNote) },
                colors = ButtonDefaults.buttonColors(containerColor = MaterialTheme.colorScheme.error)
            ) {
                Text(if (isBangla) "নিষ্পত্তি নিশ্চিত করুন" else "Confirm Settlement")
            }
        },
        dismissButton = {
            TextButton(onClick = onDismiss) {
                Text(if (isBangla) "বাতিল" else "Cancel")
            }
        }
    )
}

@Composable
fun LedgerStatCard(
    title: String,
    amount: Double,
    color: Color,
    isBangla: Boolean = true,
    modifier: Modifier = Modifier
) {
    Card(
        modifier = modifier,
        shape = RoundedCornerShape(14.dp),
        colors = CardDefaults.cardColors(containerColor = color.copy(alpha = 0.08f))
    ) {
        Column(
            modifier = Modifier.padding(12.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Text(
                text = title,
                style = MaterialTheme.typography.labelSmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
            Spacer(modifier = Modifier.height(4.dp))
            Text(
                text = CurrencyFormatter.formatBDT(amount, toBanglaDigits = isBangla),
                style = MaterialTheme.typography.titleSmall,
                fontWeight = FontWeight.Bold,
                color = color
            )
        }
    }
}

@Composable
fun DetailRow(label: String, value: String) {
    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.SpaceBetween
    ) {
        Text(
            text = label,
            style = MaterialTheme.typography.bodyMedium,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )
        Text(
            text = value,
            style = MaterialTheme.typography.bodyMedium,
            fontWeight = FontWeight.Medium,
            color = MaterialTheme.colorScheme.onSurface
        )
    }
}
