package com.helptrickbd.myapplicationsomithierp.presentation.screens.loans

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
import androidx.compose.material.icons.filled.Handshake
import androidx.compose.material.icons.filled.MonetizationOn
import androidx.compose.material.icons.filled.Person
import androidx.compose.material.icons.filled.VolunteerActivism
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
import androidx.compose.material3.SuggestionChip
import androidx.compose.material3.Surface
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
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import com.helptrickbd.myapplicationsomithierp.core.util.safeRound
import com.helptrickbd.myapplicationsomithierp.domain.model.Loan
import com.helptrickbd.myapplicationsomithierp.domain.model.Member
import com.helptrickbd.myapplicationsomithierp.presentation.screens.loans.components.LoanAmountPreviewCard
import com.helptrickbd.myapplicationsomithierp.presentation.screens.loans.components.LoanRepaymentSummaryCard

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

    val amount = safeRound(loanAmountText.toDoubleOrNull() ?: 0.0)
    val isFormValid = selectedMember != null && amount > 0

    val purposeSuggestions = remember(isBangla) {
        if (isBangla) listOf("চিকিৎসা সহায়তা", "শিক্ষা খরচ", "পারিবারিক জরুরি সাহায্য", "ব্যবসার প্রাথমিক পুঁজি")
        else listOf("Medical Emergency", "Education Support", "Family Relief", "Halal Seed Capital")
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    Text(
                        text = if (isBangla) "করযে হাসানা প্রদান" else "Disburse Qard Hasan",
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
            // Shariah Banner
            Surface(
                shape = RoundedCornerShape(14.dp),
                color = MaterialTheme.colorScheme.primaryContainer.copy(alpha = 0.4f),
                modifier = Modifier.fillMaxWidth()
            ) {
                Row(
                    modifier = Modifier.padding(14.dp),
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(10.dp)
                ) {
                    Icon(
                        imageVector = Icons.Default.VolunteerActivism,
                        contentDescription = null,
                        tint = MaterialTheme.colorScheme.primary
                    )
                    Text(
                        text = if (isBangla)
                            "১০০% সুদমুক্ত করযে হাসানা। কোনো প্রকার সুদ বা জরিমানা নেই। ঋণগ্রহীতা শুধু মূল টাকা কিস্তিতে পরিশোধ করবেন।"
                        else
                            "100% Interest-free Qard Hasan. Zero interest or penalty. Borrower repays only the principal amount.",
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
            }

            // Member Selector Dropdown
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

            // Amount Field
            OutlinedTextField(
                value = loanAmountText,
                onValueChange = { loanAmountText = it },
                label = { Text(if (isBangla) "করযে হাসানার পরিমাণ (টাকা) *" else "Qard Hasan Amount (BDT) *") },
                leadingIcon = { Icon(Icons.Default.MonetizationOn, contentDescription = null) },
                keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
                singleLine = true,
                shape = RoundedCornerShape(14.dp),
                modifier = Modifier.fillMaxWidth()
            )

            // Live Amount Words Preview
            LoanAmountPreviewCard(
                amount = amount,
                isBangla = isBangla
            )

            // Purpose Field & Suggestion Chips
            Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
                OutlinedTextField(
                    value = loanReason,
                    onValueChange = { loanReason = it },
                    label = { Text(if (isBangla) "প্রদানের কারণ / মানবিক উদ্দেশ্য" else "Welfare Purpose / Reason") },
                    leadingIcon = { Icon(Icons.AutoMirrored.Filled.Notes, contentDescription = null) },
                    singleLine = false,
                    maxLines = 2,
                    shape = RoundedCornerShape(14.dp),
                    modifier = Modifier.fillMaxWidth()
                )

                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    purposeSuggestions.take(2).forEach { suggestion ->
                        SuggestionChip(
                            onClick = { loanReason = suggestion },
                            label = { Text(suggestion, style = MaterialTheme.typography.labelSmall) }
                        )
                    }
                }
            }

            // Repayment Summary Card (Zero Interest)
            LoanRepaymentSummaryCard(
                amount = amount,
                isBangla = isBangla
            )

            Spacer(modifier = Modifier.height(8.dp))

            // Submit Button
            Button(
                onClick = {
                    if (isFormValid && selectedMember != null) {
                        val loan = Loan(
                            memberId = selectedMember!!.id,
                            memberName = selectedMember!!.name,
                            branchId = selectedMember!!.branchId,
                            amount = amount,
                            reason = loanReason.trim().ifBlank {
                                if (isBangla) "জরুরি কল্যাণমূলক সহায়তা" else "Emergency Welfare Aid"
                            }
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
                Icon(imageVector = Icons.Default.Handshake, contentDescription = null)
                Spacer(modifier = Modifier.width(8.dp))
                Text(
                    text = if (isBangla) "করযে হাসানা প্রদান নিশ্চিত করুন" else "Confirm Qard Hasan",
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.Bold
                )
            }
        }
    }
}
