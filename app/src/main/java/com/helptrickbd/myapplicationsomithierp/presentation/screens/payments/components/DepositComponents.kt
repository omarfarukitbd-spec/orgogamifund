package com.helptrickbd.myapplicationsomithierp.presentation.screens.payments.components

import android.content.ClipData
import android.content.ClipboardManager
import android.content.Context
import android.widget.Toast
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ContentCopy
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.helptrickbd.myapplicationsomithierp.domain.model.Branch

@Composable
fun AccountCopyRow(
    label: String,
    accountNumber: String,
    clipboard: ClipboardManager,
    context: Context,
    isBangla: Boolean
) {
    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically
    ) {
        Column {
            Text(
                text = label,
                style = MaterialTheme.typography.labelSmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
            Text(
                text = accountNumber,
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.Bold,
                color = MaterialTheme.colorScheme.onSurface
            )
        }
        OutlinedButton(
            onClick = {
                clipboard.setPrimaryClip(ClipData.newPlainText("accountNumber", accountNumber))
                Toast.makeText(
                    context,
                    if (isBangla) "নম্বর কপি হয়েছে" else "Copied to clipboard",
                    Toast.LENGTH_SHORT
                ).show()
            },
            shape = RoundedCornerShape(10.dp)
        ) {
            Icon(
                imageVector = Icons.Default.ContentCopy,
                contentDescription = null,
                modifier = Modifier.size(14.dp)
            )
            Spacer(modifier = Modifier.width(4.dp))
            Text(if (isBangla) "কপি" else "Copy")
        }
    }
}

@Composable
fun DepositAccountDetailsCard(
    selectedTab: Int,
    branch: Branch,
    clipboardManager: ClipboardManager,
    context: Context,
    isBangla: Boolean,
    modifier: Modifier = Modifier
) {
    Card(
        modifier = modifier.fillMaxWidth(),
        shape = RoundedCornerShape(16.dp),
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface),
        elevation = CardDefaults.cardElevation(defaultElevation = 1.dp)
    ) {
        Column(
            modifier = Modifier.padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(10.dp)
        ) {
            when (selectedTab) {
                0 -> AccountCopyRow(
                    label = if (isBangla) "ফান্ডের বিকাশ নম্বর" else "Somithi bKash Number",
                    accountNumber = branch.bkashNumber.ifEmpty { "01824797072" },
                    clipboard = clipboardManager,
                    context = context,
                    isBangla = isBangla
                )
                1 -> AccountCopyRow(
                    label = if (isBangla) "ফান্ডের নগদ নম্বর" else "Somithi Nagad Number",
                    accountNumber = branch.nagadNumber.ifEmpty { "01824797072" },
                    clipboard = clipboardManager,
                    context = context,
                    isBangla = isBangla
                )
                2 -> {
                    val bank = branch.bankDetails
                    Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
                        Text(
                            text = "${bank.bankName} - ${bank.branchName}",
                            style = MaterialTheme.typography.bodyMedium,
                            fontWeight = FontWeight.Bold,
                            color = MaterialTheme.colorScheme.primary
                        )
                        Text(
                            text = if (isBangla) "অ্যাকাউন্টের নাম: ${bank.accountName}" else "Account Name: ${bank.accountName}",
                            style = MaterialTheme.typography.labelSmall,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                        AccountCopyRow(
                            label = if (isBangla) "অ্যাকাউন্ট নম্বর" else "Account Number",
                            accountNumber = bank.accountNumber,
                            clipboard = clipboardManager,
                            context = context,
                            isBangla = isBangla
                        )
                        Text(
                            text = if (isBangla) "রাউটিং নম্বর: ${bank.routingNumber}" else "Routing No: ${bank.routingNumber}",
                            style = MaterialTheme.typography.labelSmall,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }
                }
            }

            Text(
                text = if (isBangla) "টাকা পাঠিয়ে প্রাপ্ত ট্রানজেকশন আইডি নিচে লিখে সাবমিট করুন।"
                else "Send money and submit the Transaction ID below.",
                style = MaterialTheme.typography.labelSmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
        }
    }
}

@Composable
fun DepositSuccessDialog(
    isBangla: Boolean,
    onDismiss: () -> Unit
) {
    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text(if (isBangla) "জমা সফলভাবে পাঠানো হয়েছে" else "Deposit Submitted Successfully") },
        text = {
            Text(
                text = if (isBangla) "আপনার জমাটি সফলভাবে সাবমিট হয়েছে। এডমিন ট্রানজেকশন যাচাই করে অনুমোদন করলেই এটি ব্যালেন্সে যুক্ত হবে।"
                else "Your deposit has been submitted. Once verified and approved by admin, it will reflect in your account balance."
            )
        },
        confirmButton = {
            TextButton(onClick = onDismiss) {
                Text(if (isBangla) "ঠিক আছে" else "OK")
            }
        }
    )
}
