package com.helptrickbd.myapplicationsomithierp.core.data

import com.google.firebase.firestore.FirebaseFirestore
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch

/**
 * Cloud Firestore Seeder (Cleaned - All dummy data removed).
 * Dummy data auto-seeding is permanently disabled per user instructions.
 */
object FirestoreDataSeeder {

    private val firestore = FirebaseFirestore.getInstance()
    private val scope = CoroutineScope(Dispatchers.IO)

    fun seedAllIfEmpty() {
        scope.launch {
            seedSuperAdminProfile()
        }
    }

    private fun seedSuperAdminProfile() {
        val superAdminEmails = listOf("omarfaruktitbd@gmail.com", "omarfarukitbd@gmail.com")
        for (email in superAdminEmails) {
            val userMap = hashMapOf(
                "email" to email,
                "displayName" to "মো: ওমর ফারুক (Super Admin)",
                "role" to "superAdmin",
                "approvalStatus" to "approved",
                "createdAt" to System.currentTimeMillis()
            )
            firestore.collection("users")
                .whereEqualTo("email", email)
                .get()
                .addOnSuccessListener { snapshot ->
                    if (snapshot.isEmpty) {
                        firestore.collection("users").add(userMap)
                    }
                }
        }
    }
}
