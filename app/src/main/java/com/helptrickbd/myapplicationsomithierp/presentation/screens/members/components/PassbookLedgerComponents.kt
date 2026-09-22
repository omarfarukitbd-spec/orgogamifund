package com.helptrickbd.myapplicationsomithierp.presentation.screens.members.components

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.HourglassEmpty
import androidx.compose.material.icons.filled.Print
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.helptrickbd.myapplicationsomithierp.core.util.CurrencyFormatter
import com.helptrickbd.myapplicationsomithierp.domain.model.ApprovalStatus
import com.helptrickbd.myapplicationsomithierp.domain.model.Payment
import com.helptrickbd.myapplicationsomithierp.ui.theme.MoneyDueAmber
import com.helptrickbd.myapplicationsomithierp.ui.theme.MoneyIncomeGreen
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

@Composable
fun PassbookMonthlyMatrix(
    year: Int,
    payments: List<Payment>,
    isBangla: Boolean,
    onReceiptClick: (Payment) -> Unit,
    modifier: Modifier = Modifier
) {
    val monthNames = remember(isBangla) {
        if (isBangla) listOf("জানুয়ারি", "ফেব্রুয়ারি", "মার্চ", "এপ্রিল", "মে", "জুন", "জুলাই", "আগস্ট", "সেপ্টেম্বর", "অক্টোবর", "নভেম্বর", "ডিসেম্বর")
        else listOf("Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec")
    }

    Card(
        modifier = modifier.fillMaxWidth(),
        shape = RoundedCornerShape(18.dp),
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface),
        elevation = CardDefaults.cardElevation(defaultElevation = 1.dp)
    ) {
        Column(modifier = Modifier.padding(14.dp), verticalArrangement = Arrangement.spacedBy(10.dp)) {
            Text(
                text = if (isBangla) "$year সালের ১২ মাসের জমার অবস্থা" else "Contribution Tracker for $year",
                style = MaterialTheme.typography.labelLarge,
                fontWeight = FontWeight.Bold,
                color = MaterialTheme.colorScheme.primary
            )

            for (row in 0..3) {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    for (col in 0..2) {
                        val index = row * 3 + col
                        val month = monthNames[index]
                        val match = payments.find {
                            (it.forMonth.contains(month, ignoreCase = true) || it.forMonth.contains(monthNames[index], ignoreCase = true)) &&
                            it.forYear == year
                        }

                        MonthStatusChip(
                            month = month,
                            payment = match,
                            isBangla = isBangla,
                            onClick = { match?.let { onReceiptClick(it) } },
                            modifier = Modifier.weight(1f)
                        )
                    }
                }
            }
        }
    }
}

@Composable
private fun MonthStatusChip(
    month: String,
    payment: Payment?,
    isBangla: Boolean,
    onClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    val isApproved = payment?.approvalStatus == ApprovalStatus.APPROVED
    val isPending = payment?.approvalStatus == ApprovalStatus.PENDING

    val bgColor = when {
        isApproved -> MoneyIncomeGreen.copy(alpha = 0.12f)
        isPending -> MoneyDueAmber.copy(alpha = 0.15f)
        else -> MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.4f)
    }
    val contentColor = when {
        isApproved -> MoneyIncomeGreen
        isPending -> MoneyDueAmber
        else -> MaterialTheme.colorScheme.onSurfaceVariant
    }

    Surface(
        modifier = modifier
            .clip(RoundedCornerShape(10.dp))
            .clickable(enabled = payment != null, onClick = onClick),
        shape = RoundedCornerShape(10.dp),
        color = bgColor,
        border = if (isApproved || isPending) BorderStroke(1.dp, contentColor.copy(alpha = 0.4f)) else null
    ) {
        Column(
            modifier = Modifier.padding(vertical = 8.dp, horizontal = 6.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Text(text = month, style = MaterialTheme.typography.labelMedium, fontWeight = FontWeight.Bold, color = MaterialTheme.colorScheme.onSurface)
            Spacer(modifier = Modifier.height(2.dp))
            when {
                isApproved -> Row(verticalAlignment = Alignment.CenterVertically) {
                    Icon(imageVector = Icons.Default.Check, contentDescription = null, tint = contentColor, modifier = Modifier.size(11.dp))
                    Spacer(modifier = Modifier.width(2.dp))
                    Text(text = if (isBangla) "পরিশোধিত" else "Paid", style = MaterialTheme.typography.labelSmall.copy(fontSize = 9.sp), color = contentColor, fontWeight = FontWeight.Bold)
                }
                isPending -> Row(verticalAlignment = Alignment.CenterVertically) {
                    Icon(imageVector = Icons.Default.HourglassEmpty, contentDescription = null, tint = contentColor, modifier = Modifier.size(11.dp))
                    Spacer(modifier = Modifier.width(2.dp))
                    Text(text = if (isBangla) "যাচাইাধীন" else "Pending", style = MaterialTheme.typography.labelSmall.copy(fontSize = 9.sp), color = contentColor, fontWeight = FontWeight.Bold)
                }
                else -> Text(text = if (isBangla) "বাকি / আসন্ন" else "Unpaid", style = MaterialTheme.typography.labelSmall.copy(fontSize = 9.sp), color = contentColor)
            }
        }
    }
}

@Composable
fun PassbookLedgerItem(
    payment: Payment,
    isBangla: Boolean,
    onPrintReceipt: () -> Unit,
    modifier: Modifier = Modifier
) {
    val dateStr = SimpleDateFormat("dd MMM, yyyy", if (isBangla) Locale("bn", "BD") else Locale.ENGLISH).format(Date(payment.date))
    val isApproved = payment.approvalStatus == ApprovalStatus.APPROVED

    Card(
        modifier = modifier.fillMaxWidth(),
        shape = RoundedCornerShape(14.dp),
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface),
        elevation = CardDefaults.cardElevation(defaultElevation = 1.dp)
    ) {
        Column(modifier = Modifier.padding(14.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Column {
                    Text(
                        text = "${payment.forMonth}, ${payment.forYear}",
                        style = MaterialTheme.typography.titleSmall,
                        fontWeight = FontWeight.Bold,
                        color = MaterialTheme.colorScheme.onSurface
                    )
                    Text(
                        text = "$dateStr • ${payment.method}" + (if (payment.transactionId.isNotBlank()) " • TrxID: ${payment.transactionId}" else ""),
                        style = MaterialTheme.typography.bodySmall.copy(fontSize = 11.sp),
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }

                Text(
                    text = "+ ${CurrencyFormatter.formatBDT(payment.amount, toBanglaDigits = isBangla)}",
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.Bold,
                    color = if (isApproved) MoneyIncomeGreen else MoneyDueAmber
                )
            }

            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Surface(
                    shape = RoundedCornerShape(6.dp),
                    color = if (isApproved) MoneyIncomeGreen.copy(alpha = 0.12f) else MoneyDueAmber.copy(alpha = 0.14f)
                ) {
                    Text(
                        text = if (isApproved) (if (isBangla) "অনুমোদিত" else "Approved") else (if (isBangla) "যাচাইাধীন" else "Pending Approval"),
                        style = MaterialTheme.typography.labelSmall.copy(fontSize = 10.sp),
                        color = if (isApproved) MoneyIncomeGreen else MoneyDueAmber,
                        fontWeight = FontWeight.Bold,
                        modifier = Modifier.padding(horizontal = 8.dp, vertical = 3.dp)
                    )
                }

                OutlinedButton(
                    onClick = onPrintReceipt,
                    shape = RoundedCornerShape(8.dp),
                    contentPadding = PaddingValues(horizontal = 10.dp, vertical = 4.dp)
                ) {
                    Icon(imageVector = Icons.Default.Print, contentDescription = null, modifier = Modifier.size(13.dp))
                    Spacer(modifier = Modifier.width(4.dp))
                    Text(text = if (isBangla) "রসিদ" else "Receipt", style = MaterialTheme.typography.labelSmall)
                }
            }
        }
    }
}
