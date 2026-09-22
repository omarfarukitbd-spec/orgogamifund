package com.helptrickbd.myapplicationsomithierp.core.pdf

import android.app.Activity
import android.content.Context
import android.content.ContextWrapper
import android.content.Intent
import android.os.Bundle
import android.os.CancellationSignal
import android.os.ParcelFileDescriptor
import android.print.PageRange
import android.print.PrintAttributes
import android.print.PrintDocumentAdapter
import android.print.PrintDocumentInfo
import android.print.PrintManager
import android.util.Log
import android.widget.Toast
import androidx.core.content.FileProvider
import java.io.File
import java.io.FileInputStream
import java.io.FileOutputStream
import java.io.IOException

object PdfPrintHelper {
    private const val TAG = "PdfPrintHelper"

    /**
     * Recursively traverses context wrappers to find the base Activity.
     * Required because Android PrintManager throws IllegalStateException when
     * initialized with a non-Activity context (e.g. ConfigurationContext).
     */
    fun findActivity(context: Context): Activity? {
        var currentContext = context
        while (currentContext is ContextWrapper) {
            if (currentContext is Activity) return currentContext
            currentContext = currentContext.baseContext
        }
        return null
    }

    /**
     * Safely prints the given PDF file using PrintManager if an Activity is available.
     * If printing is unsupported or fails, gracefully falls back to opening the PDF
     * with an external PDF viewer or sharing it via FileProvider.
     */
    fun printOrSharePdf(
        context: Context,
        jobName: String,
        documentName: String,
        pdfFile: File
    ) {
        if (!pdfFile.exists()) {
            val isBangla = context.resources.configuration.locales[0].language == "bn"
            Toast.makeText(
                context,
                if (isBangla) "পিডিএফ ফাইলটি পাওয়া যায়নি" else "PDF file not found",
                Toast.LENGTH_SHORT
            ).show()
            return
        }

        val activity = findActivity(context)
        val printManager = if (activity != null) {
            activity.getSystemService(Context.PRINT_SERVICE) as? PrintManager
        } else {
            context.getSystemService(Context.PRINT_SERVICE) as? PrintManager
        }

        if (printManager != null && activity != null) {
            try {
                printManager.print(
                    jobName,
                    object : PrintDocumentAdapter() {
                        override fun onLayout(
                            oldAttributes: PrintAttributes?,
                            newAttributes: PrintAttributes?,
                            cancellationSignal: CancellationSignal?,
                            callback: LayoutResultCallback?,
                            extras: Bundle?
                        ) {
                            if (cancellationSignal?.isCanceled == true) {
                                callback?.onLayoutCancelled()
                                return
                            }
                            val info = PrintDocumentInfo.Builder(documentName)
                                .setContentType(PrintDocumentInfo.CONTENT_TYPE_DOCUMENT)
                                .setPageCount(PrintDocumentInfo.PAGE_COUNT_UNKNOWN)
                                .build()
                            callback?.onLayoutFinished(info, true)
                        }

                        override fun onWrite(
                            pages: Array<out PageRange>?,
                            destination: ParcelFileDescriptor?,
                            cancellationSignal: CancellationSignal?,
                            callback: WriteResultCallback?
                        ) {
                            var input: FileInputStream? = null
                            var output: FileOutputStream? = null
                            try {
                                input = FileInputStream(pdfFile)
                                output = FileOutputStream(destination?.fileDescriptor)
                                val buf = ByteArray(2048)
                                var bytesRead: Int
                                while (input.read(buf).also { bytesRead = it } > 0) {
                                    output.write(buf, 0, bytesRead)
                                }
                                callback?.onWriteFinished(arrayOf(PageRange.ALL_PAGES))
                            } catch (e: Exception) {
                                Log.e(TAG, "Failed writing PDF bytes", e)
                                callback?.onWriteFailed(e.localizedMessage)
                            } finally {
                                try {
                                    input?.close()
                                    output?.close()
                                } catch (_: IOException) {}
                            }
                        }
                    },
                    null
                )
                return
            } catch (e: Throwable) {
                Log.e(TAG, "PrintManager.print failed, attempting external viewer fallback", e)
            }
        }

        // Fallback: Open with installed PDF viewer
        openWithExternalViewer(context, pdfFile)
    }

    /**
     * Opens the generated PDF with an external viewer or launches a share sheet.
     */
    fun openWithExternalViewer(context: Context, pdfFile: File) {
        val isBangla = context.resources.configuration.locales[0].language == "bn"
        try {
            val uri = FileProvider.getUriForFile(
                context,
                "${context.packageName}.fileprovider",
                pdfFile
            )
            val intent = Intent(Intent.ACTION_VIEW).apply {
                setDataAndType(uri, "application/pdf")
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            context.startActivity(intent)
        } catch (e: Exception) {
            Log.e(TAG, "Direct PDF viewer launch failed, opening share sheet", e)
            try {
                val uri = FileProvider.getUriForFile(
                    context,
                    "${context.packageName}.fileprovider",
                    pdfFile
                )
                val shareIntent = Intent(Intent.ACTION_SEND).apply {
                    type = "application/pdf"
                    putExtra(Intent.EXTRA_STREAM, uri)
                    addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                }
                val chooserTitle = if (isBangla) "ডকুমেন্ট শেয়ার বা প্রিন্ট করুন" else "Share or Print Document"
                context.startActivity(Intent.createChooser(shareIntent, chooserTitle))
            } catch (ex: Exception) {
                Log.e(TAG, "All PDF fallback attempts failed", ex)
                Toast.makeText(
                    context,
                    if (isBangla) "পিডিএফ ওপেন করা সম্ভব হয়নি" else "Could not open PDF viewer",
                    Toast.LENGTH_SHORT
                ).show()
            }
        }
    }
}
