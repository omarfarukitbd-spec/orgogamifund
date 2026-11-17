package com.helptrickbd.myapplicationsomithierp.presentation.screens.governance.components

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.helptrickbd.myapplicationsomithierp.domain.model.MemberApplication
import com.helptrickbd.myapplicationsomithierp.ui.theme.MoneyExpenseRed

@Composable
fun RejectApplicationDialog(
    application: MemberApplication,
    rejectionReason: String,
    onReasonChange: (String) -> Unit,
    isBangla: Boolean,
    onConfirmReject: () -> Unit,
    onDismiss: () -> Unit
) {
    AlertDialog(
        onDismissRequest = onDismiss,
        title = {
            Text(
                text = if (isBangla) "আবেদন বাতিল নিশ্চিতকরণ" else "Confirm Application Rejection",
                fontWeight = FontWeight.Bold,
                color = MaterialTheme.colorScheme.onSurface
            )
        },
        text = {
            Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
                Text(
                    text = if (isBangla)
                        "${application.applicantName}-এর সদস্য হওয়ার আবেদন বাতিল করতে চান?"
                    else
                        "Do you want to reject the membership application of ${application.applicantName}?",
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
                OutlinedTextField(
                    value = rejectionReason,
                    onValueChange = onReasonChange,
                    label = { Text(if (isBangla) "বাতিলের কারণ" else "Reason for rejection") },
                    modifier = Modifier.fillMaxWidth(),
                    shape = RoundedCornerShape(10.dp)
                )
            }
        },
        confirmButton = {
            Button(
                onClick = onConfirmReject,
                colors = ButtonDefaults.buttonColors(containerColor = MoneyExpenseRed)
            ) {
                Text(if (isBangla) "বাতিল করুন" else "Reject")
            }
        },
        dismissButton = {
            TextButton(onClick = onDismiss) {
                Text(if (isBangla) "ফিরে যান" else "Cancel")
            }
        }
    )
}
