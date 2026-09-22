package com.helptrickbd.myapplicationsomithierp.presentation.navigation

import androidx.navigation.NavGraphBuilder
import androidx.navigation.NavHostController
import androidx.navigation.compose.composable
import com.helptrickbd.myapplicationsomithierp.core.data.FirestoreWriteManager
import com.helptrickbd.myapplicationsomithierp.core.data.ShomitiDataManager
import com.helptrickbd.myapplicationsomithierp.core.util.CurrencyFormatter
import com.helptrickbd.myapplicationsomithierp.domain.repository.NotificationRepository
import com.helptrickbd.myapplicationsomithierp.domain.model.*
import com.helptrickbd.myapplicationsomithierp.presentation.screens.expenses.AddExpenseScreen
import com.helptrickbd.myapplicationsomithierp.presentation.screens.expenses.ExpenseListScreen
import com.helptrickbd.myapplicationsomithierp.presentation.screens.loans.IssueLoanScreen
import com.helptrickbd.myapplicationsomithierp.presentation.screens.loans.LoanListScreen
import com.helptrickbd.myapplicationsomithierp.presentation.screens.payments.DefaulterListScreen
import com.helptrickbd.myapplicationsomithierp.presentation.screens.payments.PaymentHistoryScreen
import com.helptrickbd.myapplicationsomithierp.presentation.screens.payments.RecordPaymentScreen
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.launch

fun NavGraphBuilder.addFinancialNavRoutes(
    navController: NavHostController,
    scope: CoroutineScope,
    notificationRepo: NotificationRepository,
    members: List<Member>,
    payments: List<Payment>,
    expenses: List<Expense>,
    loans: List<Loan>
) {
    composable(Screen.Contributions.route) {
        PaymentHistoryScreen(
            payments = payments,
            onRecordNewPayment = { navController.navigate(Screen.RecordPayment.route) },
            onNavigateBack = { navController.popBackStack() }
        )
    }

    composable(Screen.RecordPayment.route) {
        RecordPaymentScreen(
            members = members,
            onConfirmSave = { newPayment ->
                FirestoreWriteManager.recordPayment(newPayment)
                scope.launch {
                    notificationRepo.addNotification(
                        NotificationItem(
                            id = "notif-${System.currentTimeMillis()}",
                            title = "চাঁদা জমা নিশ্চিতকরণ",
                            message = "${newPayment.memberName}-এর ৳${CurrencyFormatter.formatBDT(newPayment.amount)} চাঁদা সফলভাবে জমা হয়েছে।",
                            type = NotificationType.PAYMENT_RECEIVED,
                            targetRoute = Screen.Contributions.route
                        )
                    )
                }
                navController.popBackStack()
            },
            onNavigateBack = { navController.popBackStack() }
        )
    }

    composable(Screen.Defaulters.route) {
        DefaulterListScreen(
            defaulters = members.filter { it.outstandingDues > 0 },
            onNavigateBack = { navController.popBackStack() }
        )
    }

    composable(Screen.Expenses.route) {
        ExpenseListScreen(
            expenses = expenses,
            onAddExpenseClick = { navController.navigate(Screen.AddExpense.route) },
            onNavigateBack = { navController.popBackStack() }
        )
    }

    composable(Screen.AddExpense.route) {
        AddExpenseScreen(
            onSaveExpense = { newExpense ->
                FirestoreWriteManager.recordExpense(newExpense)
                navController.popBackStack()
            },
            onNavigateBack = { navController.popBackStack() }
        )
    }

    composable(Screen.Loans.route) {
        LoanListScreen(
            loans = loans,
            onIssueLoanClick = { navController.navigate(Screen.IssueLoan.route) },
            onRepayInstallment = { loanId, amount, method ->
                ShomitiDataManager.repayLoanInstallment(loanId, amount, method)
            },
            onNavigateBack = { navController.popBackStack() }
        )
    }

    composable(Screen.IssueLoan.route) {
        IssueLoanScreen(
            members = members,
            onDisburseLoan = { newLoan ->
                FirestoreWriteManager.disburseLoan(newLoan)
                navController.popBackStack()
            },
            onNavigateBack = { navController.popBackStack() }
        )
    }
}
