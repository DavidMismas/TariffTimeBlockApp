//
//  ContentView.swift
//  TariffTimeBlockApp
//
//  Created by David Mišmaš on 20. 1. 26.
//

import SwiftUI

struct ContentView: View {
    private let engine = TariffEngine()

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            let status = engine.status(for: context.date)

            NavigationStack {
                ScrollView {
                    VStack(spacing: 14) {

                        // BIG: trenutni blok (kot prej)
                        CurrentBlockCard(status: status)

                        // Seznam vseh intervalov (trenutni je samo obarvan)
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Danes (vsi intervali)")
                                .font(.headline.weight(.bold))
                                .padding(.horizontal, 4)

                            ForEach(Array(status.daySlots.enumerated()), id: \.offset) { idx, slot in
                                SlotCard(
                                    title: slot.level.displayTitle,
                                    subtitle: slot.level.subtitle,
                                    rightTop: slot.interval.display,
                                    rightBottom: idx == status.currentIndex
                                        ? "\(status.season.title) · \(status.dayType.title)"
                                        : "",
                                    accentLevel: idx == status.currentIndex ? slot.level : nil
                                )
                            }
                        }

                        // Info kartica
                        InfoCard(status: status)
                            .padding(.top, 6)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 14)
                    .padding(.bottom, 22)
                }
                .navigationTitle("Omrežnina")
                .navigationBarTitleDisplayMode(.inline)
            }
        }
    }
}

// MARK: - Cards

private struct CurrentBlockCard: View {
    let status: TariffStatus

    var body: some View {
        let lvl = status.currentSlot.level

        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Trenutno")
                        .font(.caption.weight(.semibold))
                        .opacity(0.9)

                    Text(lvl.displayTitle)
                        .font(.system(size: 42, weight: .heavy, design: .rounded))

                    Text(lvl.subtitle)
                        .font(.headline.weight(.semibold))
                        .opacity(0.95)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 6) {
                    Text(status.currentSlot.interval.display)
                        .font(.headline.weight(.semibold))
                        .opacity(0.95)

                    Text("\(status.season.title) · \(status.dayType.title)")
                        .font(.caption)
                        .opacity(0.9)
                }
            }

            Divider()

            HStack {
                Text("Velja še:")
                    .font(.subheadline.weight(.semibold))
                    .opacity(0.95)
                Spacer()
                Text(formatCountdown(status.secondsToNextChange))
                    .font(.system(.subheadline, design: .monospaced).weight(.bold))
                    .opacity(0.95)
            }

            HStack {
                Text("Naslednji:")
                    .font(.subheadline.weight(.semibold))
                    .opacity(0.95)
                Spacer()
                Text("\(status.nextSlot.level.displayTitle) od \(status.nextChangeDate.formatted(date: .omitted, time: .shortened))")
                    .font(.subheadline.weight(.bold))
                    .opacity(0.95)
            }
        }
        .padding(16)
        .foregroundStyle(lvl.textColor)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(lvl.color)
        )
    }

    private func formatCountdown(_ seconds: Int) -> String {
        let s = max(0, seconds)
        let h = s / 3600
        let m = (s % 3600) / 60
        let sec = s % 60

        if h > 0 {
            return String(format: "%02dh %02dm %02ds", h, m, sec)
        } else if m > 0 {
            return String(format: "%02dm %02ds", m, sec)
        } else {
            return String(format: "%02ds", sec)
        }
    }
}

/// “Majhna kartica” (isti stil kot “naslednji” prej),
/// samo da jo lahko obarvamo, če je trenutna.
private struct SlotCard: View {
    let title: String
    let subtitle: String
    let rightTop: String
    let rightBottom: String
    let accentLevel: TariffLevel?

    var body: some View {
        let isAccent = (accentLevel != nil)

        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.title3.weight(.heavy))
                    Text(subtitle)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(isAccent ? accentLevel!.textColor.opacity(0.9) : .secondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 6) {
                    Text(rightTop)
                        .font(.headline.weight(.semibold))
                    if !rightBottom.isEmpty {
                        Text(rightBottom)
                            .font(.caption)
                            .foregroundStyle(isAccent ? accentLevel!.textColor.opacity(0.9) : .secondary)
                    }
                }
            }
        }
        .padding(16)
        .foregroundStyle(isAccent ? accentLevel!.textColor : .primary)
        .background {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(isAccent ? AnyShapeStyle(accentLevel!.color)
                               : AnyShapeStyle(.ultraThinMaterial))
        }

    }
}

private struct InfoCard: View {
    let status: TariffStatus

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Info")
                .font(.headline.weight(.bold))

            HStack {
                Label("Datum", systemImage: "calendar")
                Spacer()
                Text(status.date.formatted(date: .abbreviated, time: .shortened))
                    .foregroundStyle(.secondary)
            }

            HStack {
                Label("Sezona", systemImage: "leaf")
                Spacer()
                Text(status.season.title)
                    .foregroundStyle(.secondary)
            }

            HStack {
                Label("Dan", systemImage: "clock")
                Spacer()
                Text(status.dayType.title)
                    .foregroundStyle(.secondary)
            }

            Divider()

           
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.ultraThinMaterial)
        )
    }
}

// MARK: - Previews

#Preview("Višja sezona • Delovni • 06:30") {
    ContentView_PreviewHost(fixedDate: makeDate(year: 2026, month: 1, day: 14, hour: 6, minute: 30))
}

#Preview("Višja sezona • Delovni • 08:30") {
    ContentView_PreviewHost(fixedDate: makeDate(year: 2026, month: 1, day: 14, hour: 8, minute: 30))
}

#Preview("Nižja sezona • Prost • 23:10 (sobota)") {
    ContentView_PreviewHost(fixedDate: makeDate(year: 2026, month: 7, day: 18, hour: 23, minute: 10))
}

#Preview("Praznik • 01.11 • 12:00") {
    ContentView_PreviewHost(fixedDate: makeDate(year: 2026, month: 11, day: 1, hour: 12, minute: 0))
}

private struct ContentView_PreviewHost: View {
    let fixedDate: Date
    private let engine = TariffEngine()

    var body: some View {
        let status = engine.status(for: fixedDate)

        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    CurrentBlockCard(status: status)

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Danes (vsi intervali)")
                            .font(.headline.weight(.bold))
                            .padding(.horizontal, 4)

                        ForEach(Array(status.daySlots.enumerated()), id: \.offset) { idx, slot in
                            SlotCard(
                                title: slot.level.displayTitle,
                                subtitle: slot.level.subtitle,
                                rightTop: slot.interval.display,
                                rightBottom: idx == status.currentIndex ? "\(status.season.title) · \(status.dayType.title)" : "",
                                accentLevel: idx == status.currentIndex ? slot.level : nil
                            )
                        }
                    }

                    InfoCard(status: status)
                        .padding(.top, 6)
                }
                .padding(.horizontal, 16)
                .padding(.top, 14)
                .padding(.bottom, 22)
            }
            .navigationTitle("Omrežnina")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

private func makeDate(year: Int, month: Int, day: Int, hour: Int, minute: Int) -> Date {
    var cal = Calendar.current
    cal.timeZone = TimeZone(identifier: "Europe/Ljubljana") ?? .current

    var comps = DateComponents()
    comps.year = year
    comps.month = month
    comps.day = day
    comps.hour = hour
    comps.minute = minute
    comps.second = 0

    return cal.date(from: comps) ?? .now
}
