//
//  TariffEngine.swift
//  TariffTimeBlockApp
//
//  Created by David Mišmaš on 20. 1. 26.
//

import Foundation

final class TariffEngine {

    private let calendar: Calendar

    init(calendar: Calendar = .current) {
        self.calendar = calendar
    }

    func status(for date: Date) -> TariffStatus {
        let season = TariffSeason.from(date: date, calendar: calendar)
        let dayType = dayType(for: date)

        let slots = scheduleSlots(for: season, dayType: dayType)
        let minuteOfDay = minutesSinceMidnight(date)

        guard let currentIndex = slots.firstIndex(where: { $0.interval.contains(minuteOfDay: minuteOfDay) }) else {
            // Če schedule kdaj ne pokrije dneva (ne bi smelo), fail-safe:
            let safeIndex = 0
            let next = nextFrom(slots: slots, currentIndex: safeIndex, date: date)
            return TariffStatus(
                date: date,
                season: season,
                dayType: dayType,
                daySlots: slots,
                currentIndex: safeIndex,
                nextIndex: next.index,
                nextChangeDate: next.changeDate
            )
        }

        let next = nextFrom(slots: slots, currentIndex: currentIndex, date: date)

        return TariffStatus(
            date: date,
            season: season,
            dayType: dayType,
            daySlots: slots,
            currentIndex: currentIndex,
            nextIndex: next.index,
            nextChangeDate: next.changeDate
        )
    }

    // MARK: - Day type (weekend + holidays)

    private func dayType(for date: Date) -> DayType {
        let weekday = calendar.component(.weekday, from: date) // 1=Sun ... 7=Sat
        let weekend = (weekday == 1 || weekday == 7)
        if weekend { return .offday }

        if SloveniaHolidays.isHoliday(date, calendar: calendar) {
            return .offday
        }

        return .workday
    }

    // MARK: - Schedules (from your table)

    private func scheduleSlots(for season: TariffSeason, dayType: DayType) -> [TariffSlot] {
        // Intervali:
        // 00–06, 06–07, 07–14, 14–16, 16–20, 20–22, 22–24
        let i00_06 = TimeIntervalMinutes(start: 0, end: 360)
        let i06_07 = TimeIntervalMinutes(start: 360, end: 420)
        let i07_14 = TimeIntervalMinutes(start: 420, end: 840)
        let i14_16 = TimeIntervalMinutes(start: 840, end: 960)
        let i16_20 = TimeIntervalMinutes(start: 960, end: 1200)
        let i20_22 = TimeIntervalMinutes(start: 1200, end: 1320)
        let i22_24 = TimeIntervalMinutes(start: 1320, end: 1440)

        switch (season, dayType) {

        // Višja sezona — Delovni dan:
        // 1: 07–14, 16–20
        // 2: 06–07, 14–16, 20–22
        // 3: 00–06, 22–24
        case (.higher, .workday):
            return [
                .init(interval: i00_06, level: .l3),
                .init(interval: i06_07, level: .l2),
                .init(interval: i07_14, level: .l1),
                .init(interval: i14_16, level: .l2),
                .init(interval: i16_20, level: .l1),
                .init(interval: i20_22, level: .l2),
                .init(interval: i22_24, level: .l3)
            ]

        // Višja sezona — Dela prost dan:
        // 2: 07–14, 16–20
        // 3: 06–07, 14–16, 20–22
        // 4: 00–06, 22–24
        case (.higher, .offday):
            return [
                .init(interval: i00_06, level: .l4),
                .init(interval: i06_07, level: .l3),
                .init(interval: i07_14, level: .l2),
                .init(interval: i14_16, level: .l3),
                .init(interval: i16_20, level: .l2),
                .init(interval: i20_22, level: .l3),
                .init(interval: i22_24, level: .l4)
            ]

        // Nižja sezona — Delovni dan:
        // 2: 07–14, 16–20
        // 3: 06–07, 14–16, 20–22
        // 4: 00–06, 22–24
        case (.lower, .workday):
            return [
                .init(interval: i00_06, level: .l4),
                .init(interval: i06_07, level: .l3),
                .init(interval: i07_14, level: .l2),
                .init(interval: i14_16, level: .l3),
                .init(interval: i16_20, level: .l2),
                .init(interval: i20_22, level: .l3),
                .init(interval: i22_24, level: .l4)
            ]

        // Nižja sezona — Dela prost dan:
        // 3: 07–14, 16–20
        // 4: 06–07, 14–16, 20–22
        // 5: 00–06, 22–24
        case (.lower, .offday):
            return [
                .init(interval: i00_06, level: .l5),
                .init(interval: i06_07, level: .l4),
                .init(interval: i07_14, level: .l3),
                .init(interval: i14_16, level: .l4),
                .init(interval: i16_20, level: .l3),
                .init(interval: i20_22, level: .l4),
                .init(interval: i22_24, level: .l5)
            ]
        }
    }

    // MARK: - Next slot

    private func nextFrom(slots: [TariffSlot], currentIndex: Int, date: Date) -> (index: Int, changeDate: Date) {
        let current = slots[currentIndex]
        let changeDate = dateAtMinuteOfDay(current.interval.end, on: date)

        if currentIndex + 1 < slots.count {
            return (currentIndex + 1, changeDate)
        } else {
            // Zadnji interval dneva -> naslednji je prvi interval naslednjega dne.
            return (0, changeDate)
        }
    }

    // MARK: - Date helpers

    private func startOfDay(_ date: Date) -> Date {
        calendar.startOfDay(for: date)
    }

    private func minutesSinceMidnight(_ date: Date) -> Int {
        let comps = calendar.dateComponents([.hour, .minute], from: date)
        let h = comps.hour ?? 0
        let m = comps.minute ?? 0
        return h * 60 + m
    }

    private func dateAtMinuteOfDay(_ minute: Int, on date: Date) -> Date {
        let dayStart = startOfDay(date)
        let clamped = max(0, min(minute, 1440))
        return calendar.date(byAdding: .minute, value: clamped, to: dayStart) ?? date
    }
}
