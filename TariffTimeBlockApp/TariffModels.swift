//
//  TariffModels.swift
//  TariffTimeBlockApp
//
//  Created by David Mišmaš on 20. 1. 26.
//

import Foundation
import SwiftUI

enum TariffClock {
    static let timeZone = TimeZone(identifier: "Europe/Ljubljana")!

    static var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "sl_SI")
        calendar.timeZone = timeZone
        return calendar
    }
}

extension Date {
    func tariffFormatted(dateStyle: DateFormatter.Style, timeStyle: DateFormatter.Style) -> String {
        let formatter = DateFormatter()
        formatter.locale = .autoupdatingCurrent
        formatter.timeZone = TariffClock.timeZone
        formatter.dateStyle = dateStyle
        formatter.timeStyle = timeStyle
        return formatter.string(from: self)
    }
}

enum TariffSeason: String, CaseIterable {
    case higher
    case lower

    var title: String {
        switch self {
        case .higher: return "Višja sezona"
        case .lower:  return "Nižja sezona"
        }
    }

    static func from(date: Date, calendar: Calendar = TariffClock.calendar) -> TariffSeason {
        let month = calendar.component(.month, from: date)
        // Višja: november, december, januar, februar
        switch month {
        case 11, 12, 1, 2: return .higher
        default: return .lower
        }
    }
}

enum DayType: String, CaseIterable {
    case workday
    case offday

    var title: String {
        switch self {
        case .workday: return "Delovni dan"
        case .offday:  return "Dela prost dan"
        }
    }
}

/// Številka reguliranega časovnega bloka. Ni neposredna cena energije.
enum TariffLevel: Int, CaseIterable {
    case l1 = 1, l2, l3, l4, l5

    var displayTitle: String { "BLOK \(rawValue)" }

    var subtitle: String {
        switch self {
        case .l1: return "najvišja obremenitev"
        case .l2: return "visoka obremenitev"
        case .l3: return "srednja obremenitev"
        case .l4: return "nižja obremenitev"
        case .l5: return "najnižja obremenitev"
        }
    }

    var color: Color {
        // Barve vezane na realno stopnjo (1 rdeče -> 5 zeleno)
        switch self {
        case .l1: return .red
        case .l2: return .orange
        case .l3: return .yellow
        case .l4: return .green.opacity(0.45)
        case .l5: return .green
        }
    }

    var textColor: Color {
        switch self {
        case .l3, .l4: return .black
        default: return .white
        }
    }
}

struct TimeIntervalMinutes: Equatable {
    /// minutes since midnight, inclusive
    let start: Int
    /// minutes since midnight, exclusive (can be 1440)
    let end: Int

    func contains(minuteOfDay: Int) -> Bool {
        minuteOfDay >= start && minuteOfDay < end
    }

    var display: String {
        "\(Self.hhmm(start)) – \(Self.hhmm(end))"
    }

    static func hhmm(_ minutes: Int) -> String {
        let m = max(0, min(minutes, 1440))
        if m == 1440 { return "24:00" }
        let h = m / 60
        let mm = m % 60
        return String(format: "%02d:%02d", h, mm)
    }
}

struct TariffSlot: Equatable, Identifiable {
    let id = UUID()
    let interval: TimeIntervalMinutes
    let level: TariffLevel
}

struct TariffStatus: Equatable {
    let date: Date
    let season: TariffSeason
    let dayType: DayType

    let daySlots: [TariffSlot]
    let currentIndex: Int

    let nextSlot: TariffSlot
    let nextChangeDate: Date

    var currentSlot: TariffSlot { daySlots[currentIndex] }

    var secondsToNextChange: Int {
        max(0, Int(nextChangeDate.timeIntervalSince(date)))
    }
}
