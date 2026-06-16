import Foundation
import Testing
@testable import MoneyTherapistDomain

@Test("topic id equals its raw value")
func topicIdMatchesRawValue() {
    for topic in TherapistTopic.allCases {
        #expect(topic.id == topic.rawValue)
    }
}

@Test("topic exposes all five emotional contexts")
func topicCaseCount() {
    #expect(TherapistTopic.allCases.count == 5)
    #expect(TherapistTopic.allCases.contains(.recentOverspend))
    #expect(TherapistTopic.allCases.contains(.guilt))
    #expect(TherapistTopic.allCases.contains(.stressTrigger))
    #expect(TherapistTopic.allCases.contains(.comparisonAnxiety))
    #expect(TherapistTopic.allCases.contains(.generalCheckin))
}

@Test("topic raw values are the stable serialized identifiers")
func topicRawValues() {
    #expect(TherapistTopic.recentOverspend.rawValue == "recentOverspend")
    #expect(TherapistTopic.guilt.rawValue == "guilt")
    #expect(TherapistTopic.stressTrigger.rawValue == "stressTrigger")
    #expect(TherapistTopic.comparisonAnxiety.rawValue == "comparisonAnxiety")
    #expect(TherapistTopic.generalCheckin.rawValue == "generalCheckin")
}

@Test("topic round-trips through its raw value")
func topicRawValueRoundTrip() {
    for topic in TherapistTopic.allCases {
        #expect(TherapistTopic(rawValue: topic.rawValue) == topic)
    }
}

@Test("topic returns nil for an unknown raw value")
func topicUnknownRawValueIsNil() {
    #expect(TherapistTopic(rawValue: "notATopic") == nil)
    #expect(TherapistTopic(rawValue: "") == nil)
}

@Test("topic title key is namespaced and unique per case")
func topicTitleKeys() {
    #expect(TherapistTopic.recentOverspend.titleKey == "moneyTherapist.topic.recentOverspend.title")
    #expect(TherapistTopic.guilt.titleKey == "moneyTherapist.topic.guilt.title")
    let keys = TherapistTopic.allCases.map(\.titleKey)
    #expect(Set(keys).count == keys.count)
}

@Test("topic subtitle key is namespaced and unique per case")
func topicSubtitleKeys() {
    #expect(
        TherapistTopic.stressTrigger.subtitleKey == "moneyTherapist.topic.stressTrigger.subtitle"
    )
    #expect(
        TherapistTopic.generalCheckin.subtitleKey == "moneyTherapist.topic.generalCheckin.subtitle"
    )
    let keys = TherapistTopic.allCases.map(\.subtitleKey)
    #expect(Set(keys).count == keys.count)
}

@Test("topic title and subtitle keys differ from each other")
func topicTitleAndSubtitleKeysDiffer() {
    for topic in TherapistTopic.allCases {
        #expect(topic.titleKey != topic.subtitleKey)
    }
}

@Test("topic exposes the expected SF Symbol icon names")
func topicIconSystemNames() {
    #expect(TherapistTopic.recentOverspend.iconSystemName == "exclamationmark.bubble")
    #expect(TherapistTopic.guilt.iconSystemName == "heart.text.square")
    #expect(TherapistTopic.stressTrigger.iconSystemName == "wind")
    #expect(TherapistTopic.comparisonAnxiety.iconSystemName == "person.2")
    #expect(TherapistTopic.generalCheckin.iconSystemName == "leaf")
}

@Test("topic icon names are non-empty for every case")
func topicIconNamesNonEmpty() {
    for topic in TherapistTopic.allCases {
        #expect(topic.iconSystemName.isEmpty == false)
    }
}
