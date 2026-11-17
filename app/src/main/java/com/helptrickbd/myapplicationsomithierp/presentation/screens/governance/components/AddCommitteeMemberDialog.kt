package com.helptrickbd.myapplicationsomithierp.presentation.screens.governance.components

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.helptrickbd.myapplicationsomithierp.domain.model.CommitteeMember

@Composable
fun AddCommitteeMemberDialog(
    isBangla: Boolean,
    onDismiss: () -> Unit,
    onConfirm: (CommitteeMember) -> Unit
) {
    var name by remember { mutableStateOf("") }
    var designation by remember { mutableStateOf(if (isBangla) "সভাপতি" else "President") }

    AlertDialog(
        onDismissRequest = onDismiss,
        title = {
            Text(
                text = if (isBangla) "নতুন কার্যনির্বাহী সদস্য যুক্ত করুন" else "Add Executive Committee Member",
                fontWeight = FontWeight.Bold,
                fontSize = 18.sp,
                color = MaterialTheme.colorScheme.onSurface
            )
        },
        text = {
            Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
                OutlinedTextField(
                    value = name,
                    onValueChange = { name = it },
                    label = { Text(if (isBangla) "সদস্যের নাম" else "Member Name") },
                    singleLine = true,
                    modifier = Modifier.fillMaxWidth()
                )

                OutlinedTextField(
                    value = designation,
                    onValueChange = { designation = it },
                    label = { Text(if (isBangla) "পদবী (উদা: সভাপতি, সাধারণ সম্পাদক, ক্যাশিয়ার)" else "Designation (e.g. President, Secretary, Cashier)") },
                    singleLine = true,
                    modifier = Modifier.fillMaxWidth()
                )
            }
        },
        confirmButton = {
            TextButton(
                onClick = {
                    if (name.isNotBlank() && designation.isNotBlank()) {
                        onConfirm(
                            CommitteeMember(
                                id = "cm-${System.currentTimeMillis()}",
                                memberName = name.trim(),
                                designation = designation.trim(),
                                termStart = System.currentTimeMillis()
                            )
                        )
                    }
                },
                enabled = name.isNotBlank() && designation.isNotBlank()
            ) {
                Text(if (isBangla) "যুক্ত করুন" else "Add Member", fontWeight = FontWeight.Bold)
            }
        },
        dismissButton = {
            TextButton(onClick = onDismiss) {
                Text(if (isBangla) "বাতিল" else "Cancel")
            }
        }
    )
}
