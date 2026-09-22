package com.helptrickbd.myapplicationsomithierp.presentation.screens.admin

import android.widget.Toast
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalConfiguration
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import com.helptrickbd.myapplicationsomithierp.core.data.FirestoreWriteManager
import com.helptrickbd.myapplicationsomithierp.domain.model.BankAccountDetails
import com.helptrickbd.myapplicationsomithierp.domain.model.Branch
import com.helptrickbd.myapplicationsomithierp.domain.model.SomithiPermissions

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun CreateSomithiFundScreen(
    onNavigateBack: () -> Unit = {}
) {
    val context = LocalContext.current
    val isBangla = LocalConfiguration.current.locales[0].language == "bn"

    var nameText by remember { mutableStateOf("") }
    var descText by remember { mutableStateOf("") }
    var monthlyAmountText by remember { mutableStateOf("1000") }
    var bkashNumberText by remember { mutableStateOf("") }
    var nagadNumberText by remember { mutableStateOf("") }
    var bankNameText by remember { mutableStateOf("Islami Bank Bangladesh PLC") }
    var bankAccNumberText by remember { mutableStateOf("") }
    var bankBranchText by remember { mutableStateOf("") }

    var allowViewTotalFund by remember { mutableStateOf(true) }
    var allowViewExpenses by remember { mutableStateOf(true) }
    var allowViewAllMembers by remember { mutableStateOf(true) }
    var isSubmitting by remember { mutableStateOf(false) }

    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    Text(
                        text = if (isBangla) "নতুন সমিতি ফান্ড তৈরি করুন" else "Create Somithi Fund",
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
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(innerPadding)
                .verticalScroll(rememberScrollState())
                .padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(14.dp)
        ) {
            // Fund General Info
            Text(if (isBangla) "সমিতি ও ফান্ডের প্রাথমিক তথ্য" else "Fund Details", style = MaterialTheme.typography.titleSmall, fontWeight = FontWeight.Bold, color = MaterialTheme.colorScheme.primary)

            OutlinedTextField(
                value = nameText,
                onValueChange = { nameText = it },
                label = { Text(if (isBangla) "সমিতির নাম (যেমন: অগ্রগামী ফান্ড - দাখিল ব্যাচ ২০১৫)" else "Somithi Name") },
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(12.dp)
            )

            OutlinedTextField(
                value = descText,
                onValueChange = { descText = it },
                label = { Text(if (isBangla) "ফান্ডের উদ্দেশ্য ও সংক্ষিপ্ত পরিচিতি" else "Purpose & Description") },
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(12.dp)
            )

            OutlinedTextField(
                value = monthlyAmountText,
                onValueChange = { monthlyAmountText = it.filter { ch -> ch.isDigit() } },
                label = { Text(if (isBangla) "বাধ্যতামূলক মাসিক চাঁদা (টাকা)" else "Monthly Deposit Amount (BDT)") },
                keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(12.dp)
            )

            HorizontalDivider(thickness = 0.5.dp, color = MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.5f))

            // Payment Accounts Info
            Text(if (isBangla) "টাকা জমার মোবাইল ব্যাংকিং ও ব্যাংক তথ্য" else "Payment Accounts Setup", style = MaterialTheme.typography.titleSmall, fontWeight = FontWeight.Bold, color = MaterialTheme.colorScheme.primary)

            OutlinedTextField(
                value = bkashNumberText,
                onValueChange = { bkashNumberText = it },
                label = { Text(if (isBangla) "ফান্ডের বিকাশ নম্বর" else "Fund bKash Number") },
                keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Phone),
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(12.dp)
            )

            OutlinedTextField(
                value = nagadNumberText,
                onValueChange = { nagadNumberText = it },
                label = { Text(if (isBangla) "ফান্ডের নগদ নম্বর" else "Fund Nagad Number") },
                keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Phone),
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(12.dp)
            )

            OutlinedTextField(
                value = bankNameText,
                onValueChange = { bankNameText = it },
                label = { Text(if (isBangla) "ব্যাংকের নাম" else "Bank Name") },
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(12.dp)
            )

            OutlinedTextField(
                value = bankAccNumberText,
                onValueChange = { bankAccNumberText = it },
                label = { Text(if (isBangla) "ব্যাংক একাউন্ট নম্বর" else "Bank Account Number") },
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(12.dp)
            )

            HorizontalDivider(thickness = 0.5.dp, color = MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.5f))

            // Permissions Toggles
            Text(if (isBangla) "সমিতি পারমিশন (মেম্বারদের দেখার অনুমতি)" else "Member View Permissions", style = MaterialTheme.typography.titleSmall, fontWeight = FontWeight.Bold, color = MaterialTheme.colorScheme.primary)

            PermissionToggleRow(
                title = if (isBangla) "মোট ফান্ডের ব্যালেন্স দেখার অনুমতি" else "Allow viewing total fund balance",
                checked = allowViewTotalFund,
                onCheckedChange = { allowViewTotalFund = it }
            )

            PermissionToggleRow(
                title = if (isBangla) "খরচের খাতা ও ভাউচার দেখার অনুমতি" else "Allow viewing expense register",
                checked = allowViewExpenses,
                onCheckedChange = { allowViewExpenses = it }
            )

            PermissionToggleRow(
                title = if (isBangla) "অন্যান্য সদস্যদের তালিকা দেখার অনুমতি" else "Allow viewing all members list",
                checked = allowViewAllMembers,
                onCheckedChange = { allowViewAllMembers = it }
            )

            Spacer(modifier = Modifier.height(10.dp))

            // Create Button
            val isValid = nameText.isNotBlank() && monthlyAmountText.isNotBlank()
            Button(
                onClick = {
                    if (!isValid) return@Button
                    isSubmitting = true
                    val branch = Branch(
                        name = nameText,
                        description = descText,
                        monthlyDepositAmount = monthlyAmountText.toDoubleOrNull() ?: 1000.0,
                        bkashNumber = bkashNumberText,
                        nagadNumber = nagadNumberText,
                        bankDetails = BankAccountDetails(
                            bankName = bankNameText,
                            accountName = nameText,
                            accountNumber = bankAccNumberText,
                            branchName = bankBranchText
                        ),
                        permissions = SomithiPermissions(
                            canMembersViewTotalFund = allowViewTotalFund,
                            canMembersViewExpenses = allowViewExpenses,
                            canMembersViewMemberList = allowViewAllMembers,
                            canMembersViewNotices = true
                        )
                    )
                    FirestoreWriteManager.createBranch(branch) { success ->
                        isSubmitting = false
                        if (success) {
                            Toast.makeText(context, if (isBangla) "সমিতি সফলভাবে তৈরি হয়েছে!" else "Somithi fund created!", Toast.LENGTH_SHORT).show()
                            onNavigateBack()
                        } else {
                            Toast.makeText(context, if (isBangla) "তৈরি ব্যর্থ হয়েছে" else "Failed to create", Toast.LENGTH_SHORT).show()
                        }
                    }
                },
                enabled = isValid && !isSubmitting,
                modifier = Modifier.fillMaxWidth().height(52.dp),
                shape = RoundedCornerShape(14.dp)
            ) {
                Text(
                    text = if (isSubmitting) (if (isBangla) "তৈরি হচ্ছে..." else "Creating...")
                    else (if (isBangla) "নতুন সমিতি ফান্ড তৈরি করুন" else "Create Somithi Fund"),
                    fontWeight = FontWeight.Bold
                )
            }
        }
    }
}

@Composable
private fun PermissionToggleRow(
    title: String,
    checked: Boolean,
    onCheckedChange: (Boolean) -> Unit
) {
    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically
    ) {
        Text(title, style = MaterialTheme.typography.bodyMedium, color = MaterialTheme.colorScheme.onSurface, modifier = Modifier.weight(1f))
        Switch(checked = checked, onCheckedChange = onCheckedChange)
    }
}
