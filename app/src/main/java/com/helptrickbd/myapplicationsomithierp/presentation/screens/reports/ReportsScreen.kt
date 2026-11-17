package com.helptrickbd.myapplicationsomithierp.presentation.screens.reports

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.Print
import androidx.compose.material.icons.filled.Share
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Scaffold
import androidx.compose.material3.ScrollableTabRow
import androidx.compose.material3.Surface
import androidx.compose.material3.Tab
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalConfiguration
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.helptrickbd.myapplicationsomithierp.core.pdf.ReportPdfGenerator
import com.helptrickbd.myapplicationsomithierp.domain.model.Expense
import com.helptrickbd.myapplicationsomithierp.domain.model.Member
import com.helptrickbd.myapplicationsomithierp.domain.model.Payment
import com.helptrickbd.myapplicationsomithierp.presentation.screens.reports.components.ExpenseReportPreview
import com.helptrickbd.myapplicationsomithierp.presentation.screens.reports.components.LoanReportPreview
import com.helptrickbd.myapplicationsomithierp.presentation.screens.reports.components.MemberLedgerReportPreview
import com.helptrickbd.myapplicationsomithierp.presentation.screens.reports.components.SummaryReportPreview

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ReportsScreen(
    members: List<Member> = emptyList(),
    payments: List<Payment> = emptyList(),
    expenses: List<Expense> = emptyList(),
    onNavigateBack: () -> Unit = {}
) {
    val context = LocalContext.current
    val isBangla = LocalConfiguration.current.locales[0].language == "bn"
    var selectedReportIndex by remember { mutableIntStateOf(0) }
    val reportTypes = remember(isBangla) {
        if (isBangla) listOf(
            "সারসংক্ষেপ বিবরণী",
            "খরচ রেজিস্টার",
            "করযে হাসানা ও আদায়",
            "সদস্যদের লেজার"
        ) else listOf(
            "Executive Summary",
            "Expense Register",
            "Qard Hasan & Collections",
            "Member Ledger"
        )
    }

    val currentReportTitle = when (selectedReportIndex) {
        0 -> if (isBangla) "অগ্রগামী ফান্ডের সার্বিক মাসিক ও বার্ষিক সারসংক্ষেপ বিবরণী" else "Ogrogami Fund Executive Summary Statement"
        1 -> if (isBangla) "অগ্রগামী ফান্ডের খরচ ও ভাউচার রেজিস্টার বিবরণী" else "Ogrogami Fund Expense Register Statement"
        2 -> if (isBangla) "করযে হাসানা বিতরণ ও কিস্তি আদায় বিবরণী" else "Qard Hasan Disbursement & Collection Statement"
        else -> if (isBangla) "সদস্যদের চাঁদা, সঞ্চয় ও বকেয়া লেজার বিবরণী" else "Member Contribution, Savings & Dues Ledger"
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    Text(
                        text = if (isBangla) "রিপোর্টস ও আর্থিক বিবরণী" else "Reports & Financial Statements",
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
        },
        bottomBar = {
            Surface(
                tonalElevation = 6.dp,
                shadowElevation = 8.dp,
                color = MaterialTheme.colorScheme.surface
            ) {
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(16.dp),
                    horizontalArrangement = Arrangement.spacedBy(12.dp)
                ) {
                    OutlinedButton(
                        onClick = {
                            val pdf = ReportPdfGenerator.generateReportPdf(
                                context = context,
                                reportTitle = currentReportTitle,
                                members = members,
                                payments = payments,
                                expenses = expenses
                            )
                            ReportPdfGenerator.shareReportPdf(context, pdf)
                        },
                        modifier = Modifier.weight(1f),
                        shape = RoundedCornerShape(12.dp)
                    ) {
                        Icon(imageVector = Icons.Default.Share, contentDescription = null, modifier = Modifier.size(18.dp))
                        Spacer(modifier = Modifier.width(6.dp))
                        Text(if (isBangla) "শেয়ার / PDF" else "Share / PDF")
                    }

                    Button(
                        onClick = {
                            val pdf = ReportPdfGenerator.generateReportPdf(
                                context = context,
                                reportTitle = currentReportTitle,
                                members = members,
                                payments = payments,
                                expenses = expenses
                            )
                            ReportPdfGenerator.printReport(context, pdf)
                        },
                        modifier = Modifier.weight(1f),
                        shape = RoundedCornerShape(12.dp),
                        colors = ButtonDefaults.buttonColors(containerColor = MaterialTheme.colorScheme.primary)
                    ) {
                        Icon(imageVector = Icons.Default.Print, contentDescription = null, modifier = Modifier.size(18.dp))
                        Spacer(modifier = Modifier.width(6.dp))
                        Text(if (isBangla) "প্রিন্ট করুন" else "Print")
                    }
                }
            }
        }
    ) { innerPadding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(innerPadding)
        ) {
            // Report Tabs
            ScrollableTabRow(
                selectedTabIndex = selectedReportIndex,
                edgePadding = 16.dp
            ) {
                reportTypes.forEachIndexed { index, title ->
                    Tab(
                        selected = selectedReportIndex == index,
                        onClick = { selectedReportIndex = index },
                        text = { Text(title, fontWeight = if (selectedReportIndex == index) FontWeight.Bold else FontWeight.Normal) }
                    )
                }
            }

            // Report Preview Content
            when (selectedReportIndex) {
                0 -> SummaryReportPreview(members = members, payments = payments, expenses = expenses, isBangla = isBangla)
                1 -> ExpenseReportPreview(expenses = expenses, isBangla = isBangla)
                2 -> DefaultersReportPreview(members = members, isBangla = isBangla)
                3 -> MemberLedgerReportPreview(members = members, isBangla = isBangla)
            }
        }
    }
}
