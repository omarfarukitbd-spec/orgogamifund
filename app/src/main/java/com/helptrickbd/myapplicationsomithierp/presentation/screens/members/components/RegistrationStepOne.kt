package com.helptrickbd.myapplicationsomithierp.presentation.screens.members.components

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp

@Composable
fun RegistrationStepOne(
    applicantName: String,
    onApplicantNameChange: (String) -> Unit,
    phone: String,
    onPhoneChange: (String) -> Unit,
    fatherOrHusbandName: String,
    onFatherOrHusbandNameChange: (String) -> Unit,
    occupation: String,
    onOccupationChange: (String) -> Unit,
    bloodGroup: String,
    onBloodGroupChange: (String) -> Unit,
    presentAddress: String,
    onPresentAddressChange: (String) -> Unit,
    permanentAddress: String,
    onPermanentAddressChange: (String) -> Unit,
    onNext: () -> Unit
) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(16.dp),
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface),
        elevation = CardDefaults.cardElevation(defaultElevation = 2.dp)
    ) {
        Column(
            modifier = Modifier.padding(18.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            Text(
                text = "১. আবেদনকারীর ব্যক্তিগত বিবরণ",
                style = MaterialTheme.typography.titleSmall,
                fontWeight = FontWeight.Bold,
                color = MaterialTheme.colorScheme.primary
            )

            OutlinedTextField(
                value = applicantName,
                onValueChange = onApplicantNameChange,
                label = { Text("পূর্ণ নাম (বাঙালি/ইংরেজি) *") },
                leadingIcon = { Icon(Icons.Default.Person, contentDescription = null) },
                singleLine = true,
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(12.dp)
            )

            OutlinedTextField(
                value = phone,
                onValueChange = onPhoneChange,
                label = { Text("মোবাইল নম্বর *") },
                leadingIcon = { Icon(Icons.Default.Phone, contentDescription = null) },
                keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Phone),
                singleLine = true,
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(12.dp)
            )

            OutlinedTextField(
                value = fatherOrHusbandName,
                onValueChange = onFatherOrHusbandNameChange,
                label = { Text("পিতা / স্বামীর নাম *") },
                singleLine = true,
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(12.dp)
            )

            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(10.dp)
            ) {
                OutlinedTextField(
                    value = occupation,
                    onValueChange = onOccupationChange,
                    label = { Text("পেশা") },
                    leadingIcon = { Icon(Icons.Default.Work, contentDescription = null) },
                    singleLine = true,
                    modifier = Modifier.weight(1.2f),
                    shape = RoundedCornerShape(12.dp)
                )

                OutlinedTextField(
                    value = bloodGroup,
                    onValueChange = onBloodGroupChange,
                    label = { Text("রক্তের গ্রুপ") },
                    singleLine = true,
                    modifier = Modifier.weight(0.8f),
                    shape = RoundedCornerShape(12.dp)
                )
            }

            OutlinedTextField(
                value = presentAddress,
                onValueChange = onPresentAddressChange,
                label = { Text("বর্তমান ঠিকানা *") },
                leadingIcon = { Icon(Icons.Default.Home, contentDescription = null) },
                maxLines = 2,
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(12.dp)
            )

            OutlinedTextField(
                value = permanentAddress,
                onValueChange = onPermanentAddressChange,
                label = { Text("স্থায়ী ঠিকানা (গ্রাম, ডাকঘর, উপজেলা, জেলা)") },
                maxLines = 2,
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(12.dp)
            )
        }
    }

    Button(
        onClick = onNext,
        modifier = Modifier
            .fillMaxWidth()
            .height(52.dp),
        shape = RoundedCornerShape(14.dp),
        colors = ButtonDefaults.buttonColors(containerColor = MaterialTheme.colorScheme.primary)
    ) {
        Text("পরবর্তী ধাপ (সমিতি ও নমিনি তথ্য)")
    }
}
