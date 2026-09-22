package com.helptrickbd.myapplicationsomithierp.presentation.navigation

import androidx.navigation.NavGraphBuilder
import androidx.navigation.NavHostController
import androidx.navigation.compose.composable
import com.helptrickbd.myapplicationsomithierp.core.datastore.AppThemeMode
import com.helptrickbd.myapplicationsomithierp.core.datastore.UserPreferences
import com.helptrickbd.myapplicationsomithierp.core.datastore.UserPreferencesRepository
import com.helptrickbd.myapplicationsomithierp.domain.model.ApprovalStatus
import com.helptrickbd.myapplicationsomithierp.domain.model.User
import com.helptrickbd.myapplicationsomithierp.presentation.screens.auth.LoginScreen
import com.helptrickbd.myapplicationsomithierp.presentation.screens.auth.PendingApprovalScreen
import com.helptrickbd.myapplicationsomithierp.presentation.screens.onboarding.OnboardingScreen
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.launch
import kotlinx.coroutines.tasks.await

fun NavGraphBuilder.addAuthNavRoutes(
    navController: NavHostController,
    preferences: UserPreferences?,
    preferencesRepo: UserPreferencesRepository,
    scope: CoroutineScope,
    currentUser: User?,
    isRootSuperAdmin: Boolean
) {
    composable(Screen.Onboarding.route) {
        OnboardingScreen(
            currentLanguage = preferences?.language?.code ?: "bn",
            onLanguageChange = { langCode ->
                scope.launch {
                    preferencesRepo.setLanguage(
                        if (langCode == "en") com.helptrickbd.myapplicationsomithierp.core.datastore.AppLanguage.ENGLISH
                        else com.helptrickbd.myapplicationsomithierp.core.datastore.AppLanguage.BANGLA
                    )
                }
            },
            currentThemeMode = preferences?.themeMode ?: AppThemeMode.SYSTEM,
            onThemeModeChange = { mode ->
                scope.launch {
                    preferencesRepo.setThemeMode(mode)
                }
            },
            onFinish = {
                scope.launch {
                    preferencesRepo.setOnboardingCompleted(true)
                }
                val nextRoute = if (currentUser == null && com.google.firebase.auth.FirebaseAuth.getInstance().currentUser == null) {
                    Screen.Auth.route
                } else if (isRootSuperAdmin || currentUser?.approvalStatus == ApprovalStatus.APPROVED) {
                    Screen.Dashboard.route
                } else {
                    Screen.PendingApproval.route
                }
                navController.navigate(nextRoute) {
                    popUpTo(Screen.Onboarding.route) { inclusive = true }
                }
            }
        )
    }

    composable(Screen.Auth.route) {
        val context = androidx.compose.ui.platform.LocalContext.current
        val activity = context as? android.app.Activity
        var showExitDialog by remember { mutableStateOf(false) }

        androidx.activity.compose.BackHandler(enabled = true) {
            showExitDialog = true
        }

        if (showExitDialog) {
            com.helptrickbd.myapplicationsomithierp.presentation.components.ExitConfirmationDialog(
                onConfirm = {
                    showExitDialog = false
                    activity?.finish()
                },
                onDismiss = { showExitDialog = false }
            )
        }

        val authRepo = androidx.compose.runtime.remember { com.helptrickbd.myapplicationsomithierp.data.repository.AuthRepositoryImpl() }
        LoginScreen(
            onSignIn = { email, pass ->
                val cleanEmail = email.trim()
                scope.launch {
                    try {
                        authRepo.signInWithEmail(cleanEmail, pass)
                    } catch (e: Exception) {
                        e.printStackTrace()
                    }
                    val isSuperAdmin = isSuperAdminEmail(cleanEmail)
                    val targetRoute = if (isSuperAdmin) Screen.Dashboard.route else Screen.PendingApproval.route
                    navController.navigate(targetRoute) {
                        popUpTo(Screen.Auth.route) { inclusive = true }
                    }
                }
            },
            onSignUp = { email, pass ->
                val cleanEmail = email.trim()
                scope.launch {
                    try {
                        authRepo.signUpWithEmail(cleanEmail, pass)
                    } catch (e: Exception) {
                        e.printStackTrace()
                    }
                    val isSuperAdmin = isSuperAdminEmail(cleanEmail)
                    val targetRoute = if (isSuperAdmin) Screen.Dashboard.route else Screen.PendingApproval.route
                    navController.navigate(targetRoute) {
                        popUpTo(Screen.Auth.route) { inclusive = true }
                    }
                }
            },
            onGoogleAccountSelected = { account ->
                val email = account.email ?: ""
                val isSuper = isSuperAdminEmail(email)

                scope.launch {
                    val idToken = account.idToken
                    var finalUid = account.id ?: java.util.UUID.randomUUID().toString()
                    if (!idToken.isNullOrBlank()) {
                        try {
                            val credential = com.google.firebase.auth.GoogleAuthProvider.getCredential(idToken, null)
                            val authResult = com.google.firebase.auth.FirebaseAuth.getInstance().signInWithCredential(credential).await()
                            authResult.user?.uid?.let { finalUid = it }
                        } catch (e: Exception) {
                            e.printStackTrace()
                        }
                    }

                    authRepo.signInWithGoogleAccount(
                        uid = finalUid,
                        email = email,
                        displayName = account.displayName,
                        photoUrl = account.photoUrl?.toString()
                    )

                    val targetRoute = if (isSuper) Screen.Dashboard.route else Screen.PendingApproval.route
                    navController.navigate(targetRoute) {
                        popUpTo(Screen.Auth.route) { inclusive = true }
                    }
                }
            },
            onNavigateToMemberApplication = {
                navController.navigate(Screen.MemberApplication.route)
            }
        )
    }

    composable(Screen.PendingApproval.route) {
        val firebaseUser = com.google.firebase.auth.FirebaseAuth.getInstance().currentUser
        val currentEmail = currentUser?.email ?: firebaseUser?.email ?: "user@gmail.com"
        PendingApprovalScreen(
            userEmail = currentEmail,
            onCheckStatus = {
                val isSuper = isSuperAdminEmail(currentEmail)
                if (isSuper || currentUser?.approvalStatus == ApprovalStatus.APPROVED) {
                    navController.navigate(Screen.Dashboard.route) {
                        popUpTo(Screen.PendingApproval.route) { inclusive = true }
                    }
                } else if (firebaseUser != null) {
                    com.google.firebase.firestore.FirebaseFirestore.getInstance()
                        .collection("users").document(firebaseUser.uid).get()
                        .addOnSuccessListener { doc ->
                            val status = doc.getString("approvalStatus")
                            val role = doc.getString("role")
                            if (status.equals("approved", ignoreCase = true) ||
                                role.equals("superadmin", ignoreCase = true) ||
                                role.equals("admin", ignoreCase = true)) {
                                navController.navigate(Screen.Dashboard.route) {
                                    popUpTo(Screen.PendingApproval.route) { inclusive = true }
                                }
                            }
                        }
                }
            },
            onApplyForMembership = {
                navController.navigate(Screen.MemberApplication.route)
            },
            onSignOut = {
                com.google.firebase.auth.FirebaseAuth.getInstance().signOut()
                navController.navigate(Screen.Auth.route) {
                    popUpTo(Screen.PendingApproval.route) { inclusive = true }
                }
            }
        )
    }
}

internal fun isSuperAdminEmail(email: String?): Boolean {
    if (email.isNullOrBlank()) return false
    val clean = email.trim()
    return clean.equals("omarfaruktitbd@gmail.com", ignoreCase = true) ||
           clean.equals("omarfarukitbd@gmail.com", ignoreCase = true)
}
