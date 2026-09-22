package com.helptrickbd.myapplicationsomithierp.presentation.screens.payments

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.automirrored.filled.Notes
import androidx.compose.material.icons.filled.CalendarMonth
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.CreditCard
import androidx.compose.material.icons.filled.MonetizationOn
import androidx.compose.material.icons.filled.Notes
import androidx.compose.material.icons.filled.Person
import androidx.compose.material.icons.filled.Print
import androidx.compose.material.icons.filled.Warning
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.ExposedDropdownMenuBox
import androidx.compose.material3.ExposedDropdownMenuDefaults
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
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
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalConfiguration
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import com.helptrickbd.myapplicationsomithierp.R
import com.helptrickbd.myapplicationsomithierp.core.pdf.PaymentReceiptPdfGenerator
import com.helptrickbd.myapplicationsomithierp.core.util.CurrencyFormatter
import com.helptrickbd.myapplicationsomithierp.core.util.safeRound
import com.helptrickbd.myapplicationsomithierp.domain.model.Member
import com.helptrickbd.myapplicationsomithierp.domain.model.Payment
import com.helptrickbd.myapplicationsomithierp.domain.model.PaymentType
import com.helptrickbd.myapplicationsomithierp.ui.theme.MoneyDueAmber
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
    var memberExpanded by remember { mutableStateOf(false) }

    var selectedType by remember { mutableStateOf(PaymentType.MONTHLY) }
    var typeExpanded by remember { mutableStateOf(false) }

    var amountText by remember { mutableStateOf("") }

    val months = remember(isBangla) {
        if (isBangla) listOf("জানুয়ারি", "ফেব্রুয়ারি", "মার্চ", "এপ্রিল", "মে", "জুন", "জুলাই", "আগস্ট", "সেপ্টেম্বর", "অক্টোবর", "নভেম্বর", "ডিসেম্বর")
        else listOf("January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December")
    }
    var selectedMonth by remember(isBangla) { mutableStateOf(months[1]) }
    var monthExpanded by remember { mutableStateOf(false) }

    var selectedYear by remember { mutableStateOf(2026) }
    var selectedMethod by remember { mutableStateOf(paymentMethods.firstOrNull() ?: "Cash") }
    var methodExpanded by remember { mutableStateOf(false) }

    var purposeNote by remember { mutableStateOf("") }

    // Duplicate Warning State
    var showDuplicateWarningDialog by remember { mutableStateOf(false) }
    var duplicatePaymentFound by remember { mutableStateOf<Payment?>(null) }

    // Success Receipt Dialog State
    var savedPaymentForReceipt by remember { mutableStateOf<Payment?>(null) }

    val isFormValid = selectedMember != null && amountText.toDoubleOrNull() != null && amountText.toDoubleOrNull()!! > 0

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
            // 1. Select Member Exposed Dropdown
            ExposedDropdownMenuBox(
                expanded = memberExpanded,
                onExpandedChange = { memberExpanded = !memberExpanded }
            ) {
                OutlinedTextField(
                    value = selectedMember?.name ?: if (isBangla) "সদস্য নির্বাচন করুন" else "Select Member",
                    onValueChange = {},
                    readOnly = true,
                    label = { Text(if (isBangla) "সদস্য নির্বাচন করুন *" else "Select Member *") },
                    leadingIcon = { Icon(Icons.Default.Person, contentDescription = null) },
                    trailingIcon = { ExposedDropdownMenuDefaults.TrailingIcon(expanded = memberExpanded) },
                    shape = RoundedCornerShape(14.dp),
                    modifier = Modifier
                        .fillMaxWidth()
                        .menuAnchor()
                )

                ExposedDropdownMenu(
                    expanded = memberExpanded,
                    onDismissRequest = { memberExpanded = false }
                ) {
                    members.forEach { member ->
                        DropdownMenuItem(
                            text = { Text("${member.name} (${member.phone})") },
                            onClick = {
                                selectedMember = member
                                memberExpanded = false
                            }
                        )
                    }
                }
            }

            // 2. Payment Type Dropdown
            ExposedDropdownMenuBox(
                expanded = typeExpanded,
                onExpandedChange = { typeExpanded = !typeExpanded }
            ) {
                OutlinedTextField(
                    value = when (selectedType) {
                        PaymentType.MONTHLY -> stringResource(R.string.payment_type_monthly)
                        PaymentType.YEARLY -> stringResource(R.string.payment_type_yearly)
                        PaymentType.SPECIAL -> stringResource(R.string.payment_type_special)
                        PaymentType.FINE -> stringResource(R.string.payment_type_fine)
                    },
                    onValueChange = {},
                    readOnly = true,
                    label = { Text(stringResource(R.string.payment_type)) },
                    trailingIcon = { ExposedDropdownMenuDefaults.TrailingIcon(expanded = typeExpanded) },
                    shape = RoundedCornerShape(14.dp),
                    modifier = Modifier
                        .fillMaxWidth()
                        .menuAnchor()
                )

                ExposedDropdownMenu(
                    expanded = typeExpanded,
                    onDismissRequest = { typeExpanded = false }
                ) {
                    PaymentType.entries.forEach { type ->
                        DropdownMenuItem(
                            text = {
                                Text(
                                    when (type) {
                                        PaymentType.MONTHLY -> stringResource(R.string.payment_type_monthly)
                                        PaymentType.YEARLY -> stringResource(R.string.payment_type_yearly)
                                        PaymentType.SPECIAL -> stringResource(R.string.payment_type_special)
                                        PaymentType.FINE -> stringResource(R.string.payment_type_fine)
                                    }
                                )
                            },
                            onClick = {
                                selectedType = type
                                typeExpanded = false
                            }
                        )
                    }
                }
            }

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
            val enteredAmount = amountText.toDoubleOrNull() ?: 0.0
            if (enteredAmount > 0.0) {
                Card(
                    modifier = Modifier.fillMaxWidth(),
                    shape = RoundedCornerShape(12.dp),
                    colors = CardDefaults.cardColors(
                        containerColor = MaterialTheme.colorScheme.primaryContainer.copy(alpha = 0.35f)
                    )
                ) {
                    Column(
                        modifier = Modifier.padding(horizontal = 14.dp, vertical = 10.dp),
                        verticalArrangement = Arrangement.spacedBy(4.dp)
                    ) {
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.SpaceBetween,
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Text(
                                text = if (isBangla) "সংখ্যায় (হাজার, লক্ষ, কোটি):" else "In Numbers:",
                                style = MaterialTheme.typography.labelMedium,
                                color = MaterialTheme.colorScheme.primary,
                                fontWeight = FontWeight.SemiBold
                            )
                            Text(
                                text = CurrencyFormatter.formatBDT(enteredAmount, showDecimals = true, toBanglaDigits = isBangla),
                                style = MaterialTheme.typography.titleMedium,
                                fontWeight = FontWeight.Bold,
                                color = MaterialTheme.colorScheme.primary
                            )
                        }
                        HorizontalDivider(thickness = 0.5.dp, color = MaterialTheme.colorScheme.primary.copy(alpha = 0.2f))
                        if (isBangla) {
                            Text(
                                text = "কথায়: ${CurrencyFormatter.formatInWords(enteredAmount, isBangla = true)}",
                                style = MaterialTheme.typography.bodySmall,
                                fontWeight = FontWeight.Medium,
                                color = MaterialTheme.colorScheme.onSurface
                            )
                        } else {
                            Text(
                                text = "In Words: ${CurrencyFormatter.formatInWords(enteredAmount, isBangla = false)}",
                                style = MaterialTheme.typography.bodySmall,
                                fontWeight = FontWeight.Medium,
                                color = MaterialTheme.colorScheme.onSurface
                            )
                        }
                    }
                }
            }

            // 4. Month & Year Row
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                ExposedDropdownMenuBox(
                    expanded = monthExpanded,
                    onExpandedChange = { monthExpanded = !monthExpanded },
                    modifier = Modifier.weight(1f)
                ) {
                    OutlinedTextField(
                        value = selectedMonth,
                        onValueChange = {},
                        readOnly = true,
                        label = { Text(stringResource(R.string.for_month)) },
                        trailingIcon = { ExposedDropdownMenuDefaults.TrailingIcon(expanded = monthExpanded) },
                        shape = RoundedCornerShape(14.dp),
                        modifier = Modifier.menuAnchor()
                    )

                    ExposedDropdownMenu(
                        expanded = monthExpanded,
                        onDismissRequest = { monthExpanded = false }
                    ) {
                        months.forEach { month ->
                            DropdownMenuItem(
                                text = { Text(month) },
                                onClick = {
                                    selectedMonth = month
                                    monthExpanded = false
                                }
                            )
                        }
                    }
                }

                OutlinedTextField(
                    value = selectedYear.toString(),
                    onValueChange = { selectedYear = it.toIntOrNull() ?: 2026 },
                    label = { Text(stringResource(R.string.for_year)) },
                    keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
                    singleLine = true,
                    shape = RoundedCornerShape(14.dp),
                    modifier = Modifier.weight(1f)
                )
            }

            // 5. Payment Method
            ExposedDropdownMenuBox(
                expanded = methodExpanded,
                onExpandedChange = { methodExpanded = !methodExpanded }
            ) {
                OutlinedTextField(
                    value = selectedMethod,
                    onValueChange = {},
                    readOnly = true,
                    label = { Text(stringResource(R.string.payment_method)) },
                    leadingIcon = { Icon(Icons.Default.CreditCard, contentDescription = null) },
                    trailingIcon = { ExposedDropdownMenuDefaults.TrailingIcon(expanded = methodExpanded) },
                    shape = RoundedCornerShape(14.dp),
                    modifier = Modifier
                        .fillMaxWidth()
                        .menuAnchor()
                )

                ExposedDropdownMenu(
                    expanded = methodExpanded,
                    onDismissRequest = { methodExpanded = false }
                ) {
                    paymentMethods.forEach { method ->
                        DropdownMenuItem(
                            text = { Text(method) },
                            onClick = {
                                selectedMethod = method
                                methodExpanded = false
                            }
                        )
                    }
                }
            }

            // 6. Purpose Note
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

            // Save Payment Button
            Button(
                onClick = {
                    if (isFormValid && selectedMember != null) {
                        val payment = Payment(
                            memberId = selectedMember!!.id,
                            memberName = selectedMember!!.name,
                            branchId = selectedMember!!.branchId,
                            type = selectedType,
                            amount = safeRound(amountText.toDoubleOrNull() ?: 0.0),
                            method = selectedMethod,
                            forMonth = selectedMonth,
                            forYear = selectedYear,
                            purposeNote = purposeNote.trim()
                        )

                        // Trigger Save or Duplicate Check
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

    // Duplicate Payment Soft Warning Dialog (§6.2)
    if (showDuplicateWarningDialog && duplicatePaymentFound != null) {
        AlertDialog(
            onDismissRequest = { showDuplicateWarningDialog = false },
            icon = { Icon(Icons.Default.Warning, contentDescription = null, tint = MoneyDueAmber) },
            title = { Text(text = stringResource(R.string.duplicate_warning_title), fontWeight = FontWeight.Bold) },
            text = {
                Text(
                    text = if (isBangla)
                        "${selectedMember?.name}-এর জন্য ${selectedMonth}, $selectedYear সালে ইতিমধ্যে ${CurrencyFormatter.formatBDT(duplicatePaymentFound!!.amount, toBanglaDigits = true)} জমা রেকর্ড করা আছে।\n\nআপনি কি নিশ্চিত যে আরেকটি পেমেন্ট জমা করতে চান?"
                    else
                        "A deposit of ${CurrencyFormatter.formatBDT(duplicatePaymentFound!!.amount, toBanglaDigits = false)} is already recorded for ${selectedMember?.name} for $selectedMonth $selectedYear.\n\nAre you sure you want to proceed?"
                )
            },
            confirmButton = {
                Button(
                    onClick = {
                        showDuplicateWarningDialog = false
                        val payment = Payment(
                            memberId = selectedMember!!.id,
                            memberName = selectedMember!!.name,
                            branchId = selectedMember!!.branchId,
                            type = selectedType,
                            amount = safeRound(amountText.toDoubleOrNull() ?: 0.0),
                            method = selectedMethod,
                            forMonth = selectedMonth,
                            forYear = selectedYear,
                            purposeNote = purposeNote.trim()
                        )
                        onConfirmSave(payment)
                        savedPaymentForReceipt = payment
                    },
                    colors = ButtonDefaults.buttonColors(containerColor = MaterialTheme.colorScheme.primary)
                ) {
                    Text(stringResource(R.string.confirm_anyway))
                }
            },
            dismissButton = {
                OutlinedButton(onClick = { showDuplicateWarningDialog = false }) {
                    Text(stringResource(R.string.cancel))
                }
            }
        )
    }

    // Success PDF Receipt Generation Dialog
    if (savedPaymentForReceipt != null) {
        AlertDialog(
            onDismissRequest = {
                savedPaymentForReceipt = null
                onNavigateBack()
            },
            icon = { Icon(Icons.Default.Print, contentDescription = null, tint = MoneyIncomeGreen) },
            title = { Text(if (isBangla) "টাকা জমা সম্পন্ন হয়েছে!" else "Payment Recorded Successfully!", fontWeight = FontWeight.Bold) },
            text = {
                Text(
                    text = if (isBangla)
                        "সফলভাবে ${CurrencyFormatter.formatBDT(savedPaymentForReceipt!!.amount, toBanglaDigits = true)} জমা রেকর্ড করা হয়েছে। আপনি কি এখনই মানি রিসিট প্রিন্ট বা শেয়ার করতে চান?"
                    else
                        "Successfully recorded deposit of ${CurrencyFormatter.formatBDT(savedPaymentForReceipt!!.amount, toBanglaDigits = false)}. Would you like to print or share the money receipt now?"
                )
            },
            confirmButton = {
                Button(
                    onClick = {
                        val pdfFile = PaymentReceiptPdfGenerator.generateReceiptPdf(context, savedPaymentForReceipt!!)
                        PaymentReceiptPdfGenerator.printReceipt(context, pdfFile)
                        savedPaymentForReceipt = null
                        onNavigateBack()
                    },
                    colors = ButtonDefaults.buttonColors(containerColor = MaterialTheme.colorScheme.primary)
                ) {
                    Text(if (isBangla) "রসিদ প্রিন্ট করুন" else "Print Receipt")
                }
            },
            dismissButton = {
                OutlinedButton(
                    onClick = {
                        savedPaymentForReceipt = null
                        onNavigateBack()
                    }
                ) {
                    Text(if (isBangla) "পরে করবো" else "Later")
                }
            }
        )
    }
}
