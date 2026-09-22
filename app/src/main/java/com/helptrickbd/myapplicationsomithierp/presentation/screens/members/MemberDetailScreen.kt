package com.helptrickbd.myapplicationsomithierp.presentation.screens.members

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.automirrored.filled.Chat
import androidx.compose.material.icons.automirrored.filled.ExitToApp
import androidx.compose.material.icons.filled.Badge
import androidx.compose.material.icons.filled.Call
import androidx.compose.material.icons.filled.Edit
import androidx.compose.material.icons.filled.MenuBook
import androidx.compose.material.icons.filled.Person
import androidx.compose.material.icons.filled.Print
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.platform.LocalConfiguration
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.helptrickbd.myapplicationsomithierp.R
import com.helptrickbd.myapplicationsomithierp.core.pdf.MemberIdCardGenerator
import com.helptrickbd.myapplicationsomithierp.domain.model.Member
import com.helptrickbd.myapplicationsomithierp.domain.model.MemberStatus
import com.helptrickbd.myapplicationsomithierp.presentation.screens.members.components.DetailRow
import com.helptrickbd.myapplicationsomithierp.presentation.screens.members.components.LedgerStatCard
import com.helptrickbd.myapplicationsomithierp.presentation.screens.members.components.MemberExitSettlementDialog
import com.helptrickbd.myapplicationsomithierp.ui.theme.MoneyDueAmber
import com.helptrickbd.myapplicationsomithierp.ui.theme.MoneyExpenseRed
import com.helptrickbd.myapplicationsomithierp.ui.theme.MoneyIncomeGreen
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun MemberDetailScreen(
    member: Member,
    orgName: String = "অগ্রগামী ফান্ড",
    onCallClick: (phone: String) -> Unit = {},
    onWhatsAppClick: (phone: String) -> Unit = {},
    onEditClick: () -> Unit = {},
    onNavigateToIdCard: (memberId: String) -> Unit = {},
    onNavigateToPassbook: (memberId: String) -> Unit = {},
    onExitSettlementClick: () -> Unit = {},
    onConfirmExit: (payoutMethod: String, note: String) -> Unit = { _, _ -> },
    onNavigateBack: () -> Unit = {}
) {
    val context = LocalContext.current
    val isBangla = LocalConfiguration.current.locales[0].language == "bn"
    var showSettlementDialog by remember { mutableStateOf(false) }
    var selectedPayoutMethod by remember { mutableStateOf("Cash") }
    var settlementNote by remember { mutableStateOf("") }

    val dateFormat = SimpleDateFormat("dd MMMM, yyyy", Locale.getDefault())
    val joinDateStr = dateFormat.format(Date(member.joinDate))

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text(text = if (isBangla) "সদস্য প্রোফাইল" else "Member Profile", fontWeight = FontWeight.Bold) },
                navigationIcon = {
                    IconButton(onClick = onNavigateBack) {
                        Icon(imageVector = Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "Back")
                    }
                },
                actions = {
                    IconButton(onClick = onEditClick) {
                        Icon(imageVector = Icons.Default.Edit, contentDescription = "Edit")
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
            // Member Header Profile Card
            Card(
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(20.dp),
                colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface),
                elevation = CardDefaults.cardElevation(defaultElevation = 2.dp)
            ) {
                Column(
                    modifier = Modifier.fillMaxWidth().padding(20.dp),
                    horizontalAlignment = Alignment.CenterHorizontally
                ) {
                    Box(
                        modifier = Modifier.size(80.dp).clip(CircleShape).background(MaterialTheme.colorScheme.primaryContainer),
                        contentAlignment = Alignment.Center
                    ) {
                        Icon(imageVector = Icons.Default.Person, contentDescription = null, tint = MaterialTheme.colorScheme.primary, modifier = Modifier.size(44.dp))
                    }

                    Spacer(modifier = Modifier.height(12.dp))
                    Text(text = member.name, style = MaterialTheme.typography.titleLarge, fontWeight = FontWeight.Bold)
                    Spacer(modifier = Modifier.height(4.dp))
                    Text(
                        text = if (isBangla) "সদস্য আইডি: #${member.id.take(8).uppercase()}" else "Member ID: #${member.id.take(8).uppercase()}",
                        style = MaterialTheme.typography.labelMedium,
                        color = MaterialTheme.colorScheme.primary,
                        fontWeight = FontWeight.SemiBold
                    )
                    Spacer(modifier = Modifier.height(8.dp))

                    Surface(
                        shape = RoundedCornerShape(8.dp),
                        color = if (member.status == MemberStatus.ACTIVE) MoneyIncomeGreen.copy(alpha = 0.12f) else MaterialTheme.colorScheme.error.copy(alpha = 0.12f)
                    ) {
                        Text(
                            text = if (member.status == MemberStatus.ACTIVE) (if (isBangla) "সক্রিয় সদস্য" else "Active Member") else (if (isBangla) "অব্যাহতিপ্রাপ্ত" else "Left"),
                            modifier = Modifier.padding(horizontal = 10.dp, vertical = 4.dp),
                            style = MaterialTheme.typography.labelSmall,
                            color = if (member.status == MemberStatus.ACTIVE) MoneyIncomeGreen else MaterialTheme.colorScheme.error,
                            fontWeight = FontWeight.Bold
                        )
                    }

                    Spacer(modifier = Modifier.height(16.dp))
                    Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                        Button(
                            onClick = { onCallClick(member.phone) },
                            modifier = Modifier.weight(1f),
                            shape = RoundedCornerShape(12.dp),
                            colors = ButtonDefaults.buttonColors(containerColor = MaterialTheme.colorScheme.primary)
                        ) {
                            Icon(imageVector = Icons.Default.Call, contentDescription = null, modifier = Modifier.size(18.dp))
                            Spacer(modifier = Modifier.width(6.dp))
                            Text(if (isBangla) "কল করুন" else "Call")
                        }

                        Button(
                            onClick = { onWhatsAppClick(member.phone) },
                            modifier = Modifier.weight(1f),
                            shape = RoundedCornerShape(12.dp),
                            colors = ButtonDefaults.buttonColors(containerColor = MoneyIncomeGreen)
                        ) {
                            Icon(imageVector = Icons.AutoMirrored.Filled.Chat, contentDescription = null, modifier = Modifier.size(18.dp))
                            Spacer(modifier = Modifier.width(6.dp))
                            Text(if (isBangla) "হোয়াটসঅ্যাপ" else "WhatsApp")
                        }
                    }
                }
            }

            // Digital Passbook Direct Action Card
            Card(
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(16.dp),
                colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.secondaryContainer.copy(alpha = 0.45f))
            ) {
                Row(
                    modifier = Modifier.fillMaxWidth().padding(16.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Icon(imageVector = Icons.Default.MenuBook, contentDescription = null, tint = MaterialTheme.colorScheme.secondary, modifier = Modifier.size(36.dp))
                    Spacer(modifier = Modifier.width(12.dp))
                    Column(modifier = Modifier.weight(1f)) {
                        Text(
                            text = if (isBangla) "সদস্য ডিজিটাল পাসবই" else "Member Digital Passbook",
                            style = MaterialTheme.typography.titleSmall,
                            fontWeight = FontWeight.Bold
                        )
                        Text(
                            text = if (isBangla) "১২ মাসের জমার অবস্থা ও সকল মানি রসিদের খাতা" else "12-month contribution tracker & receipt ledger",
                            style = MaterialTheme.typography.bodySmall,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }
                    Button(
                        onClick = { onNavigateToPassbook(member.id) },
                        shape = RoundedCornerShape(10.dp),
                        colors = ButtonDefaults.buttonColors(containerColor = MaterialTheme.colorScheme.secondary)
                    ) {
                        Text(if (isBangla) "পাসবই দেখুন" else "View Passbook")
                    }
                }
            }

            // Printable Membership ID Card Action Button
            Card(
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(16.dp),
                colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.primaryContainer.copy(alpha = 0.4f))
            ) {
                Row(
                    modifier = Modifier.fillMaxWidth().padding(16.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Icon(imageVector = Icons.Default.Badge, contentDescription = null, tint = MaterialTheme.colorScheme.primary, modifier = Modifier.size(36.dp))
                    Spacer(modifier = Modifier.width(12.dp))
                    Column(modifier = Modifier.weight(1f)) {
                        Text(text = stringResource(R.string.generate_id_card), style = MaterialTheme.typography.titleSmall, fontWeight = FontWeight.Bold)
                        Text(
                            text = if (isBangla) "লোগো ও ছবিসহ সরাসরি প্রিন্ট বা PDF ডাউনলোড করুন" else "Print or download PDF ID card with logo & photo",
                            style = MaterialTheme.typography.bodySmall,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }
                    OutlinedButton(onClick = { onNavigateToIdCard(member.id) }, shape = RoundedCornerShape(10.dp)) {
                        Text(if (isBangla) "কার্ড দেখুন" else "View Card")
                    }
                    Spacer(modifier = Modifier.width(6.dp))
                    Button(
                        onClick = {
                            val pdfFile = MemberIdCardGenerator.generateIdCardPdf(context = context, member = member, orgName = orgName)
                            MemberIdCardGenerator.printIdCard(context, pdfFile)
                        },
                        shape = RoundedCornerShape(10.dp),
                        colors = ButtonDefaults.buttonColors(containerColor = MaterialTheme.colorScheme.primary)
                    ) {
                        Icon(imageVector = Icons.Default.Print, contentDescription = null, modifier = Modifier.size(16.dp))
                        Spacer(modifier = Modifier.width(4.dp))
                        Text(if (isBangla) "প্রিন্ট" else "Print")
                    }
                }
            }

            // Financial Summary Ledger
            Text(text = if (isBangla) "আর্থিক সারসংক্ষেপ" else "Financial Summary", style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold)
            Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                LedgerStatCard(title = if (isBangla) "মোট সঞ্চয়/জমা" else "Total Savings", amount = member.totalContributed, color = MoneyIncomeGreen, isBangla = isBangla, modifier = Modifier.weight(1f))
                LedgerStatCard(title = if (isBangla) "বকেয়া চাঁদা" else "Dues", amount = member.outstandingDues, color = MoneyDueAmber, isBangla = isBangla, modifier = Modifier.weight(1f))
                LedgerStatCard(title = if (isBangla) "চলতি ঋণ" else "Active Loan", amount = member.activeLoanBalance, color = MoneyExpenseRed, isBangla = isBangla, modifier = Modifier.weight(1f))
            }

            // Detailed Information Card
            Card(modifier = Modifier.fillMaxWidth(), shape = RoundedCornerShape(16.dp), colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface)) {
                Column(modifier = Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
                    DetailRow(label = stringResource(R.string.member_phone), value = member.phone)
                    DetailRow(label = stringResource(R.string.member_address), value = member.address.ifEmpty { if (isBangla) "ঠিকানা দেওয়া হয়নি" else "Address not provided" })
                    DetailRow(label = stringResource(R.string.member_nid), value = member.nid.ifEmpty { if (isBangla) "NID দেওয়া হয়নি" else "NID not provided" })
                    DetailRow(label = stringResource(R.string.member_branch), value = member.branchId.ifEmpty { if (isBangla) "প্রধান শাখা" else "Main Branch" })
                    DetailRow(label = stringResource(R.string.member_join_date), value = joinDateStr)
                    if (member.emergencyContact.name.isNotEmpty()) {
                        DetailRow(label = if (isBangla) "জরুরি যোগাযোগ" else "Emergency Contact", value = "${member.emergencyContact.name} (${member.emergencyContact.phone})")
                    }
                }
            }

            // Exit / Resignation Settlement Workflow Trigger
            if (member.status == MemberStatus.ACTIVE) {
                OutlinedButton(
                    onClick = { onExitSettlementClick(); showSettlementDialog = true },
                    modifier = Modifier.fillMaxWidth(),
                    shape = RoundedCornerShape(12.dp),
                    colors = ButtonDefaults.outlinedButtonColors(contentColor = MaterialTheme.colorScheme.error)
                ) {
                    Icon(imageVector = Icons.AutoMirrored.Filled.ExitToApp, contentDescription = null, modifier = Modifier.size(18.dp))
                    Spacer(modifier = Modifier.width(8.dp))
                    Text(text = if (isBangla) "সদস্য পদত্যাগ ও চূড়ান্ত নিষ্পত্তি" else "Member Resignation & Final Settlement", style = MaterialTheme.typography.bodyMedium, fontWeight = FontWeight.Bold)
                }
            }
        }
    }

    if (showSettlementDialog) {
        MemberExitSettlementDialog(
            member = member,
            isBangla = isBangla,
            selectedPayoutMethod = selectedPayoutMethod,
            onPayoutMethodChange = { selectedPayoutMethod = it },
            settlementNote = settlementNote,
            onNoteChange = { settlementNote = it },
            onConfirmExit = { method, note -> onConfirmExit(method, note); showSettlementDialog = false },
            onDismiss = { showSettlementDialog = false }
        )
    }
}
