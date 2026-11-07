package com.helptrickbd.myapplicationsomithierp.presentation.screens.members.components

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import coil.compose.AsyncImage
import com.helptrickbd.myapplicationsomithierp.domain.model.Member

@Composable
fun MemberDetailExpandedInfo(
    member: Member,
    isBangla: Boolean,
    joinDateStr: String,
    modifier: Modifier = Modifier
) {
    Card(
        modifier = modifier.fillMaxWidth(),
        shape = RoundedCornerShape(16.dp),
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface),
        elevation = CardDefaults.cardElevation(defaultElevation = 1.dp)
    ) {
        Column(
            modifier = Modifier.padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(10.dp)
        ) {
            // Section 1: Personal
            Text(
                text = if (isBangla) "ব্যক্তিগত তথ্য" else "Personal Info",
                style = MaterialTheme.typography.titleSmall,
                fontWeight = FontWeight.Bold,
                color = MaterialTheme.colorScheme.primary
            )
            DetailRow(label = if (isBangla) "পূর্ণ নাম (বাংলা)" else "Name (Bangla)", value = member.name)
            if (member.nameEn.isNotBlank()) {
                DetailRow(label = if (isBangla) "পূর্ণ নাম (ইংরেজি)" else "Name (English)", value = member.nameEn)
            }
            if (member.fatherName.isNotBlank()) {
                DetailRow(label = if (isBangla) "পিতার নাম" else "Father's Name", value = member.fatherName)
            }
            if (member.dateOfBirth.isNotBlank()) {
                DetailRow(label = if (isBangla) "জন্ম তারিখ" else "Date of Birth", value = member.dateOfBirth)
            }
            if (member.occupation.isNotBlank()) {
                DetailRow(label = if (isBangla) "পেশা" else "Occupation", value = member.occupation)
            }
            if (member.memberType.isNotBlank()) {
                DetailRow(label = if (isBangla) "সদস্যের ধরন" else "Member Type", value = member.memberType)
            }
            member.customFieldsPersonal.forEach { (k, v) -> DetailRow(label = k, value = v) }

            HorizontalDivider(color = MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.5f))

            // Section 2: Contact & Address
            Text(
                text = if (isBangla) "যোগাযোগ ও ঠিকানা" else "Contact & Address",
                style = MaterialTheme.typography.titleSmall,
                fontWeight = FontWeight.Bold,
                color = MaterialTheme.colorScheme.primary
            )
            DetailRow(label = if (isBangla) "মোবাইল" else "Mobile", value = member.phone)
            if (member.whatsappNumber.isNotBlank()) {
                DetailRow(label = "WhatsApp", value = member.whatsappNumber)
            }
            val locationParts = listOf(member.village, member.upazila, member.district).filter { it.isNotBlank() }
            if (locationParts.isNotEmpty()) {
                DetailRow(label = if (isBangla) "ঠিকানা" else "Address", value = locationParts.joinToString(", "))
            } else if (member.address.isNotBlank()) {
                DetailRow(label = if (isBangla) "ঠিকানা" else "Address", value = member.address)
            }
            member.customFieldsContact.forEach { (k, v) -> DetailRow(label = k, value = v) }

            HorizontalDivider(color = MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.5f))

            // Section 3: Documents
            Text(
                text = if (isBangla) "পরিচয় নথি ও ছবি" else "Identity & Documents",
                style = MaterialTheme.typography.titleSmall,
                fontWeight = FontWeight.Bold,
                color = MaterialTheme.colorScheme.primary
            )
            DetailRow(
                label = if (isBangla) "NID নম্বর" else "NID Number",
                value = member.nid.ifEmpty { if (isBangla) "প্রদান করা হয়নি" else "Not provided" }
            )
            if (!member.nidPhotoUrl.isNullOrBlank()) {
                Spacer(modifier = Modifier.height(4.dp))
                Text(
                    text = if (isBangla) "NID কার্ডের ছবি:" else "NID Card Photo:",
                    style = MaterialTheme.typography.labelSmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
                Surface(
                    modifier = Modifier
                        .fillMaxWidth()
                        .clip(RoundedCornerShape(10.dp)),
                    border = BorderStroke(1.dp, MaterialTheme.colorScheme.outlineVariant)
                ) {
                    AsyncImage(
                        model = member.nidPhotoUrl,
                        contentDescription = "NID Card",
                        contentScale = ContentScale.FillWidth,
                        modifier = Modifier.fillMaxWidth().height(140.dp)
                    )
                }
            }
            member.customFieldsDocs.forEach { (k, v) -> DetailRow(label = k, value = v) }

            // Section 4: Emergency Contact
            if (member.emergencyContact.name.isNotBlank()) {
                HorizontalDivider(color = MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.5f))
                Text(
                    text = if (isBangla) "জরুরি যোগাযোগ" else "Emergency Contact",
                    style = MaterialTheme.typography.titleSmall,
                    fontWeight = FontWeight.Bold,
                    color = MaterialTheme.colorScheme.primary
                )
                DetailRow(label = if (isBangla) "নাম" else "Name", value = member.emergencyContact.name)
                if (member.emergencyContact.relation.isNotBlank()) {
                    DetailRow(label = if (isBangla) "সম্পর্ক" else "Relation", value = member.emergencyContact.relation)
                }
                if (member.emergencyContact.phone.isNotBlank()) {
                    DetailRow(label = if (isBangla) "ফোন" else "Phone", value = member.emergencyContact.phone)
                }
                member.customFieldsEmergency.forEach { (k, v) -> DetailRow(label = k, value = v) }
            }

            // Membership Info
            HorizontalDivider(color = MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.5f))
            DetailRow(label = if (isBangla) "শাখা / ফান্ড" else "Branch / Fund", value = member.branchId.ifEmpty { if (isBangla) "মূল শাখা" else "Main Branch" })
            DetailRow(label = if (isBangla) "যোগদানের তারিখ" else "Join Date", value = joinDateStr)
            member.customFields.forEach { (k, v) -> DetailRow(label = k, value = v) }
        }
    }
}
