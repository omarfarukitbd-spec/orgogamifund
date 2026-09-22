package com.helptrickbd.myapplicationsomithierp

import com.helptrickbd.myapplicationsomithierp.core.util.AmountInWordsConverter
import com.helptrickbd.myapplicationsomithierp.core.util.CurrencyFormatter
import org.junit.Assert.assertEquals
import org.junit.Test

class CurrencyFormatterTest {

    @Test
    fun testIndianCommaGrouping() {
        assertEquals("500", CurrencyFormatter.formatIndianGrouping(500))
        assertEquals("1,500", CurrencyFormatter.formatIndianGrouping(1500))
        assertEquals("85,000", CurrencyFormatter.formatIndianGrouping(85000))
        assertEquals("3,50,000", CurrencyFormatter.formatIndianGrouping(350000))
        assertEquals("12,50,000", CurrencyFormatter.formatIndianGrouping(1250000))
        assertEquals("1,25,00,000", CurrencyFormatter.formatIndianGrouping(12500000))
        assertEquals("12,50,00,000", CurrencyFormatter.formatIndianGrouping(125000000))
    }

    @Test
    fun testAmountInBengaliWords() {
        assertEquals("পাঁচশত টাকা মাত্র", AmountInWordsConverter.convertToBengaliWords(500.0))
        assertEquals("এক হাজার পাঁচশত টাকা মাত্র", AmountInWordsConverter.convertToBengaliWords(1500.0))
        assertEquals("পঁচিশ হাজার টাকা মাত্র", AmountInWordsConverter.convertToBengaliWords(25000.0))
        assertEquals("বারো লক্ষ পঞ্চাশ হাজার টাকা মাত্র", AmountInWordsConverter.convertToBengaliWords(1250000.0))
        assertEquals("এক কোটি পঁচিশ লক্ষ টাকা মাত্র", AmountInWordsConverter.convertToBengaliWords(12500000.0))
    }

    @Test
    fun testAmountInEnglishWords() {
        assertEquals("Five Hundred Taka Only", AmountInWordsConverter.convertToEnglishWords(500.0))
        assertEquals("One Thousand Five Hundred Taka Only", AmountInWordsConverter.convertToEnglishWords(1500.0))
        assertEquals("Twenty Five Thousand Taka Only", AmountInWordsConverter.convertToEnglishWords(25000.0))
        assertEquals("Twelve Lakh Fifty Thousand Taka Only", AmountInWordsConverter.convertToEnglishWords(1250000.0))
        assertEquals("One Crore Twenty Five Lakh Taka Only", AmountInWordsConverter.convertToEnglishWords(12500000.0))
    }
}
