package com.helptrickbd.myapplicationsomithierp.core.util

import kotlin.math.roundToLong

/**
 * Universal converter for formatting monetary amounts into written words
 * in both Bengali (বাংলা) and English.
 * Strictly enforces `safeRound` before any conversion.
 */
object AmountInWordsConverter {

    private val banglaUnits = arrayOf(
        "", "এক", "দুই", "তিন", "চার", "পাঁচ", "ছয়", "সাত", "আট", "নয়", "দশ",
        "এগারো", "বারো", "তেরো", "চৌদ্দ", "পনেরো", "ষোল", "সতেরো", "আঠারো", "উনিশ", "বিশ",
        "একুশ", "বাইশ", "তেইশ", "চব্বিশ", "পঁচিশ", "ছাব্বিশ", "সাতাশ", "আঠাশ", "ঊনত্রিশ", "ত্রিশ",
        "একত্রিশ", "বত্রিশ", "তেত্রিশ", "চৌত্রিশ", "পঁয়ত্রিশ", "ছত্রিশ", "সাঁইত্রিশ", "আটত্রিশ", "ঊনচল্লিশ", "চল্লিশ",
        "একচল্লিশ", "বিয়াল্লিশ", "তেতাল্লিশ", "চুয়াল্লিশ", "পঁয়তাল্লিশ", "ছেচল্লিশ", "সাতচল্লিশ", "আটচল্লিশ", "ঊনপঞ্চাশ", "পঞ্চাশ",
        "একান্ন", "বায়ান্ন", "তিপ্পান্ন", "চুয়ান্ন", "পঞ্চান্ন", "ছাপ্পান্ন", "সাতান্ন", "আটান্ন", "ঊনষাট", "ষাট",
        "একষট্টি", "বাষট্টি", "তেষট্টি", "চৌষট্টি", "পঁয়ষট্টি", "ছেষট্টি", "সাতষট্টি", "আটষট্টি", "ঊনসত্তর", "সত্তর",
        "একাত্তর", "বাহাত্তর", "তিয়াত্তর", "চৌহাত্তর", "পঁচাত্তর", "ছিয়াত্তর", "সাতাত্তর", "আটাত্তর", "ঊনআশি", "আশি",
        "একাশি", "বিরাশি", "তিরাশি", "চুরাশি", "পঁচাশি", "ছিয়াশি", "সাতাশি", "অষ্টআশি", "ঊননব্বই", "নব্বই",
        "একানব্বই", "বিরানব্বই", "তিরানব্বই", "চুরানব্বই", "পঁচানব্বই", "ছিয়ানব্বই", "সাতানব্বই", "আটানব্বই", "নিরানব্বই"
    )

    private val englishUnits = arrayOf(
        "", "One", "Two", "Three", "Four", "Five", "Six", "Seven", "Eight", "Nine", "Ten",
        "Eleven", "Twelve", "Thirteen", "Fourteen", "Fifteen", "Sixteen", "Seventeen", "Eighteen", "Nineteen"
    )

    private val englishTens = arrayOf(
        "", "", "Twenty", "Thirty", "Forty", "Fifty", "Sixty", "Seventy", "Eighty", "Ninety"
    )

    /**
     * Converts a rounded amount into Bengali words.
     * e.g., 1250000.0 -> "বারো লক্ষ পঞ্চাশ হাজার টাকা মাত্র"
     */
    fun convertToBengaliWords(amount: Double): String {
        val rounded = safeRound(amount)
        if (rounded <= 0.0) return "শূন্য টাকা মাত্র"

        val wholePart = rounded.toLong()
        val paisaPart = ((rounded - wholePart) * 100).roundToLong()

        val sb = StringBuilder()
        var remaining = wholePart

        // 1. Crores (কোটি) - multiples of 1,00,00,000
        val crore = remaining / 10000000L
        if (crore > 0) {
            sb.append(convertBengaliChunk(crore)).append(" কোটি ")
            remaining %= 10000000L
        }

        // 2. Lakhs (লক্ষ) - multiples of 1,00,000
        val lakh = remaining / 100000L
        if (lakh > 0) {
            sb.append(convertBengaliChunk(lakh)).append(" লক্ষ ")
            remaining %= 100000L
        }

        // 3. Thousands (হাজার) - multiples of 1,000
        val thousand = remaining / 1000L
        if (thousand > 0) {
            sb.append(convertBengaliChunk(thousand)).append(" হাজার ")
            remaining %= 1000L
        }

        // 4. Hundreds (শত) - multiples of 100
        val hundred = remaining / 100L
        if (hundred > 0) {
            val hText = when (hundred) {
                1L -> "একশত"
                2L -> "দুইশত"
                3L -> "তিনশত"
                4L -> "চারশত"
                5L -> "পাঁচশত"
                6L -> "ছয়শত"
                7L -> "সাতশত"
                8L -> "আটশত"
                9L -> "নয়শত"
                else -> "${convertBengaliChunk(hundred)}শত"
            }
            sb.append(hText).append(" ")
            remaining %= 100L
        }

        // 5. Remaining (1 - 99)
        if (remaining > 0) {
            sb.append(convertBengaliChunk(remaining)).append(" ")
        }

        var result = sb.toString().trim()
        if (result.isNotEmpty()) {
            result += " টাকা"
        }

        if (paisaPart > 0) {
            val paisaText = convertBengaliChunk(paisaPart)
            result = if (result.isNotEmpty()) "$result $paisaText পয়সা মাত্র" else "$paisaText পয়সা মাত্র"
        } else {
            result += " মাত্র"
        }

        return result
    }

    private fun convertBengaliChunk(number: Long): String {
        if (number <= 0) return ""
        if (number < 100) {
            return banglaUnits.getOrNull(number.toInt()) ?: number.toString()
        }
        // If chunk is >= 100 (e.g. for > 99 crore), recursively format
        val hundred = number / 100
        val rem = number % 100
        val hundredText = (banglaUnits.getOrNull(hundred.toInt()) ?: hundred.toString()) + " শত"
        return if (rem > 0) "$hundredText ${banglaUnits.getOrNull(rem.toInt()) ?: rem.toString()}" else hundredText
    }

    /**
     * Converts a rounded amount into English words (using Indian/South Asian scale: Lakh, Crore).
     * e.g., 1250000.0 -> "Twelve Lakh Fifty Thousand Taka Only"
     */
    fun convertToEnglishWords(amount: Double): String {
        val rounded = safeRound(amount)
        if (rounded <= 0.0) return "Zero Taka Only"

        val wholePart = rounded.toLong()
        val paisaPart = ((rounded - wholePart) * 100).roundToLong()

        val sb = StringBuilder()
        var remaining = wholePart

        // 1. Crores - multiples of 1,00,00,000
        val crore = remaining / 10000000L
        if (crore > 0) {
            sb.append(convertEnglishChunk(crore)).append(" Crore ")
            remaining %= 10000000L
        }

        // 2. Lakhs - multiples of 1,00,000
        val lakh = remaining / 100000L
        if (lakh > 0) {
            sb.append(convertEnglishChunk(lakh)).append(" Lakh ")
            remaining %= 100000L
        }

        // 3. Thousands - multiples of 1,000
        val thousand = remaining / 1000L
        if (thousand > 0) {
            sb.append(convertEnglishChunk(thousand)).append(" Thousand ")
            remaining %= 1000L
        }

        // 4. Hundreds - multiples of 100
        val hundred = remaining / 100L
        if (hundred > 0) {
            sb.append(convertEnglishChunk(hundred)).append(" Hundred ")
            remaining %= 100L
        }

        // 5. Remaining (1 - 99)
        if (remaining > 0) {
            sb.append(convertEnglishChunk(remaining)).append(" ")
        }

        var result = sb.toString().trim()
        if (result.isNotEmpty()) {
            result += " Taka"
        }

        if (paisaPart > 0) {
            val paisaText = convertEnglishChunk(paisaPart)
            result = if (result.isNotEmpty()) "$result and $paisaText Paisa Only" else "$paisaText Paisa Only"
        } else {
            result += " Only"
        }

        return result
    }

    private fun convertEnglishChunk(number: Long): String {
        if (number <= 0) return ""
        if (number < 20) {
            return englishUnits[number.toInt()]
        }
        if (number < 100) {
            val ten = (number / 10).toInt()
            val unit = (number % 10).toInt()
            return if (unit > 0) "${englishTens[ten]} ${englishUnits[unit]}" else englishTens[ten]
        }
        val hundred = (number / 100).toInt()
        val rem = number % 100
        val hundredText = "${englishUnits[hundred]} Hundred"
        return if (rem > 0) "$hundredText and ${convertEnglishChunk(rem)}" else hundredText
    }
}
