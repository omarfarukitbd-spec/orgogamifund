package com.helptrickbd.myapplicationsomithierp.domain.repository

import com.helptrickbd.myapplicationsomithierp.core.util.Resource
import com.helptrickbd.myapplicationsomithierp.domain.model.Branch
import com.helptrickbd.myapplicationsomithierp.domain.model.Organization
import kotlinx.coroutines.flow.Flow

interface BranchRepository {
    fun getOrganizationFlow(): Flow<Resource<Organization>>
    suspend fun updateOrganizationBranding(name: String, logoUrl: String?): Resource<Unit>
    
    fun getBranchesFlow(): Flow<Resource<List<Branch>>>
    fun getBranchByIdFlow(branchId: String): Flow<Resource<Branch>>
    suspend fun createBranch(branch: Branch): Resource<String>
    suspend fun updateBranch(branch: Branch): Resource<Unit>
    suspend fun deleteBranch(branchId: String): Resource<Unit>
}
