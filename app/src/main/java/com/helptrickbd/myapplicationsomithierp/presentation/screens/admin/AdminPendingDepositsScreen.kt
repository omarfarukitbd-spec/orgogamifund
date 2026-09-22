package com.helptrickbd.myapplicationsomithierp.presentation.screens.admin

import android.content.ClipData
import android.content.ClipboardManager
import android.content.Context
import android.widget.Toast
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.ContentCopy
import androidx.compose.material.icons.filled.Payments
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalConfiguration
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.helptrickbd.myapplicationsomithierp.core.data.FirestoreWriteManager
import com.helptrickbd.myapplicationsomithierp.core.util.CurrencyFormatter
import com.helptrickbd.myapplicationsomithierp.domain.model.ApprovalStatus
import com.helptrickbd.myapplicationsomithierp.domain.model.Payment
import com.helptrickbd.myapplicationsomithierp.ui.theme.MoneyExpenseRed
import com.helptrickbd.myapplicationsomithierp.ui.theme.MoneyIncomeGreen
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun AdminPendingDepositsScreen(
    payments: List<Payment>,
    onNavigateBack: () -> Unit = {}
) {
    val context = LocalContext.current
    val isBangla = LocalConfiguration.current.locales[0].language == "bn"
    val clipboardManager = remember { context.getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager }

    val pendingDeposits = remember(payments) {
        payments.filter { it.approvalStatus == ApprovalStatus.PENDING }
    }

    var selectedForReject by remember { mutableStateOf<Payment?>(null) }
    var rejectReason by remember { mutableStateOf("") }

    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    Text(
                        text = if (isBangla) "অপেক্ষমাণ জমা যাচাই ও অনুমোদন" else "Pending Deposit Approvals",
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
        }
    ) { innerPadding ->
        if (pendingDeposits.isEmpty()) {
            Box(
                modifier = Modifier.fillMaxSize().padding(innerPadding),
                contentAlignment = Alignment.Center
            ) {
                Text(
                    text = if (isBangla) "কোনো অপেক্ষমাণ জমা নেই। সকল জমা অনুমোদিত!" else "No pending deposits to verify.",
                    style = MaterialTheme.typography.bodyLarge,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
        } else {
            LazyColumn(
                modifier = Modifier.fillMaxSize().padding(innerPadding),
                contentPadding = PaddingValues(16.dp),
                verticalArrangement = Arrangement.spacedBy(14.dp)
            ) {
                items(pendingDeposits) { payment ->
                    PendingDepositCard(
                        payment = payment,
                        clipboard = clipboardManager,
                        context = context,
                        isBangla = isBangla,
                        onApprove = {
                            val receiptNo = "REC-${SimpleDateFormat("yyyyMM", Locale.US).format(Date())}-${(1000..9999).random()}"
                            FirestoreWriteManager.approveDeposit(payment, receiptNo) { success ->
                                Toast.makeText(
                                    context,
                                    if (success) (if (isBangla) "জমা অনুমোদিত হয়েছে! রসিদ: $receiptNo" else "Approved! Receipt: $receiptNo")
                                    else (if (isBangla) "অনুমোদন ব্যর্থ হয়েছে" else "Approval failed"),
                                    Toast.LENGTH_SHORT
                                ).show()
                            }
                        },
                        onReject = { selectedForReject = payment }
                    )
                }
            }
        }
    }

    // Rejection Reason Dialog
    if (selectedForReject != null) {
        AlertDialog(
            onDismissRequest = { selectedForReject = null; rejectReason = "" },
            title = { Text(if (isBangla) "জমা বাতিলের কারণ" else "Reason for Rejection") },
            text = {
                OutlinedTextField(
                    value = rejectReason,
                    onValueChange = { rejectReason = it },
                    label = { Text(if (isBangla) "কারণ লিখুন (যেমন: ভুল TrxID)" else "Enter reason (e.g. Invalid TrxID)") },
                    modifier = Modifier.fillMaxWidth()
                )
            },
            confirmButton = {
                Button(
                    onClick = {
                        val payment = selectedForReject ?: return@Button
                        FirestoreWriteManager.rejectDeposit(payment.id, rejectReason.ifBlank { "TrxID invalid" }) {
                            Toast.makeText(context, if (isBangla) "জমা বাতিল করা হয়েছে" else "Deposit rejected", Toast.LENGTH_SHORT).show()
                            selectedForReject = null
                            rejectReason = ""
                        }
                    },
                    colors = ButtonDefaults.buttonColors(containerColor = MaterialTheme.colorScheme.error)
                ) {
                    Text(if (isBangla) "বাতিল নিশ্চিত করুন" else "Confirm Rejection")
                }
            },
            dismissButton = {
                TextButton(onClick = { selectedForReject = null; rejectReason = "" }) {
                    Text(if (isBangla) "ফিরে যান" else "Cancel")
                }
            }
        )
    }
}

@Composable
private fun PendingDepositCard(
    payment: Payment,
    clipboard: ClipboardManager,
    context: Context,
    isBangla: Boolean,
    onApprove: () -> Unit,
    onReject: () -> Unit
) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(16.dp),
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface),
        elevation = CardDefaults.cardElevation(defaultElevation = 2.dp)
    ) {
        Column(
            modifier = Modifier.padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(10.dp)
        ) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    Surface(shape = CircleShape, color = MaterialTheme.colorScheme.primaryContainer, modifier = Modifier.size(36.dp)) {
                        Box(contentAlignment = Alignment.Center) {
                            Icon(Icons.Default.Payments, contentDescription = null, tint = MaterialTheme.colorScheme.primary, modifier = Modifier.size(20.dp))
                        }
                    }
                    Column {
                        Text(payment.memberName.ifEmpty { payment.memberId }, style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold)
                        Text("${payment.forMonth} ${payment.forYear}", style = MaterialTheme.typography.labelSmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
                    }
                }

                Text(
                    text = CurrencyFormatter.formatBDT(payment.amount, toBanglaDigits = isBangla),
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.Bold,
                    color = MoneyIncomeGreen
                )
            }

            HorizontalDivider(thickness = 0.5.dp, color = MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.5f))

            // Method & TrxID Row with 1-Tap Copy
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Column {
                    Text(
                        text = if (isBangla) "পদ্ধতি: ${payment.method}" else "Method: ${payment.method}",
                        style = MaterialTheme.typography.labelMedium,
                        fontWeight = FontWeight.SemiBold
                    )
                    Text(
                        text = "TrxID: ${payment.transactionId.ifEmpty { "N/A" }}",
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.primary,
                        fontWeight = FontWeight.Bold
                    )
                }

                if (payment.transactionId.isNotBlank()) {
                    OutlinedButton(
                        onClick = {
                            clipboard.setPrimaryClip(ClipData.newPlainText("TrxID", payment.transactionId))
                            Toast.makeText(context, if (isBangla) "TrxID কপি হয়েছে" else "TrxID Copied", Toast.LENGTH_SHORT).show()
                        },
                        shape = RoundedCornerShape(8.dp),
                        contentPadding = PaddingValues(horizontal = 8.dp, vertical = 4.dp)
                    ) {
                        Icon(Icons.Default.ContentCopy, contentDescription = null, modifier = Modifier.size(12.dp))
                        Spacer(modifier = Modifier.width(4.dp))
                        Text(if (isBangla) "কপি" else "Copy", fontSize = 11.sp)
                    }
                }
            }

            if (payment.purposeNote.isNotBlank()) {
                Text(
                    text = if (isBangla) "নোট: ${payment.purposeNote}" else "Note: ${payment.purposeNote}",
                    style = MaterialTheme.typography.labelSmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }

            // Action Buttons
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(10.dp)
            ) {
                OutlinedButton(
                    onClick = onReject,
                    modifier = Modifier.weight(1f),
                    shape = RoundedCornerShape(10.dp),
                    colors = ButtonDefaults.outlinedButtonColors(contentColor = MoneyExpenseRed)
                ) {
                    Icon(Icons.Default.Close, contentDescription = null, modifier = Modifier.size(16.dp))
                    Spacer(modifier = Modifier.width(4.dp))
                    Text(if (isBangla) "বাতিল" else "Reject")
                }

                Button(
                    onClick = onApprove,
                    modifier = Modifier.weight(1f),
                    shape = RoundedCornerShape(10.dp),
                    colors = ButtonDefaults.buttonColors(containerColor = MoneyIncomeGreen)
                ) {
                    Icon(Icons.Default.Check, contentDescription = null, modifier = Modifier.size(16.dp))
                    Spacer(modifier = Modifier.width(4.dp))
                    Text(if (isBangla) "অনুমোদন" else "Approve")
                }
            }
        }
    }
}
