package com.helptrickbd.myapplicationsomithierp.presentation.screens.governance.components

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.width
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.RadioButton
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.helptrickbd.myapplicationsomithierp.domain.model.Notice
import com.helptrickbd.myapplicationsomithierp.domain.model.NoticeScope
import com.helptrickbd.myapplicationsomithierp.domain.model.NoticeType

@Composable
fun AddNoticeDialog(
    isBangla: Boolean,
    onDismiss: () -> Unit,
    onConfirm: (Notice) -> Unit
) {
    var title by remember { mutableStateOf("") }
    var body by remember { mutableStateOf("") }
    var selectedType by remember { mutableStateOf(NoticeType.NOTICE) }
    val selectedScope = remember { NoticeScope.ORGANIZATION }

    AlertDialog(
        onDismissRequest = onDismiss,
        title = {
            Text(
                text = if (isBangla) "নতুন নোটিশ / সভার বিবরণী প্রকাশ" else "Publish Notice / Meeting Minutes",
                fontWeight = FontWeight.Bold,
                fontSize = 18.sp,
                color = MaterialTheme.colorScheme.onSurface
            )
        },
        text = {
            Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
                OutlinedTextField(
                    value = title,
                    onValueChange = { title = it },
                    label = { Text(if (isBangla) "নোটিশের শিরোনাম" else "Notice Title") },
                    modifier = Modifier.fillMaxWidth()
                )

                OutlinedTextField(
                    value = body,
                    onValueChange = { body = it },
                    label = { Text(if (isBangla) "বিস্তারিত বিবরণ" else "Detailed Description") },
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(120.dp),
                    maxLines = 5
                )

                Text(
                    text = if (isBangla) "ধরন নির্বাচন করুন:" else "Select Type:",
                    style = MaterialTheme.typography.labelMedium,
                    fontWeight = FontWeight.Bold,
                    color = MaterialTheme.colorScheme.onSurface
                )

                Row(verticalAlignment = Alignment.CenterVertically) {
                    RadioButton(
                        selected = selectedType == NoticeType.NOTICE,
                        onClick = { selectedType = NoticeType.NOTICE }
                    )
                    Text(if (isBangla) "সাধারণ নোটিশ" else "General Notice")
                    Spacer(modifier = Modifier.width(16.dp))
                    RadioButton(
                        selected = selectedType == NoticeType.MEETING_MINUTES,
                        onClick = { selectedType = NoticeType.MEETING_MINUTES }
                    )
                    Text(if (isBangla) "সভার বিবরণী" else "Meeting Minutes")
                }
            }
        },
        confirmButton = {
            TextButton(
                onClick = {
                    if (title.isNotBlank() && body.isNotBlank()) {
                        onConfirm(
                            Notice(
                                id = "not-${System.currentTimeMillis()}",
                                title = title.trim(),
                                body = body.trim(),
                                type = selectedType,
                                scope = selectedScope,
                                postedAt = System.currentTimeMillis()
                            )
                        )
                    }
                },
                enabled = title.isNotBlank() && body.isNotBlank()
            ) {
                Text(if (isBangla) "প্রকাশ করুন" else "Publish", fontWeight = FontWeight.Bold)
            }
        },
        dismissButton = {
            TextButton(onClick = onDismiss) {
                Text(if (isBangla) "বাতিল" else "Cancel")
            }
        }
    )
}
