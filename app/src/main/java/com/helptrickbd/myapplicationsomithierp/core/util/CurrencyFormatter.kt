package com.helptrickbd.myapplicationsomithierp.core.util

import kotlin.math.abs
import kotlin.math.roundToLong

object CurrencyFormatter {

    private val banglaDigits = mapOf(
        '0' to '০', '1' to '১', '2' to '২', '3' to '৩', '4' to '৪',
        '5' to '৫', '6' to '৬', '7' to '৭', '8' to '৮', '9' to '৯'
    )

    /**
     * Formats an amount using the Indian/South Asian grouping system:
     * - Last 3 digits (Hundreds)
     * - Next 2 digits (Thousands / হাজার)
     * - Next 2 digits (Lakh / লক্ষ)
     * - Next 2 digits (Crore / কোটি)
     * Examples:
     * 1500 -> "1,500" (১,৫০০)
     * 85000 -> "85,000" (৮৫,০০০)
     * 350000 -> "3,50,000" (৩,৫০,০০০)
     * 1250000 -> "12,50,000" (১২,৫০,০০০)
     * 12500000 -> "1,25,00,000" (১,২৫,০০,০০০)
     */
    fun formatBDT(amount: Double, showDecimals: Boolean = false, toBanglaDigits: Boolean = false): String {
        val roundedAmount = safeRound(amount)
        val isNegative = roundedAmount < 0
        val absAmount = abs(roundedAmount)

        val wholePart = absAmount.toLong()
        val decimalPart = ((absAmount - wholePart) * 100).roundToLong()

        val formattedWhole = formatIndianGrouping(wholePart)
        val formattedNumber = if (showDecimals) {
            String.format("%s.%02d", formattedWhole, decimalPart)
        } else {
            formattedWhole
        }

        val prefix = if (isNegative) "-৳ " else "৳ "
        val result = "$prefix$formattedNumber"

        return if (toBanglaDigits) {
            convertToBanglaDigits(result)
        } else {
            result
        }
    }

    fun formatBDT(amount: Long, toBanglaDigits: Boolean = false): String {
        return formatBDT(amount.toDouble(), showDecimals = false, toBanglaDigits = toBanglaDigits)
    }

    /**
     * Formats an integer using South Asian comma placement:
     * Comma after Thousand (হাজার), Lakh (লক্ষ), and Crore (কোটি).
     */
    fun formatIndianGrouping(value: Long): String {
        val s = value.toString()
        if (s.length <= 3) return s

        val last3 = s.takeLast(3)
        val remaining = s.dropLast(3)

        val sb = StringBuilder()
        var count = 0
        for (i in remaining.length - 1 downTo 0) {
            sb.append(remaining[i])
            count++
            if (count == 2 && i != 0) {
                sb.append(',')
                count = 0
            }
        }
        return sb.reverse().toString() + "," + last3
    }

    /**
     * Converts an amount into written words (কথায় প্রকাশ)
     */
    fun formatInWords(amount: Double, isBangla: Boolean = true): String {
        return if (isBangla) {
            AmountInWordsConverter.convertToBengaliWords(amount)
        } else {
            AmountInWordsConverter.convertToEnglishWords(amount)
        }
    }

    fun convertToBanglaDigits(input: String): String {
        val sb = StringBuilder()
        for (char in input) {
            sb.append(banglaDigits[char] ?: char)
        }
        return sb.toString()
    }
}
