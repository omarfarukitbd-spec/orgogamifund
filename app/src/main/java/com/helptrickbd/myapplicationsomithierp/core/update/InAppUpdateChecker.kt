package com.helptrickbd.myapplicationsomithierp.core.update

import android.content.Context
import android.content.Intent
import androidx.core.net.toUri

data class AppUpdateInfo(
    val latestVersionCode: Int = 2,
    val latestVersionName: String = "1.1.0",
    val releaseNotes: String = "নতুন ফিচার: নোটিশ বোর্ড, কমিটি ডিরেক্টরি এবং পূর্ণ ডাটা ব্যাকআপ সুবিধা।",
    val downloadUrl: String = "https://github.com/helptrickbd/somithierp/releases/latest",
    val isMandatory: Boolean = false
)

class InAppUpdateChecker(private val context: Context) {

    // Current app version code
    val currentVersionCode: Int = 1
    val currentVersionName: String = "1.0.0"

    fun checkForUpdate(onResult: (AppUpdateInfo?, Boolean) -> Unit) {
        // In production, fetch remote config or Firestore /version doc
        // Here we simulate checking against the hosted latest info:
        val mockLatestInfo = AppUpdateInfo(
            latestVersionCode = 2,
            latestVersionName = "1.1.0",
            releaseNotes = "• নোটিশ বোর্ড ও সভার কার্যবিবরণী সংযোজন\n• কমিটি পরিচালনা পর্ষদ যুক্তকরণ\n• দ্রুত লেনদেন ও রসিদ প্রিন্ট অপ্টিমাইজেশন",
            downloadUrl = "https://github.com/helptrickbd/somithierp/releases/latest",
            isMandatory = false
        )

        val hasNewVersion = mockLatestInfo.latestVersionCode > currentVersionCode
        onResult(mockLatestInfo, hasNewVersion)
    }

    fun openDownloadUrl(downloadUrl: String) {
        val intent = Intent(Intent.ACTION_VIEW, downloadUrl.toUri()).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        context.startActivity(intent)
    }
}
