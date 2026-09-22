package com.helptrickbd.myapplicationsomithierp.core.pdf

import android.content.Context
import android.content.Intent
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.RectF
import android.graphics.pdf.PdfDocument

import com.helptrickbd.myapplicationsomithierp.core.util.CurrencyFormatter
import com.helptrickbd.myapplicationsomithierp.core.util.safeRound
import com.helptrickbd.myapplicationsomithierp.domain.model.Expense
import com.helptrickbd.myapplicationsomithierp.domain.model.Loan
import com.helptrickbd.myapplicationsomithierp.domain.model.Member
import com.helptrickbd.myapplicationsomithierp.domain.model.Payment
import java.io.File
import java.io.FileInputStream
import java.io.FileOutputStream
import java.io.IOException
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

object ReportPdfGenerator {

    const val PAGE_WIDTH = 595 // A4 standard width in points
    const val PAGE_HEIGHT = 842 // A4 standard height in points

    fun generateReportPdf(
        context: Context,
        reportTitle: String,
        orgName: String = "সোনার বাংলা সমবায় সমিতি",
        members: List<Member> = emptyList(),
        payments: List<Payment> = emptyList(),
        expenses: List<Expense> = emptyList(),
        loans: List<Loan> = emptyList()
    ): File {
        val pdfDocument = PdfDocument()
        val pageInfo = PdfDocument.PageInfo.Builder(PAGE_WIDTH, PAGE_HEIGHT, 1).create()
        val page = pdfDocument.startPage(pageInfo)
        val canvas = page.canvas

        drawReportDocument(canvas, reportTitle, orgName, members, payments, expenses, loans)

        pdfDocument.finishPage(page)

        val outputFile = File(context.cacheDir, "REPORT_${System.currentTimeMillis()}.pdf")
        val outputStream = FileOutputStream(outputFile)
        pdfDocument.writeTo(outputStream)
        pdfDocument.close()
        outputStream.close()

        return outputFile
    }

    private fun drawReportDocument(
        canvas: Canvas,
        reportTitle: String,
        orgName: String,
        members: List<Member>,
        payments: List<Payment>,
        expenses: List<Expense>,
        loans: List<Loan>
    ) {
        val paint = Paint(Paint.ANTI_ALIAS_FLAG)

        // 1. Background
        paint.color = Color.WHITE
        paint.style = Paint.Style.FILL
        canvas.drawRect(0f, 0f, PAGE_WIDTH.toFloat(), PAGE_HEIGHT.toFloat(), paint)

        // 2. Top Header Accent
        paint.color = Color.rgb(15, 118, 110) // Primary Teal
        canvas.drawRect(0f, 0f, PAGE_WIDTH.toFloat(), 12f, paint)

        // 3. Organization Title & Date
        paint.color = Color.rgb(15, 23, 42)
        paint.textSize = 20f
        paint.isFakeBoldText = true
        canvas.drawText(orgName, 40f, 50f, paint)

        paint.color = Color.rgb(100, 116, 139)
        paint.textSize = 10f
        paint.isFakeBoldText = false
        canvas.drawText("সমবায় সমিতি সার্বিক আর্থিক ও কার্যক্রম প্রতিবেদন", 40f, 68f, paint)

        val dateFormat = SimpleDateFormat("dd MMMM, yyyy", Locale.getDefault())
        val dateText = "প্রতিবেদন প্রকাশের তারিখ: ${dateFormat.format(Date())}"
        paint.textAlign = Paint.Align.RIGHT
        canvas.drawText(dateText, PAGE_WIDTH - 40f, 50f, paint)
        paint.textAlign = Paint.Align.LEFT

        // Divider
        paint.color = Color.rgb(226, 232, 240)
        paint.strokeWidth = 1f
        canvas.drawLine(40f, 85f, PAGE_WIDTH - 40f, 85f, paint)

        // Report Title Badge
        paint.color = Color.rgb(241, 245, 249)
        paint.style = Paint.Style.FILL
        val badgeRect = RectF(40f, 100f, PAGE_WIDTH - 40f, 140f)
        canvas.drawRoundRect(badgeRect, 8f, 8f, paint)

        paint.color = Color.rgb(15, 118, 110)
        paint.textSize = 14f
        paint.isFakeBoldText = true
        canvas.drawText(reportTitle, 55f, 125f, paint)

        // Draw Content based on report type
        var currentY = 165f

        when {
            reportTitle.contains("সারসংক্ষেপ") -> {
                currentY = drawSummarySection(canvas, paint, currentY, members, payments, expenses, loans)
            }
            reportTitle.contains("খরচ") -> {
                currentY = drawExpenseSection(canvas, paint, currentY, expenses)
            }
            reportTitle.contains("ঋণ") -> {
                currentY = drawLoanSection(canvas, paint, currentY, loans)
            }
            else -> {
                currentY = drawMemberLedgerSection(canvas, paint, currentY, members)
            }
        }

        // Footer
        paint.color = Color.rgb(148, 163, 184)
        paint.textSize = 9f
        paint.isFakeBoldText = false
        canvas.drawLine(40f, PAGE_HEIGHT - 40f, PAGE_WIDTH - 40f, PAGE_HEIGHT - 40f, paint)
        canvas.drawText("This report is generated securely by Shomiti Manager ERP.", 40f, PAGE_HEIGHT - 25f, paint)
        paint.textAlign = Paint.Align.RIGHT
        canvas.drawText("পৃষ্ঠা ১ / ১", PAGE_WIDTH - 40f, PAGE_HEIGHT - 25f, paint)
    }

    private fun drawSummarySection(
        canvas: Canvas,
        paint: Paint,
        startY: Float,
        members: List<Member>,
        payments: List<Payment>,
        expenses: List<Expense>,
        loans: List<Loan>
    ): Float {
        var y = startY
        val totalCollections = safeRound(payments.sumOf { safeRound(it.amount) })
        val totalExpenses = safeRound(expenses.sumOf { safeRound(it.amount) })
        val totalActiveLoans = safeRound(loans.filter { it.status.name == "ACTIVE" }.sumOf { safeRound(it.outstandingBalance) })
        val totalDues = safeRound(members.sumOf { safeRound(it.outstandingDues) })
        val runningBalance = safeRound(1250000.0 + totalCollections - totalExpenses - totalActiveLoans)

        val metrics = listOf(
            "মোট সংগৃহীত চাঁদা ও সঞ্চয়" to CurrencyFormatter.formatBDT(totalCollections),
            "মোট নির্বাহকৃত সমিতি খরচ" to CurrencyFormatter.formatBDT(totalExpenses),
            "সদস্যদের মাঝে চলতি বিতরণকৃত ঋণ" to CurrencyFormatter.formatBDT(totalActiveLoans),
            "সদস্যদের মোট বকেয়া চাঁদা" to CurrencyFormatter.formatBDT(totalDues),
            "সমিতির নেট বর্তমান তহবিল স্থিতি" to CurrencyFormatter.formatBDT(runningBalance)
        )

        paint.textSize = 12f
        metrics.forEach { (label, value) ->
            paint.color = Color.rgb(71, 85, 105)
            paint.isFakeBoldText = false
            canvas.drawText(label, 50f, y, paint)

            paint.color = Color.rgb(15, 23, 42)
            paint.isFakeBoldText = true
            paint.textAlign = Paint.Align.RIGHT
            canvas.drawText(value, PAGE_WIDTH - 50f, y, paint)
            paint.textAlign = Paint.Align.LEFT

            paint.color = Color.rgb(241, 245, 249)
            canvas.drawLine(50f, y + 8f, PAGE_WIDTH - 50f, y + 8f, paint)
            y += 36f
        }

        return y
    }

    private fun drawExpenseSection(canvas: Canvas, paint: Paint, startY: Float, expenses: List<Expense>): Float {
        var y = startY
        // Header
        paint.color = Color.rgb(241, 245, 249)
        canvas.drawRect(40f, y, PAGE_WIDTH - 40f, y + 26f, paint)
        paint.color = Color.rgb(15, 23, 42)
        paint.textSize = 10f
        paint.isFakeBoldText = true
        canvas.drawText("খাত", 50f, y + 18f, paint)
        canvas.drawText("বিবরণ", 160f, y + 18f, paint)
        paint.textAlign = Paint.Align.RIGHT
        canvas.drawText("পরিমাণ (টাকা)", PAGE_WIDTH - 50f, y + 18f, paint)
        paint.textAlign = Paint.Align.LEFT

        y += 34f
        paint.isFakeBoldText = false
        paint.textSize = 10f

        expenses.take(12).forEach { exp ->
            paint.color = Color.rgb(51, 65, 85)
            canvas.drawText(exp.category, 50f, y, paint)
            canvas.drawText(exp.description.take(25), 160f, y, paint)
            paint.textAlign = Paint.Align.RIGHT
            paint.color = Color.rgb(220, 38, 38)
            canvas.drawText(CurrencyFormatter.formatBDT(safeRound(exp.amount)), PAGE_WIDTH - 50f, y, paint)
            paint.textAlign = Paint.Align.LEFT

            y += 24f
        }

        return y
    }

    private fun drawLoanSection(canvas: Canvas, paint: Paint, startY: Float, loans: List<Loan>): Float {
        var y = startY
        paint.color = Color.rgb(241, 245, 249)
        canvas.drawRect(40f, y, PAGE_WIDTH - 40f, y + 26f, paint)
        paint.color = Color.rgb(15, 23, 42)
        paint.textSize = 10f
        paint.isFakeBoldText = true
        canvas.drawText("সদস্যের নাম", 50f, y + 18f, paint)
        canvas.drawText("বিতরণ", 180f, y + 18f, paint)
        canvas.drawText("আদায়", 300f, y + 18f, paint)
        paint.textAlign = Paint.Align.RIGHT
        canvas.drawText("অবশিষ্ট বকেয়া", PAGE_WIDTH - 50f, y + 18f, paint)
        paint.textAlign = Paint.Align.LEFT

        y += 34f
        paint.isFakeBoldText = false
        paint.textSize = 10f

        loans.take(12).forEach { loan ->
            paint.color = Color.rgb(51, 65, 85)
            canvas.drawText(loan.memberName, 50f, y, paint)
            canvas.drawText(CurrencyFormatter.formatBDT(safeRound(loan.amount)), 180f, y, paint)
            canvas.drawText(CurrencyFormatter.formatBDT(safeRound(loan.totalRepaid)), 300f, y, paint)
            paint.textAlign = Paint.Align.RIGHT
            paint.color = Color.rgb(220, 38, 38)
            canvas.drawText(CurrencyFormatter.formatBDT(safeRound(loan.outstandingBalance)), PAGE_WIDTH - 50f, y, paint)
            paint.textAlign = Paint.Align.LEFT

            y += 24f
        }

        return y
    }

    private fun drawMemberLedgerSection(canvas: Canvas, paint: Paint, startY: Float, members: List<Member>): Float {
        var y = startY
        paint.color = Color.rgb(241, 245, 249)
        canvas.drawRect(40f, y, PAGE_WIDTH - 40f, y + 26f, paint)
        paint.color = Color.rgb(15, 23, 42)
        paint.textSize = 10f
        paint.isFakeBoldText = true
        canvas.drawText("সদস্যের নাম", 50f, y + 18f, paint)
        canvas.drawText("মোবাইল", 170f, y + 18f, paint)
        canvas.drawText("মোট সঞ্চয়", 290f, y + 18f, paint)
        paint.textAlign = Paint.Align.RIGHT
        canvas.drawText("বকেয়া", PAGE_WIDTH - 50f, y + 18f, paint)
        paint.textAlign = Paint.Align.LEFT

        y += 34f
        paint.isFakeBoldText = false
        paint.textSize = 10f

        members.take(15).forEach { m ->
            paint.color = Color.rgb(51, 65, 85)
            canvas.drawText(m.name, 50f, y, paint)
            canvas.drawText(m.phone, 170f, y, paint)
            paint.color = Color.rgb(22, 163, 74)
            canvas.drawText(CurrencyFormatter.formatBDT(safeRound(m.totalContributed)), 290f, y, paint)
            paint.textAlign = Paint.Align.RIGHT
            paint.color = if (m.outstandingDues > 0) Color.rgb(217, 119, 6) else Color.GRAY
            canvas.drawText(CurrencyFormatter.formatBDT(safeRound(m.outstandingDues)), PAGE_WIDTH - 50f, y, paint)
            paint.textAlign = Paint.Align.LEFT

            y += 24f
        }

        return y
    }

    fun printReport(context: Context, pdfFile: File) {
        val jobName = "Shomiti_Report_${System.currentTimeMillis()}"
        PdfPrintHelper.printOrSharePdf(
            context = context,
            jobName = jobName,
            documentName = "shomiti_report_${System.currentTimeMillis()}.pdf",
            pdfFile = pdfFile
        )
    }

    fun shareReportPdf(context: Context, pdfFile: File) {
        PdfPrintHelper.openWithExternalViewer(context, pdfFile)
    }
}
