package com.helptrickbd.myapplicationsomithierp.core.pdf

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.RectF
import android.graphics.pdf.PdfDocument
import android.os.Bundle
import android.os.CancellationSignal
import android.os.ParcelFileDescriptor
import android.print.PageRange
import android.print.PrintAttributes
import android.print.PrintDocumentAdapter
import android.print.PrintDocumentInfo
import android.print.PrintManager
import com.helptrickbd.myapplicationsomithierp.R
import com.helptrickbd.myapplicationsomithierp.domain.model.Member
import java.io.File
import java.io.FileOutputStream
import java.io.FileInputStream
import java.io.IOException
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

object MemberIdCardGenerator {

    /**
     * Standard ID-1 / CR80 card size: 85.6mm x 53.98mm ~ 243 x 153 points (x2 for high DPI: 500 x 315)
     */
    const val CARD_WIDTH = 500
    const val CARD_HEIGHT = 315

    fun generateIdCardPdf(
        context: Context,
        member: Member,
        orgName: String = "অগ্রগামী ফান্ড",
        photoBitmap: Bitmap? = null
    ): File {
        val pdfDocument = PdfDocument()
        val pageInfo = PdfDocument.PageInfo.Builder(CARD_WIDTH, CARD_HEIGHT, 1).create()
        val page = pdfDocument.startPage(pageInfo)
        val canvas = page.canvas

        val logoBitmap = try {
            BitmapFactory.decodeResource(context.resources, R.drawable.ogrogami_fund_logo)
        } catch (_: Exception) {
            null
        }

        drawCardContent(canvas, member, orgName, photoBitmap, logoBitmap)

        pdfDocument.finishPage(page)

        val outputFile = File(context.cacheDir, "ID_CARD_${member.id}.pdf")
        val outputStream = FileOutputStream(outputFile)
        pdfDocument.writeTo(outputStream)
        pdfDocument.close()
        outputStream.close()

        return outputFile
    }

    private fun drawCardContent(
        canvas: Canvas,
        member: Member,
        orgName: String,
        photoBitmap: Bitmap?,
        logoBitmap: Bitmap? = null
    ) {
        val paint = Paint(Paint.ANTI_ALIAS_FLAG)

        // 1. Background White Card with rounded corners
        paint.color = Color.WHITE
        paint.style = Paint.Style.FILL
        val cardRect = RectF(8f, 8f, (CARD_WIDTH - 8).toFloat(), (CARD_HEIGHT - 8).toFloat())
        canvas.drawRoundRect(cardRect, 16f, 16f, paint)

        // 2. Card Border (Emerald Slate)
        paint.color = Color.rgb(203, 213, 225) // Slate-300
        paint.style = Paint.Style.STROKE
        paint.strokeWidth = 2f
        canvas.drawRoundRect(cardRect, 16f, 16f, paint)

        // 3. Header Bar (Deep Navy & Emerald)
        paint.style = Paint.Style.FILL
        paint.color = Color.rgb(15, 76, 129) // Classic Trust Navy
        val headerRect = RectF(8f, 8f, (CARD_WIDTH - 8).toFloat(), 68f)
        canvas.drawRoundRect(headerRect, 16f, 16f, paint)
        canvas.drawRect(8f, 40f, (CARD_WIDTH - 8).toFloat(), 68f, paint)

        // Draw Ogrogami Logo in Header
        if (logoBitmap != null) {
            val scaledLogo = Bitmap.createScaledBitmap(logoBitmap, 48, 48, true)
            canvas.drawBitmap(scaledLogo, 20f, 14f, paint)
        }

        // 4. Organization Title
        val textLeft = if (logoBitmap != null) 78f else 24f
        paint.color = Color.WHITE
        paint.textSize = 18f
        paint.isFakeBoldText = true
        canvas.drawText(orgName, textLeft, 38f, paint)

        paint.textSize = 9.5f
        paint.isFakeBoldText = false
        paint.color = Color.rgb(224, 242, 254) // Sky-100
        canvas.drawText("একটি সঞ্চয় ও কল্যাণমূলক সমবায় প্রতিষ্ঠান • সদস্য পরিচয়পত্র", textLeft, 55f, paint)

        // 5. Member Photo or Avatar Box
        val photoLeft = 24f
        val photoTop = 84f
        val photoSize = 100f
        val photoRect = RectF(photoLeft, photoTop, photoLeft + photoSize, photoTop + photoSize + 22f)

        if (photoBitmap != null) {
            canvas.drawBitmap(Bitmap.createScaledBitmap(photoBitmap, photoSize.toInt(), (photoSize + 22).toInt(), true), photoLeft, photoTop, paint)
        } else {
            paint.color = Color.rgb(241, 245, 249) // Slate-100
            canvas.drawRoundRect(photoRect, 8f, 8f, paint)
            paint.color = Color.rgb(148, 163, 184)
            paint.style = Paint.Style.STROKE
            paint.strokeWidth = 1f
            canvas.drawRoundRect(photoRect, 8f, 8f, paint)
            paint.style = Paint.Style.FILL
            paint.textSize = 11f
            paint.color = Color.rgb(100, 116, 139)
            canvas.drawText("সদস্য ছবি", photoLeft + 24f, photoTop + 65f, paint)
        }

        // 6. Member Details
        val infoLeft = 145f
        var currentY = 98f

        // Name
        paint.color = Color.rgb(15, 23, 42) // Slate-900
        paint.textSize = 16f
        paint.isFakeBoldText = true
        canvas.drawText(member.name.ifEmpty { "সদস্যের নাম" }, infoLeft, currentY, paint)

        // Member ID Badge
        currentY += 24f
        paint.textSize = 11f
        paint.color = Color.rgb(0, 121, 107)
        canvas.drawText("MEMBER ID: #${member.id.take(8).uppercase()}", infoLeft, currentY, paint)

        // Branch
        currentY += 20f
        paint.color = Color.rgb(71, 85, 105)
        paint.isFakeBoldText = false
        canvas.drawText("Branch: ${member.branchId.ifEmpty { "Main Branch" }}", infoLeft, currentY, paint)

        // Mobile Phone
        currentY += 18f
        canvas.drawText("Mobile: ${member.phone}", infoLeft, currentY, paint)

        // Join Date
        currentY += 18f
        val dateStr = SimpleDateFormat("dd MMM, yyyy", Locale.getDefault()).format(Date(member.joinDate))
        canvas.drawText("Joining Date: $dateStr", infoLeft, currentY, paint)

        // Emergency Contact
        if (member.emergencyContact.phone.isNotEmpty()) {
            currentY += 18f
            canvas.drawText("Emergency: ${member.emergencyContact.phone}", infoLeft, currentY, paint)
        }

        // 7. Footer Decorative Line
        paint.color = Color.rgb(226, 232, 240)
        canvas.drawLine(24f, 260f, (CARD_WIDTH - 24).toFloat(), 260f, paint)

        // Signatures Placeholder
        paint.color = Color.rgb(100, 116, 139)
        paint.textSize = 9f
        canvas.drawText("Member Signature", 40f, 290f, paint)
        canvas.drawText("Authorized Signature", (CARD_WIDTH - 150).toFloat(), 290f, paint)
    }

    fun printIdCard(context: Context, pdfFile: File) {
        val jobName = "Shomiti_ID_Card_${System.currentTimeMillis()}"
        PdfPrintHelper.printOrSharePdf(
            context = context,
            jobName = jobName,
            documentName = "id_card_${System.currentTimeMillis()}.pdf",
            pdfFile = pdfFile
        )
    }
}
