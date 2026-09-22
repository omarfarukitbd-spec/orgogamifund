package com.helptrickbd.myapplicationsomithierp.presentation.screens.loans

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
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
import androidx.compose.material.icons.filled.CreditCard
import androidx.compose.material.icons.filled.MonetizationOn
import androidx.compose.material.icons.filled.Percent
import androidx.compose.material.icons.filled.Person
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
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Switch
import androidx.compose.material3.SwitchDefaults
import androidx.compose.ui.platform.LocalConfiguration
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
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import com.helptrickbd.myapplicationsomithierp.core.util.CurrencyFormatter
import com.helptrickbd.myapplicationsomithierp.core.util.safeRound
import com.helptrickbd.myapplicationsomithierp.domain.model.Loan
import com.helptrickbd.myapplicationsomithierp.domain.model.Member

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun IssueLoanScreen(
    members: List<Member> = emptyList(),
    onDisburseLoan: (Loan) -> Unit = {},
    onNavigateBack: () -> Unit = {}
) {
    val isBangla = LocalConfiguration.current.locales[0].language == "bn"

    var selectedMember by remember { mutableStateOf<Member?>(members.firstOrNull()) }
    var memberExpanded by remember { mutableStateOf(false) }

    var loanAmountText by remember { mutableStateOf("") }
    var loanReason by remember { mutableStateOf("") }
    var interestEnabled by remember { mutableStateOf(false) }
    var interestRateText by remember { mutableStateOf("5") }

    val amount = safeRound(loanAmountText.toDoubleOrNull() ?: 0.0)
    val rate = if (interestEnabled) safeRound(interestRateText.toDoubleOrNull() ?: 0.0) else 0.0
    val totalPayable = safeRound(if (interestEnabled) safeRound(amount + safeRound(amount * rate / 100.0)) else amount)

    val isFormValid = selectedMember != null && amount > 0

    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    Text(
                        text = if (isBangla) "নতুন ঋণ / দাদন বিতরণ" else "Issue New Loan",
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
            // Member Dropdown
            ExposedDropdownMenuBox(
                expanded = memberExpanded,
                onExpandedChange = { memberExpanded = !memberExpanded }
            ) {
                OutlinedTextField(
                    value = selectedMember?.name ?: if (isBangla) "সদস্য নির্বাচন করুন" else "Select Member",
                    onValueChange = {},
                    readOnly = true,
                    label = { Text(if (isBangla) "ঋণগ্রহীতা সদস্য *" else "Borrower Member *") },
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

            // Loan Amount
            OutlinedTextField(
                value = loanAmountText,
                onValueChange = { loanAmountText = it },
                label = { Text(if (isBangla) "বিতরণকৃত ঋণের পরিমাণ (টাকা) *" else "Loan Amount (BDT) *") },
                leadingIcon = { Icon(Icons.Default.MonetizationOn, contentDescription = null) },
                keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
                singleLine = true,
                shape = RoundedCornerShape(14.dp),
                modifier = Modifier.fillMaxWidth()
            )

            // Live Amount Preview (কমা গ্রুপিং ও কথায় প্রকাশ)
            val enteredAmount = loanAmountText.toDoubleOrNull() ?: 0.0
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

            // Loan Reason
            OutlinedTextField(
                value = loanReason,
                onValueChange = { loanReason = it },
                label = { Text(if (isBangla) "ঋণ গ্রহণের উদ্দেশ্য / কারণ" else "Loan Purpose / Reason") },
                leadingIcon = { Icon(Icons.AutoMirrored.Filled.Notes, contentDescription = null) },
                singleLine = false,
                maxLines = 2,
                shape = RoundedCornerShape(14.dp),
                modifier = Modifier.fillMaxWidth()
            )

            // Optional Interest Toggle (§6.4)
            Card(
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(16.dp),
                colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface)
            ) {
                Column(modifier = Modifier.padding(16.dp)) {
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Column {
                            Text(
                                text = if (isBangla) "সুদ / সার্ভিস চার্জ প্রযোজ্য" else "Apply Interest / Service Charge",
                                style = MaterialTheme.typography.titleSmall,
                                fontWeight = FontWeight.SemiBold
                            )
                            Text(
                                text = if (isBangla) "ডিফল্টভাবে সুদমুক্ত (Interest-Free) থাকে" else "Interest-free by default",
                                style = MaterialTheme.typography.bodySmall,
                                color = MaterialTheme.colorScheme.onSurfaceVariant
                            )
                        }

                        Switch(
                            checked = interestEnabled,
                            onCheckedChange = { interestEnabled = it },
                            colors = SwitchDefaults.colors(checkedThumbColor = MaterialTheme.colorScheme.primary)
                        )
                    }

                    AnimatedVisibility(visible = interestEnabled) {
                        Column {
                            Spacer(modifier = Modifier.height(14.dp))
                            OutlinedTextField(
                                value = interestRateText,
                                onValueChange = { interestRateText = it },
                                label = { Text(if (isBangla) "সুদের হার (শতাংশ %)" else "Interest Rate (%)") },
                                leadingIcon = { Icon(Icons.Default.Percent, contentDescription = null) },
                                keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
                                singleLine = true,
                                shape = RoundedCornerShape(12.dp),
                                modifier = Modifier.fillMaxWidth()
                            )
                        }
                    }
                }
            }

            // Amortization Summary Card
            Card(
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(16.dp),
                colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.primaryContainer.copy(alpha = 0.4f))
            ) {
                Column(
                    modifier = Modifier.padding(16.dp),
                    verticalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    Text(
                        text = if (isBangla) "পরিশোধ বিবরণী সারসংক্ষেপ:" else "Repayment Summary:",
                        style = MaterialTheme.typography.labelMedium,
                        fontWeight = FontWeight.Bold
                    )
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween
                    ) {
                        Text(text = if (isBangla) "মূল ঋণ (Principal):" else "Principal Amount:", style = MaterialTheme.typography.bodyMedium)
                        Text(text = CurrencyFormatter.formatBDT(amount, toBanglaDigits = isBangla), fontWeight = FontWeight.Bold)
                    }
                    if (interestEnabled) {
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.SpaceBetween
                        ) {
                            Text(text = if (isBangla) "মোট সুদ (${rate}%):" else "Total Interest (${rate}%):", style = MaterialTheme.typography.bodyMedium)
                            Text(text = CurrencyFormatter.formatBDT(safeRound(amount * rate / 100.0), toBanglaDigits = isBangla), fontWeight = FontWeight.Bold)
                        }
                    }
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween
                    ) {
                        Text(text = if (isBangla) "মোট পরিশোধযোগ্য:" else "Total Payable:", style = MaterialTheme.typography.titleSmall, fontWeight = FontWeight.Bold)
                        Text(
                            text = CurrencyFormatter.formatBDT(totalPayable, toBanglaDigits = isBangla),
                            style = MaterialTheme.typography.titleMedium,
                            fontWeight = FontWeight.Bold,
                            color = MaterialTheme.colorScheme.primary
                        )
                    }
                }
            }

            Spacer(modifier = Modifier.height(8.dp))

            // Disburse Loan Button
            Button(
                onClick = {
                    if (isFormValid && selectedMember != null) {
                        val loan = Loan(
                            memberId = selectedMember!!.id,
                            memberName = selectedMember!!.name,
                            branchId = selectedMember!!.branchId,
                            amount = amount,
                            reason = loanReason.trim(),
                            interestEnabled = interestEnabled,
                            interestRate = rate
                        )
                        onDisburseLoan(loan)
                    }
                },
                modifier = Modifier
                    .fillMaxWidth()
                    .height(52.dp),
                shape = RoundedCornerShape(14.dp),
                colors = ButtonDefaults.buttonColors(containerColor = MaterialTheme.colorScheme.primary),
                enabled = isFormValid
            ) {
                Icon(imageVector = Icons.Default.CreditCard, contentDescription = null)
                Spacer(modifier = Modifier.width(8.dp))
                Text(
                    text = if (isBangla) "ঋণ বিতরণ সম্পন্ন করুন" else "Disburse Loan",
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.Bold
                )
            }
        }
    }
}
