import SwiftUI
import WidgetKit
import XCTest
@testable import TariffTimeBlockApp

@MainActor
final class WidgetRenderingTests: XCTestCase {
    func testWidgetLightAndDarkSnapshots() throws {
        let date = makeDate(year: 2026, month: 7, day: 6, hour: 18, minute: 30)
        let entry = TariffEntry(date: date, status: TariffEngine().status(for: date))

        try attachSnapshot(
            entry: entry,
            family: .systemSmall,
            colorScheme: .light,
            size: CGSize(width: 170, height: 170),
            name: "Widget-Small-Light"
        )
        try attachSnapshot(
            entry: entry,
            family: .systemSmall,
            colorScheme: .dark,
            size: CGSize(width: 170, height: 170),
            name: "Widget-Small-Dark"
        )
        try attachSnapshot(
            entry: entry,
            family: .systemMedium,
            colorScheme: .light,
            size: CGSize(width: 364, height: 170),
            name: "Widget-Medium-Light-iPad"
        )
        try attachSnapshot(
            entry: entry,
            family: .systemMedium,
            colorScheme: .dark,
            size: CGSize(width: 364, height: 170),
            name: "Widget-Medium-Dark-iPad"
        )
    }

    private func attachSnapshot(
        entry: TariffEntry,
        family: WidgetFamily,
        colorScheme: ColorScheme,
        size: CGSize,
        name: String
    ) throws {
        let background = colorScheme == .dark
            ? Color(red: 0.055, green: 0.065, blue: 0.085)
            : Color(red: 0.975, green: 0.98, blue: 0.99)

        let content = ZStack {
            background

            TariffWidgetView(entry: entry, familyOverride: family)
                .environment(\.colorScheme, colorScheme)
                .padding(16)
        }
        .frame(width: size.width, height: size.height)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))

        let renderer = ImageRenderer(content: content)
        renderer.scale = 2

        let image = try XCTUnwrap(renderer.uiImage)
        XCTAssertGreaterThan(image.size.width, 0)
        XCTAssertGreaterThan(image.size.height, 0)

        let attachment = XCTAttachment(image: image)
        attachment.name = name
        attachment.lifetime = XCTAttachment.Lifetime.keepAlways
        add(attachment)
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
        return components.date!
    }
}
