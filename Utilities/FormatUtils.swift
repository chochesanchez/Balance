import Foundation

// MARK: - Currency & Date Formatting Utilities
// Shared formatting helpers used across the app.

/// Formats an amount as a currency string for the given currency code.
func formatCurrency(_ amount: Double, currency: String = "USD") -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .currency
    formatter.currencyCode = currency
    return formatter.string(from: NSNumber(value: amount)) ?? "$0.00"
}

/// Formats an amount as a compact currency string (no fractional digits).
func formatCompactAmount(_ amount: Double, currency: String = "USD") -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .currency
    formatter.currencyCode = currency
    formatter.maximumFractionDigits = 0
    return formatter.string(from: NSNumber(value: amount)) ?? "$0"
}

/// Formats a signed amount, prepending "+" for positive values.
func formatSignedCurrency(_ amount: Double, currency: String = "USD") -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .currency
    formatter.currencyCode = currency
    let formatted = formatter.string(from: NSNumber(value: abs(amount))) ?? "$0.00"
    return amount >= 0 ? "+\(formatted)" : "-\(formatted)"
}

/// Formats a date as a short time string (e.g. "3:45 PM").
func formatTime(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.timeStyle = .short
    return formatter.string(from: date)
}
