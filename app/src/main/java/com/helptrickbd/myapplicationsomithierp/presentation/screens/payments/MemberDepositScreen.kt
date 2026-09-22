package com.helptrickbd.myapplicationsomithierp.presentation.screens.payments

import android.content.ClipboardManager
import android.content.Context
import android.widget.Toast
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.ContentPaste
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.ExposedDropdownMenuBox
import androidx.compose.material3.ExposedDropdownMenuDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Tab
import androidx.compose.material3.TabRow
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.platform.LocalConfiguration
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.helptrickbd.myapplicationsomithierp.core.data.FirestoreWriteManager
import com.helptrickbd.myapplicationsomithierp.domain.model.ApprovalStatus
import com.helptrickbd.myapplicationsomithierp.domain.model.Branch
import com.helptrickbd.myapplicationsomithierp.domain.model.Payment
import com.helptrickbd.myapplicationsomithierp.domain.model.PaymentType
import com.helptrickbd.myapplicationsomithierp.presentation.screens.payments.components.DepositAccountDetailsCard
import com.helptrickbd.myapplicationsomithierp.presentation.screens.payments.components.DepositSuccessDialog

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun MemberDepositScreen(
    branch: Branch,
    memberId: String = "m-101",
    memberName: String = "সদস্য",
    onNavigateBack: () -> Unit = {}
) {
    val context = LocalContext.current
    val isBangla = LocalConfiguration.current.locales[0].language == "bn"
    val clipboardManager = remember { context.getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager }

    var selectedTab by remember { mutableIntStateOf(0) }
    var amountText by remember { mutableStateOf(branch.monthlyDepositAmount.toInt().toString()) }
    var trxIdText by remember { mutableStateOf("") }
    var noteText by remember { mutableStateOf("") }
    var showSuccessDialog by remember { mutableStateOf(false) }
    var isSubmitting by remember { mutableStateOf(false) }

    val months = remember(isBangla) {
        if (isBangla) listOf("জানুয়ারি", "ফেব্রুয়ারি", "মার্চ", "এপ্রিল", "মে", "জুন", "জুলাই", "আগস্ট", "সেপ্টেম্বর", "অক্টোবর", "নভেম্বর", "ডিসেম্বর")
        else listOf("January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December")
    }
    var selectedMonth by remember(isBangla) { mutableStateOf(months[0]) }
    var monthExpanded by remember { mutableStateOf(false) }

    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    Text(
                        text = if (isBangla) "টাকা জমা প্রদান" else "Deposit Contribution",
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.Bold
                    )
                },
                navigationIcon = {
                    IconButton(onClick = onNavigateBack) {
                        Icon(
                            imageVector = Icons.AutoMirrored.Filled.ArrowBack,
                            contentDescription = if (isBangla) "ফিরে যান" else "Back"
                        )
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
            TabRow(
                selectedTabIndex = selectedTab,
                modifier = Modifier.clip(RoundedCornerShape(12.dp)),
                containerColor = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.5f)
            ) {
                Tab(
                    selected = selectedTab == 0,
                    onClick = { selectedTab = 0 },
                    text = { Text(if (isBangla) "বিকাশ" else "bKash", fontWeight = FontWeight.Bold) }
                )
                Tab(
                    selected = selectedTab == 1,
                    onClick = { selectedTab = 1 },
                    text = { Text(if (isBangla) "নগদ" else "Nagad", fontWeight = FontWeight.Bold) }
                )
                Tab(
                    selected = selectedTab == 2,
                    onClick = { selectedTab = 2 },
                    text = { Text(if (isBangla) "ব্যাংক" else "Bank", fontWeight = FontWeight.Bold) }
                )
            }

            DepositAccountDetailsCard(
                selectedTab = selectedTab,
                branch = branch,
                clipboardManager = clipboardManager,
                context = context,
                isBangla = isBangla
            )

            OutlinedTextField(
                value = amountText,
                onValueChange = { amountText = it.filter { ch -> ch.isDigit() } },
                label = { Text(if (isBangla) "টাকার পরিমাণ" else "Amount (BDT)") },
                keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(12.dp)
            )

            ExposedDropdownMenuBox(
                expanded = monthExpanded,
                onExpandedChange = { monthExpanded = !monthExpanded }
            ) {
                OutlinedTextField(
                    value = selectedMonth,
                    onValueChange = {},
                    readOnly = true,
                    label = { Text(if (isBangla) "জমার মাস" else "Contribution Month") },
                    trailingIcon = { ExposedDropdownMenuDefaults.TrailingIcon(expanded = monthExpanded) },
                    modifier = Modifier.fillMaxWidth().menuAnchor(),
                    shape = RoundedCornerShape(12.dp)
                )
                ExposedDropdownMenu(
                    expanded = monthExpanded,
                    onDismissRequest = { monthExpanded = false }
                ) {
                    months.forEach { month ->
                        DropdownMenuItem(
                            text = { Text(month) },
                            onClick = { selectedMonth = month; monthExpanded = false }
                        )
                    }
                }
            }

            OutlinedTextField(
                value = trxIdText,
                onValueChange = { trxIdText = it.trim() },
                label = { Text(if (isBangla) "ট্রানজেকশন আইডি" else "Transaction ID") },
                trailingIcon = {
                    IconButton(
                        onClick = {
                            val clip = clipboardManager.primaryClip
                            if (clip != null && clip.itemCount > 0) {
                                trxIdText = clip.getItemAt(0).text.toString().trim()
                            }
                        }
                    ) {
                        Icon(
                            imageVector = Icons.Default.ContentPaste,
                            contentDescription = "Paste",
                            tint = MaterialTheme.colorScheme.primary
                        )
                    }
                },
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(12.dp)
            )

            OutlinedTextField(
                value = noteText,
                onValueChange = { noteText = it },
                label = { Text(if (isBangla) "মন্তব্য (ঐচ্ছিক)" else "Note (Optional)") },
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(12.dp)
            )

            val isValid = amountText.toDoubleOrNull() != null && amountText.toDoubleOrNull()!! > 0 && trxIdText.isNotBlank()
            Button(
                onClick = {
                    if (!isValid) return@Button
                    isSubmitting = true
                    val payment = Payment(
                        memberId = memberId,
                        memberName = memberName,
                        branchId = branch.id,
                        type = PaymentType.MONTHLY,
                        amount = amountText.toDouble(),
                        method = when (selectedTab) { 0 -> "bKash"; 1 -> "Nagad"; else -> "Bank Transfer" },
                        forMonth = selectedMonth,
                        forYear = 2026,
                        purposeNote = noteText,
                        transactionId = trxIdText,
                        approvalStatus = ApprovalStatus.PENDING
                    )
                    FirestoreWriteManager.submitMemberDeposit(payment) { success ->
                        isSubmitting = false
                        if (success) {
                            showSuccessDialog = true
                        } else {
                            Toast.makeText(context, if (isBangla) "জমা পাঠাতে ব্যর্থ হয়েছে" else "Failed to submit deposit", Toast.LENGTH_SHORT).show()
                        }
                    }
                },
                enabled = isValid && !isSubmitting,
                modifier = Modifier.fillMaxWidth().height(52.dp),
                shape = RoundedCornerShape(14.dp),
                colors = ButtonDefaults.buttonColors(containerColor = MaterialTheme.colorScheme.primary)
            ) {
                Text(
                    text = if (isSubmitting) (if (isBangla) "পাঠানো হচ্ছে..." else "Submitting...")
                    else (if (isBangla) "জমা নিশ্চিত করুন ও অনুমোদনে পাঠান" else "Submit Deposit for Approval"),
                    fontWeight = FontWeight.Bold,
                    fontSize = 15.sp
                )
            }
        }
    }

    if (showSuccessDialog) {
        DepositSuccessDialog(
            isBangla = isBangla,
            onDismiss = { showSuccessDialog = false; onNavigateBack() }
        )
    }
}
