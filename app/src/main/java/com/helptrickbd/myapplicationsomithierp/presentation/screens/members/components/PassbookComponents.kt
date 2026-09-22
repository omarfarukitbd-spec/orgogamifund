package com.helptrickbd.myapplicationsomithierp.presentation.screens.members.components

import android.content.Context
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Person
import androidx.compose.material.icons.filled.Print
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.helptrickbd.myapplicationsomithierp.core.pdf.PassbookPdfGenerator
import com.helptrickbd.myapplicationsomithierp.core.util.CurrencyFormatter
import com.helptrickbd.myapplicationsomithierp.domain.model.Member
import com.helptrickbd.myapplicationsomithierp.domain.model.Payment
import com.helptrickbd.myapplicationsomithierp.ui.theme.MoneyDueAmber
import com.helptrickbd.myapplicationsomithierp.ui.theme.MoneyExpenseRed
import com.helptrickbd.myapplicationsomithierp.ui.theme.MoneyIncomeGreen

@Composable
fun PassbookHeaderCard(
    member: Member,
    branchName: String,
    payments: List<Payment>,
    context: Context,
    isBangla: Boolean,
    modifier: Modifier = Modifier
) {
    Card(
        modifier = modifier.fillMaxWidth(),
        shape = RoundedCornerShape(20.dp),
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface),
        elevation = CardDefaults.cardElevation(defaultElevation = 2.dp)
    ) {
        Column(
            modifier = Modifier.padding(18.dp),
            verticalArrangement = Arrangement.spacedBy(14.dp)
        ) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Box(
                    modifier = Modifier
                        .size(54.dp)
                        .clip(CircleShape)
                        .background(MaterialTheme.colorScheme.primaryContainer),
                    contentAlignment = Alignment.Center
                ) {
                    Icon(
                        imageVector = Icons.Default.Person,
                        contentDescription = null,
                        tint = MaterialTheme.colorScheme.primary,
                        modifier = Modifier.size(30.dp)
                    )
                }

                Spacer(modifier = Modifier.width(14.dp))

                Column(modifier = Modifier.weight(1f)) {
                    Text(
                        text = member.name,
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.Bold,
                        color = MaterialTheme.colorScheme.onSurface
                    )
                    Text(
                        text = branchName,
                        style = MaterialTheme.typography.labelSmall,
                        color = MaterialTheme.colorScheme.primary
                    )
                    Text(
                        text = if (isBangla) "আইডি: #${member.id.take(8).uppercase()} • মোবাইল: ${member.phone}"
                        else "ID: #${member.id.take(8).uppercase()} • Phone: ${member.phone}",
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
            }

            Button(
                onClick = {
                    PassbookPdfGenerator.printPassbook(
                        context = context,
                        member = member,
                        branchName = branchName,
                        payments = payments
                    )
                },
                modifier = Modifier.fillMaxWidth().height(44.dp),
                shape = RoundedCornerShape(12.dp),
                colors = ButtonDefaults.buttonColors(containerColor = MaterialTheme.colorScheme.primary)
            ) {
                Icon(imageVector = Icons.Default.Print, contentDescription = null, modifier = Modifier.size(18.dp))
                Spacer(modifier = Modifier.width(8.dp))
                Text(
                    text = if (isBangla) "পাসবই স্টেটমেন্ট প্রিন্ট ও ডাউনলোড" else "Print Passbook Statement",
                    fontWeight = FontWeight.Bold,
                    fontSize = 13.sp
                )
            }
        }
    }
}

@Composable
fun PassbookSummaryRow(
    totalSavings: Double,
    dues: Double,
    loans: Double,
    pendingDepositsCount: Int,
    isBangla: Boolean,
    modifier: Modifier = Modifier
) {
    Row(
        modifier = modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.spacedBy(8.dp)
    ) {
        SummaryMiniCard(
            title = if (isBangla) "মোট জমা" else "Savings",
            amount = CurrencyFormatter.formatBDT(totalSavings, toBanglaDigits = isBangla),
            color = MoneyIncomeGreen,
            modifier = Modifier.weight(1f)
        )
        SummaryMiniCard(
            title = if (isBangla) "বকেয়া" else "Dues",
            amount = CurrencyFormatter.formatBDT(dues, toBanglaDigits = isBangla),
            color = MoneyDueAmber,
            modifier = Modifier.weight(1f)
        )
        SummaryMiniCard(
            title = if (isBangla) "চলতি ঋণ" else "Loans",
            amount = CurrencyFormatter.formatBDT(loans, toBanglaDigits = isBangla),
            color = MoneyExpenseRed,
            modifier = Modifier.weight(1f)
        )
        SummaryMiniCard(
            title = if (isBangla) "অপেক্ষমাণ" else "Pending",
            amount = if (isBangla) "$pendingDepositsCount টি" else "$pendingDepositsCount",
            color = Color(0xFF0284C7),
            modifier = Modifier.weight(1f)
        )
    }
}

@Composable
private fun SummaryMiniCard(
    title: String,
    amount: String,
    color: Color,
    modifier: Modifier = Modifier
) {
    Card(
        modifier = modifier,
        shape = RoundedCornerShape(14.dp),
        colors = CardDefaults.cardColors(containerColor = color.copy(alpha = 0.09f))
    ) {
        Column(
            modifier = Modifier.padding(vertical = 10.dp, horizontal = 6.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Text(
                text = title,
                style = MaterialTheme.typography.labelSmall.copy(fontSize = 10.sp),
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
            Spacer(modifier = Modifier.height(2.dp))
            Text(
                text = amount,
                style = MaterialTheme.typography.labelMedium.copy(fontSize = 12.sp),
                fontWeight = FontWeight.Bold,
                color = color,
                maxLines = 1
            )
        }
    }
}
