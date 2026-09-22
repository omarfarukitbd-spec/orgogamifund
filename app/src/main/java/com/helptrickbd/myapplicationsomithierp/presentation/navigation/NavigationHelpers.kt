package com.helptrickbd.myapplicationsomithierp.presentation.navigation

import android.content.Context
import android.content.Intent
import android.net.Uri

internal fun launchCall(context: Context, phone: String) {
    if (phone.isNotBlank()) {
        try {
            val intent = Intent(Intent.ACTION_DIAL, Uri.parse("tel:$phone"))
            context.startActivity(intent)
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }
}

internal fun launchWhatsApp(
    context: Context,
    phone: String,
    message: String = "আসসালামু আলাইকুম, সমিতি থেকে আপনার সাথে যোগাযোগ করা হচ্ছে।"
) {
    if (phone.isNotBlank()) {
        try {
            val cleanPhone = if (phone.startsWith("+88")) phone else if (phone.startsWith("88")) "+$phone" else "+88$phone"
            val uri = Uri.parse("https://api.whatsapp.com/send?phone=$cleanPhone&text=${Uri.encode(message)}")
            val intent = Intent(Intent.ACTION_VIEW, uri)
            context.startActivity(intent)
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }
}
