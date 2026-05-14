import Foundation
import os

enum Log {
    private static let subsystem = "com.chochesanchez.Balanced"
    static let app      = Logger(subsystem: subsystem, category: "app")
    static let sync     = Logger(subsystem: subsystem, category: "sync")
    static let finance  = Logger(subsystem: subsystem, category: "finance")
    static let intents  = Logger(subsystem: subsystem, category: "intents")
    static let plus     = Logger(subsystem: subsystem, category: "plus")
}
