import XCTest
@testable import TariffTimeBlockApp

@MainActor
final class TariffEngineTests: XCTestCase {
    private let engine = TariffEngine()

    func test2026HigherSeasonWorkdaySchedule() {
        XCTAssertEqual(status(2026, 1, 14, 6, 30).currentSlot.level, .l2)
        XCTAssertEqual(status(2026, 1, 14, 8).currentSlot.level, .l1)
        XCTAssertEqual(status(2026, 1, 14, 15).currentSlot.level, .l2)
        XCTAssertEqual(status(2026, 1, 14, 23).currentSlot.level, .l3)
    }

    func test2026WeekendUsesOffdaySchedule() {
        let morning = status(2026, 1, 17, 8)
        let night = status(2026, 1, 17, 23)

        XCTAssertEqual(morning.dayType, .offday)
        XCTAssertEqual(morning.currentSlot.level, .l2)
        XCTAssertEqual(night.currentSlot.level, .l4)
    }

    func testHolidayUsesOffdaySchedule() {
        let fixedHoliday = status(2026, 5, 1, 8)
        let easterMonday = status(2026, 4, 6, 8)

        XCTAssertEqual(fixedHoliday.dayType, .offday)
        XCTAssertEqual(fixedHoliday.currentSlot.level, .l3)
        XCTAssertEqual(easterMonday.dayType, .offday)
        XCTAssertEqual(easterMonday.currentSlot.level, .l3)
    }

    func testNextSlotAtMidnightUsesNextDaysSchedule() {
        let fridayNight = status(2026, 1, 16, 23)

        XCTAssertEqual(fridayNight.currentSlot.level, .l3)
        XCTAssertEqual(fridayNight.nextSlot.level, .l4)
        XCTAssertEqual(fridayNight.nextChangeDate, date(2026, 1, 17, 0))
    }

    func testNextSlotAtMidnightUsesNextSeason() {
        let lastHigherSeasonNight = status(2026, 2, 28, 23)

        XCTAssertEqual(lastHigherSeasonNight.season, .higher)
        XCTAssertEqual(lastHigherSeasonNight.nextSlot.level, .l5)
        XCTAssertEqual(lastHigherSeasonNight.nextChangeDate, date(2026, 3, 1, 0))
    }

    func testScheduleChangesOnFirstJanuary2027() {
        let last2026Status = status(2026, 12, 31, 23)
        let first2027Status = status(2027, 1, 1, 0)
        let first2027WorkdayMorning = status(2027, 1, 4, 6, 30)

        XCTAssertEqual(last2026Status.currentSlot.level, .l3)
        XCTAssertEqual(last2026Status.nextSlot.level, .l4)
        XCTAssertEqual(first2027Status.currentSlot.level, .l4)
        XCTAssertEqual(first2027WorkdayMorning.currentSlot.level, .l1)
        XCTAssertEqual(first2027WorkdayMorning.currentSlot.interval, .init(start: 360, end: 720))
    }

    func test2027LowerSeasonSchedule() {
        let workday = status(2027, 7, 5, 13)
        let offday = status(2027, 7, 4, 13)

        XCTAssertEqual(workday.currentSlot.level, .l4)
        XCTAssertEqual(offday.currentSlot.level, .l5)
    }

    func testSpringDSTChangeKeepsSixOClockBoundary() {
        let beforeBoundary = status(2026, 3, 29, 5, 59)

        XCTAssertEqual(beforeBoundary.nextChangeDate, date(2026, 3, 29, 6))
        XCTAssertEqual(beforeBoundary.secondsToNextChange, 60)
    }

    func testAutumnDSTChangeKeepsSixOClockBoundary() {
        let beforeBoundary = status(2026, 10, 25, 5, 59)

        XCTAssertEqual(beforeBoundary.nextChangeDate, date(2026, 10, 25, 6))
        XCTAssertEqual(beforeBoundary.secondsToNextChange, 60)
    }

    func testEngineAlwaysInterpretsDatesInSlovenianTime() throws {
        let formatter = ISO8601DateFormatter()
        let instant = try XCTUnwrap(formatter.date(from: "2026-01-14T05:30:00Z"))
        let result = engine.status(for: instant)

        XCTAssertEqual(result.currentSlot.level, .l2)
        XCTAssertEqual(result.currentSlot.interval, .init(start: 360, end: 420))
    }

    private func status(
        _ year: Int,
        _ month: Int,
        _ day: Int,
        _ hour: Int,
        _ minute: Int = 0
    ) -> TariffStatus {
        engine.status(for: date(year, month, day, hour, minute))
    }

    private func date(
        _ year: Int,
        _ month: Int,
        _ day: Int,
        _ hour: Int,
        _ minute: Int = 0
    ) -> Date {
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
