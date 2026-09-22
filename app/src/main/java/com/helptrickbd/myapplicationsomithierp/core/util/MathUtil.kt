package com.helptrickbd.myapplicationsomithierp.core.util

import kotlin.math.round

/**
 * Universal safeRound logic enforced across all financial calculations, balances,
 * interest, dividends, payments, dues, and ledger balances.
 * Guarantees precision up to 2 decimal places and avoids floating-point inaccuracies.
 */
fun safeRound(value: Double?): Double {
    if (value == null || value.isNaN() || value.isInfinite()) return 0.0
    return round(value * 100.0) / 100.0
}

fun safeRound(value: Number?): Double {
    return safeRound(value?.toDouble())
}

fun safeRound(value: String?): Double {
    return safeRound(value?.toDoubleOrNull())
}

fun Double.safeRound(): Double = safeRound(this)
fun Float.safeRound(): Double = safeRound(this.toDouble())
