package com.helptrickbd.myapplicationsomithierp.presentation.screens.admin.components

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Close
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp

@Composable
fun CreateFundSection3Terms(
    isBangla: Boolean,
    terms: List<String>,
    onTermsChange: (List<String>) -> Unit
) {
    SectionHeader(title = if (isBangla) "সমিতির শর্তাবলী" else "Terms & Conditions")

    Text(
        text = if (isBangla) "মাদ্রাসার নিয়ম অনুযায়ী শর্তাবলী যোগ বা সম্পাদনা করুন"
        else "Add or edit terms according to Madrasha rules",
        style = MaterialTheme.typography.bodySmall,
        color = MaterialTheme.colorScheme.onSurfaceVariant
    )

    terms.forEachIndexed { index, term ->
        TermRow(
            term = term,
            index = index,
            isBangla = isBangla,
            onTermChange = { newVal ->
                val updated = terms.toMutableList().also { it[index] = newVal }
                onTermsChange(updated)
            },
            onRemove = {
                onTermsChange(terms.toMutableList().also { it.removeAt(index) })
            }
        )
    }

    OutlinedButton(
        onClick = { onTermsChange(terms + "") },
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(12.dp)
    ) {
        Icon(
            imageVector = Icons.Default.Add,
            contentDescription = null,
            modifier = Modifier.size(18.dp)
        )
        Spacer(modifier = Modifier.width(6.dp))
        Text(
            text = if (isBangla) "নতুন শর্ত যোগ করুন" else "Add New Term",
            fontWeight = FontWeight.Medium
        )
    }
}

@Composable
private fun TermRow(
    term: String,
    index: Int,
    isBangla: Boolean,
    onTermChange: (String) -> Unit,
    onRemove: () -> Unit
) {
    Row(
        verticalAlignment = Alignment.Top,
        horizontalArrangement = Arrangement.spacedBy(6.dp)
    ) {
        OutlinedTextField(
            value = term,
            onValueChange = onTermChange,
            label = { Text("${if (isBangla) "শর্ত" else "Term"} ${index + 1}") },
            minLines = 1, maxLines = 3,
            modifier = Modifier.weight(1f),
            shape = RoundedCornerShape(12.dp)
        )
        IconButton(
            onClick = onRemove,
            modifier = Modifier.padding(top = 4.dp)
        ) {
            Icon(
                imageVector = Icons.Default.Close,
                contentDescription = if (isBangla) "সরিয়ে দিন" else "Remove",
                tint = MaterialTheme.colorScheme.error
            )
        }
    }
}
