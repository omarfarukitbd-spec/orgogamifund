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
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.imePadding
import com.helptrickbd.myapplicationsomithierp.core.data.FirestoreWriteManager
import com.helptrickbd.myapplicationsomithierp.domain.model.*
import com.helptrickbd.myapplicationsomithierp.presentation.screens.admin.components.*

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun CreateSomithiFundScreen(
    onNavigateBack: () -> Unit = {}
) {
    val context = LocalContext.current
    val isBangla = LocalConfiguration.current.locales[0].language == "bn"

    // Section 1: Identity
    var nameText by remember { mutableStateOf("") }
    var codeText by remember { mutableStateOf("") }
    var yearText by remember { mutableStateOf("") }
    var descText by remember { mutableStateOf("") }
    var logoUrlText by remember { mutableStateOf("") }
    var bannerUrlText by remember { mutableStateOf("") }

    // Section 1: Contribution
    var monthlyAmountText by remember { mutableStateOf("500") }
    var admissionFeeText by remember { mutableStateOf("0") }
    var optionalEnabled by remember { mutableStateOf(false) }
    var minOptionalText by remember { mutableStateOf("") }
    var dueDayText by remember { mutableStateOf("10") }
    var lateFineText by remember { mutableStateOf("0") }

    // Section 2: Payment
    var bkashText by remember { mutableStateOf("") }
    var nagadText by remember { mutableStateOf("") }
    var bankNameText by remember { mutableStateOf("ইসলামী ব্যাংক বাংলাদেশ পিএলসি") }
    var bankAccText by remember { mutableStateOf("") }
    var bankBranchText by remember { mutableStateOf("") }
    var routingText by remember { mutableStateOf("") }

    // Section 2: Permissions (all on by default)
    var allowViewTotalFund by remember { mutableStateOf(true) }
    var allowViewExpenses by remember { mutableStateOf(true) }
    var allowViewMembers by remember { mutableStateOf(true) }
    var allowViewNotices by remember { mutableStateOf(true) }
    var allowViewPaymentHistory by remember { mutableStateOf(true) }

    // Section 3: Terms
    var terms by remember {
        mutableStateOf(
            listOf(
                "প্রতি মাসে নির্ধারিত তারিখের মধ্যে বাধ্যতামূলক মাসিক চাঁদা পরিশোধ করতে হবে।",
                "মাদ্রাসার উন্নয়ন ও শিক্ষার্থীদের কল্যাণে সংগৃহীত অর্থ ব্যয় করা হবে।",
                "সমিতির সাধারণ বিধিমালা ও পরিচালনা পরিষদের সিদ্ধান্ত মেনে চলতে হবে।",
                "সমিতির অভ্যন্তরীণ শৃঙ্খলা ও ঐক্য বজায় রাখতে হবে।"
            )
        )
    }

    var isSubmitting by remember { mutableStateOf(false) }
    val isValid = nameText.isNotBlank() && monthlyAmountText.isNotBlank()

    Scaffold(
        contentWindowInsets = WindowInsets(0),
        topBar = {
            TopAppBar(
                title = {
                    Text(
                        text = if (isBangla) "নতুন সমিতি ফান্ড তৈরি করুন" else "Create Somithi Fund",
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
            // --- SECTION 1: IDENTITY ---
            CreateFundSection1Identity(
                isBangla = isBangla,
                nameText = nameText, onNameChange = { nameText = it },
                codeText = codeText, onCodeChange = { codeText = it },
                yearText = yearText, onYearChange = { yearText = it },
                descText = descText, onDescChange = { descText = it },
                logoUrlText = logoUrlText, onLogoUrlChange = { logoUrlText = it },
                bannerUrlText = bannerUrlText, onBannerUrlChange = { bannerUrlText = it }
            )

            // --- SECTION 1: CONTRIBUTION RULES ---
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

            // --- SECTION 2: PAYMENT ACCOUNTS ---
            CreateFundSection2Payment(
                isBangla = isBangla,
                bkashText = bkashText, onBkashChange = { bkashText = it },
                nagadText = nagadText, onNagadChange = { nagadText = it },
                bankNameText = bankNameText, onBankNameChange = { bankNameText = it },
                bankAccText = bankAccText, onBankAccChange = { bankAccText = it },
                bankBranchText = bankBranchText, onBankBranchChange = { bankBranchText = it },
                routingText = routingText, onRoutingChange = { routingText = it }
            )

            // --- SECTION 2: PERMISSIONS ---
            CreateFundSection2Permissions(
                isBangla = isBangla,
                allowViewTotalFund = allowViewTotalFund, onTotalFundChange = { allowViewTotalFund = it },
                allowViewExpenses = allowViewExpenses, onExpensesChange = { allowViewExpenses = it },
                allowViewMembers = allowViewMembers, onMembersChange = { allowViewMembers = it },
                allowViewNotices = allowViewNotices, onNoticesChange = { allowViewNotices = it },
                allowViewPaymentHistory = allowViewPaymentHistory,
                onPaymentHistoryChange = { allowViewPaymentHistory = it }
            )

            // --- SECTION 3: TERMS & CONDITIONS ---
            CreateFundSection3Terms(
                isBangla = isBangla,
                terms = terms,
                onTermsChange = { terms = it }
            )

            Spacer(modifier = Modifier.height(8.dp))

            // --- SUBMIT BUTTON ---
            Button(
                onClick = {
                    if (!isValid) return@Button
                    isSubmitting = true
                    val branch = Branch(
                        name = nameText.trim(),
                        code = codeText.trim(),
                        establishedYear = yearText.trim(),
                        description = descText.trim(),
                        logoUrl = logoUrlText.trim(),
                        bannerUrl = bannerUrlText.trim(),
                        monthlyDepositAmount = monthlyAmountText.toDoubleOrNull() ?: 500.0,
                        admissionFee = admissionFeeText.toDoubleOrNull() ?: 0.0,
                        optionalDepositEnabled = optionalEnabled,
                        minOptionalDeposit = minOptionalText.toDoubleOrNull() ?: 0.0,
                        monthlyDueDay = dueDayText.toIntOrNull() ?: 10,
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
                    FirestoreWriteManager.createBranch(branch) { success ->
                        isSubmitting = false
                        Toast.makeText(
                            context,
                            if (success) (if (isBangla) "সমিতি সফলভাবে তৈরি হয়েছে" else "Somithi created!")
                            else (if (isBangla) "তৈরি ব্যর্থ হয়েছে" else "Failed to create"),
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
                    text = if (isSubmitting) (if (isBangla) "তৈরি হচ্ছে..." else "Creating...")
                    else (if (isBangla) "নতুন সমিতি ফান্ড তৈরি করুন" else "Create Somithi Fund"),
                    fontWeight = FontWeight.Bold,
                    style = MaterialTheme.typography.bodyLarge
                )
            }

            Spacer(modifier = Modifier.height(16.dp))
        }
    }
}
