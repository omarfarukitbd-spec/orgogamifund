package com.helptrickbd.myapplicationsomithierp.core.backup

import android.content.Context
import android.content.Intent
import androidx.core.content.FileProvider
import com.helptrickbd.myapplicationsomithierp.domain.model.AuditLog
import com.helptrickbd.myapplicationsomithierp.domain.model.CommitteeMember
import com.helptrickbd.myapplicationsomithierp.domain.model.Expense
import com.helptrickbd.myapplicationsomithierp.domain.model.Loan
import com.helptrickbd.myapplicationsomithierp.domain.model.Member
import com.helptrickbd.myapplicationsomithierp.domain.model.Notice
import com.helptrickbd.myapplicationsomithierp.domain.model.Payment
import org.json.JSONArray
import org.json.JSONObject
import java.io.File
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

data class BackupPayload(
    val exportTimestamp: Long = System.currentTimeMillis(),
    val appVersion: String = "1.0.0",
    val orgName: String = "Shomiti Manager",
    val members: List<Member> = emptyList(),
    val payments: List<Payment> = emptyList(),
    val expenses: List<Expense> = emptyList(),
    val loans: List<Loan> = emptyList(),
    val notices: List<Notice> = emptyList(),
    val committee: List<CommitteeMember> = emptyList(),
    val auditLogs: List<AuditLog> = emptyList()
)

data class BackupSummary(
    val fileName: String,
    val fileSizeKb: Long,
    val memberCount: Int,
    val paymentCount: Int,
    val expenseCount: Int,
    val loanCount: Int,
    val noticeCount: Int,
    val committeeCount: Int
)

class DataBackupManager(private val context: Context) {

    fun generateBackupJson(payload: BackupPayload): File {
        val root = JSONObject()
        root.put("exportTimestamp", payload.exportTimestamp)
        root.put("exportDate", SimpleDateFormat("yyyy-MM-dd HH:mm:ss", Locale.getDefault()).format(Date(payload.exportTimestamp)))
        root.put("appVersion", payload.appVersion)
        root.put("orgName", payload.orgName)

        // Members
        val membersArray = JSONArray()
        payload.members.forEach { m ->
            val obj = JSONObject()
            obj.put("id", m.id)
            obj.put("name", m.name)
            obj.put("phone", m.phone)
            obj.put("address", m.address)
            obj.put("nid", m.nid)
            obj.put("branchId", m.branchId)
            obj.put("status", m.status.name)
            obj.put("totalContributed", m.totalContributed)
            obj.put("outstandingDues", m.outstandingDues)
            obj.put("activeLoanBalance", m.activeLoanBalance)
            membersArray.put(obj)
        }
        root.put("members", membersArray)

        // Payments
        val paymentsArray = JSONArray()
        payload.payments.forEach { p ->
            val obj = JSONObject()
            obj.put("id", p.id)
            obj.put("memberId", p.memberId)
            obj.put("memberName", p.memberName)
            obj.put("amount", p.amount)
            obj.put("method", p.method)
            obj.put("receiptNumber", p.receiptNumber)
            obj.put("forMonth", p.forMonth)
            obj.put("forYear", p.forYear)
            obj.put("type", p.type.name)
            paymentsArray.put(obj)
        }
        root.put("payments", paymentsArray)

        // Expenses
        val expensesArray = JSONArray()
        payload.expenses.forEach { e ->
            val obj = JSONObject()
            obj.put("id", e.id)
            obj.put("branchId", e.branchId)
            obj.put("category", e.category)
            obj.put("amount", e.amount)
            obj.put("description", e.description)
            obj.put("attachmentUrl", e.attachmentUrl ?: JSONObject.NULL)
            obj.put("date", e.date)
            obj.put("recordedBy", e.recordedBy)
            expensesArray.put(obj)
        }
        root.put("expenses", expensesArray)

        // Loans
        val loansArray = JSONArray()
        payload.loans.forEach { l ->
            val obj = JSONObject()
            obj.put("id", l.id)
            obj.put("memberId", l.memberId)
            obj.put("memberName", l.memberName)
            obj.put("branchId", l.branchId)
            obj.put("amount", l.amount)
            obj.put("dateIssued", l.dateIssued)
            obj.put("reason", l.reason)
            obj.put("interestEnabled", l.interestEnabled)
            obj.put("interestRate", l.interestRate)
            obj.put("totalPayable", l.totalPayable)
            obj.put("totalRepaid", l.totalRepaid)
            obj.put("outstandingBalance", l.outstandingBalance)
            obj.put("status", l.status.name)
            loansArray.put(obj)
        }
        root.put("loans", loansArray)

        // Notices
        val noticesArray = JSONArray()
        payload.notices.forEach { n ->
            val obj = JSONObject()
            obj.put("id", n.id)
            obj.put("title", n.title)
            obj.put("body", n.body)
            obj.put("type", n.type.name)
            obj.put("scope", n.scope.name)
            obj.put("postedAt", n.postedAt)
            noticesArray.put(obj)
        }
        root.put("notices", noticesArray)

        // Committee
        val committeeArray = JSONArray()
        payload.committee.forEach { c ->
            val obj = JSONObject()
            obj.put("id", c.id)
            obj.put("memberName", c.memberName)
            obj.put("designation", c.designation)
            obj.put("termStart", c.termStart)
            obj.put("termEnd", c.termEnd ?: JSONObject.NULL)
            committeeArray.put(obj)
        }
        root.put("committee", committeeArray)

        // Audit Logs
        val auditArray = JSONArray()
        payload.auditLogs.forEach { a ->
            val obj = JSONObject()
            obj.put("id", a.id)
            obj.put("entityType", a.entityType)
            obj.put("action", a.action.name)
            obj.put("changedBy", a.changedBy)
            obj.put("timestamp", a.timestamp)
            obj.put("note", a.note)
            auditArray.put(obj)
        }
        root.put("auditLogs", auditArray)

        val timeStamp = SimpleDateFormat("yyyyMMdd_HHmmss", Locale.getDefault()).format(Date())
        val fileName = "SomithiERP_Backup_$timeStamp.json"
        val backupDir = File(context.cacheDir, "backups")
        if (!backupDir.exists()) {
            backupDir.mkdirs()
        }
        val file = File(backupDir, fileName)
        file.writeText(root.toString(2))
        return file
    }

    fun shareBackupFile(file: File) {
        val uri = FileProvider.getUriForFile(
            context,
            "${context.packageName}.fileprovider",
            file
        )

        val sendIntent = Intent(Intent.ACTION_SEND).apply {
            type = "application/json"
            putExtra(Intent.EXTRA_SUBJECT, "Somithi ERP Database Backup (${file.name})")
            putExtra(Intent.EXTRA_STREAM, uri)
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        }

        val chooser = Intent.createChooser(sendIntent, "সমিতির ডেটা ব্যাকআপ সংরক্ষণ / শেয়ার করুন").apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        context.startActivity(chooser)
    }
}
