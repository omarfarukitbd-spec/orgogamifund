package com.helptrickbd.myapplicationsomithierp.presentation.screens.members.components

import androidx.compose.foundation.layout.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp

@Composable
fun MemberFormSection2Contact(
    isBangla: Boolean,
    isAdminOrSuper: Boolean,
    phone: String, onPhoneChange: (String) -> Unit,
    whatsapp: String, onWhatsappChange: (String) -> Unit,
    village: String, onVillageChange: (String) -> Unit,
    upazila: String, onUpazilaChange: (String) -> Unit,
    district: String, onDistrictChange: (String) -> Unit,
    customFields: Map<String, String>,
    onCustomFieldsChange: (Map<String, String>) -> Unit
) {
    var sameAsPhone by remember { mutableStateOf(whatsapp == phone && phone.isNotBlank()) }

    MemberSectionHeader(
        title = if (isBangla) "বিভাগ ২: যোগাযোগ ও ঠিকানা" else "Section 2: Contact & Address"
    )

    MemberField(
        label = if (isBangla) "মোবাইল নম্বর*" else "Mobile Number*",
        value = phone,
        onValueChange = { new ->
            onPhoneChange(new)
            if (sameAsPhone) onWhatsappChange(new)
        },
        keyboardType = KeyboardType.Phone
    )
    Spacer(modifier = Modifier.height(6.dp))

    // WhatsApp same-as-mobile toggle
    Row(
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(8.dp)
    ) {
        Checkbox(
            checked = sameAsPhone,
            onCheckedChange = { checked ->
                sameAsPhone = checked
                if (checked) onWhatsappChange(phone)
                else onWhatsappChange("")
            }
        )
        Text(
            text = if (isBangla) "WhatsApp নম্বর একই" else "WhatsApp same as mobile",
            style = MaterialTheme.typography.bodySmall,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )
    }

    if (!sameAsPhone) {
        Spacer(modifier = Modifier.height(4.dp))
        MemberField(
            label = if (isBangla) "WhatsApp নম্বর" else "WhatsApp Number",
            value = whatsapp,
            onValueChange = onWhatsappChange,
            keyboardType = KeyboardType.Phone
        )
    }
    Spacer(modifier = Modifier.height(8.dp))

    MemberField(
        label = if (isBangla) "গ্রাম / মহল্লা" else "Village / Area",
        value = village, onValueChange = onVillageChange
    )
    Spacer(modifier = Modifier.height(8.dp))

    Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
        Box(modifier = Modifier.weight(1f)) {
            MemberField(
                label = if (isBangla) "উপজেলা" else "Upazila",
                value = upazila, onValueChange = onUpazilaChange
            )
        }
        Box(modifier = Modifier.weight(1f)) {
            MemberField(
                label = if (isBangla) "জেলা" else "District",
                value = district, onValueChange = onDistrictChange
            )
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
