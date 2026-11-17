package com.helptrickbd.myapplicationsomithierp.presentation.screens.members.components

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp

private val memberTypes = listOf(
    "স্বেচ্ছাসেবী", "ব্যবসায়ী", "শিক্ষার্থী",
    "শিক্ষক", "চাকরিজীবী", "কৃষক", "অন্যান্য"
)
private val memberTypesEn = listOf(
    "Volunteer", "Businessman", "Student",
    "Teacher", "Job Holder", "Farmer", "Other"
)

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun MemberFormSection1Personal(
    isBangla: Boolean,
    isAdminOrSuper: Boolean,
    name: String, onNameChange: (String) -> Unit,
    nameEn: String, onNameEnChange: (String) -> Unit,
    fatherName: String, onFatherNameChange: (String) -> Unit,
    dateOfBirth: String, onDobChange: (String) -> Unit,
    occupation: String, onOccupationChange: (String) -> Unit,
    memberType: String, onMemberTypeChange: (String) -> Unit,
    customFields: Map<String, String>,
    onCustomFieldsChange: (Map<String, String>) -> Unit
) {
    var typeExpanded by remember { mutableStateOf(false) }
    val types = if (isBangla) memberTypes else memberTypesEn

    MemberSectionHeader(
        title = if (isBangla) "বিভাগ ১: ব্যক্তিগত তথ্য" else "Section 1: Personal Info"
    )

    MemberField(
        label = if (isBangla) "পূর্ণ নাম (বাংলা)*" else "Full Name (Bangla)*",
        value = name, onValueChange = onNameChange
    )
    Spacer(modifier = Modifier.height(8.dp))

    MemberField(
        label = if (isBangla) "পূর্ণ নাম (ইংরেজি)" else "Full Name (English)",
        value = nameEn, onValueChange = onNameEnChange
    )
    Spacer(modifier = Modifier.height(8.dp))

    MemberField(
        label = if (isBangla) "পিতার নাম" else "Father's Name",
        value = fatherName, onValueChange = onFatherNameChange
    )
    Spacer(modifier = Modifier.height(8.dp))

    MemberField(
        label = if (isBangla) "জন্ম তারিখ (DD/MM/YYYY)" else "Date of Birth (DD/MM/YYYY)",
        value = dateOfBirth, onValueChange = onDobChange
    )
    Spacer(modifier = Modifier.height(8.dp))

    MemberField(
        label = if (isBangla) "পেশা" else "Occupation",
        value = occupation, onValueChange = onOccupationChange
    )
    Spacer(modifier = Modifier.height(8.dp))

    // Member type dropdown
    ExposedDropdownMenuBox(
        expanded = typeExpanded,
        onExpandedChange = { typeExpanded = it }
    ) {
        OutlinedTextField(
            value = memberType.ifBlank { if (isBangla) "সদস্যের ধরন নির্বাচন করুন" else "Select Member Type" },
            onValueChange = {},
            readOnly = true,
            label = { Text(if (isBangla) "সদস্যের ধরন" else "Member Type") },
            trailingIcon = { ExposedDropdownMenuDefaults.TrailingIcon(expanded = typeExpanded) },
            modifier = Modifier.menuAnchor().fillMaxWidth(),
            shape = RoundedCornerShape(10.dp)
        )
        ExposedDropdownMenu(expanded = typeExpanded, onDismissRequest = { typeExpanded = false }) {
            types.forEach { type ->
                DropdownMenuItem(
                    text = { Text(type) },
                    onClick = { onMemberTypeChange(type); typeExpanded = false }
                )
            }
        }
    }
    Spacer(modifier = Modifier.height(8.dp))

    CustomFieldAdder(
        isBangla = isBangla,
        isAdminOrSuper = isAdminOrSuper,
        customFields = customFields,
        onFieldsChange = onCustomFieldsChange
    )
}
