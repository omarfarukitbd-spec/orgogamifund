package com.helptrickbd.myapplicationsomithierp.presentation.screens.admin.components

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp

@Composable
fun CreateFundSection2Payment(
    isBangla: Boolean,
    bkashText: String,
    onBkashChange: (String) -> Unit,
    nagadText: String,
    onNagadChange: (String) -> Unit,
    bankNameText: String,
    onBankNameChange: (String) -> Unit,
    bankAccText: String,
    onBankAccChange: (String) -> Unit,
    bankBranchText: String,
    onBankBranchChange: (String) -> Unit,
    routingText: String,
    onRoutingChange: (String) -> Unit
) {
    SectionHeader(title = if (isBangla) "মোবাইল ব্যাংকিং ও ব্যাংক তথ্য" else "Payment Accounts")

    Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
        OutlinedTextField(
            value = bkashText, onValueChange = onBkashChange,
            label = { Text(if (isBangla) "বিকাশ নম্বর" else "bKash Number") },
            keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Phone),
            modifier = Modifier.weight(1f), shape = RoundedCornerShape(12.dp)
        )
        OutlinedTextField(
            value = nagadText, onValueChange = onNagadChange,
            label = { Text(if (isBangla) "নগদ নম্বর" else "Nagad Number") },
            keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Phone),
            modifier = Modifier.weight(1f), shape = RoundedCornerShape(12.dp)
        )
    }

    OutlinedTextField(
        value = bankNameText, onValueChange = onBankNameChange,
        label = { Text(if (isBangla) "ব্যাংকের নাম" else "Bank Name") },
        modifier = Modifier.fillMaxWidth(), shape = RoundedCornerShape(12.dp)
    )

    Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
        OutlinedTextField(
            value = bankAccText, onValueChange = onBankAccChange,
            label = { Text(if (isBangla) "একাউন্ট নম্বর" else "Account Number") },
            keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
            modifier = Modifier.weight(1f), shape = RoundedCornerShape(12.dp)
        )
        OutlinedTextField(
            value = routingText, onValueChange = onRoutingChange,
            label = { Text(if (isBangla) "রাউটিং নম্বর" else "Routing No.") },
            keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
            modifier = Modifier.weight(1f), shape = RoundedCornerShape(12.dp)
        )
    }

    OutlinedTextField(
        value = bankBranchText, onValueChange = onBankBranchChange,
        label = { Text(if (isBangla) "ব্যাংক শাখার নাম" else "Bank Branch Name") },
        modifier = Modifier.fillMaxWidth(), shape = RoundedCornerShape(12.dp)
    )
}

@Composable
fun CreateFundSection2Permissions(
    isBangla: Boolean,
    allowViewTotalFund: Boolean,
    onTotalFundChange: (Boolean) -> Unit,
    allowViewExpenses: Boolean,
    onExpensesChange: (Boolean) -> Unit,
    allowViewMembers: Boolean,
    onMembersChange: (Boolean) -> Unit,
    allowViewNotices: Boolean,
    onNoticesChange: (Boolean) -> Unit,
    allowViewPaymentHistory: Boolean,
    onPaymentHistoryChange: (Boolean) -> Unit
) {
    SectionHeader(title = if (isBangla) "সদস্যদের দেখার পারমিশন (Admin নিয়ন্ত্রিত)" else "Member View Permissions")

    val items = listOf(
        Triple(
            if (isBangla) "মোট ফান্ডের ব্যালেন্স দেখতে পাবেন" else "View total fund balance",
            allowViewTotalFund, onTotalFundChange
        ),
        Triple(
            if (isBangla) "খরচের তালিকা ও ভাউচার দেখতে পাবেন" else "View expense register",
            allowViewExpenses, onExpensesChange
        ),
        Triple(
            if (isBangla) "অন্যান্য সদস্যদের তালিকা দেখতে পাবেন" else "View all members list",
            allowViewMembers, onMembersChange
        ),
        Triple(
            if (isBangla) "নোটিশ বোর্ড দেখতে পাবেন" else "View notice board",
            allowViewNotices, onNoticesChange
        ),
        Triple(
            if (isBangla) "প্রতিটি সদস্যের পেমেন্ট ইতিহাস দেখতে পাবেন (কে কত দিল)" else "View each member's payment history",
            allowViewPaymentHistory, onPaymentHistoryChange
        )
    )

    items.forEach { (title, checked, onChange) ->
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Text(
                text = title,
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurface,
                modifier = Modifier.weight(1f).padding(end = 8.dp)
            )
            Switch(checked = checked, onCheckedChange = onChange)
        }
    }
}
