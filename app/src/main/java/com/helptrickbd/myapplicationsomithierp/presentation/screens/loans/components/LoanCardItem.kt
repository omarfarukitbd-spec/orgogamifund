package com.helptrickbd.myapplicationsomithierp.presentation.screens.loans.components

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.Handshake
import androidx.compose.material.icons.filled.Payments
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.helptrickbd.myapplicationsomithierp.core.util.CurrencyFormatter
import com.helptrickbd.myapplicationsomithierp.domain.model.Loan
import com.helptrickbd.myapplicationsomithierp.domain.model.LoanStatus
import com.helptrickbd.myapplicationsomithierp.ui.theme.MoneyDueAmber
import com.helptrickbd.myapplicationsomithierp.ui.theme.MoneyExpenseRed
import com.helptrickbd.myapplicationsomithierp.ui.theme.MoneyIncomeGreen
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

@Composable
fun LoanCardItem(
    loan: Loan,
    isBangla: Boolean = true,
    onCollectInstallmentClick: () -> Unit
) {
    val dateFormat = remember(isBangla) {
        SimpleDateFormat("dd MMM, yyyy", if (isBangla) Locale("bn", "BD") else Locale.ENGLISH)
    }
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
                            imageVector = if (loan.status == LoanStatus.ACTIVE) Icons.Default.Handshake else Icons.Default.CheckCircle,
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
                            text = if (isBangla) "বিতরণ: $dateStr" else "Issued: $dateStr",
                            style = MaterialTheme.typography.labelSmall,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }
                }

                Surface(
                    shape = RoundedCornerShape(8.dp),
                    color = if (loan.status == LoanStatus.ACTIVE) MoneyDueAmber.copy(alpha = 0.15f) else MoneyIncomeGreen.copy(alpha = 0.15f)
                ) {
                    Text(
                        text = if (loan.status == LoanStatus.ACTIVE) (if (isBangla) "চলতি" else "Active") else (if (isBangla) "পরিশোধিত" else "Repaid"),
                        modifier = Modifier.padding(horizontal = 8.dp, vertical = 4.dp),
                        style = MaterialTheme.typography.labelSmall,
                        color = if (loan.status == LoanStatus.ACTIVE) MoneyDueAmber else MoneyIncomeGreen,
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
                    text = if (isBangla) "পরিশোধ: ${CurrencyFormatter.formatBDT(loan.totalRepaid, toBanglaDigits = true)}" else "Repaid: ${CurrencyFormatter.formatBDT(loan.totalRepaid, toBanglaDigits = false)}",
                    style = MaterialTheme.typography.labelSmall,
                    color = MoneyIncomeGreen,
                    fontWeight = FontWeight.Bold
                )
                Text(
                    text = if (isBangla) "মূল ঋণ: ${CurrencyFormatter.formatBDT(loan.totalPayable, toBanglaDigits = true)}" else "Principal: ${CurrencyFormatter.formatBDT(loan.totalPayable, toBanglaDigits = false)}",
                    style = MaterialTheme.typography.labelSmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
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
                        text = if (isBangla) "অবশিষ্ট দেনা" else "Remaining Balance",
                        style = MaterialTheme.typography.labelSmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
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
                        Text(if (isBangla) "কিস্তি জমা" else "Repay")
                    }
                }
            }
        }
    }
}
