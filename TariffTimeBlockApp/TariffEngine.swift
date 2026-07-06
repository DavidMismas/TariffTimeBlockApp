//
//  TariffEngine.swift
//  TariffTimeBlockApp
//
//  Created by David Mišmaš on 20. 1. 26.
//

import Foundation

final class TariffEngine {

    private enum ScheduleVersion {
        case through2026
        case from2027

        static func from(date: Date, calendar: Calendar) -> ScheduleVersion {
            calendar.component(.year, from: date) >= 2027 ? .from2027 : .through2026
        }
    }

    private let calendar: Calendar

    init() {
        self.calendar = TariffClock.calendar
    }

    func status(for date: Date) -> TariffStatus {
        let season = TariffSeason.from(date: date, calendar: calendar)
        let dayType = dayType(for: date)
        let slots = scheduleSlots(for: date, season: season, dayType: dayType)
        let minuteOfDay = minutesSinceMidnight(date)

        guard let currentIndex = slots.firstIndex(where: { $0.interval.contains(minuteOfDay: minuteOfDay) }) else {
            preconditionFailure("Tarifni urnik ne pokrije celotnega dneva.")
        }

        let currentSlot = slots[currentIndex]
        let nextChangeDate = dateAtMinuteOfDay(currentSlot.interval.end, on: date)
        let nextSlot = slot(at: nextChangeDate)

        return TariffStatus(
            date: date,
            season: season,
            dayType: dayType,
            daySlots: slots,
            currentIndex: currentIndex,
            nextSlot: nextSlot,
            nextChangeDate: nextChangeDate
        )
    }

    // MARK: - Day type (weekend + holidays)

    private func dayType(for date: Date) -> DayType {
        let weekday = calendar.component(.weekday, from: date) // 1=Sun ... 7=Sat
        if weekday == 1 || weekday == 7 {
            return .offday
        }

        return SloveniaHolidays.isHoliday(date, calendar: calendar) ? .offday : .workday
    }

    // MARK: - Schedules

    private func scheduleSlots(for date: Date, season: TariffSeason, dayType: DayType) -> [TariffSlot] {
        switch ScheduleVersion.from(date: date, calendar: calendar) {
        case .through2026:
            return scheduleThrough2026(for: season, dayType: dayType)
        case .from2027:
            return scheduleFrom2027(for: season, dayType: dayType)
        }
    }

    /// Urnik, ki velja do vključno 31. 12. 2026.
    private func scheduleThrough2026(for season: TariffSeason, dayType: DayType) -> [TariffSlot] {
        let intervals = [
            TimeIntervalMinutes(start: 0, end: 360),
            TimeIntervalMinutes(start: 360, end: 420),
            TimeIntervalMinutes(start: 420, end: 840),
            TimeIntervalMinutes(start: 840, end: 960),
            TimeIntervalMinutes(start: 960, end: 1200),
            TimeIntervalMinutes(start: 1200, end: 1320),
            TimeIntervalMinutes(start: 1320, end: 1440)
        ]

        let levels: [TariffLevel]
        switch (season, dayType) {
        case (.higher, .workday): levels = [.l3, .l2, .l1, .l2, .l1, .l2, .l3]
        case (.higher, .offday), (.lower, .workday): levels = [.l4, .l3, .l2, .l3, .l2, .l3, .l4]
        case (.lower, .offday): levels = [.l5, .l4, .l3, .l4, .l3, .l4, .l5]
        }

        return zip(intervals, levels).map {
            TariffSlot(interval: $0.0, level: $0.1)
        }
    }

    /// Urnik iz spremenjene Priloge 2, ki se uporablja od 1. 1. 2027.
    private func scheduleFrom2027(for season: TariffSeason, dayType: DayType) -> [TariffSlot] {
        switch (season, dayType) {
        case (.higher, .workday):
            return makeSlots([
                (0, 360, .l3),
                (360, 720, .l1),
                (720, 1020, .l2),
                (1020, 1200, .l1),
                (1200, 1320, .l2),
                (1320, 1440, .l3)
            ])

        case (.higher, .offday):
            return makeSlots([
                (0, 360, .l4),
                (360, 720, .l3),
                (720, 1020, .l4),
                (1020, 1320, .l3),
                (1320, 1440, .l4)
            ])

        case (.lower, .workday):
            return makeSlots([
                (0, 360, .l5),
                (360, 720, .l3),
                (720, 1020, .l4),
                (1020, 1320, .l3),
                (1320, 1440, .l5)
            ])

        case (.lower, .offday):
            return makeSlots([
                (0, 360, .l5),
                (360, 720, .l4),
                (720, 1020, .l5),
                (1020, 1320, .l4),
                (1320, 1440, .l5)
            ])
        }
    }

    private func makeSlots(_ definitions: [(start: Int, end: Int, level: TariffLevel)]) -> [TariffSlot] {
        definitions.map {
            TariffSlot(interval: TimeIntervalMinutes(start: $0.start, end: $0.end), level: $0.level)
        }
    }

    // MARK: - Next slot

    private func slot(at date: Date) -> TariffSlot {
        let season = TariffSeason.from(date: date, calendar: calendar)
        let slots = scheduleSlots(for: date, season: season, dayType: dayType(for: date))
        let minuteOfDay = minutesSinceMidnight(date)

        guard let slot = slots.first(where: { $0.interval.contains(minuteOfDay: minuteOfDay) }) else {
            preconditionFailure("Tarifni urnik ne pokrije naslednjega trenutka.")
        }
        return slot
    }

    // MARK: - Date helpers

    private func minutesSinceMidnight(_ date: Date) -> Int {
        let components = calendar.dateComponents([.hour, .minute], from: date)
        return (components.hour ?? 0) * 60 + (components.minute ?? 0)
    }

    /// Ustvari lokalni stenski čas v Sloveniji. Dodajanje 1440 minut bi bilo ob prehodu
    /// na poletni ali zimski čas zamaknjeno za eno uro, zato polnoč premaknemo po dnevih.
    private func dateAtMinuteOfDay(_ minute: Int, on date: Date) -> Date {
        let dayStart = calendar.startOfDay(for: date)
        let clamped = max(0, min(minute, 1440))

        if clamped == 1440 {
            return calendar.date(byAdding: .day, value: 1, to: dayStart) ?? date
        }

        var components = calendar.dateComponents([.year, .month, .day], from: date)
        components.hour = clamped / 60
        components.minute = clamped % 60
        components.second = 0
        components.timeZone = TariffClock.timeZone
        return calendar.date(from: components) ?? date
    }
}
