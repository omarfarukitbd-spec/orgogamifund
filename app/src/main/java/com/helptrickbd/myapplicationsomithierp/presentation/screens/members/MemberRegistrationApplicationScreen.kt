package com.helptrickbd.myapplicationsomithierp.presentation.screens.members

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.helptrickbd.myapplicationsomithierp.core.util.safeRound
import com.helptrickbd.myapplicationsomithierp.domain.model.ApprovalStatus
import com.helptrickbd.myapplicationsomithierp.domain.model.Branch
import com.helptrickbd.myapplicationsomithierp.domain.model.MemberApplication
import com.helptrickbd.myapplicationsomithierp.presentation.screens.members.components.*
import kotlinx.coroutines.launch
import java.util.UUID

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun MemberRegistrationApplicationScreen(
    availableBranches: List<Branch> = emptyList(),
    initialBranchId: String? = null,
    onSubmitApplication: (MemberApplication) -> Unit = {},
    onNavigateBack: () -> Unit = {}
) {
    var currentStep by remember { mutableIntStateOf(1) }
    val scope = rememberCoroutineScope()
    val snackbarHostState = remember { SnackbarHostState() }

    // Step 1 State: Personal Details
    var applicantName by remember { mutableStateOf("") }
    var phone by remember { mutableStateOf("") }
    var email by remember { mutableStateOf("") }
    var fatherOrHusbandName by remember { mutableStateOf("") }
    var occupation by remember { mutableStateOf("") }
    var bloodGroup by remember { mutableStateOf("B+") }
    var presentAddress by remember { mutableStateOf("") }
    var permanentAddress by remember { mutableStateOf("") }

    // Step 2 State: Shomiti & Nominee
    val defaultBranch = availableBranches.firstOrNull { it.id == initialBranchId }
        ?: availableBranches.firstOrNull()
        ?: Branch(id = "b-1", name = "অগ্রগামী সঞ্চয় ও ঋণদান সমিতি")
    var selectedBranch by remember(initialBranchId, availableBranches) { mutableStateOf(defaultBranch) }
    var shareCountText by remember { mutableStateOf("1") }
    var monthlyDepositText by remember { mutableStateOf("1000") }
    var nomineeName by remember { mutableStateOf("") }
    var nomineeRelation by remember { mutableStateOf("স্ত্রী") }
    var nomineePhone by remember { mutableStateOf("") }
    var nomineeNid by remember { mutableStateOf("") }

    // Step 3 State: Documents & Verification
    var nidNumber by remember { mutableStateOf("") }
    var isNidAttached by remember { mutableStateOf(true) }
    var isPhotoAttached by remember { mutableStateOf(true) }
    var termsAgreed by remember { mutableStateOf(false) }

    Scaffold(
        snackbarHost = { SnackbarHost(hostState = snackbarHostState) },
        topBar = {
            TopAppBar(
                title = {
                    Column {
                        Text(
                            text = "সদস্য আবেদন ফরম",
                            style = MaterialTheme.typography.titleMedium,
                            fontWeight = FontWeight.Bold
                        )
                        Text(
                            text = "অগ্রগামী ফান্ড",
                            style = MaterialTheme.typography.labelSmall,
                            color = MaterialTheme.colorScheme.primary
                        )
                    }
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
                .padding(20.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            StepProgressHeader(currentStep = currentStep)

            when (currentStep) {
                1 -> {
                    RegistrationStepOne(
                        applicantName = applicantName,
                        onApplicantNameChange = { applicantName = it },
                        phone = phone,
                        onPhoneChange = { phone = it },
                        fatherOrHusbandName = fatherOrHusbandName,
                        onFatherOrHusbandNameChange = { fatherOrHusbandName = it },
                        occupation = occupation,
                        onOccupationChange = { occupation = it },
                        bloodGroup = bloodGroup,
                        onBloodGroupChange = { bloodGroup = it },
                        presentAddress = presentAddress,
                        onPresentAddressChange = { presentAddress = it },
                        permanentAddress = permanentAddress,
                        onPermanentAddressChange = { permanentAddress = it },
                        onNext = {
                            if (applicantName.isBlank() || phone.isBlank() || presentAddress.isBlank()) {
                                scope.launch {
                                    snackbarHostState.showSnackbar("অনুগ্রহ করে নাম, মোবাইল এবং ঠিকানা পূরণ করুন")
                                }
                            } else {
                                currentStep = 2
                            }
                        }
                    )
                }
                2 -> {
                    RegistrationStepTwo(
                        availableBranches = availableBranches,
                        selectedBranch = selectedBranch,
                        onBranchSelected = { selectedBranch = it },
                        shareCountText = shareCountText,
                        onShareCountChange = { shareCountText = it },
                        monthlyDepositText = monthlyDepositText,
                        onMonthlyDepositChange = { monthlyDepositText = it },
                        nomineeName = nomineeName,
                        onNomineeNameChange = { nomineeName = it },
                        nomineeRelation = nomineeRelation,
                        onNomineeRelationChange = { nomineeRelation = it },
                        nomineePhone = nomineePhone,
                        onNomineePhoneChange = { nomineePhone = it },
                        nomineeNid = nomineeNid,
                        onNomineeNidChange = { nomineeNid = it },
                        onBack = { currentStep = 1 },
                        onNext = {
                            if (nomineeName.isBlank()) {
                                scope.launch {
                                    snackbarHostState.showSnackbar("অনুগ্রহ করে নমিনীর নাম প্রদান করুন")
                                }
                            } else {
                                currentStep = 3
                            }
                        }
                    )
                }
                3 -> {
                    RegistrationStepThree(
                        selectedBranch = selectedBranch,
                        nidNumber = nidNumber,
                        onNidNumberChange = { nidNumber = it },
                        isNidAttached = isNidAttached,
                        onToggleNidAttached = { isNidAttached = !isNidAttached },
                        isPhotoAttached = isPhotoAttached,
                        onTogglePhotoAttached = { isPhotoAttached = !isPhotoAttached },
                        termsAgreed = termsAgreed,
                        onTermsAgreedChange = { termsAgreed = it },
                        onBack = { currentStep = 2 },
                        onSubmit = {
                            if (nidNumber.isBlank()) {
                                scope.launch {
                                    snackbarHostState.showSnackbar("অনুগ্রহ করে আপনার NID নম্বরটি লিখুন")
                                }
                            } else if (!termsAgreed) {
                                scope.launch {
                                    snackbarHostState.showSnackbar("অনুগ্রহ করে নিয়মাবলী স্বীকার বাক্সে টিক চিহ্ন দিন")
                                }
                            } else {
                                val safeShareCount = shareCountText.toIntOrNull() ?: 1
                                val safeDeposit = (monthlyDepositText.toDoubleOrNull() ?: 1000.0).safeRound()

                                val newApplication = MemberApplication(
                                    id = "APP-${UUID.randomUUID().toString().take(6).uppercase()}",
                                    applicantName = applicantName.trim(),
                                    phone = phone.trim(),
                                    email = email.trim(),
                                    fatherOrHusbandName = fatherOrHusbandName.trim(),
                                    occupation = occupation.trim().ifEmpty { "ব্যবসায়ী" },
                                    bloodGroup = bloodGroup.trim(),
                                    presentAddress = presentAddress.trim(),
                                    permanentAddress = permanentAddress.trim().ifEmpty { presentAddress.trim() },
                                    nidNumber = nidNumber.trim(),
                                    hasNidDocument = isNidAttached,
                                    hasPhotoDocument = isPhotoAttached,
                                    nomineeName = nomineeName.trim(),
                                    nomineeRelation = nomineeRelation.trim(),
                                    nomineePhone = nomineePhone.trim(),
                                    nomineeNid = nomineeNid.trim(),
                                    targetShomitiId = selectedBranch.id,
                                    targetShomitiName = selectedBranch.name,
                                    shareCount = safeShareCount,
                                    monthlyDepositCommitment = safeDeposit,
                                    status = ApprovalStatus.PENDING,
                                    appliedAt = System.currentTimeMillis()
                                )
                                onSubmitApplication(newApplication)
                            }
                        }
                    )
                }
            }
        }
    }
}
