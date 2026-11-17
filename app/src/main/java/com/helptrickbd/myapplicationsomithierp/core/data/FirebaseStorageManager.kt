package com.helptrickbd.myapplicationsomithierp.core.data

import android.net.Uri
import com.google.firebase.storage.FirebaseStorage

object FirebaseStorageManager {

    private val storage = FirebaseStorage.getInstance()

    /**
     * Uploads a member profile photo to Firebase Storage.
     * Path: members/{memberId}/profile.jpg
     * @param onComplete returns the download URL on success, null on failure.
     */
    fun uploadMemberPhoto(
        memberId: String,
        imageUri: Uri,
        onComplete: (downloadUrl: String?) -> Unit
    ) {
        val ref = storage.reference
            .child("members")
            .child(memberId)
            .child("profile.jpg")

        ref.putFile(imageUri)
            .addOnSuccessListener {
                ref.downloadUrl
                    .addOnSuccessListener { uri -> onComplete(uri.toString()) }
                    .addOnFailureListener { onComplete(null) }
            }
            .addOnFailureListener { onComplete(null) }
    }

    /**
     * Uploads a member NID photo to Firebase Storage.
     * Path: members/{memberId}/nid.jpg
     * @param onComplete returns the download URL on success, null on failure.
     */
    fun uploadNidPhoto(
        memberId: String,
        imageUri: Uri,
        onComplete: (downloadUrl: String?) -> Unit
    ) {
        val ref = storage.reference
            .child("members")
            .child(memberId)
            .child("nid.jpg")

        ref.putFile(imageUri)
            .addOnSuccessListener {
                ref.downloadUrl
                    .addOnSuccessListener { uri -> onComplete(uri.toString()) }
                    .addOnFailureListener { onComplete(null) }
            }
            .addOnFailureListener { onComplete(null) }
    }

    /**
     * Deletes all photos for a given member (called on member exit/deletion).
     */
    fun deleteMemberPhotos(memberId: String) {
        storage.reference.child("members").child(memberId).child("profile.jpg").delete()
        storage.reference.child("members").child(memberId).child("nid.jpg").delete()
    }
}
