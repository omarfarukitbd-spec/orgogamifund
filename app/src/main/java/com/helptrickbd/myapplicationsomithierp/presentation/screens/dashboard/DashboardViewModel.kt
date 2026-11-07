package com.helptrickbd.myapplicationsomithierp.presentation.screens.dashboard

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.helptrickbd.myapplicationsomithierp.core.data.FirestoreDataManager
import com.helptrickbd.myapplicationsomithierp.core.data.FirestoreWriteManager
import com.helptrickbd.myapplicationsomithierp.core.util.safeRound
import com.helptrickbd.myapplicationsomithierp.domain.model.*
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch

class DashboardViewModel : ViewModel() {

    private val _uiState = MutableStateFlow(DashboardUiState())
    val uiState: StateFlow<DashboardUiState> = _uiState.asStateFlow()

    init {
        observeData()
    }

    private fun observeData() {
        viewModelScope.launch {
            combine(
                FirestoreDataManager.branches,
                FirestoreDataManager.selectedBranchId,
                FirestoreDataManager.payments,
                FirestoreDataManager.expenses
            ) { branches: List<Branch>, selBranchId: String, payments: List<Payment>, expenses: List<Expense> ->
                val activeBranchId = if (selBranchId.isNotBlank()) {
                    selBranchId
                } else {
                    branches.firstOrNull()?.id ?: ""
                }

                val activeBranch = branches.find { it.id == activeBranchId } ?: branches.firstOrNull()

                val branchPayments = payments.filter { it.branchId == activeBranchId && it.approvalStatus == ApprovalStatus.APPROVED }
                val branchExpenses = expenses.filter { it.branchId == activeBranchId }

                val monthCollection = branchPayments.sumOf { it.amount }.safeRound()
                val totalExp = branchExpenses.sumOf { it.amount }.safeRound()
                val totalBalance = activeBranch?.balance ?: 0.0
                val pendingApps = FirestoreDataManager.memberApplications.value.count { it.status == ApprovalStatus.PENDING }

                _uiState.update { current ->
                    current.copy(
                        branches = branches,
                        selectedBranchId = activeBranchId,
                        orgName = activeBranch?.name ?: current.orgName,
                        totalFundBalance = totalBalance,
                        thisMonthCollection = monthCollection,
                        totalExpenses = totalExp,
                        pendingApplicationsCount = pendingApps,
                        recentPayments = branchPayments.take(6)
                    )
                }
            }.collect()
        }
    }

    fun selectBranch(branchId: String) {
        FirestoreDataManager.selectBranch(branchId)
        _uiState.update { it.copy(selectedBranchId = branchId) }
    }

    fun addActivityPhoto(branchId: String, photoUrl: String, onComplete: (Boolean) -> Unit) {
        val branch = _uiState.value.branches.find { it.id == branchId } ?: return
        val updatedPhotos = branch.activityPhotos + photoUrl
        FirestoreWriteManager.updateBranchBranding(
            branchId = branchId,
            logoUrl = branch.logoUrl,
            bannerUrl = branch.bannerUrl,
            activityPhotos = updatedPhotos,
            onComplete = onComplete
        )
    }

    fun updateSomithiBranding(
        branchId: String,
        logoUrl: String,
        bannerUrl: String,
        onComplete: (Boolean) -> Unit
    ) {
        val branch = _uiState.value.branches.find { it.id == branchId } ?: return
        FirestoreWriteManager.updateBranchBranding(
            branchId = branchId,
            logoUrl = logoUrl,
            bannerUrl = bannerUrl,
            activityPhotos = branch.activityPhotos,
            onComplete = onComplete
        )
    }
}
