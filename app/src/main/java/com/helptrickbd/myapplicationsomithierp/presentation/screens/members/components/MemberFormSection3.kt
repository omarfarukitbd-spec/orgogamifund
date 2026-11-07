package com.helptrickbd.myapplicationsomithierp.presentation.screens.members.components

import android.net.Uri
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.AddAPhoto
import androidx.compose.material.icons.filled.Badge
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.UploadFile
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import coil.compose.AsyncImage
import com.helptrickbd.myapplicationsomithierp.ui.theme.MoneyIncomeGreen

@Composable
fun MemberFormSection3Photos(
    isBangla: Boolean,
    isAdminOrSuper: Boolean,
    nid: String, onNidChange: (String) -> Unit,
    profilePhotoUri: Uri?, onProfilePhotoSelected: (Uri) -> Unit,
    nidPhotoUri: Uri?, onNidPhotoSelected: (Uri) -> Unit,
    existingPhotoUrl: String? = null,
    existingNidUrl: String? = null,
    customFields: Map<String, String>,
    onCustomFieldsChange: (Map<String, String>) -> Unit
) {
    val profileLauncher = rememberLauncherForActivityResult(
        ActivityResultContracts.GetContent()
    ) { uri -> uri?.let { onProfilePhotoSelected(it) } }

    val nidLauncher = rememberLauncherForActivityResult(
        ActivityResultContracts.GetContent()
    ) { uri -> uri?.let { onNidPhotoSelected(it) } }

    MemberSectionHeader(
        title = if (isBangla) "বিভাগ ৩: পরিচয় নথি ও ছবি" else "Section 3: Documents & Photos"
    )

    // Profile Photo Picker
    Text(
        text = if (isBangla) "প্রোফাইল ছবি" else "Profile Photo",
        style = MaterialTheme.typography.labelMedium,
        fontWeight = FontWeight.SemiBold,
        color = MaterialTheme.colorScheme.onSurfaceVariant
    )
    Spacer(modifier = Modifier.height(6.dp))

    Box(
        modifier = Modifier
            .size(88.dp)
            .clip(CircleShape)
            .background(MaterialTheme.colorScheme.surfaceVariant)
            .clickable { profileLauncher.launch("image/*") },
        contentAlignment = Alignment.Center
    ) {
        val photoSource = profilePhotoUri?.toString() ?: existingPhotoUrl
        if (photoSource != null) {
            AsyncImage(
                model = photoSource,
                contentDescription = null,
                contentScale = ContentScale.Crop,
                modifier = Modifier.fillMaxSize()
            )
            // Uploaded indicator
            if (profilePhotoUri != null) {
                Icon(
                    imageVector = Icons.Default.CheckCircle,
                    contentDescription = null,
                    tint = MoneyIncomeGreen,
                    modifier = Modifier
                        .align(Alignment.BottomEnd)
                        .size(20.dp)
                        .background(MaterialTheme.colorScheme.surface, CircleShape)
                )
            }
        } else {
            Icon(
                imageVector = Icons.Default.AddAPhoto,
                contentDescription = null,
                tint = MaterialTheme.colorScheme.onSurfaceVariant,
                modifier = Modifier.size(28.dp)
            )
        }
    }
    Text(
        text = if (isBangla) "ট্যাপ করে ছবি নির্বাচন করুন" else "Tap to select photo",
        style = MaterialTheme.typography.labelSmall.copy(fontSize = 11.sp),
        color = MaterialTheme.colorScheme.onSurfaceVariant,
        modifier = Modifier.padding(top = 4.dp)
    )

    Spacer(modifier = Modifier.height(16.dp))

    // NID Number
    MemberField(
        label = if (isBangla) "জাতীয় পরিচয়পত্র নম্বর (NID)" else "National ID Number (NID)",
        value = nid, onValueChange = onNidChange,
        keyboardType = KeyboardType.Number
    )
    Spacer(modifier = Modifier.height(10.dp))

    // NID Photo Picker
    Text(
        text = if (isBangla) "NID-এর ছবি" else "NID Photo",
        style = MaterialTheme.typography.labelMedium,
        fontWeight = FontWeight.SemiBold,
        color = MaterialTheme.colorScheme.onSurfaceVariant
    )
    Spacer(modifier = Modifier.height(6.dp))

    Surface(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(12.dp))
            .clickable { nidLauncher.launch("image/*") },
        shape = RoundedCornerShape(12.dp),
        border = BorderStroke(1.dp, MaterialTheme.colorScheme.outlineVariant),
        color = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.4f)
    ) {
        val nidSource = nidPhotoUri?.toString() ?: existingNidUrl
        if (nidSource != null) {
            AsyncImage(
                model = nidSource,
                contentDescription = null,
                contentScale = ContentScale.FillWidth,
                modifier = Modifier.fillMaxWidth().height(130.dp)
            )
        } else {
            Row(
                modifier = Modifier.padding(16.dp),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(10.dp)
            ) {
                Icon(Icons.Default.Badge, contentDescription = null,
                    tint = MaterialTheme.colorScheme.onSurfaceVariant)
                Text(
                    text = if (isBangla) "NID কার্ডের ছবি আপলোড করুন" else "Upload NID card photo",
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
                Spacer(modifier = Modifier.weight(1f))
                Icon(Icons.Default.UploadFile, contentDescription = null,
                    tint = MaterialTheme.colorScheme.primary)
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
