package com.helptrickbd.myapplicationsomithierp.core.data

import com.helptrickbd.myapplicationsomithierp.core.util.safeRound
import com.helptrickbd.myapplicationsomithierp.domain.model.*
import java.util.UUID

/**
 * Handles core financial operations and ledger calculations for Shomiti ERP.
 * Strictly enforces `safeRound()` on every transaction amount, installment, and settlement.
 */
internal object ShomitiFinancialMutations {

    fun recordPayment(dataManager: ShomitiDataManager, payment: Payment) {
        val roundedAmount = safeRound(payment.amount)
        val sanitizedPayment = payment.copy(
            id = if (payment.id.isEmpty()) "p-${UUID.randomUUID().toString().take(8)}" else payment.id,
            amount = roundedAmount,
            receiptNumber = if (payment.receiptNumber.isEmpty()) "RCP-${System.currentTimeMillis() % 1000000}" else payment.receiptNumber,
            date = if (payment.date == 0L) System.currentTimeMillis() else payment.date
        )

        dataManager._payments.value = listOf(sanitizedPayment) + dataManager._payments.value

        // Update member dues and contributions with safeRound
        dataManager._members.value = dataManager._members.value.map { member ->
            if (member.id == sanitizedPayment.memberId) {
                member.copy(
                    totalContributed = safeRound(member.totalContributed + roundedAmount),
                    outstandingDues = safeRound((member.outstandingDues - roundedAmount).coerceAtLeast(0.0))
                )
            } else {
                member
            }
        }

        // Update branch balance with safeRound
        dataManager._branches.value = dataManager._branches.value.map { branch ->
            if (branch.id == sanitizedPayment.branchId) {
                branch.copy(balance = safeRound(branch.balance + roundedAmount))
            } else {
                branch
            }
        }

        dataManager.refreshState()
    }

    fun recordExpense(dataManager: ShomitiDataManager, expense: Expense) {
        val roundedAmount = safeRound(expense.amount)
        val sanitizedExpense = expense.copy(
            id = if (expense.id.isEmpty()) "exp-${UUID.randomUUID().toString().take(8)}" else expense.id,
            amount = roundedAmount,
            date = if (expense.date == 0L) System.currentTimeMillis() else expense.date
        )

        dataManager._expenses.value = listOf(sanitizedExpense) + dataManager._expenses.value

        // Deduct from branch balance with safeRound
        dataManager._branches.value = dataManager._branches.value.map { branch ->
            if (branch.id == sanitizedExpense.branchId || branch.id == "b-1") {
                branch.copy(balance = safeRound(branch.balance - roundedAmount))
            } else {
                branch
            }
        }

        dataManager.refreshState()
    }

    fun disburseLoan(dataManager: ShomitiDataManager, loan: Loan) {
        val roundedAmount = safeRound(loan.amount)
        val sanitizedLoan = loan.copy(
            id = if (loan.id.isEmpty()) "ln-${UUID.randomUUID().toString().take(8)}" else loan.id,
            amount = roundedAmount,
            dateIssued = if (loan.dateIssued == 0L) System.currentTimeMillis() else loan.dateIssued
        )

        dataManager._loans.value = listOf(sanitizedLoan) + dataManager._loans.value

        // Update member active loan balance with safeRound
        dataManager._members.value = dataManager._members.value.map { member ->
            if (member.id == sanitizedLoan.memberId) {
                member.copy(
                    activeLoanBalance = safeRound(member.activeLoanBalance + sanitizedLoan.totalPayable)
                )
            } else {
                member
            }
        }

        // Deduct principal from branch balance
        dataManager._branches.value = dataManager._branches.value.map { branch ->
            if (branch.id == sanitizedLoan.branchId || branch.id == "b-1") {
                branch.copy(balance = safeRound(branch.balance - roundedAmount))
            } else {
                branch
            }
        }

        dataManager.refreshState()
    }

    fun repayLoanInstallment(
        dataManager: ShomitiDataManager,
        loanId: String,
        repaymentAmount: Double,
        method: String = "Cash"
    ) {
        val safeAmount = safeRound(repaymentAmount)
        var memberIdToUpdate: String? = null

        dataManager._loans.value = dataManager._loans.value.map { loan ->
            if (loan.id == loanId) {
                memberIdToUpdate = loan.memberId
                val newRepayment = LoanRepayment(amount = safeAmount, date = System.currentTimeMillis(), method = method)
                val updatedRepayments = loan.repayments + newRepayment
                val updatedLoan = loan.copy(repayments = updatedRepayments)
                val newStatus = if (updatedLoan.outstandingBalance <= 0.0) LoanStatus.PAID_OFF else LoanStatus.ACTIVE
                updatedLoan.copy(status = newStatus)
            } else {
                loan
            }
        }

        memberIdToUpdate?.let { mId ->
            dataManager._members.value = dataManager._members.value.map { member ->
                if (member.id == mId) {
                    member.copy(
                        activeLoanBalance = safeRound((member.activeLoanBalance - safeAmount).coerceAtLeast(0.0))
                    )
                } else {
                    member
                }
            }
        }

        // Credit to branch balance
        dataManager._branches.value = dataManager._branches.value.map { branch ->
            if (branch.id == "b-1") {
                branch.copy(balance = safeRound(branch.balance + safeAmount))
            } else {
                branch
            }
        }

        dataManager.refreshState()
    }

    fun processMemberExit(
        dataManager: ShomitiDataManager,
        memberId: String,
        payoutMethod: String = "Cash",
        note: String = ""
    ): MemberExit? {
        val member = dataManager._members.value.find { it.id == memberId } ?: return null
        
        val safeContributed = safeRound(member.totalContributed)
        val safeDues = safeRound(member.outstandingDues)
        val safeLoans = safeRound(member.activeLoanBalance)

        // Settlement Formula: Net Refund = Contributed - Dues - ActiveLoans
        val netSettlement = safeRound((safeContributed - safeDues - safeLoans).coerceAtLeast(0.0))

        val exitRecord = MemberExit(
            id = "exit-${UUID.randomUUID().toString().take(8)}",
            memberId = member.id,
            memberName = member.name,
            totalContributed = safeContributed,
            outstandingDues = safeDues,
            outstandingLoan = safeLoans,
            finalSettlementAmount = netSettlement,
            payoutDate = System.currentTimeMillis(),
            payoutMethod = payoutMethod,
            processedBy = "Super Admin"
        )

        // Mark member as LEFT
        dataManager._members.value = dataManager._members.value.map { m ->
            if (m.id == memberId) {
                m.copy(
                    status = MemberStatus.LEFT,
                    exitDate = System.currentTimeMillis(),
                    outstandingDues = 0.0,
                    activeLoanBalance = 0.0
                )
            } else {
                m
            }
        }

        // Deduct payout from branch balance with safeRound
        dataManager._branches.value = dataManager._branches.value.map { branch ->
            if (branch.id == member.branchId || branch.id == "b-1") {
                branch.copy(balance = safeRound(branch.balance - netSettlement))
            } else {
                branch
            }
        }

        dataManager.refreshState()
        return exitRecord
    }

    fun distributeDividends(dataManager: ShomitiDataManager, run: DividendRun) {
        run.allocations.forEach { allocation ->
            val safePayout = safeRound(allocation.amountPaid)
        }
        dataManager.refreshState()
    }
}
