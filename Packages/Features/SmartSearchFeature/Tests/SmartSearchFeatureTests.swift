import ComposableArchitecture
import Foundation
import SmartSearchDomain
import Testing
@testable import SmartSearchFeature

@MainActor
struct SmartSearchFeatureTests {
    @Test("example tap populates query and parses immediately")
    func exampleTapParses() async {
        let store = TestStore(initialState: SmartSearchFeature.State()) {
            SmartSearchFeature()
        } withDependencies: {
            $0.date = .constant(Date(timeIntervalSince1970: 1_700_000_000))
        }

        await store.send(.exampleTapped("cà phê hôm qua")) {
            $0.queryText = "cà phê hôm qua"
            $0.lastQuery = SmartSearchParser.parse(
                "cà phê hôm qua",
                referenceDate: Date(timeIntervalSince1970: 1_700_000_000)
            )
        }
    }
}
