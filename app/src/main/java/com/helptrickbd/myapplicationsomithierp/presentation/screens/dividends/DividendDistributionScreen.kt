package com.helptrickbd.myapplicationsomithierp.presentation.screens.dividends

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.Calculate
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.MonetizationOn
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.ExperimentalMaterial3Api
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
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import com.helptrickbd.myapplicationsomithierp.core.util.CurrencyFormatter
import com.helptrickbd.myapplicationsomithierp.core.util.safeRound
import com.helptrickbd.myapplicationsomithierp.domain.model.DividendAllocation
import com.helptrickbd.myapplicationsomithierp.domain.model.DividendRun
import com.helptrickbd.myapplicationsomithierp.domain.model.Member
import com.helptrickbd.myapplicationsomithierp.presentation.screens.dividends.components.DividendAllocationCard
import com.helptrickbd.myapplicationsomithierp.ui.theme.MoneyIncomeGreen

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun DividendDistributionScreen(
    members: List<Member> = emptyList(),
    onConfirmDividendPayout: (DividendRun) -> Unit = {},
    onNavigateBack: () -> Unit = {}
) {
    val isBangla = LocalConfiguration.current.locales[0].language == "bn"
    var profitAmountText by remember { mutableStateOf("") }
    var yearText by remember { mutableStateOf("2026") }
    var showConfirmDialog by remember { mutableStateOf(false) }

    val totalProfit = safeRound(profitAmountText.toDoubleOrNull() ?: 0.0)
    val year = yearText.toIntOrNull() ?: 2026
    val totalOrgContributions = safeRound(members.sumOf { safeRound(it.totalContributed) }).coerceAtLeast(1.0)

    val allocations = members.map { member ->
        val shareRatio = (member.totalContributed / totalOrgContributions).coerceAtLeast(0.0)
        val calculatedAmount = safeRound(totalProfit * shareRatio)
        DividendAllocation(
            memberId = member.id,
            memberName = member.name,
            contributionShare = safeRound(shareRatio * 100.0),
            amountPaid = calculatedAmount
        )
    }

    val isCalculated = totalProfit > 0

    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    Text(
                        text = if (isBangla) "বার্ষিক লভ্যাংশ বণ্টন (Dividend)" else "Annual Dividend Distribution",
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
                .padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            // Profit Input Card
            Card(
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(16.dp),
                colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface),
                elevation = CardDefaults.cardElevation(defaultElevation = 2.dp)
            ) {
                Column(
                    modifier = Modifier.padding(16.dp),
                    verticalArrangement = Arrangement.spacedBy(12.dp)
                ) {
                    Text(
                        text = if (isBangla) "মোট বণ্টনযোগ্য লাভ নির্ধারণ করুন" else "Set Total Distributable Halal Profit",
                        style = MaterialTheme.typography.titleSmall,
                        fontWeight = FontWeight.Bold
                    )

                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.spacedBy(10.dp)
                    ) {
                        OutlinedTextField(
                            value = profitAmountText,
                            onValueChange = { profitAmountText = it },
                            label = { Text(if (isBangla) "মোট নিট মুনাফা (টাকা)" else "Net Profit (BDT)") },
                            leadingIcon = { Icon(Icons.Default.MonetizationOn, contentDescription = null, tint = MoneyIncomeGreen) },
                            keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
                            singleLine = true,
                            shape = RoundedCornerShape(12.dp),
                            modifier = Modifier.weight(1.5f)
                        )

                        OutlinedTextField(
                            value = yearText,
                            onValueChange = { yearText = it },
                            label = { Text(if (isBangla) "অর্থবছর" else "Fiscal Year") },
                            keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
                            singleLine = true,
                            shape = RoundedCornerShape(12.dp),
                            modifier = Modifier.weight(1f)
                        )
                    }

                    Text(
                        text = if (isBangla) "সদস্যদের বার্ষিক মোট জমার আনুপাতিক হার (Proportional Share) অনুযায়ী লাভ স্বয়ংক্রিয়ভাবে হিসাব করা হবে।"
                        else "Profit is automatically calculated based on each member's proportional contribution share.",
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
            }

            // Computed Allocation List Header
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = if (isBangla) "সদস্যভিত্তিক লভ্যাংশ বণ্টন তালিকা (${allocations.size})" else "Member Allocation List (${allocations.size})",
                    style = MaterialTheme.typography.titleSmall,
                    fontWeight = FontWeight.Bold
                )

                if (isCalculated) {
                    Text(
                        text = "${if (isBangla) "মোট" else "Total"}: ${CurrencyFormatter.formatBDT(totalProfit, toBanglaDigits = isBangla)}",
                        style = MaterialTheme.typography.labelMedium,
                        fontWeight = FontWeight.Bold,
                        color = MoneyIncomeGreen
                    )
                }
            }

            // Allocation List
            LazyColumn(
                modifier = Modifier
                    .weight(1f)
                    .fillMaxWidth(),
                verticalArrangement = Arrangement.spacedBy(10.dp)
            ) {
                items(allocations, key = { it.memberId }) { allocation ->
                    DividendAllocationCard(allocation = allocation, isBangla = isBangla)
                }
            }

            // Confirm Payout Button
            Button(
                onClick = { showConfirmDialog = true },
                modifier = Modifier
                    .fillMaxWidth()
                    .height(52.dp),
                shape = RoundedCornerShape(14.dp),
                colors = ButtonDefaults.buttonColors(containerColor = MoneyIncomeGreen),
                enabled = isCalculated
            ) {
                Icon(imageVector = Icons.Default.Check, contentDescription = null)
                Spacer(modifier = Modifier.width(8.dp))
                Text(
                    text = if (isBangla) "লভ্যাংশ বিতরণ নিশ্চিত করুন" else "Confirm Dividend Distribution",
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.Bold
                )
            }
        }
    }

    // Confirmation Modal
    if (showConfirmDialog) {
        AlertDialog(
            onDismissRequest = { showConfirmDialog = false },
            icon = { Icon(Icons.Default.Calculate, contentDescription = null, tint = MoneyIncomeGreen) },
            title = { Text(if (isBangla) "লভ্যাংশ বণ্টন নিশ্চিতকরণ" else "Confirm Dividend Distribution", fontWeight = FontWeight.Bold) },
            text = {
                Text(
                    text = if (isBangla)
                        "$year অর্থবছরের জন্য সর্বমোট ${CurrencyFormatter.formatBDT(totalProfit, toBanglaDigits = true)} টাকা ${allocations.size} জন সদস্যের লেজারে যোগ হবে। আপনি কি নিশ্চিত?"
                    else
                        "A total of ${CurrencyFormatter.formatBDT(totalProfit, toBanglaDigits = false)} will be credited to ${allocations.size} members for fiscal year $year. Are you sure?"
                )
            },
            confirmButton = {
                Button(
                    onClick = {
                        showConfirmDialog = false
                        val dividendRun = DividendRun(
                            year = year,
                            totalDistributableAmount = totalProfit,
                            confirmedBy = "SuperAdmin",
                            allocations = allocations
                        )
                        onConfirmDividendPayout(dividendRun)
                        onNavigateBack()
                    },
                    colors = ButtonDefaults.buttonColors(containerColor = MoneyIncomeGreen)
                ) {
                    Text(if (isBangla) "হ্যাঁ, কনফার্ম করুন" else "Confirm")
                }
            },
            dismissButton = {
                OutlinedButton(onClick = { showConfirmDialog = false }) {
                    Text(if (isBangla) "বাতিল" else "Cancel")
                }
            }
        )
    }
}
