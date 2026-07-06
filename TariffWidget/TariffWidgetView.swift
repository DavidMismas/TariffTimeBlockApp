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
    @Environment(\.colorScheme) private var colorScheme
    let entry: TariffEntry
    private let familyOverride: WidgetFamily?

    init(entry: TariffEntry, familyOverride: WidgetFamily? = nil) {
        self.entry = entry
        self.familyOverride = familyOverride
    }

    var body: some View {
        Group {
            switch familyOverride ?? family {
            case .systemMedium:
                MediumWidget(status: entry.status, palette: palette)
            default:
                SmallWidget(status: entry.status, palette: palette)
            }
        }
        .foregroundStyle(palette.primary)
        .containerBackground(for: .widget) {
            palette.background
        }
    }

    private var palette: WidgetPalette {
        WidgetPalette(colorScheme: colorScheme)
    }
}

private struct WidgetPalette {
    let background: Color
    let surface: Color
    let primary: Color
    let secondary: Color
    let separator: Color

    init(colorScheme: ColorScheme) {
        if colorScheme == .dark {
            background = Color(red: 0.055, green: 0.065, blue: 0.085)
            surface = Color.white.opacity(0.075)
            primary = .white
            secondary = Color.white.opacity(0.68)
            separator = Color.white.opacity(0.14)
        } else {
            background = Color(red: 0.975, green: 0.98, blue: 0.99)
            surface = Color.black.opacity(0.045)
            primary = Color(red: 0.07, green: 0.08, blue: 0.1)
            secondary = Color.black.opacity(0.58)
            separator = Color.black.opacity(0.1)
        }
    }
}

private struct SmallWidget: View {
    let status: TariffStatus
    let palette: WidgetPalette

    var body: some View {
        let level = status.currentSlot.level

        VStack(alignment: .leading, spacing: 7) {
            HStack(spacing: 8) {
                Text("OMREŽNINA")
                    .font(.caption2.weight(.bold))
                    .tracking(0.6)
                    .foregroundStyle(palette.secondary)

                Spacer(minLength: 4)

                Circle()
                    .fill(level.color)
                    .frame(width: 10, height: 10)
                    .widgetAccentable()
            }

            Text(level.displayTitle)
                .font(.system(size: 27, weight: .heavy, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Text(status.currentSlot.interval.display)
                .font(.system(.caption, design: .monospaced).weight(.semibold))
                .foregroundStyle(palette.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Spacer(minLength: 2)

            Rectangle()
                .fill(palette.separator)
                .frame(height: 1)

            HStack(spacing: 6) {
                Text("Naslednji")
                    .font(.caption2)
                    .foregroundStyle(palette.secondary)
                Spacer(minLength: 4)
                Text(status.nextSlot.level.displayTitle)
                    .font(.caption2.weight(.bold))
                Text(status.nextChangeDate.tariffFormatted(dateStyle: .none, timeStyle: .short))
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundStyle(palette.secondary)
            }
            .lineLimit(1)
            .minimumScaleFactor(0.72)
        }
        .accessibilityElement(children: .combine)
    }
}

private struct MediumWidget: View {
    let status: TariffStatus
    let palette: WidgetPalette

    var body: some View {
        let level = status.currentSlot.level

        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 7) {
                HStack(spacing: 7) {
                    Circle()
                        .fill(level.color)
                        .frame(width: 10, height: 10)
                        .widgetAccentable()

                    Text("TRENUTNO")
                        .font(.caption2.weight(.bold))
                        .tracking(0.6)
                        .foregroundStyle(palette.secondary)
                }

                Text(level.displayTitle)
                    .font(.system(size: 33, weight: .heavy, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)

                Text(status.currentSlot.interval.display)
                    .font(.system(.subheadline, design: .monospaced).weight(.semibold))
                    .foregroundStyle(palette.secondary)
                    .lineLimit(1)

                Text(level.subtitle)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(palette.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Rectangle()
                .fill(palette.separator)
                .frame(width: 1)

            VStack(alignment: .leading, spacing: 7) {
                Label("Naslednji", systemImage: "arrow.right.circle.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(palette.secondary)

                Text(status.nextSlot.level.displayTitle)
                    .font(.system(.title3, design: .rounded).weight(.bold))
                    .lineLimit(1)

                Text("ob \(status.nextChangeDate.tariffFormatted(dateStyle: .none, timeStyle: .short))")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(palette.secondary)

                Text(status.nextChangeDate, style: .timer)
                    .font(.system(.caption2, design: .monospaced).weight(.semibold))
                    .foregroundStyle(level.color)
                    .lineLimit(1)
            }
            .padding(12)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .background(palette.surface, in: .rect(cornerRadius: 14))
        }
        .accessibilityElement(children: .combine)
    }
}
