import Foundation
import Testing
@testable import WellnessDomain

@Test("whole hours and remaining minutes split rounded minutes")
func wholeHoursAndRemainingMinutesSplitRoundedMinutes() {
    let conversion = HoursOfLifeConversion(
        amount: 0,
        workMinutes: 0,
        workHours: 0,
        roundedWorkMinutes: 185
    )

    #expect(conversion.wholeHours == 3)
    #expect(conversion.remainingMinutes == 5)
}

@Test("zero rounded minutes split into zero hours and minutes")
func zeroRoundedMinutesSplitIntoZero() {
    let conversion = HoursOfLifeConversion(
        amount: 0,
        workMinutes: 0,
        workHours: 0,
        roundedWorkMinutes: 0
    )

    #expect(conversion.wholeHours == 0)
    #expect(conversion.remainingMinutes == 0)
}

@Test("exact hour multiples leave no remaining minutes")
func exactHourMultiplesLeaveNoRemainingMinutes() {
    let conversion = HoursOfLifeConversion(
        amount: 0,
        workMinutes: 0,
        workHours: 0,
        roundedWorkMinutes: 120
    )

    #expect(conversion.wholeHours == 2)
    #expect(conversion.remainingMinutes == 0)
}

@Test("conversion equality compares all stored fields")
func conversionEqualityComparesAllStoredFields() {
    let base = HoursOfLifeConversion(
        amount: 150_000,
        workMinutes: 120,
        workHours: 2,
        roundedWorkMinutes: 120
    )

    #expect(
        base == HoursOfLifeConversion(
            amount: 150_000,
            workMinutes: 120,
            workHours: 2,
            roundedWorkMinutes: 120
        )
    )
    #expect(
        base != HoursOfLifeConversion(
            amount: 150_000,
            workMinutes: 121,
            workHours: 2,
            roundedWorkMinutes: 120
        )
    )
}

@Test("conversion round-trips through codable")
func conversionRoundTripsThroughCodable() throws {
    let conversion = HoursOfLifeConversion(
        amount: 212_500,
        workMinutes: 170,
        workHours: 2.8,
        roundedWorkMinutes: 170
    )

    let data = try JSONEncoder().encode(conversion)
    let decoded = try JSONDecoder().decode(HoursOfLifeConversion.self, from: data)

    #expect(decoded == conversion)
}
