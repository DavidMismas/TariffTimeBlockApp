//
//  SloveniaHolidays.swift
//  TariffTimeBlockApp
//
//  Created by David Mišmaš on 20. 1. 26.
//

import Foundation

/// Slovenija – osnovni prazniki.
/// Vključeno:
/// - fiksni datumi
/// - velikonočni ponedeljek (moveable)
///
/// Če želiš kasneje 100% pokritost (npr. kakšna enkratna sprememba, posebni dela-prosti dnevi),
/// dodamo še ročno tabelo po letih. Za normalen utility app je to dovolj.
struct SloveniaHolidays {

    static func isHoliday(_ date: Date, calendar: Calendar = .current) -> Bool {
        let day = calendar.startOfDay(for: date)

        // Fiksni prazniki (mesec, dan)
        let fixed: Set<FixedMD> = [
            .init(m: 1, d: 1),  // novo leto
            .init(m: 1, d: 2),  // novo leto
            .init(m: 2, d: 8),  // Prešernov dan
            .init(m: 4, d: 27), // dan upora
            .init(m: 5, d: 1),  // praznik dela
            .init(m: 5, d: 2),  // praznik dela
            .init(m: 6, d: 25), // dan državnosti
            .init(m: 8, d: 15), // Marijino vnebovzetje
            .init(m: 10, d: 31),// dan reformacije
            .init(m: 11, d: 1), // dan spomina na mrtve
            .init(m: 12, d: 25),// božič
            .init(m: 12, d: 26) // dan samostojnosti in enotnosti
        ]

        let comps = calendar.dateComponents([.month, .day, .year], from: day)
        if let m = comps.month, let d = comps.day {
            if fixed.contains(.init(m: m, d: d)) { return true }
        }

        // Velikonočni ponedeljek
        if let y = comps.year {
            let easterSunday = westernEasterSunday(year: y, calendar: calendar)
            let easterMonday = calendar.date(byAdding: .day, value: 1, to: easterSunday)!
            if calendar.isDate(day, inSameDayAs: easterMonday) { return true }
        }

        return false
    }

    // MARK: - Helpers

    private struct FixedMD: Hashable {
        let m: Int
        let d: Int
    }

    /// Meeus/Jones/Butcher (Gregorian) – zanesljivo za večino let, ki nas zanimajo.
    private static func westernEasterSunday(year: Int, calendar: Calendar) -> Date {
        let a = year % 19
        let b = year / 100
        let c = year % 100
        let d = b / 4
        let e = b % 4
        let f = (b + 8) / 25
        let g = (b - f + 1) / 3
        let h = (19 * a + b - d - g + 15) % 30
        let i = c / 4
        let k = c % 4
        let l = (32 + 2 * e + 2 * i - h - k) % 7
        let m = (a + 11 * h + 22 * l) / 451
        let month = (h + l - 7 * m + 114) / 31   // 3=March, 4=April
        let day = ((h + l - 7 * m + 114) % 31) + 1

        var comps = DateComponents()
        comps.year = year
        comps.month = month
        comps.day = day
        comps.hour = 0
        comps.minute = 0
        comps.second = 0

        return calendar.date(from: comps) ?? .distantPast
    }
}

