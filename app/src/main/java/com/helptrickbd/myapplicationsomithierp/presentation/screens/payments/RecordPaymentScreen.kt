package com.helptrickbd.myapplicationsomithierp.presentation.screens.payments

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.automirrored.filled.Notes
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.MonetizationOn
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalConfiguration
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import com.helptrickbd.myapplicationsomithierp.core.util.safeRound
import com.helptrickbd.myapplicationsomithierp.domain.model.Member
import com.helptrickbd.myapplicationsomithierp.domain.model.Payment
import com.helptrickbd.myapplicationsomithierp.domain.model.PaymentType
import com.helptrickbd.myapplicationsomithierp.presentation.screens.payments.components.DuplicatePaymentWarningDialog
import com.helptrickbd.myapplicationsomithierp.presentation.screens.payments.components.MemberSelectorDropdown
import com.helptrickbd.myapplicationsomithierp.presentation.screens.payments.components.MonthYearSelectorRow
import com.helptrickbd.myapplicationsomithierp.presentation.screens.payments.components.PaymentAmountPreviewCard
import com.helptrickbd.myapplicationsomithierp.presentation.screens.payments.components.PaymentMethodSelectorDropdown
import com.helptrickbd.myapplicationsomithierp.presentation.screens.payments.components.PaymentReceiptSuccessDialog
import com.helptrickbd.myapplicationsomithierp.presentation.screens.payments.components.PaymentTypeSelectorDropdown
import com.helptrickbd.myapplicationsomithierp.ui.theme.MoneyIncomeGreen

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun RecordPaymentScreen(
    members: List<Member> = emptyList(),
    paymentMethods: List<String> = listOf("Cash", "bKash", "Bank Transfer"),
    onCheckDuplicate: suspend (memberId: String, type: PaymentType, month: String, year: Int) -> Payment? = { _, _, _, _ -> null },
    onConfirmSave: (Payment) -> Unit = {},
    onNavigateBack: () -> Unit = {}
) {
    val context = LocalContext.current
    val isBangla = LocalConfiguration.current.locales[0].language == "bn"

    var selectedMember by remember { mutableStateOf<Member?>(members.firstOrNull()) }
    var selectedType by remember { mutableStateOf(PaymentType.MONTHLY) }
    var amountText by remember { mutableStateOf("") }

    val months = remember(isBangla) {
        if (isBangla) listOf("জানুয়ারি", "ফেব্রুয়ারি", "মার্চ", "এপ্রিল", "মে", "জুন", "জুলাই", "আগস্ট", "সেপ্টেম্বর", "অক্টোবর", "নভেম্বর", "ডিসেম্বর")
        else listOf("January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December")
    }
    var selectedMonth by remember(isBangla) { mutableStateOf(months[1]) }
    var selectedYear by remember { mutableStateOf(2026) }
    var selectedMethod by remember { mutableStateOf(paymentMethods.firstOrNull() ?: "Cash") }
    var purposeNote by remember { mutableStateOf("") }

    // Duplicate Warning & Success Receipt State
    var showDuplicateWarningDialog by remember { mutableStateOf(false) }
    var duplicatePaymentFound by remember { mutableStateOf<Payment?>(null) }
    var savedPaymentForReceipt by remember { mutableStateOf<Payment?>(null) }

    val enteredAmount = amountText.toDoubleOrNull() ?: 0.0
    val isFormValid = selectedMember != null && enteredAmount > 0.0

    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    Text(
                        text = if (isBangla) "চাঁদা / কিস্তি জমা গ্রহণ" else "Record Contribution / Payment",
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
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            // 1. Member Selector Dropdown
            MemberSelectorDropdown(
                members = members,
                selectedMember = selectedMember,
                onMemberSelected = { selectedMember = it },
                isBangla = isBangla
            )

            // 2. Payment Type Dropdown
            PaymentTypeSelectorDropdown(
                selectedType = selectedType,
                onTypeSelected = { selectedType = it }
            )

            // 3. Amount Field
            OutlinedTextField(
                value = amountText,
                onValueChange = { amountText = it },
                label = { Text(if (isBangla) "জমার পরিমাণ (টাকা) *" else "Deposit Amount (BDT) *") },
                leadingIcon = {
                    Icon(
                        imageVector = Icons.Default.MonetizationOn,
                        contentDescription = null,
                        tint = MoneyIncomeGreen
                    )
                },
                keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
                singleLine = true,
                shape = RoundedCornerShape(14.dp),
                modifier = Modifier.fillMaxWidth()
            )

            // Live Amount in Words & South Asian Grouping Preview
            PaymentAmountPreviewCard(
                amount = enteredAmount,
                isBangla = isBangla
            )

            // 4. Month & Year Row
            MonthYearSelectorRow(
                selectedMonth = selectedMonth,
                onMonthSelected = { selectedMonth = it },
                selectedYear = selectedYear,
                onYearChanged = { selectedYear = it },
                months = months
            )

            // 5. Payment Method Dropdown
            PaymentMethodSelectorDropdown(
                paymentMethods = paymentMethods,
                selectedMethod = selectedMethod,
                onMethodSelected = { selectedMethod = it }
            )

            // 6. Purpose Note Field
            OutlinedTextField(
                value = purposeNote,
                onValueChange = { purposeNote = it },
                label = { Text(if (isBangla) "মন্তব্য / নোট (ঐচ্ছিক)" else "Note / Purpose (Optional)") },
                leadingIcon = { Icon(Icons.AutoMirrored.Filled.Notes, contentDescription = null) },
                singleLine = true,
                shape = RoundedCornerShape(14.dp),
                modifier = Modifier.fillMaxWidth()
            )

            Spacer(modifier = Modifier.height(12.dp))

            // Confirm Payment Button
            Button(
                onClick = {
                    if (isFormValid && selectedMember != null) {
                        val payment = Payment(
                            memberId = selectedMember!!.id,
                            memberName = selectedMember!!.name,
                            branchId = selectedMember!!.branchId,
                            type = selectedType,
                            amount = safeRound(enteredAmount),
                            method = selectedMethod,
                            forMonth = selectedMonth,
                            forYear = selectedYear,
                            purposeNote = purposeNote.trim()
                        )
                        onConfirmSave(payment)
                        savedPaymentForReceipt = payment
                    }
                },
                modifier = Modifier
                    .fillMaxWidth()
                    .height(52.dp),
                shape = RoundedCornerShape(14.dp),
                colors = ButtonDefaults.buttonColors(containerColor = MaterialTheme.colorScheme.primary),
                enabled = isFormValid
            ) {
                Icon(imageVector = Icons.Default.Check, contentDescription = null)
                Spacer(modifier = Modifier.width(8.dp))
                Text(
                    text = if (isBangla) "জমা নিশ্চিত করুন ও রসিদ তৈরি করুন" else "Confirm Payment & Print Receipt",
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.Bold
                )
            }
        }
    }

    // Duplicate Payment Soft Warning Dialog
    if (showDuplicateWarningDialog && duplicatePaymentFound != null) {
        DuplicatePaymentWarningDialog(
            selectedMember = selectedMember,
            selectedMonth = selectedMonth,
            selectedYear = selectedYear,
            duplicatePayment = duplicatePaymentFound!!,
            isBangla = isBangla,
            onConfirm = {
                showDuplicateWarningDialog = false
                val payment = Payment(
                    memberId = selectedMember!!.id,
                    memberName = selectedMember!!.name,
                    branchId = selectedMember!!.branchId,
                    type = selectedType,
                    amount = safeRound(enteredAmount),
                    method = selectedMethod,
                    forMonth = selectedMonth,
                    forYear = selectedYear,
                    purposeNote = purposeNote.trim()
                )
                onConfirmSave(payment)
                savedPaymentForReceipt = payment
            },
            onDismiss = { showDuplicateWarningDialog = false }
        )
    }

    // Success PDF Receipt Generation Dialog
    if (savedPaymentForReceipt != null) {
        PaymentReceiptSuccessDialog(
            payment = savedPaymentForReceipt!!,
            isBangla = isBangla,
            context = context,
            onPrint = {
                savedPaymentForReceipt = null
                onNavigateBack()
            },
            onDismiss = {
                savedPaymentForReceipt = null
                onNavigateBack()
            }
        )
    }
}
