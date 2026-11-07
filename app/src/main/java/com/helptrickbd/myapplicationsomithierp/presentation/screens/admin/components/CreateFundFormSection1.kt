package com.helptrickbd.myapplicationsomithierp.presentation.screens.admin.components

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.expandVertically
import androidx.compose.animation.shrinkVertically
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp

@Composable
fun CreateFundSection1Identity(
    isBangla: Boolean,
    nameText: String,
    onNameChange: (String) -> Unit,
    codeText: String,
    onCodeChange: (String) -> Unit,
    yearText: String,
    onYearChange: (String) -> Unit,
    descText: String,
    onDescChange: (String) -> Unit,
    logoUrlText: String = "",
    onLogoUrlChange: (String) -> Unit = {},
    bannerUrlText: String = "",
    onBannerUrlChange: (String) -> Unit = {}
) {
    SectionHeader(title = if (isBangla) "সমিতির পরিচয় ও তথ্য" else "Fund Identity")

    OutlinedTextField(
        value = nameText, onValueChange = onNameChange,
        label = { Text(if (isBangla) "সমিতির নাম (যেমন: মাদ্রাসা কল্যাণ ফান্ড ২০১৫)" else "Somithi Name") },
        modifier = Modifier.fillMaxWidth(), shape = RoundedCornerShape(12.dp)
    )

    Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
        OutlinedTextField(
            value = codeText, onValueChange = onCodeChange,
            label = { Text(if (isBangla) "সংক্ষিপ্ত কোড" else "Short Code") },
            placeholder = { Text("MKF-25") },
            modifier = Modifier.weight(1f), shape = RoundedCornerShape(12.dp)
        )
        OutlinedTextField(
            value = yearText, onValueChange = { if (it.length <= 4) onYearChange(it) },
            label = { Text(if (isBangla) "প্রতিষ্ঠার বছর" else "Est. Year") },
            placeholder = { Text("2015") },
            keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
            modifier = Modifier.weight(1f), shape = RoundedCornerShape(12.dp)
        )
    }

    OutlinedTextField(
        value = descText, onValueChange = onDescChange,
        label = { Text(if (isBangla) "ফান্ডের উদ্দেশ্য ও পরিচিতি" else "Purpose & Description") },
        minLines = 2, maxLines = 3,
        modifier = Modifier.fillMaxWidth(), shape = RoundedCornerShape(12.dp)
    )

    OutlinedTextField(
        value = logoUrlText, onValueChange = onLogoUrlChange,
        label = { Text(if (isBangla) "সমিতির লোগো লিংক (Logo URL)" else "Somithi Logo URL") },
        placeholder = { Text("https://example.com/logo.png") },
        singleLine = true,
        modifier = Modifier.fillMaxWidth(), shape = RoundedCornerShape(12.dp)
    )

    OutlinedTextField(
        value = bannerUrlText, onValueChange = onBannerUrlChange,
        label = { Text(if (isBangla) "সমিতির ব্যানার লিংক (Cover Banner URL)" else "Banner Cover URL") },
        placeholder = { Text("https://example.com/banner.jpg") },
        singleLine = true,
        modifier = Modifier.fillMaxWidth(), shape = RoundedCornerShape(12.dp)
    )
}

@Composable
fun CreateFundSection1Contribution(
    isBangla: Boolean,
    monthlyAmountText: String,
    onMonthlyAmountChange: (String) -> Unit,
    admissionFeeText: String,
    onAdmissionFeeChange: (String) -> Unit,
    optionalEnabled: Boolean,
    onOptionalEnabledChange: (Boolean) -> Unit,
    minOptionalText: String,
    onMinOptionalChange: (String) -> Unit,
    dueDayText: String,
    onDueDayChange: (String) -> Unit,
    lateFineText: String,
    onLateFineChange: (String) -> Unit
) {
    SectionHeader(title = if (isBangla) "চাঁদার নিয়ম ও অর্থ ব্যবস্থাপনা" else "Contribution Rules")

    Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
        OutlinedTextField(
            value = monthlyAmountText,
            onValueChange = { onMonthlyAmountChange(it.filter { c -> c.isDigit() }) },
            label = { Text(if (isBangla) "মাসিক চাঁদা (টাকা)" else "Monthly Amount") },
            keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
            modifier = Modifier.weight(1f), shape = RoundedCornerShape(12.dp)
        )
        OutlinedTextField(
            value = admissionFeeText,
            onValueChange = { onAdmissionFeeChange(it.filter { c -> c.isDigit() }) },
            label = { Text(if (isBangla) "ভর্তি ফি (টাকা)" else "Admission Fee") },
            keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
            modifier = Modifier.weight(1f), shape = RoundedCornerShape(12.dp)
        )
    }

    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically
    ) {
        Column(modifier = Modifier.weight(1f)) {
            Text(
                text = if (isBangla) "ঐচ্ছিক সঞ্চয়ের সুবিধা" else "Optional Deposit Enabled",
                style = MaterialTheme.typography.bodyMedium,
                fontWeight = FontWeight.Medium,
                color = MaterialTheme.colorScheme.onSurface
            )
            Text(
                text = if (isBangla) "সদস্যরা ইচ্ছামতো বাড়তি টাকা দিতে পারবেন" else "Members can give extra voluntarily",
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
        }
        Switch(checked = optionalEnabled, onCheckedChange = onOptionalEnabledChange)
    }

    AnimatedVisibility(
        visible = optionalEnabled,
        enter = expandVertically(), exit = shrinkVertically()
    ) {
        OutlinedTextField(
            value = minOptionalText,
            onValueChange = { onMinOptionalChange(it.filter { c -> c.isDigit() }) },
            label = { Text(if (isBangla) "সর্বনিম্ন ঐচ্ছিক পরিমাণ (টাকা)" else "Min Optional Amount") },
            keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
            modifier = Modifier.fillMaxWidth(), shape = RoundedCornerShape(12.dp)
        )
    }

    Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
        OutlinedTextField(
            value = dueDayText,
            onValueChange = { v ->
                val n = v.filter { c -> c.isDigit() }.take(2)
                if (n.isEmpty() || (n.toIntOrNull() ?: 0) <= 31) onDueDayChange(n)
            },
            label = { Text(if (isBangla) "চাঁদার শেষ তারিখ (১-৩১)" else "Due Day (1-31)") },
            keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
            modifier = Modifier.weight(1f), shape = RoundedCornerShape(12.dp)
        )
        OutlinedTextField(
            value = lateFineText,
            onValueChange = { onLateFineChange(it.filter { c -> c.isDigit() }) },
            label = { Text(if (isBangla) "দেরির জরিমানা (টাকা)" else "Late Fine (BDT)") },
            keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
            modifier = Modifier.weight(1f), shape = RoundedCornerShape(12.dp)
        )
    }
}

@Composable
fun SectionHeader(title: String) {
    Text(
        text = title,
        style = MaterialTheme.typography.titleSmall,
        fontWeight = FontWeight.Bold,
        color = MaterialTheme.colorScheme.primary
    )
    HorizontalDivider(
        thickness = 1.dp,
        color = MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.4f)
    )
}
