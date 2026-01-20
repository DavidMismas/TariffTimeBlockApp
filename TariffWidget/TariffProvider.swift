//
//  TariffProvider.swift
//  TariffTimeBlockApp
//
//  Created by David Mišmaš on 20. 1. 26.
//
import WidgetKit
import SwiftUI

struct TariffEntry: TimelineEntry {
    let date: Date
    let status: TariffStatus
}

struct TariffProvider: TimelineProvider {
    private let engine = TariffEngine()

    func placeholder(in context: Context) -> TariffEntry {
        let date = previewDateIfNeeded(context) ?? Date()
        return TariffEntry(date: date, status: engine.status(for: date))
    }

    func getSnapshot(in context: Context, completion: @escaping (TariffEntry) -> Void) {
        let date = previewDateIfNeeded(context) ?? Date()
        completion(TariffEntry(date: date, status: engine.status(for: date)))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TariffEntry>) -> Void) {
        let now = Date()
        let status = engine.status(for: now)

        // Osveži ob naslednji spremembi intervala (+ 2s buffer)
        let refresh = status.nextChangeDate.addingTimeInterval(2)

        let entry = TariffEntry(date: now, status: status)
        completion(Timeline(entries: [entry], policy: .after(refresh)))
    }

    // MARK: - Preview helper

    private func previewDateIfNeeded(_ context: Context) -> Date? {
        guard context.isPreview else { return nil }

        // Stabilen preview datum (npr. višja sezona, delovni dan, 06:30)
        var cal = Calendar.current
        cal.timeZone = TimeZone(identifier: "Europe/Ljubljana") ?? .current

        var comps = DateComponents()
        comps.year = 2026
        comps.month = 1
        comps.day = 14
        comps.hour = 6
        comps.minute = 30
        comps.second = 0

        return cal.date(from: comps)
    }
}

