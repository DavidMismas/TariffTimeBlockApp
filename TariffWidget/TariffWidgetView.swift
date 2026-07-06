//
//  TariffWidgetView.swift
//  TariffTimeBlockApp
//
//  Created by David Mišmaš on 20. 1. 26.
//

import WidgetKit
import SwiftUI

struct TariffWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: TariffEntry

    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidget(status: entry.status)
                .containerBackground(.background, for: .widget)

        case .systemMedium:
            MediumWidget(status: entry.status)
                .containerBackground(.background, for: .widget)

        default:
            SmallWidget(status: entry.status)
                .containerBackground(.background, for: .widget)
        }
    }
}

// MARK: - Shared Card Shell (prepreči “čez rob”)

private struct WidgetCard<Content: View>: View {
    let accent: Color
    let content: Content

    init(accent: Color, @ViewBuilder content: () -> Content) {
        self.accent = accent
        self.content = content()
    }

    var body: some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding(12) // varno znotraj widgeta
            .background {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(.ultraThinMaterial)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(accent.opacity(0.65), lineWidth: 2) // ZNOTRAJ, ne ven
            }
    }
}

// MARK: - Small (2x2)

private struct SmallWidget: View {
    let status: TariffStatus

    var body: some View {
        let lvl = status.currentSlot.level

        WidgetCard(accent: lvl.color) {
            VStack(alignment: .leading, spacing: 6) {
                Text(lvl.displayTitle)
                    .font(.system(size: 26, weight: .heavy, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.9)

                Text(status.currentSlot.interval.display)
                    .font(.system(.caption, design: .monospaced).weight(.semibold))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)

                Spacer(minLength: 0)

                HStack(spacing: 6) {
                    Text("Naslednji")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                    Spacer(minLength: 6)
                    Text(status.nextSlot.level.displayTitle)
                        .font(.caption2.weight(.bold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.9)
                }
            }
        }
    }
}

// MARK: - Medium (4x2) — ISTA višina kot small, samo širše

private struct MediumWidget: View {
    let status: TariffStatus

    var body: some View {
        let lvl = status.currentSlot.level

        WidgetCard(accent: lvl.color) {
            HStack(alignment: .top, spacing: 12) {

                // LEVO: glavno
                VStack(alignment: .leading, spacing: 8) {
                    Text(lvl.displayTitle)
                        .font(.system(size: 32, weight: .heavy, design: .rounded))
                        .lineLimit(1)
                        .minimumScaleFactor(0.9)

                    Text(status.currentSlot.interval.display)
                        .font(.system(.subheadline, design: .monospaced).weight(.semibold))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)

                    Text(lvl.subtitle)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer(minLength: 0)

                // DESNO: naslednji (kompaktno, da izkoristi širino)
                VStack(alignment: .trailing, spacing: 8) {
                    Text("Naslednji")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)

                    Text(status.nextSlot.level.displayTitle)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .lineLimit(1)
                        .minimumScaleFactor(0.9)

                    Text("ob \(status.nextChangeDate.tariffFormatted(dateStyle: .none, timeStyle: .short))")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)

                    // Optional: timer (če želiš, odstrani)
                    Text(status.nextChangeDate, style: .timer)
                        .font(.system(.caption2, design: .monospaced).weight(.semibold))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                }
            }
        }
    }
}
