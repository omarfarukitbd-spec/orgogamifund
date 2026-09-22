package com.helptrickbd.myapplicationsomithierp.presentation.screens.members.components

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.Send
import androidx.compose.material.icons.filled.AddAPhoto
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.Description
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import com.helptrickbd.myapplicationsomithierp.domain.model.Branch
import com.helptrickbd.myapplicationsomithierp.ui.theme.MoneyIncomeGreen

@Composable
fun RegistrationStepThree(
    selectedBranch: Branch,
    nidNumber: String,
    onNidNumberChange: (String) -> Unit,
    isNidAttached: Boolean,
    onToggleNidAttached: () -> Unit,
    isPhotoAttached: Boolean,
    onTogglePhotoAttached: () -> Unit,
    termsAgreed: Boolean,
    onTermsAgreedChange: (Boolean) -> Unit,
    onBack: () -> Unit,
    onSubmit: () -> Unit
) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(16.dp),
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface),
        elevation = CardDefaults.cardElevation(defaultElevation = 2.dp)
    ) {
        Column(
            modifier = Modifier.padding(18.dp),
            verticalArrangement = Arrangement.spacedBy(14.dp)
        ) {
            Text(
                text = "৩. ডকুমেন্টস ও যাচাইকরণ",
                style = MaterialTheme.typography.titleSmall,
                fontWeight = FontWeight.Bold,
                color = MaterialTheme.colorScheme.primary
            )

            OutlinedTextField(
                value = nidNumber,
                onValueChange = { onNidNumberChange(it.filter { c -> c.isDigit() }) },
                label = { Text("আবেদনকারীর জাতীয় পরিচয়পত্র (NID) নম্বর *") },
                keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
                singleLine = true,
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(12.dp)
            )

            // NID Attachment Card
            Surface(
                modifier = Modifier
                    .fillMaxWidth()
                    .clickable { onToggleNidAttached() },
                shape = RoundedCornerShape(12.dp),
                color = if (isNidAttached) MoneyIncomeGreen.copy(alpha = 0.1f) else MaterialTheme.colorScheme.surfaceVariant,
                border = BorderStroke(1.dp, if (isNidAttached) MoneyIncomeGreen else MaterialTheme.colorScheme.outlineVariant)
            ) {
                Row(
                    modifier = Modifier.padding(14.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Icon(
                        imageVector = if (isNidAttached) Icons.Default.CheckCircle else Icons.Default.Description,
                        contentDescription = null,
                        tint = if (isNidAttached) MoneyIncomeGreen else MaterialTheme.colorScheme.onSurfaceVariant
                    )
                    Spacer(modifier = Modifier.width(12.dp))
                    Column(modifier = Modifier.weight(1f)) {
                        Text(
                            text = "জাতীয় পরিচয়পত্রের কপি (NID Card)",
                            style = MaterialTheme.typography.labelLarge,
                            fontWeight = FontWeight.SemiBold
                        )
                        Text(
                            text = if (isNidAttached) "ডকুমেন্ট সংযুক্ত করা হয়েছে (nid_front_back.pdf)" else "ফাইল আপলোড করতে ট্যাপ করুন",
                            style = MaterialTheme.typography.labelSmall,
                            color = if (isNidAttached) MoneyIncomeGreen else MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }
                }
            }

            // Passport Photo Attachment Card
            Surface(
                modifier = Modifier
                    .fillMaxWidth()
                    .clickable { onTogglePhotoAttached() },
                shape = RoundedCornerShape(12.dp),
                color = if (isPhotoAttached) MoneyIncomeGreen.copy(alpha = 0.1f) else MaterialTheme.colorScheme.surfaceVariant,
                border = BorderStroke(1.dp, if (isPhotoAttached) MoneyIncomeGreen else MaterialTheme.colorScheme.outlineVariant)
            ) {
                Row(
                    modifier = Modifier.padding(14.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Icon(
                        imageVector = if (isPhotoAttached) Icons.Default.CheckCircle else Icons.Default.AddAPhoto,
                        contentDescription = null,
                        tint = if (isPhotoAttached) MoneyIncomeGreen else MaterialTheme.colorScheme.onSurfaceVariant
                    )
                    Spacer(modifier = Modifier.width(12.dp))
                    Column(modifier = Modifier.weight(1f)) {
                        Text(
                            text = "সদস্যের পাসপোর্ট সাইজ ছবি",
                            style = MaterialTheme.typography.labelLarge,
                            fontWeight = FontWeight.SemiBold
                        )
                        Text(
                            text = if (isPhotoAttached) "ছবি সিলেক্ট করা হয়েছে (member_photo.jpg)" else "ছবি তুলতে বা সিলেক্ট করতে ট্যাপ করুন",
                            style = MaterialTheme.typography.labelSmall,
                            color = if (isPhotoAttached) MoneyIncomeGreen else MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }
                }
            }

            // Shomiti Specific Terms and Conditions Preview
            Surface(
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(12.dp),
                color = MaterialTheme.colorScheme.primary.copy(alpha = 0.06f),
                border = BorderStroke(1.dp, MaterialTheme.colorScheme.primary.copy(alpha = 0.2f))
            ) {
                Column(modifier = Modifier.padding(14.dp)) {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Icon(
                            imageVector = Icons.Default.Description,
                            contentDescription = null,
                            tint = MaterialTheme.colorScheme.primary,
                            modifier = Modifier.size(18.dp)
                        )
                        Spacer(modifier = Modifier.width(8.dp))
                        Text(
                            text = "${selectedBranch.name}-এর আবশ্যক শর্তাবলী:",
                            style = MaterialTheme.typography.titleSmall,
                            fontWeight = FontWeight.Bold,
                            color = MaterialTheme.colorScheme.primary
                        )
                    }
                    Spacer(modifier = Modifier.height(8.dp))
                    selectedBranch.termsAndConditions.forEach { term ->
                        Row(
                            modifier = Modifier.padding(vertical = 3.dp),
                            verticalAlignment = Alignment.Top
                        ) {
                            Icon(
                                imageVector = Icons.Default.CheckCircle,
                                contentDescription = null,
                                tint = MaterialTheme.colorScheme.primary,
                                modifier = Modifier.size(14.dp).padding(top = 2.dp)
                            )
                            Spacer(modifier = Modifier.width(6.dp))
                            Text(
                                text = term,
                                style = MaterialTheme.typography.bodySmall,
                                color = MaterialTheme.colorScheme.onSurface
                            )
                        }
                    }
                }
            }

            // Terms and declaration
            Row(
                modifier = Modifier.fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Checkbox(
                    checked = termsAgreed,
                    onCheckedChange = onTermsAgreedChange,
                    colors = CheckboxDefaults.colors(checkedColor = MaterialTheme.colorScheme.primary)
                )
                Spacer(modifier = Modifier.width(4.dp))
                Text(
                    text = "আমি প্রত্যয়ন করছি যে উপরে প্রদত্ত সকল তথ্য সত্য ও নির্ভুল। আমি '${selectedBranch.name}'-এর উপরোক্ত সকল শর্তাবলী ও অগ্রগামী ফান্ডের গঠনতন্ত্র মেনে চলতে অঙ্গীকারবদ্ধ।",
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
        }
    }

    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        OutlinedButton(
            onClick = onBack,
            modifier = Modifier
                .weight(1f)
                .height(52.dp),
            shape = RoundedCornerShape(14.dp)
        ) {
            Text("আগের ধাপ")
        }

        Button(
            onClick = onSubmit,
            modifier = Modifier
                .weight(1.4f)
                .height(52.dp),
            shape = RoundedCornerShape(14.dp),
            colors = ButtonDefaults.buttonColors(containerColor = MaterialTheme.colorScheme.primary)
        ) {
            Icon(imageVector = Icons.AutoMirrored.Filled.Send, contentDescription = null, modifier = Modifier.size(18.dp))
            Spacer(modifier = Modifier.width(8.dp))
            Text("আবেদন জমা দিন")
        }
    }
}
