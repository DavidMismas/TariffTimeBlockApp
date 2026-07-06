//
//  ContentView.swift
//  TariffTimeBlockApp
//
//  Created by David Mišmaš on 20. 1. 26.
//

import SwiftUI

struct ContentView: View {
    private let engine = TariffEngine()
    @State private var isShowingInfo = false

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            dashboard(status: engine.status(for: context.date))
        }
    }

    private func dashboard(status: TariffStatus) -> some View {
        NavigationStack {
            ScrollView {
                TariffDashboard(status: status)
                    .frame(maxWidth: 780)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 16)
                    .padding(.top, 14)
                    .padding(.bottom, 28)
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("Omrežnina")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isShowingInfo = true
                    } label: {
                        Image(systemName: "info.circle")
                    }
                    .accessibilityLabel("O aplikaciji")
                }
            }
            .sheet(isPresented: $isShowingInfo) {
                AppInfoView()
            }
        }
    }
}

private struct AppInfoView: View {
    @Environment(\.dismiss) private var dismiss

    private let sourceURL = URL(
        string: "https://www.uro.si/prenova-omre%C5%BEnine/novi-%C4%8Dasovni-bloki"
    )!

    var body: some View {
        NavigationStack {
            List {
                Section("Vir") {
                    Link(destination: sourceURL) {
                        Label("Agencija za energijo – URO", systemImage: "arrow.up.right.square")
                    }
                }

                Section("O aplikaciji") {
                    Label("Ni uradna aplikacija.", systemImage: "exclamationmark.circle")
                    LabeledContent("Razvijalec", value: "David Mišmaš")
                }
            }
            .navigationTitle("Informacije")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Zapri") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

private struct TariffDashboard: View {
    let status: TariffStatus

    var body: some View {
        VStack(spacing: 18) {
            CurrentBlockCard(status: status)

            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .firstTextBaseline) {
                    Text("Današnji razpored")
                        .font(.headline.weight(.bold))
                    Spacer()
                    Text("\(status.daySlots.count) intervalov")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 4)

                ForEach(Array(status.daySlots.enumerated()), id: \.offset) { index, slot in
                    SlotCard(slot: slot, isCurrent: index == status.currentIndex)
                }
            }

            InfoCard(status: status)
        }
    }
}

// MARK: - Current block

private struct CurrentBlockCard: View {
    let status: TariffStatus

    var body: some View {
        let level = status.currentSlot.level

        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 10) {
                Label("Trenutno", systemImage: "bolt.fill")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(level.color)

                Spacer()

                Text("\(status.season.title) · \(status.dayType.title)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }

            HStack(alignment: .firstTextBaseline, spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(level.displayTitle)
                        .font(.system(size: 42, weight: .heavy, design: .rounded))
                        .lineLimit(1)

                    Text(level.subtitle)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 8)

                Text(status.currentSlot.interval.display)
                    .font(.system(.title3, design: .monospaced).weight(.bold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }

            Divider()

            ViewThatFits(in: .horizontal) {
                HStack(spacing: 18) {
                    statusMetric(
                        title: "Velja še",
                        value: formatCountdown(status.secondsToNextChange),
                        icon: "timer"
                    )

                    Divider()

                    statusMetric(
                        title: "Naslednji",
                        value: "\(status.nextSlot.level.displayTitle) ob \(status.nextChangeDate.tariffFormatted(dateStyle: .none, timeStyle: .short))",
                        icon: "arrow.right.circle"
                    )
                }

                VStack(spacing: 12) {
                    statusMetric(
                        title: "Velja še",
                        value: formatCountdown(status.secondsToNextChange),
                        icon: "timer"
                    )
                    Divider()
                    statusMetric(
                        title: "Naslednji",
                        value: "\(status.nextSlot.level.displayTitle) ob \(status.nextChangeDate.tariffFormatted(dateStyle: .none, timeStyle: .short))",
                        icon: "arrow.right.circle"
                    )
                }
            }
        }
        .padding(20)
        .background(Color(uiColor: .secondarySystemGroupedBackground), in: .rect(cornerRadius: 22))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(level.color.opacity(0.45), lineWidth: 1.5)
        }
        .overlay(alignment: .leading) {
            Capsule()
                .fill(level.color)
                .frame(width: 5)
                .padding(.vertical, 20)
        }
    }

    private func statusMetric(title: String, value: String, icon: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.body.weight(.semibold))
                .foregroundStyle(.secondary)
                .frame(width: 22)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.system(.subheadline, design: .rounded).weight(.bold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func formatCountdown(_ seconds: Int) -> String {
        let value = max(0, seconds)
        let hours = value / 3600
        let minutes = (value % 3600) / 60
        let remainingSeconds = value % 60

        if hours > 0 {
            return String(format: "%02dh %02dm %02ds", hours, minutes, remainingSeconds)
        } else if minutes > 0 {
            return String(format: "%02dm %02ds", minutes, remainingSeconds)
        } else {
            return String(format: "%02ds", remainingSeconds)
        }
    }
}

// MARK: - Schedule

private struct SlotCard: View {
    let slot: TariffSlot
    let isCurrent: Bool

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(slot.level.color)
                .frame(width: 10, height: 10)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 8) {
                    Text(slot.level.displayTitle)
                        .font(.headline.weight(.bold))

                    if isCurrent {
                        Text("ZDAJ")
                            .font(.caption2.weight(.heavy))
                            .foregroundStyle(slot.level.color)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(slot.level.color.opacity(0.12), in: .capsule)
                    }
                }

                Text(slot.level.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 12)

            Text(slot.interval.display)
                .font(.system(.subheadline, design: .monospaced).weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color(uiColor: .secondarySystemGroupedBackground), in: .rect(cornerRadius: 18))
        .overlay {
            if isCurrent {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(slot.level.color.opacity(0.55), lineWidth: 1.5)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Details

private struct InfoCard: View {
    let status: TariffStatus

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Podrobnosti")
                .font(.headline.weight(.bold))

            infoRow(title: "Datum", value: status.date.tariffFormatted(dateStyle: .medium, timeStyle: .short), icon: "calendar")
            infoRow(title: "Sezona", value: status.season.title, icon: "leaf")
            infoRow(title: "Dan", value: status.dayType.title, icon: "clock")
        }
        .padding(18)
        .background(Color(uiColor: .secondarySystemGroupedBackground), in: .rect(cornerRadius: 20))
    }

    private func infoRow(title: String, value: String, icon: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(.secondary)
                .frame(width: 22)
            Text(title)
            Spacer()
            Text(value)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.trailing)
        }
        .font(.subheadline)
    }
}

// MARK: - Previews

#Preview("Light · iPhone") {
    previewDashboard(date: makeDate(year: 2026, month: 1, day: 14, hour: 8, minute: 30))
        .preferredColorScheme(.light)
}

#Preview("Dark · iPhone") {
    previewDashboard(date: makeDate(year: 2026, month: 7, day: 18, hour: 23, minute: 10))
        .preferredColorScheme(.dark)
}

private func previewDashboard(date: Date) -> some View {
    let status = TariffEngine().status(for: date)
    return NavigationStack {
        ScrollView {
            TariffDashboard(status: status)
                .frame(maxWidth: 780)
                .frame(maxWidth: .infinity)
                .padding(16)
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle("Omrežnina")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private func makeDate(year: Int, month: Int, day: Int, hour: Int, minute: Int) -> Date {
    var components = DateComponents()
    components.calendar = TariffClock.calendar
    components.timeZone = TariffClock.timeZone
    components.year = year
    components.month = month
    components.day = day
    components.hour = hour
    components.minute = minute
    components.second = 0
    return components.date ?? .now
}
