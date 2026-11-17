package com.helptrickbd.myapplicationsomithierp.presentation.screens.payments.components

import android.content.Context
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Print
import androidx.compose.material.icons.filled.Warning
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import com.helptrickbd.myapplicationsomithierp.R
import com.helptrickbd.myapplicationsomithierp.core.pdf.PaymentReceiptPdfGenerator
import com.helptrickbd.myapplicationsomithierp.core.util.CurrencyFormatter
import com.helptrickbd.myapplicationsomithierp.domain.model.Member
import com.helptrickbd.myapplicationsomithierp.domain.model.Payment
import com.helptrickbd.myapplicationsomithierp.ui.theme.MoneyDueAmber
import com.helptrickbd.myapplicationsomithierp.ui.theme.MoneyIncomeGreen

@Composable
fun DuplicatePaymentWarningDialog(
    selectedMember: Member?,
    selectedMonth: String,
    selectedYear: Int,
    duplicatePayment: Payment,
    isBangla: Boolean,
    onConfirm: () -> Unit,
    onDismiss: () -> Unit
) {
    AlertDialog(
        onDismissRequest = onDismiss,
        icon = { Icon(Icons.Default.Warning, contentDescription = null, tint = MoneyDueAmber) },
        title = { Text(text = stringResource(R.string.duplicate_warning_title), fontWeight = FontWeight.Bold) },
        text = {
            Text(
                text = if (isBangla)
                    "${selectedMember?.name}-এর জন্য ${selectedMonth}, $selectedYear সালে ইতিমধ্যে ${CurrencyFormatter.formatBDT(duplicatePayment.amount, toBanglaDigits = true)} জমা রেকর্ড করা আছে।\n\nআপনি কি নিশ্চিত যে আরেকটি পেমেন্ট জমা করতে চান?"
                else
                    "A deposit of ${CurrencyFormatter.formatBDT(duplicatePayment.amount, toBanglaDigits = false)} is already recorded for ${selectedMember?.name} for $selectedMonth $selectedYear.\n\nAre you sure you want to proceed?"
            )
        },
        confirmButton = {
            Button(
                onClick = onConfirm,
                colors = ButtonDefaults.buttonColors(containerColor = MaterialTheme.colorScheme.primary)
            ) {
                Text(stringResource(R.string.confirm_anyway))
            }
        },
        dismissButton = {
            OutlinedButton(onClick = onDismiss) {
                Text(stringResource(R.string.cancel))
            }
        }
    )
}

@Composable
fun PaymentReceiptSuccessDialog(
    payment: Payment,
    isBangla: Boolean,
    context: Context,
    onPrint: () -> Unit,
    onDismiss: () -> Unit
) {
    AlertDialog(
        onDismissRequest = onDismiss,
        icon = { Icon(Icons.Default.Print, contentDescription = null, tint = MoneyIncomeGreen) },
        title = {
            Text(
                text = if (isBangla) "টাকা জমা সম্পন্ন হয়েছে!" else "Payment Recorded Successfully!",
                fontWeight = FontWeight.Bold
            )
        },
        text = {
            Text(
                text = if (isBangla)
                    "সফলভাবে ${CurrencyFormatter.formatBDT(payment.amount, toBanglaDigits = true)} জমা রেকর্ড করা হয়েছে। আপনি কি এখনই মানি রিসিট প্রিন্ট বা শেয়ার করতে চান?"
                else
                    "Successfully recorded deposit of ${CurrencyFormatter.formatBDT(payment.amount, toBanglaDigits = false)}. Would you like to print or share the money receipt now?"
            )
        },
        confirmButton = {
            Button(
                onClick = {
                    val pdfFile = PaymentReceiptPdfGenerator.generateReceiptPdf(context, payment)
                    PaymentReceiptPdfGenerator.printReceipt(context, pdfFile)
                    onPrint()
                },
                colors = ButtonDefaults.buttonColors(containerColor = MaterialTheme.colorScheme.primary)
            ) {
                Text(if (isBangla) "রসিদ প্রিন্ট করুন" else "Print Receipt")
            }
        },
        dismissButton = {
            OutlinedButton(onClick = onDismiss) {
                Text(if (isBangla) "পরে করবো" else "Later")
            }
        }
    )
}
