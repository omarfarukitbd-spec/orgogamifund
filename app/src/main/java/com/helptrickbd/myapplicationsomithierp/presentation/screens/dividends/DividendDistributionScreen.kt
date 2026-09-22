package com.helptrickbd.myapplicationsomithierp.presentation.screens.dividends

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.Calculate
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.MonetizationOn
import androidx.compose.material.icons.filled.Person
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
import androidx.compose.ui.draw.clip
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import com.helptrickbd.myapplicationsomithierp.core.util.CurrencyFormatter
import com.helptrickbd.myapplicationsomithierp.domain.model.DividendAllocation
import com.helptrickbd.myapplicationsomithierp.domain.model.DividendRun
import com.helptrickbd.myapplicationsomithierp.domain.model.Member
import com.helptrickbd.myapplicationsomithierp.core.util.safeRound
import com.helptrickbd.myapplicationsomithierp.ui.theme.MoneyIncomeGreen

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun DividendDistributionScreen(
    members: List<Member> = emptyList(),
    onConfirmDividendPayout: (DividendRun) -> Unit = {},
    onNavigateBack: () -> Unit = {}
) {
    var profitAmountText by remember { mutableStateOf("") }
    var yearText by remember { mutableStateOf("2026") }
    var showConfirmDialog by remember { mutableStateOf(false) }

    val totalProfit = safeRound(profitAmountText.toDoubleOrNull() ?: 0.0)
    val year = yearText.toIntOrNull() ?: 2026
    val totalOrgContributions = safeRound(members.sumOf { safeRound(it.totalContributed) }).coerceAtLeast(1.0)

    // Compute proportional share for each active member (§6.7)
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
                        text = "বার্ষিক লভ্যাংশ বণ্টন (Dividend)",
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
                        text = "মোট বণ্টনযোগ্য লাভ নির্ধারণ করুন",
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
                            label = { Text("মোট নিট মুনাফা (টাকা)") },
                            leadingIcon = { Icon(Icons.Default.MonetizationOn, contentDescription = null, tint = MoneyIncomeGreen) },
                            keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
                            singleLine = true,
                            shape = RoundedCornerShape(12.dp),
                            modifier = Modifier.weight(1.5f)
                        )

                        OutlinedTextField(
                            value = yearText,
                            onValueChange = { yearText = it },
                            label = { Text("অর্থবছর") },
                            keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
                            singleLine = true,
                            shape = RoundedCornerShape(12.dp),
                            modifier = Modifier.weight(1f)
                        )
                    }

                    Text(
                        text = "সদস্যদের বার্ষিক মোট জমার আনুপাতিক হার (Proportional Share) অনুযায়ী লাভ স্বয়ংক্রিয়ভাবে হিসাব করা হবে।",
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
                    text = "সদস্যভিত্তিক লভ্যাংশ বণ্টন তালিকা (${allocations.size})",
                    style = MaterialTheme.typography.titleSmall,
                    fontWeight = FontWeight.Bold
                )

                if (isCalculated) {
                    Text(
                        text = "মোট: ${CurrencyFormatter.formatBDT(totalProfit)}",
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
                items(allocations) { allocation ->
                    DividendAllocationCard(allocation = allocation)
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
                    text = "লভ্যাংশ বিতরণ নিশ্চিত করুন",
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
            title = { Text("লভ্যাংশ বণ্টন নিশ্চিতকরণ", fontWeight = FontWeight.Bold) },
            text = {
                Text(
                    text = "$year অর্থবছরের জন্য সর্বমোট ${CurrencyFormatter.formatBDT(totalProfit)} টাকা ${allocations.size} জন সদস্যের লেজারে যোগ হবে। আপনি কি নিশ্চিত?"
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
                    Text("হ্যাঁ, কনফার্ম করুন")
                }
            },
            dismissButton = {
                OutlinedButton(onClick = { showConfirmDialog = false }) {
                    Text("বাতিল")
                }
            }
        )
    }
}

@Composable
fun DividendAllocationCard(allocation: DividendAllocation) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(14.dp),
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface),
        elevation = CardDefaults.cardElevation(defaultElevation = 1.dp)
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(14.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Box(
                modifier = Modifier
                    .size(40.dp)
                    .clip(CircleShape)
                    .background(MaterialTheme.colorScheme.primaryContainer),
                contentAlignment = Alignment.Center
            ) {
                Icon(
                    imageVector = Icons.Default.Person,
                    contentDescription = null,
                    tint = MaterialTheme.colorScheme.primary,
                    modifier = Modifier.size(22.dp)
                )
            }

            Spacer(modifier = Modifier.width(12.dp))

            Column(modifier = Modifier.weight(1f)) {
                Text(
                    text = allocation.memberName,
                    style = MaterialTheme.typography.bodyMedium,
                    fontWeight = FontWeight.Bold
                )
                Text(
                    text = "জমার আনুপাতিক হার: ${"%.2f".format(allocation.contributionShare)}%",
                    style = MaterialTheme.typography.labelSmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }

            Text(
                text = "+ ${CurrencyFormatter.formatBDT(allocation.amountPaid)}",
                style = MaterialTheme.typography.titleSmall,
                fontWeight = FontWeight.Bold,
                color = MoneyIncomeGreen
            )
        }
    }
}
