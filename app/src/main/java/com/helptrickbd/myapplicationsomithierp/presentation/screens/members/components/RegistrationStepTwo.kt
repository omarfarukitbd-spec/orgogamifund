package com.helptrickbd.myapplicationsomithierp.presentation.screens.members.components

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import com.helptrickbd.myapplicationsomithierp.domain.model.Branch

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun RegistrationStepTwo(
    availableBranches: List<Branch>,
    selectedBranch: Branch,
    onBranchSelected: (Branch) -> Unit,
    shareCountText: String,
    onShareCountChange: (String) -> Unit,
    monthlyDepositText: String,
    onMonthlyDepositChange: (String) -> Unit,
    nomineeName: String,
    onNomineeNameChange: (String) -> Unit,
    nomineeRelation: String,
    onNomineeRelationChange: (String) -> Unit,
    nomineePhone: String,
    onNomineePhoneChange: (String) -> Unit,
    nomineeNid: String,
    onNomineeNidChange: (String) -> Unit,
    onBack: () -> Unit,
    onNext: () -> Unit
) {
    var isBranchDropdownExpanded by remember { mutableStateOf(false) }

    Card(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(16.dp),
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface),
        elevation = CardDefaults.cardElevation(defaultElevation = 2.dp)
    ) {
        Column(
            modifier = Modifier.padding(18.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            Text(
                text = "২. সমিতি নির্বাচন ও সঞ্চয় পরিকল্পনা",
                style = MaterialTheme.typography.titleSmall,
                fontWeight = FontWeight.Bold,
                color = MaterialTheme.colorScheme.primary
            )

            // Shomiti Branch Selector Dropdown
            ExposedDropdownMenuBox(
                expanded = isBranchDropdownExpanded,
                onExpandedChange = { isBranchDropdownExpanded = it }
            ) {
                OutlinedTextField(
                    value = selectedBranch.name,
                    onValueChange = {},
                    readOnly = true,
                    label = { Text("কোন সমিতিতে যুক্ত হতে চান?") },
                    trailingIcon = { ExposedDropdownMenuDefaults.TrailingIcon(expanded = isBranchDropdownExpanded) },
                    modifier = Modifier
                        .fillMaxWidth()
                        .menuAnchor(ExposedDropdownMenuAnchorType.PrimaryNotEditable),
                    shape = RoundedCornerShape(12.dp)
                )
                ExposedDropdownMenu(
                    expanded = isBranchDropdownExpanded,
                    onDismissRequest = { isBranchDropdownExpanded = false }
                ) {
                    val branchesToShow = if (availableBranches.isNotEmpty()) availableBranches else listOf(selectedBranch)
                    branchesToShow.forEach { branch ->
                        DropdownMenuItem(
                            text = { Text(branch.name) },
                            onClick = {
                                onBranchSelected(branch)
                                isBranchDropdownExpanded = false
                            }
                        )
                    }
                }
            }

            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(10.dp)
            ) {
                OutlinedTextField(
                    value = shareCountText,
                    onValueChange = { onShareCountChange(it.filter { c -> c.isDigit() }) },
                    label = { Text("শেয়ার সংখ্যা") },
                    keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
                    singleLine = true,
                    modifier = Modifier.weight(1f),
                    shape = RoundedCornerShape(12.dp)
                )

                OutlinedTextField(
                    value = monthlyDepositText,
                    onValueChange = { onMonthlyDepositChange(it.filter { c -> c.isDigit() }) },
                    label = { Text("মাসিক সঞ্চয় (৳)") },
                    keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
                    singleLine = true,
                    modifier = Modifier.weight(1f),
                    shape = RoundedCornerShape(12.dp)
                )
            }

            Spacer(modifier = Modifier.height(4.dp))
            Text(
                text = "নমিনীর বিবরণ",
                style = MaterialTheme.typography.titleSmall,
                fontWeight = FontWeight.Bold,
                color = MaterialTheme.colorScheme.secondary
            )

            OutlinedTextField(
                value = nomineeName,
                onValueChange = onNomineeNameChange,
                label = { Text("নমিনীর নাম *") },
                singleLine = true,
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(12.dp)
            )

            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(10.dp)
            ) {
                OutlinedTextField(
                    value = nomineeRelation,
                    onValueChange = onNomineeRelationChange,
                    label = { Text("সম্পর্ক *") },
                    singleLine = true,
                    modifier = Modifier.weight(1f),
                    shape = RoundedCornerShape(12.dp)
                )

                OutlinedTextField(
                    value = nomineePhone,
                    onValueChange = onNomineePhoneChange,
                    label = { Text("নমিনীর মোবাইল") },
                    keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Phone),
                    singleLine = true,
                    modifier = Modifier.weight(1.2f),
                    shape = RoundedCornerShape(12.dp)
                )
            }

            OutlinedTextField(
                value = nomineeNid,
                onValueChange = { onNomineeNidChange(it.filter { c -> c.isDigit() }) },
                label = { Text("নমিনীর জাতীয় পরিচয়পত্র (NID) নম্বর") },
                keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
                singleLine = true,
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(12.dp)
            )
        }
    }

    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        OutlinedButton(
            onClick = onBack,
            modifier = Modifier
                .weight(1f)
                .height(52.dp),
            shape = RoundedCornerShape(14.dp)
        ) {
            Text("আগের ধাপ")
        }

        Button(
            onClick = onNext,
            modifier = Modifier
                .weight(1.2f)
                .height(52.dp),
            shape = RoundedCornerShape(14.dp),
            colors = ButtonDefaults.buttonColors(containerColor = MaterialTheme.colorScheme.primary)
        ) {
            Text("পরবর্তী ধাপ (ডকুমেন্টস)")
        }
    }
}
