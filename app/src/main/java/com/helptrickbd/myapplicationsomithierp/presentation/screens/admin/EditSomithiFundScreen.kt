package com.helptrickbd.myapplicationsomithierp.presentation.screens.admin

import android.widget.Toast
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalConfiguration
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.helptrickbd.myapplicationsomithierp.core.data.FirestoreWriteManager
import com.helptrickbd.myapplicationsomithierp.domain.model.*
import com.helptrickbd.myapplicationsomithierp.presentation.screens.admin.components.*

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun EditSomithiFundScreen(
    branch: Branch,
    onNavigateBack: () -> Unit = {}
) {
    val context = LocalContext.current
    val isBangla = LocalConfiguration.current.locales[0].language == "bn"

    // Section 1: Identity — pre-filled
    var nameText by remember { mutableStateOf(branch.name) }
    var codeText by remember { mutableStateOf(branch.code) }
    var yearText by remember { mutableStateOf(branch.establishedYear) }
    var descText by remember { mutableStateOf(branch.description) }
    var logoUrlText by remember { mutableStateOf(branch.logoUrl) }
    var bannerUrlText by remember { mutableStateOf(branch.bannerUrl) }

    // Section 1: Contribution — pre-filled
    var monthlyAmountText by remember { mutableStateOf(branch.monthlyDepositAmount.toInt().toString()) }
    var admissionFeeText by remember { mutableStateOf(branch.admissionFee.toInt().toString()) }
    var optionalEnabled by remember { mutableStateOf(branch.optionalDepositEnabled) }
    var minOptionalText by remember { mutableStateOf(if (branch.minOptionalDeposit > 0) branch.minOptionalDeposit.toInt().toString() else "") }
    var dueDayText by remember { mutableStateOf(branch.monthlyDueDay.toString()) }
    var lateFineText by remember { mutableStateOf(branch.lateFineAmount.toInt().toString()) }

    // Section 2: Payment — pre-filled
    var bkashText by remember { mutableStateOf(branch.bkashNumber) }
    var nagadText by remember { mutableStateOf(branch.nagadNumber) }
    var bankNameText by remember { mutableStateOf(branch.bankDetails.bankName) }
    var bankAccText by remember { mutableStateOf(branch.bankDetails.accountNumber) }
    var bankBranchText by remember { mutableStateOf(branch.bankDetails.branchName) }
    var routingText by remember { mutableStateOf(branch.bankDetails.routingNumber) }

    // Section 2: Permissions — pre-filled
    var allowViewTotalFund by remember { mutableStateOf(branch.permissions.canMembersViewTotalFund) }
    var allowViewExpenses by remember { mutableStateOf(branch.permissions.canMembersViewExpenses) }
    var allowViewMembers by remember { mutableStateOf(branch.permissions.canMembersViewMemberList) }
    var allowViewNotices by remember { mutableStateOf(branch.permissions.canMembersViewNotices) }
    var allowViewPaymentHistory by remember { mutableStateOf(branch.permissions.canMembersViewPaymentHistory) }

    // Section 3: Terms — pre-filled
    var terms by remember { mutableStateOf(branch.termsAndConditions.ifEmpty {
        listOf("প্রতি মাসে নির্ধারিত তারিখের মধ্যে বাধ্যতামূলক মাসিক চাঁদা পরিশোধ করতে হবে।")
    }) }

    var isSubmitting by remember { mutableStateOf(false) }
    val isValid = nameText.isNotBlank() && monthlyAmountText.isNotBlank()

    Scaffold(
        contentWindowInsets = WindowInsets(0, 0, 0, 0),
        topBar = {
            TopAppBar(
                title = {
                    Text(
                        text = if (isBangla) "সমিতি সম্পাদনা করুন" else "Edit Somithi Fund",
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.Bold
                    )
                },
                navigationIcon = {
                    IconButton(onClick = onNavigateBack) {
                        Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "Back")
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
                .imePadding()
                .verticalScroll(rememberScrollState())
                .padding(horizontal = 16.dp, vertical = 12.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            CreateFundSection1Identity(
                isBangla = isBangla,
                nameText = nameText, onNameChange = { nameText = it },
                codeText = codeText, onCodeChange = { codeText = it },
                yearText = yearText, onYearChange = { yearText = it },
                descText = descText, onDescChange = { descText = it },
                logoUrlText = logoUrlText, onLogoUrlChange = { logoUrlText = it },
                bannerUrlText = bannerUrlText, onBannerUrlChange = { bannerUrlText = it }
            )

            CreateFundSection1Contribution(
                isBangla = isBangla,
                monthlyAmountText = monthlyAmountText,
                onMonthlyAmountChange = { monthlyAmountText = it },
                admissionFeeText = admissionFeeText,
                onAdmissionFeeChange = { admissionFeeText = it },
                optionalEnabled = optionalEnabled,
                onOptionalEnabledChange = { optionalEnabled = it },
                minOptionalText = minOptionalText,
                onMinOptionalChange = { minOptionalText = it },
                dueDayText = dueDayText, onDueDayChange = { dueDayText = it },
                lateFineText = lateFineText, onLateFineChange = { lateFineText = it }
            )

            CreateFundSection2Payment(
                isBangla = isBangla,
                bkashText = bkashText, onBkashChange = { bkashText = it },
                nagadText = nagadText, onNagadChange = { nagadText = it },
                bankNameText = bankNameText, onBankNameChange = { bankNameText = it },
                bankAccText = bankAccText, onBankAccChange = { bankAccText = it },
                bankBranchText = bankBranchText, onBankBranchChange = { bankBranchText = it },
                routingText = routingText, onRoutingChange = { routingText = it }
            )

            CreateFundSection2Permissions(
                isBangla = isBangla,
                allowViewTotalFund = allowViewTotalFund, onTotalFundChange = { allowViewTotalFund = it },
                allowViewExpenses = allowViewExpenses, onExpensesChange = { allowViewExpenses = it },
                allowViewMembers = allowViewMembers, onMembersChange = { allowViewMembers = it },
                allowViewNotices = allowViewNotices, onNoticesChange = { allowViewNotices = it },
                allowViewPaymentHistory = allowViewPaymentHistory,
                onPaymentHistoryChange = { allowViewPaymentHistory = it }
            )

            CreateFundSection3Terms(
                isBangla = isBangla,
                terms = terms,
                onTermsChange = { terms = it }
            )

            Spacer(modifier = Modifier.height(8.dp))

            Button(
                onClick = {
                    if (!isValid) return@Button
                    isSubmitting = true
                    val updated = branch.copy(
                        name = nameText.trim(),
                        code = codeText.trim(),
                        establishedYear = yearText.trim(),
                        description = descText.trim(),
                        logoUrl = logoUrlText.trim(),
                        bannerUrl = bannerUrlText.trim(),
                        monthlyDepositAmount = monthlyAmountText.toDoubleOrNull() ?: branch.monthlyDepositAmount,
                        admissionFee = admissionFeeText.toDoubleOrNull() ?: branch.admissionFee,
                        optionalDepositEnabled = optionalEnabled,
                        minOptionalDeposit = minOptionalText.toDoubleOrNull() ?: 0.0,
                        monthlyDueDay = dueDayText.toIntOrNull() ?: branch.monthlyDueDay,
                        lateFineAmount = lateFineText.toDoubleOrNull() ?: 0.0,
                        bkashNumber = bkashText.trim(),
                        nagadNumber = nagadText.trim(),
                        bankDetails = BankAccountDetails(
                            bankName = bankNameText.trim(),
                            accountName = nameText.trim(),
                            accountNumber = bankAccText.trim(),
                            branchName = bankBranchText.trim(),
                            routingNumber = routingText.trim()
                        ),
                        permissions = SomithiPermissions(
                            canMembersViewTotalFund = allowViewTotalFund,
                            canMembersViewExpenses = allowViewExpenses,
                            canMembersViewMemberList = allowViewMembers,
                            canMembersViewNotices = allowViewNotices,
                            canMembersViewPaymentHistory = allowViewPaymentHistory
                        ),
                        termsAndConditions = terms.filter { it.isNotBlank() }
                    )
                    FirestoreWriteManager.createBranch(updated) { success ->
                        isSubmitting = false
                        Toast.makeText(
                            context,
                            if (success) (if (isBangla) "সমিতি সফলভাবে আপডেট হয়েছে" else "Somithi updated!")
                            else (if (isBangla) "আপডেট ব্যর্থ হয়েছে" else "Update failed"),
                            Toast.LENGTH_SHORT
                        ).show()
                        if (success) onNavigateBack()
                    }
                },
                enabled = isValid && !isSubmitting,
                modifier = Modifier.fillMaxWidth().height(54.dp),
                shape = MaterialTheme.shapes.medium
            ) {
                Text(
                    text = if (isSubmitting) (if (isBangla) "আপডেট হচ্ছে..." else "Updating...")
                    else (if (isBangla) "পরিবর্তন সংরক্ষণ করুন" else "Save Changes"),
                    fontWeight = FontWeight.Bold,
                    style = MaterialTheme.typography.bodyLarge
                )
            }

            Spacer(modifier = Modifier.height(16.dp))
        }
    }
}
