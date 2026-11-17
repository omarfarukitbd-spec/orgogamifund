package com.helptrickbd.myapplicationsomithierp.presentation.screens.search

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.Clear
import androidx.compose.material.icons.filled.Search
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.FilterChip
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TextFieldDefaults
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
import androidx.compose.ui.unit.dp
import com.helptrickbd.myapplicationsomithierp.core.ui.EmptyStateView
import com.helptrickbd.myapplicationsomithierp.domain.model.Member
import com.helptrickbd.myapplicationsomithierp.domain.model.Payment
import com.helptrickbd.myapplicationsomithierp.presentation.screens.search.components.SearchMemberCard
import com.helptrickbd.myapplicationsomithierp.presentation.screens.search.components.SearchPaymentCard

enum class SearchCategory {
    ALL,
    MEMBERS,
    RECEIPTS,
    PHONES
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun GlobalSearchScreen(
    members: List<Member> = emptyList(),
    payments: List<Payment> = emptyList(),
    onMemberClick: (String) -> Unit = {},
    onPaymentClick: (Payment) -> Unit = {},
    onNavigateBack: () -> Unit = {}
) {
    var searchQuery by remember { mutableStateOf("") }
    var selectedCategory by remember { mutableStateOf(SearchCategory.ALL) }

    val cleanQuery = searchQuery.trim().lowercase()

    val matchedMembers = remember(cleanQuery, members, selectedCategory) {
        if (cleanQuery.isEmpty() || selectedCategory == SearchCategory.RECEIPTS) {
            emptyList()
        } else {
            members.filter { member ->
                when (selectedCategory) {
                    SearchCategory.PHONES -> member.phone.contains(cleanQuery)
                    SearchCategory.MEMBERS -> member.name.lowercase().contains(cleanQuery) || member.id.lowercase().contains(cleanQuery)
                    else -> member.name.lowercase().contains(cleanQuery) ||
                            member.phone.contains(cleanQuery) ||
                            member.id.lowercase().contains(cleanQuery)
                }
            }
        }
    }

    val matchedPayments = remember(cleanQuery, payments, selectedCategory) {
        if (cleanQuery.isEmpty() || selectedCategory == SearchCategory.MEMBERS || selectedCategory == SearchCategory.PHONES) {
            emptyList()
        } else {
            payments.filter { payment ->
                payment.receiptNumber.lowercase().contains(cleanQuery) ||
                        payment.memberName.lowercase().contains(cleanQuery) ||
                        payment.amount.toString().contains(cleanQuery)
            }
        }
    }

    val isBangla = LocalConfiguration.current.locales[0].language == "bn"
    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    Text(
                        text = if (isBangla) "সার্বজনীন অনুসন্ধান" else "Global Search",
                        fontWeight = FontWeight.Bold
                    )
                },
                navigationIcon = {
                    IconButton(onClick = onNavigateBack) {
                        Icon(
                            imageVector = Icons.AutoMirrored.Filled.ArrowBack,
                            contentDescription = "Back"
                        )
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = MaterialTheme.colorScheme.surface
                )
            )
        }
    ) { innerPadding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(innerPadding)
        ) {
            // Search Input Field
            Box(modifier = Modifier.padding(horizontal = 16.dp, vertical = 8.dp)) {
                OutlinedTextField(
                    value = searchQuery,
                    onValueChange = { searchQuery = it },
                    modifier = Modifier.fillMaxWidth(),
                    placeholder = { Text(if (isBangla) "নাম, ফোন নম্বর, রশিদ বা আইডি খুঁজুন..." else "Search by name, phone, receipt or ID...") },
                    leadingIcon = {
                        Icon(
                            imageVector = Icons.Default.Search,
                            contentDescription = null,
                            tint = MaterialTheme.colorScheme.primary
                        )
                    },
                    trailingIcon = {
                        if (searchQuery.isNotEmpty()) {
                            IconButton(onClick = { searchQuery = "" }) {
                                Icon(
                                    imageVector = Icons.Default.Clear,
                                    contentDescription = "Clear"
                                )
                            }
                        }
                    },
                    shape = RoundedCornerShape(16.dp),
                    colors = TextFieldDefaults.colors(
                        focusedContainerColor = MaterialTheme.colorScheme.surface,
                        unfocusedContainerColor = MaterialTheme.colorScheme.surface
                    ),
                    singleLine = true
                )
            }

            // Category Filter Chips
            LazyRow(
                modifier = Modifier.fillMaxWidth(),
                contentPadding = PaddingValues(horizontal = 16.dp, vertical = 4.dp),
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                item {
                    FilterChip(
                        selected = selectedCategory == SearchCategory.ALL,
                        onClick = { selectedCategory = SearchCategory.ALL },
                        label = { Text(if (isBangla) "সব ফলাফল" else "All Results") }
                    )
                }
                item {
                    FilterChip(
                        selected = selectedCategory == SearchCategory.MEMBERS,
                        onClick = { selectedCategory = SearchCategory.MEMBERS },
                        label = { Text(if (isBangla) "সদস্যবৃন্দ" else "Members") }
                    )
                }
                item {
                    FilterChip(
                        selected = selectedCategory == SearchCategory.RECEIPTS,
                        onClick = { selectedCategory = SearchCategory.RECEIPTS },
                        label = { Text(if (isBangla) "রশিদ নম্বর" else "Receipt No") }
                    )
                }
                item {
                    FilterChip(
                        selected = selectedCategory == SearchCategory.PHONES,
                        onClick = { selectedCategory = SearchCategory.PHONES },
                        label = { Text(if (isBangla) "ফোন নম্বর" else "Phone Number") }
                    )
                }
            }

            // Results List
            if (searchQuery.isBlank()) {
                Box(
                    modifier = Modifier.fillMaxSize(),
                    contentAlignment = Alignment.Center
                ) {
                    EmptyStateView(
                        icon = Icons.Default.Search,
                        title = if (isBangla) "অনুসন্ধান করতে টাইপ করুন" else "Type to Search",
                        description = if (isBangla) "সদস্যের নাম, মোবাইল নম্বর, সদস্য আইডি কিংবা রশিদ নম্বর দিয়ে অনুসন্ধান করতে পারেন।" else "Search by member name, mobile number, member ID, or receipt number."
                    )
                }
            } else if (matchedMembers.isEmpty() && matchedPayments.isEmpty()) {
                Box(
                    modifier = Modifier.fillMaxSize(),
                    contentAlignment = Alignment.Center
                ) {
                    EmptyStateView(
                        icon = Icons.Default.Search,
                        title = if (isBangla) "কোনো তথ্য পাওয়া যায়নি" else "No Data Found",
                        description = if (isBangla) "'$searchQuery' দিয়ে কোনো সদস্য বা রশিদ খুঁজে পাওয়া যায়নি।" else "No member or receipt found matching '$searchQuery'."
                    )
                }
            } else {
                LazyColumn(
                    modifier = Modifier.fillMaxSize(),
                    contentPadding = PaddingValues(16.dp),
                    verticalArrangement = Arrangement.spacedBy(12.dp)
                ) {
                    if (matchedMembers.isNotEmpty()) {
                        item {
                            Text(
                                text = if (isBangla) "সদস্যবৃন্দ (${matchedMembers.size})" else "Members (${matchedMembers.size})",
                                style = MaterialTheme.typography.titleMedium,
                                fontWeight = FontWeight.Bold,
                                color = MaterialTheme.colorScheme.primary,
                                modifier = Modifier.padding(bottom = 4.dp)
                            )
                        }

                        items(matchedMembers) { member ->
                            SearchMemberCard(
                                member = member,
                                onClick = { onMemberClick(member.id) }
                            )
                        }
                    }

                    if (matchedPayments.isNotEmpty()) {
                        item {
                            Spacer(modifier = Modifier.height(8.dp))
                            Text(
                                text = if (isBangla) "জমা রশিদসমূহ (${matchedPayments.size})" else "Receipts (${matchedPayments.size})",
                                style = MaterialTheme.typography.titleMedium,
                                fontWeight = FontWeight.Bold,
                                color = MaterialTheme.colorScheme.primary,
                                modifier = Modifier.padding(bottom = 4.dp)
                            )
                        }

                        items(matchedPayments) { payment ->
                            SearchPaymentCard(
                                payment = payment,
                                isBangla = isBangla,
                                onClick = { onPaymentClick(payment) }
                            )
                        }
                    }
                }
            }
        }
    }
}
