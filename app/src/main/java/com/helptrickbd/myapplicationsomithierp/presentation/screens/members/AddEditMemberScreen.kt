package com.helptrickbd.myapplicationsomithierp.presentation.screens.members

import android.net.Uri
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
import com.helptrickbd.myapplicationsomithierp.core.data.FirebaseStorageManager
import com.helptrickbd.myapplicationsomithierp.core.data.FirestoreWriteManager
import com.helptrickbd.myapplicationsomithierp.domain.model.*
import com.helptrickbd.myapplicationsomithierp.presentation.screens.members.components.*
import java.util.UUID

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun AddEditMemberScreen(
    existingMember: Member? = null,
    defaultBranchId: String = "",
    userRole: UserRole = UserRole.MEMBER,
    onNavigateBack: () -> Unit = {}
) {
    val context = LocalContext.current
    val isBangla = LocalConfiguration.current.locales[0].language == "bn"
    val isEdit = existingMember != null
    val isAdminOrSuper = userRole == UserRole.SUPER_ADMIN || userRole == UserRole.BRANCH_ADMIN

    // Section 1: Personal
    var name by remember { mutableStateOf(existingMember?.name ?: "") }
    var nameEn by remember { mutableStateOf(existingMember?.nameEn ?: "") }
    var fatherName by remember { mutableStateOf(existingMember?.fatherName ?: "") }
    var dateOfBirth by remember { mutableStateOf(existingMember?.dateOfBirth ?: "") }
    var occupation by remember { mutableStateOf(existingMember?.occupation ?: "") }
    var memberType by remember { mutableStateOf(existingMember?.memberType ?: "") }
    var customPersonal by remember { mutableStateOf(existingMember?.customFieldsPersonal ?: emptyMap()) }

    // Section 2: Contact
    var phone by remember { mutableStateOf(existingMember?.phone ?: "") }
    var whatsapp by remember { mutableStateOf(existingMember?.whatsappNumber ?: "") }
    var village by remember { mutableStateOf(existingMember?.village ?: "") }
    var upazila by remember { mutableStateOf(existingMember?.upazila ?: "") }
    var district by remember { mutableStateOf(existingMember?.district ?: "") }
    var customContact by remember { mutableStateOf(existingMember?.customFieldsContact ?: emptyMap()) }

    // Section 3: Docs & Photos
    var nid by remember { mutableStateOf(existingMember?.nid ?: "") }
    var profilePhotoUri by remember { mutableStateOf<Uri?>(null) }
    var nidPhotoUri by remember { mutableStateOf<Uri?>(null) }
    var customDocs by remember { mutableStateOf(existingMember?.customFieldsDocs ?: emptyMap()) }

    // Section 4: Emergency
    var emergencyName by remember { mutableStateOf(existingMember?.emergencyContact?.name ?: "") }
    var emergencyRelation by remember { mutableStateOf(existingMember?.emergencyContact?.relation ?: "") }
    var emergencyPhone by remember { mutableStateOf(existingMember?.emergencyContact?.phone ?: "") }
    var customEmergency by remember { mutableStateOf(existingMember?.customFieldsEmergency ?: emptyMap()) }

    var isSubmitting by remember { mutableStateOf(false) }
    var submitStep by remember { mutableStateOf("") }
    val isValid = name.isNotBlank() && phone.isNotBlank()

    Scaffold(
        contentWindowInsets = WindowInsets(0, 0, 0, 0),
        topBar = {
            TopAppBar(
                title = {
                    Text(
                        text = if (isEdit) (if (isBangla) "সদস্য সম্পাদনা" else "Edit Member")
                        else (if (isBangla) "নতুন সদস্য যোগ করুন" else "Add New Member"),
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.Bold
                    )
                },
                navigationIcon = {
                    IconButton(onClick = onNavigateBack) {
                        Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = null)
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
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            MemberFormSection1Personal(
                isBangla = isBangla, isAdminOrSuper = isAdminOrSuper,
                name = name, onNameChange = { name = it },
                nameEn = nameEn, onNameEnChange = { nameEn = it },
                fatherName = fatherName, onFatherNameChange = { fatherName = it },
                dateOfBirth = dateOfBirth, onDobChange = { dateOfBirth = it },
                occupation = occupation, onOccupationChange = { occupation = it },
                memberType = memberType, onMemberTypeChange = { memberType = it },
                customFields = customPersonal, onCustomFieldsChange = { customPersonal = it }
            )

            MemberFormSection2Contact(
                isBangla = isBangla, isAdminOrSuper = isAdminOrSuper,
                phone = phone, onPhoneChange = { phone = it },
                whatsapp = whatsapp, onWhatsappChange = { whatsapp = it },
                village = village, onVillageChange = { village = it },
                upazila = upazila, onUpazilaChange = { upazila = it },
                district = district, onDistrictChange = { district = it },
                customFields = customContact, onCustomFieldsChange = { customContact = it }
            )

            MemberFormSection3Photos(
                isBangla = isBangla, isAdminOrSuper = isAdminOrSuper,
                nid = nid, onNidChange = { nid = it },
                profilePhotoUri = profilePhotoUri,
                onProfilePhotoSelected = { profilePhotoUri = it },
                nidPhotoUri = nidPhotoUri,
                onNidPhotoSelected = { nidPhotoUri = it },
                existingPhotoUrl = existingMember?.photoUrl,
                existingNidUrl = existingMember?.nidPhotoUrl,
                customFields = customDocs, onCustomFieldsChange = { customDocs = it }
            )

            MemberFormSection4Emergency(
                isBangla = isBangla, isAdminOrSuper = isAdminOrSuper,
                emergencyName = emergencyName, onNameChange = { emergencyName = it },
                emergencyRelation = emergencyRelation, onRelationChange = { emergencyRelation = it },
                emergencyPhone = emergencyPhone, onPhoneChange = { emergencyPhone = it },
                customFields = customEmergency, onCustomFieldsChange = { customEmergency = it }
            )

            if (isSubmitting) {
                LinearProgressIndicator(modifier = Modifier.fillMaxWidth())
                Text(
                    text = submitStep,
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }

            Button(
                onClick = {
                    if (!isValid || isSubmitting) return@Button
                    isSubmitting = true
                    val memberId = existingMember?.id?.takeIf { it.isNotBlank() }
                        ?: "m-${UUID.randomUUID().toString().take(8)}"

                    fun buildAndSave(finalPhotoUrl: String?, finalNidUrl: String?) {
                        val member = Member(
                            id = memberId,
                            name = name.trim(), nameEn = nameEn.trim(),
                            fatherName = fatherName.trim(), dateOfBirth = dateOfBirth.trim(),
                            occupation = occupation.trim(), memberType = memberType.trim(),
                            phone = phone.trim(), whatsappNumber = whatsapp.trim(),
                            village = village.trim(), upazila = upazila.trim(),
                            district = district.trim(),
                            nid = nid.trim(),
                            photoUrl = finalPhotoUrl ?: existingMember?.photoUrl,
                            nidPhotoUrl = finalNidUrl ?: existingMember?.nidPhotoUrl,
                            emergencyContact = EmergencyContact(
                                name = emergencyName.trim(),
                                relation = emergencyRelation.trim(),
                                phone = emergencyPhone.trim()
                            ),
                            customFieldsPersonal = customPersonal,
                            customFieldsContact = customContact,
                            customFieldsDocs = customDocs,
                            customFieldsEmergency = customEmergency,
                            branchId = existingMember?.branchId ?: defaultBranchId,
                            joinDate = existingMember?.joinDate ?: System.currentTimeMillis(),
                            linkedUserId = existingMember?.linkedUserId
                        )
                        FirestoreWriteManager.addMember(member) { success ->
                            isSubmitting = false
                            Toast.makeText(
                                context,
                                if (success) (if (isBangla) "সদস্য সফলভাবে সংরক্ষিত হয়েছে" else "Member saved!")
                                else (if (isBangla) "সংরক্ষণ ব্যর্থ হয়েছে" else "Save failed"),
                                Toast.LENGTH_SHORT
                            ).show()
                            if (success) onNavigateBack()
                        }
                    }

                    // Upload profile photo first, then NID, then save
                    val pUri = profilePhotoUri
                    val nUri = nidPhotoUri
                    if (pUri != null) {
                        submitStep = if (isBangla) "প্রোফাইল ছবি আপলোড হচ্ছে..." else "Uploading profile photo..."
                        FirebaseStorageManager.uploadMemberPhoto(memberId, pUri) { pUrl ->
                            if (nUri != null) {
                                submitStep = if (isBangla) "NID ছবি আপলোড হচ্ছে..." else "Uploading NID photo..."
                                FirebaseStorageManager.uploadNidPhoto(memberId, nUri) { nUrl ->
                                    buildAndSave(pUrl, nUrl)
                                }
                            } else buildAndSave(pUrl, null)
                        }
                    } else if (nUri != null) {
                        submitStep = if (isBangla) "NID ছবি আপলোড হচ্ছে..." else "Uploading NID photo..."
                        FirebaseStorageManager.uploadNidPhoto(memberId, nUri) { nUrl ->
                            buildAndSave(null, nUrl)
                        }
                    } else {
                        submitStep = if (isBangla) "সংরক্ষণ হচ্ছে..." else "Saving..."
                        buildAndSave(null, null)
                    }
                },
                enabled = isValid && !isSubmitting,
                modifier = Modifier.fillMaxWidth().height(54.dp),
                shape = MaterialTheme.shapes.medium
            ) {
                Text(
                    text = if (isSubmitting) submitStep.ifBlank { if (isBangla) "অপেক্ষা করুন..." else "Please wait..." }
                    else if (isEdit) (if (isBangla) "পরিবর্তন সংরক্ষণ করুন" else "Save Changes")
                    else (if (isBangla) "সদস্য নিবন্ধন করুন" else "Register Member"),
                    fontWeight = FontWeight.Bold,
                    style = MaterialTheme.typography.bodyLarge
                )
            }

            Spacer(modifier = Modifier.height(16.dp))
        }
    }
}
