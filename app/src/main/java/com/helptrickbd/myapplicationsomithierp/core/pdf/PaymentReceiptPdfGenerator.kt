package com.helptrickbd.myapplicationsomithierp.core.pdf

import android.content.Context
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
import com.helptrickbd.myapplicationsomithierp.core.util.CurrencyFormatter
import com.helptrickbd.myapplicationsomithierp.domain.model.Payment
import java.io.File
import java.io.FileInputStream
import java.io.FileOutputStream
import java.io.IOException
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

object PaymentReceiptPdfGenerator {

    const val RECEIPT_WIDTH = 420
    const val RECEIPT_HEIGHT = 580

    fun generateReceiptPdf(
        context: Context,
        payment: Payment,
        orgName: String = "সোনার বাংলা সমবায় সমিতি"
    ): File {
        val pdfDocument = PdfDocument()
        val pageInfo = PdfDocument.PageInfo.Builder(RECEIPT_WIDTH, RECEIPT_HEIGHT, 1).create()
        val page = pdfDocument.startPage(pageInfo)
        val canvas = page.canvas

        drawReceipt(canvas, payment, orgName)

        pdfDocument.finishPage(page)

        val outputFile = File(context.cacheDir, "RECEIPT_${payment.receiptNumber}.pdf")
        val outputStream = FileOutputStream(outputFile)
        pdfDocument.writeTo(outputStream)
        pdfDocument.close()
        outputStream.close()

        return outputFile
    }

    private fun drawReceipt(canvas: Canvas, payment: Payment, orgName: String) {
        val paint = Paint(Paint.ANTI_ALIAS_FLAG)

        // 1. Background Paper
        paint.color = Color.WHITE
        paint.style = Paint.Style.FILL
        val cardRect = RectF(12f, 12f, (RECEIPT_WIDTH - 12).toFloat(), (RECEIPT_HEIGHT - 12).toFloat())
        canvas.drawRoundRect(cardRect, 14f, 14f, paint)

        // 2. Outer Border
        paint.color = Color.rgb(203, 213, 225) // Slate-300
        paint.style = Paint.Style.STROKE
        paint.strokeWidth = 2f
        canvas.drawRoundRect(cardRect, 14f, 14f, paint)

        // 3. Header Background Banner
        paint.style = Paint.Style.FILL
        paint.color = Color.rgb(0, 121, 107) // Emerald-700
        val headerRect = RectF(12f, 12f, (RECEIPT_WIDTH - 12).toFloat(), 75f)
        canvas.drawRoundRect(headerRect, 14f, 14f, paint)
        canvas.drawRect(12f, 50f, (RECEIPT_WIDTH - 12).toFloat(), 75f, paint)

        // 4. Header Text
        paint.color = Color.WHITE
        paint.textSize = 18f
        paint.isFakeBoldText = true
        canvas.drawText(orgName, 24f, 40f, paint)

        paint.textSize = 11f
        paint.isFakeBoldText = false
        canvas.drawText("MONEY RECEIPT / টাকা প্রাপ্তির রসিদ", 24f, 60f, paint)

        // 5. Receipt Meta Row
        var y = 105f
        paint.color = Color.rgb(71, 85, 105) // Slate-600
        paint.textSize = 11f
        paint.isFakeBoldText = true
        canvas.drawText("Receipt No: ${payment.receiptNumber}", 24f, y, paint)

        val dateStr = SimpleDateFormat("dd/MM/yyyy, hh:mm a", Locale.getDefault()).format(Date(payment.date))
        paint.isFakeBoldText = false
        canvas.drawText("Date: $dateStr", 240f, y, paint)

        // Divider
        y += 12f
        paint.color = Color.rgb(226, 232, 240)
        canvas.drawLine(24f, y, (RECEIPT_WIDTH - 24).toFloat(), y, paint)

        // 6. Member Information Section
        y += 26f
        paint.color = Color.rgb(15, 23, 42) // Slate-900
        paint.textSize = 12f
        paint.isFakeBoldText = true
        canvas.drawText("Received From: ${payment.memberName}", 24f, y, paint)

        y += 22f
        paint.color = Color.rgb(71, 85, 105)
        paint.textSize = 11f
        paint.isFakeBoldText = false
        canvas.drawText("Member ID: #${payment.memberId.take(8).uppercase()}", 24f, y, paint)
        canvas.drawText("Branch: ${payment.branchId}", 240f, y, paint)

        // 7. Payment Particulars Box
        y += 24f
        paint.color = Color.rgb(248, 250, 252) // Slate-50
        paint.style = Paint.Style.FILL
        val tableRect = RectF(24f, y, (RECEIPT_WIDTH - 24).toFloat(), y + 140f)
        canvas.drawRoundRect(tableRect, 8f, 8f, paint)

        paint.color = Color.rgb(203, 213, 225)
        paint.style = Paint.Style.STROKE
        paint.strokeWidth = 1f
        canvas.drawRoundRect(tableRect, 8f, 8f, paint)

        // Details inside Box
        paint.style = Paint.Style.FILL
        y += 28f
        paint.color = Color.rgb(100, 116, 139)
        paint.textSize = 11f
        canvas.drawText("Payment Type:", 36f, y, paint)
        paint.color = Color.rgb(15, 23, 42)
        paint.isFakeBoldText = true
        canvas.drawText(payment.type.name, 150f, y, paint)

        y += 26f
        paint.color = Color.rgb(100, 116, 139)
        paint.isFakeBoldText = false
        canvas.drawText("For Period:", 36f, y, paint)
        paint.color = Color.rgb(15, 23, 42)
        paint.isFakeBoldText = true
        canvas.drawText("${payment.forMonth}, ${payment.forYear}", 150f, y, paint)

        y += 26f
        paint.color = Color.rgb(100, 116, 139)
        paint.isFakeBoldText = false
        canvas.drawText("Payment Method:", 36f, y, paint)
        paint.color = Color.rgb(15, 23, 42)
        paint.isFakeBoldText = true
        canvas.drawText(payment.method, 150f, y, paint)

        if (payment.purposeNote.isNotEmpty()) {
            y += 26f
            paint.color = Color.rgb(100, 116, 139)
            paint.isFakeBoldText = false
            canvas.drawText("Note:", 36f, y, paint)
            paint.color = Color.rgb(15, 23, 42)
            canvas.drawText(payment.purposeNote, 150f, y, paint)
        }

        // 8. Total Amount Highlight Banner
        y = 330f
        paint.color = Color.rgb(236, 253, 245) // Mint-50
        val totalRect = RectF(24f, y, (RECEIPT_WIDTH - 24).toFloat(), y + 54f)
        canvas.drawRoundRect(totalRect, 10f, 10f, paint)

        paint.color = Color.rgb(16, 185, 129) // Emerald border
        paint.style = Paint.Style.STROKE
        paint.strokeWidth = 1.5f
        canvas.drawRoundRect(totalRect, 10f, 10f, paint)

        paint.style = Paint.Style.FILL
        paint.color = Color.rgb(4, 120, 87)
        paint.textSize = 14f
        paint.isFakeBoldText = true
        canvas.drawText("TOTAL RECEIVED:", 40f, y + 34f, paint)

        paint.color = Color.rgb(4, 120, 87)
        paint.textSize = 18f
        val amountStr = CurrencyFormatter.formatBDT(payment.amount)
        canvas.drawText(amountStr, (RECEIPT_WIDTH - 160).toFloat(), y + 34f, paint)

        // Amount In Words (কথায় ও ইংরেজিতে)
        val wordsBangla = CurrencyFormatter.formatInWords(payment.amount, isBangla = true)
        val wordsEnglish = CurrencyFormatter.formatInWords(payment.amount, isBangla = false)
        paint.color = Color.rgb(71, 85, 105)
        paint.textSize = 10f
        paint.isFakeBoldText = true
        canvas.drawText("In Words / কথায়:", 26f, y + 78f, paint)
        paint.isFakeBoldText = false
        paint.color = Color.rgb(15, 23, 42)
        canvas.drawText(wordsBangla, 26f, y + 95f, paint)
        paint.color = Color.rgb(100, 116, 139)
        paint.textSize = 9f
        canvas.drawText("($wordsEnglish)", 26f, y + 110f, paint)

        // 9. Signatures and Stamp Footer
        y = 480f
        paint.color = Color.rgb(148, 163, 184)
        canvas.drawLine(40f, y, 160f, y, paint)
        canvas.drawLine((RECEIPT_WIDTH - 160).toFloat(), y, (RECEIPT_WIDTH - 40).toFloat(), y, paint)

        paint.color = Color.rgb(100, 116, 139)
        paint.textSize = 10f
        paint.isFakeBoldText = false
        canvas.drawText("Member Signature", 55f, y + 18f, paint)
        canvas.drawText("Authorized Collector", (RECEIPT_WIDTH - 150).toFloat(), y + 18f, paint)

        // Computer generated note
        y += 45f
        paint.color = Color.rgb(148, 163, 184)
        paint.textSize = 8f
        canvas.drawText("This is an official computer-generated receipt from Shomiti Manager ERP.", 60f, y, paint)
    }

    fun printReceipt(context: Context, pdfFile: File) {
        val jobName = "Shomiti_Receipt_${System.currentTimeMillis()}"
        PdfPrintHelper.printOrSharePdf(
            context = context,
            jobName = jobName,
            documentName = "money_receipt_${System.currentTimeMillis()}.pdf",
            pdfFile = pdfFile
        )
    }
}
