package com.helptrickbd.myapplicationsomithierp.core.pdf

import android.content.Context
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.RectF
import android.graphics.pdf.PdfDocument
import com.helptrickbd.myapplicationsomithierp.core.util.CurrencyFormatter
import com.helptrickbd.myapplicationsomithierp.domain.model.ApprovalStatus
import com.helptrickbd.myapplicationsomithierp.domain.model.Member
import com.helptrickbd.myapplicationsomithierp.domain.model.Payment
import java.io.File
import java.io.FileOutputStream
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

object PassbookPdfGenerator {

    private const val PAGE_WIDTH = 595 // A4 Width in PostScript points
    private const val PAGE_HEIGHT = 842 // A4 Height in PostScript points

    fun generatePassbookPdf(
        context: Context,
        member: Member,
        branchName: String = "অগ্রগামী ফান্ড (দাখিল ব্যাচ ২০১৫)",
        payments: List<Payment>
    ): File {
        val pdfDocument = PdfDocument()
        val pageInfo = PdfDocument.PageInfo.Builder(PAGE_WIDTH, PAGE_HEIGHT, 1).create()
        val page = pdfDocument.startPage(pageInfo)
        val canvas = page.canvas

        drawPassbook(canvas, member, branchName, payments)

        pdfDocument.finishPage(page)

        val outputFile = File(context.cacheDir, "PASSBOOK_${member.id.take(8)}.pdf")
        val outputStream = FileOutputStream(outputFile)
        pdfDocument.writeTo(outputStream)
        pdfDocument.close()
        outputStream.close()

        return outputFile
    }

    private fun drawPassbook(canvas: Canvas, member: Member, branchName: String, payments: List<Payment>) {
        val paint = Paint(Paint.ANTI_ALIAS_FLAG)

        // 1. Background
        paint.color = Color.WHITE
        paint.style = Paint.Style.FILL
        canvas.drawRect(0f, 0f, PAGE_WIDTH.toFloat(), PAGE_HEIGHT.toFloat(), paint)

        // 2. Decorative Header Banner
        paint.color = Color.rgb(15, 76, 129) // Somithi Navy
        canvas.drawRect(0f, 0f, PAGE_WIDTH.toFloat(), 90f, paint)

        // Somithi Name
        paint.color = Color.WHITE
        paint.textSize = 18f
        paint.isFakeBoldText = true
        paint.textAlign = Paint.Align.CENTER
        canvas.drawText(branchName, PAGE_WIDTH / 2f, 38f, paint)

        // Subtitle
        paint.textSize = 12f
        paint.isFakeBoldText = false
        paint.color = Color.rgb(224, 242, 254)
        canvas.drawText("সদস্য ডিজিটাল পাসবই হিসাব বিবরণী (Member Passbook Statement)", PAGE_WIDTH / 2f, 58f, paint)

        val generatedDate = SimpleDateFormat("dd MMMM, yyyy - hh:mm a", Locale.getDefault()).format(Date())
        paint.textSize = 9f
        paint.color = Color.rgb(186, 230, 253)
        canvas.drawText("ইস্যুর তারিখ ও সময়: $generatedDate", PAGE_WIDTH / 2f, 75f, paint)

        // 3. Member Info Box
        paint.textAlign = Paint.Align.LEFT
        val memberBox = RectF(24f, 105f, PAGE_WIDTH - 24f, 180f)
        paint.color = Color.rgb(248, 250, 252) // Slate-50
        paint.style = Paint.Style.FILL
        canvas.drawRoundRect(memberBox, 10f, 10f, paint)

        paint.color = Color.rgb(203, 213, 225)
        paint.style = Paint.Style.STROKE
        paint.strokeWidth = 1f
        canvas.drawRoundRect(memberBox, 10f, 10f, paint)

        paint.style = Paint.Style.FILL
        paint.color = Color.rgb(15, 23, 42) // Slate-900
        paint.textSize = 12f
        paint.isFakeBoldText = true
        canvas.drawText("সদস্যের নাম: ${member.name}", 38f, 130f, paint)
        canvas.drawText("সদস্য আইডি: #${member.id.take(8).uppercase()}", 320f, 130f, paint)

        paint.isFakeBoldText = false
        paint.color = Color.rgb(71, 85, 105)
        paint.textSize = 10f
        canvas.drawText("মোবাইল নম্বর: ${member.phone}", 38f, 150f, paint)
        canvas.drawText("শাখা কোড: ${member.branchId}", 320f, 150f, paint)
        canvas.drawText("সদস্যপদ স্ট্যাটাস: ${if (member.status.name == "ACTIVE") "সক্রিয় (Active)" else "নিষ্ক্রিয়"}", 38f, 168f, paint)

        // 4. Financial Highlights Strip
        val summaryBox = RectF(24f, 192f, PAGE_WIDTH - 24f, 245f)
        paint.color = Color.rgb(241, 245, 249)
        canvas.drawRoundRect(summaryBox, 8f, 8f, paint)

        val totalSavings = payments.filter { it.approvalStatus == ApprovalStatus.APPROVED }.sumOf { it.amount }
        val pendingCount = payments.count { it.approvalStatus == ApprovalStatus.PENDING }

        paint.textAlign = Paint.Align.CENTER
        paint.textSize = 9f
        paint.color = Color.rgb(100, 116, 139)
        canvas.drawText("মোট সঞ্চয় জমা", 100f, 210f, paint)
        canvas.drawText("বর্তমান বকেয়া", 235f, 210f, paint)
        canvas.drawText("চলতি ঋণ/কর্জ", 370f, 210f, paint)
        canvas.drawText("অপেক্ষমাণ জমা", 500f, 210f, paint)

        paint.textSize = 12f
        paint.isFakeBoldText = true
        paint.color = Color.rgb(22, 101, 52) // Green
        canvas.drawText(CurrencyFormatter.formatBDT(totalSavings), 100f, 230f, paint)

        paint.color = Color.rgb(180, 83, 9) // Amber
        canvas.drawText(CurrencyFormatter.formatBDT(member.outstandingDues), 235f, 230f, paint)

        paint.color = Color.rgb(185, 28, 28) // Red
        canvas.drawText(CurrencyFormatter.formatBDT(member.activeLoanBalance), 370f, 230f, paint)

        paint.color = Color.rgb(30, 64, 175) // Blue
        canvas.drawText("$pendingCount টি", 500f, 230f, paint)

        // 5. Table Header
        var currentY = 275f
        paint.textAlign = Paint.Align.LEFT
        paint.color = Color.rgb(15, 76, 129)
        canvas.drawRect(24f, currentY - 16f, PAGE_WIDTH - 24f, currentY + 8f, paint)

        paint.color = Color.WHITE
        paint.textSize = 9f
        paint.isFakeBoldText = true
        canvas.drawText("তারিখ", 32f, currentY, paint)
        canvas.drawText("জমার মাস", 110f, currentY, paint)
        canvas.drawText("মাধ্যম ও TrxID", 205f, currentY, paint)
        canvas.drawText("পরিমাণ (টাকা)", 380f, currentY, paint)
        canvas.drawText("স্ট্যাটাস", 495f, currentY, paint)

        // 6. Table Rows
        currentY += 24f
        paint.isFakeBoldText = false
        val dateFormat = SimpleDateFormat("dd/MM/yyyy", Locale.getDefault())

        val sortedPayments = payments.sortedByDescending { it.date }.take(18)
        for (payment in sortedPayments) {
            paint.color = Color.rgb(248, 250, 252)
            canvas.drawRect(24f, currentY - 14f, PAGE_WIDTH - 24f, currentY + 6f, paint)

            paint.color = Color.rgb(51, 65, 85)
            paint.textSize = 9f
            canvas.drawText(dateFormat.format(Date(payment.date)), 32f, currentY, paint)
            canvas.drawText("${payment.forMonth} ${payment.forYear}", 110f, currentY, paint)
            val trxText = if (payment.transactionId.isNotBlank()) " (${payment.transactionId.take(10)})" else ""
            canvas.drawText("${payment.method}$trxText", 205f, currentY, paint)

            paint.isFakeBoldText = true
            paint.color = Color.rgb(22, 101, 52)
            canvas.drawText("+ " + CurrencyFormatter.formatBDT(payment.amount), 380f, currentY, paint)

            paint.isFakeBoldText = false
            paint.color = if (payment.approvalStatus == ApprovalStatus.APPROVED) Color.rgb(22, 101, 52) else Color.rgb(180, 83, 9)
            val statusLabel = if (payment.approvalStatus == ApprovalStatus.APPROVED) "অনুমোদিত" else "অপেক্ষমাণ"
            canvas.drawText(statusLabel, 495f, currentY, paint)

            currentY += 22f
            if (currentY > PAGE_HEIGHT - 90f) break
        }

        // 7. Signature Footer
        val footerY = PAGE_HEIGHT - 45f
        paint.color = Color.rgb(148, 163, 184)
        paint.strokeWidth = 1f
        canvas.drawLine(40f, footerY - 15f, 180f, footerY - 15f, paint)
        canvas.drawLine(PAGE_WIDTH - 180f, footerY - 15f, PAGE_WIDTH - 40f, footerY - 15f, paint)

        paint.textAlign = Paint.Align.CENTER
        paint.textSize = 9f
        paint.color = Color.rgb(71, 85, 105)
        canvas.drawText("সদস্যের স্বাক্ষর", 110f, footerY, paint)
        canvas.drawText("সাধারণ সম্পাদক / কোষাধ্যক্ষ", PAGE_WIDTH - 110f, footerY, paint)
    }

    fun printPassbook(
        context: Context,
        member: Member,
        branchName: String,
        payments: List<Payment>
    ) {
        val pdfFile = generatePassbookPdf(context, member, branchName, payments)
        PdfPrintHelper.printOrSharePdf(
            context = context,
            jobName = "Passbook_${member.id}",
            documentName = "Passbook_${member.name}.pdf",
            pdfFile = pdfFile
        )
    }
}
