package com.helptrickbd.myapplicationsomithierp.presentation.screens.members.components

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp

private val relations = listOf("বাবা", "মা", "ভাই", "বোন", "স্বামী", "স্ত্রী", "বন্ধু", "অন্যান্য")
private val relationsEn = listOf("Father", "Mother", "Brother", "Sister", "Husband", "Wife", "Friend", "Other")

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun MemberFormSection4Emergency(
    isBangla: Boolean,
    isAdminOrSuper: Boolean,
    emergencyName: String, onNameChange: (String) -> Unit,
    emergencyRelation: String, onRelationChange: (String) -> Unit,
    emergencyPhone: String, onPhoneChange: (String) -> Unit,
    customFields: Map<String, String>,
    onCustomFieldsChange: (Map<String, String>) -> Unit
) {
    var relationExpanded by remember { mutableStateOf(false) }
    val rels = if (isBangla) relations else relationsEn

    MemberSectionHeader(
        title = if (isBangla) "বিভাগ ৪: জরুরি যোগাযোগ" else "Section 4: Emergency Contact"
    )

    MemberField(
        label = if (isBangla) "জরুরি যোগাযোগের নাম" else "Emergency Contact Name",
        value = emergencyName, onValueChange = onNameChange
    )
    Spacer(modifier = Modifier.height(8.dp))

    ExposedDropdownMenuBox(
        expanded = relationExpanded,
        onExpandedChange = { relationExpanded = it }
    ) {
        OutlinedTextField(
            value = emergencyRelation.ifBlank { if (isBangla) "সম্পর্ক নির্বাচন করুন" else "Select Relation" },
            onValueChange = {},
            readOnly = true,
            label = { Text(if (isBangla) "সদস্যের সাথে সম্পর্ক" else "Relation to Member") },
            trailingIcon = { ExposedDropdownMenuDefaults.TrailingIcon(expanded = relationExpanded) },
            modifier = Modifier.menuAnchor().fillMaxWidth(),
            shape = RoundedCornerShape(10.dp)
        )
        ExposedDropdownMenu(
            expanded = relationExpanded,
            onDismissRequest = { relationExpanded = false }
        ) {
            rels.forEach { rel ->
                DropdownMenuItem(
                    text = { Text(rel) },
                    onClick = { onRelationChange(rel); relationExpanded = false }
                )
            }
        }
    }
    Spacer(modifier = Modifier.height(8.dp))

    MemberField(
        label = if (isBangla) "জরুরি ফোন নম্বর" else "Emergency Phone",
        value = emergencyPhone, onValueChange = onPhoneChange,
        keyboardType = KeyboardType.Phone
    )
    Spacer(modifier = Modifier.height(8.dp))

    CustomFieldAdder(
        isBangla = isBangla,
        isAdminOrSuper = isAdminOrSuper,
        customFields = customFields,
        onFieldsChange = onCustomFieldsChange
    )
}
