import ComposableArchitecture
import Foundation
import HuiTrackerDomain

@Reducer
public struct HuiTrackerFeature: Sendable {
    @ObservableState
    public struct State: Equatable {
        public var groups: IdentifiedArrayOf<HuiGroup>
        public var overallSummary: HuiOverallSummary
        public var isLoading: Bool
        public var isEditorPresented: Bool
        public var editingGroup: HuiGroup?
        public var selectedGroupID: UUID?
        public var draftName: String
        public var draftOrganizerName: String
        public var draftContributionText: String
        public var draftPeriodKind: HuiPeriodKind
        public var draftMemberCountText: String
        public var draftStartDate: Date
        public var draftNote: String
        public var errorMessageKey: String?
        public var editorErrorMessageKey: String?

        public var selectedGroup: HuiGroup? {
            guard let id = selectedGroupID else { return nil }
            return groups[id: id]
        }

        public var groupSummaries: [HuiGroupSummary] {
            groups.map(HuiSummaryBuilder.group(from:))
        }

        public init(
            groups: IdentifiedArrayOf<HuiGroup> = [],
            overallSummary: HuiOverallSummary = HuiOverallSummary(),
            isLoading: Bool = false,
            isEditorPresented: Bool = false,
            editingGroup: HuiGroup? = nil,
            selectedGroupID: UUID? = nil,
            draftName: String = "",
            draftOrganizerName: String = "",
            draftContributionText: String = "",
            draftPeriodKind: HuiPeriodKind = .monthly,
            draftMemberCountText: String = "",
            draftStartDate: Date = Date(timeIntervalSinceReferenceDate: 0),
            draftNote: String = "",
            errorMessageKey: String? = nil,
            editorErrorMessageKey: String? = nil
        ) {
            self.groups = groups
            self.overallSummary = overallSummary
            self.isLoading = isLoading
            self.isEditorPresented = isEditorPresented
            self.editingGroup = editingGroup
            self.selectedGroupID = selectedGroupID
            self.draftName = draftName
            self.draftOrganizerName = draftOrganizerName
            self.draftContributionText = draftContributionText
            self.draftPeriodKind = draftPeriodKind
            self.draftMemberCountText = draftMemberCountText
            self.draftStartDate = draftStartDate
            self.draftNote = draftNote
            self.errorMessageKey = errorMessageKey
            self.editorErrorMessageKey = editorErrorMessageKey
        }
    }

    public enum Action: Equatable, Sendable {
        case task
        case groupsLoaded([HuiGroup])
        case loadFailed(String)
        case addButtonTapped
        case editButtonTapped(HuiGroup)
        case editorDismissed
        case nameChanged(String)
        case organizerNameChanged(String)
        case contributionTextChanged(String)
        case periodKindChanged(HuiPeriodKind)
        case memberCountTextChanged(String)
        case startDateChanged(Date)
        case noteChanged(String)
        case saveButtonTapped
        case groupSaved(HuiGroup)
        case saveFailed(String)
        case deleteButtonTapped(UUID)
        case groupDeleted(UUID)
        case deleteFailed(String)
        case groupSelected(UUID)
        case groupDeselected
        case cyclePaidToggled(groupID: UUID, cycleID: UUID)
        case cycleReceivedToggled(groupID: UUID, cycleID: UUID)
        case cyclePersisted(HuiGroup)
    }

    @Dependency(\.huiTrackerRepository) private var repository
    @Dependency(\.date.now) private var now
    @Dependency(\.uuid) private var uuid

    public init() {}

    public var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .task:
                state.isLoading = true
                return .run { send in
                    do {
                        let groups = try await repository.fetchAll()
                        await send(.groupsLoaded(groups))
                    } catch {
                        await send(.loadFailed("hui.error.loadFailed"))
                    }
                }

            case let .groupsLoaded(groups):
                state.isLoading = false
                state.groups = IdentifiedArray(uniqueElements: groups)
                state.overallSummary = HuiSummaryBuilder.overall(from: groups)
                return .none

            case let .loadFailed(key):
                state.isLoading = false
                state.errorMessageKey = key
                return .none

            case .addButtonTapped:
                state.editingGroup = nil
                state.draftName = ""
                state.draftOrganizerName = ""
                state.draftContributionText = ""
                state.draftPeriodKind = .monthly
                state.draftMemberCountText = ""
                state.draftStartDate = now
                state.draftNote = ""
                state.editorErrorMessageKey = nil
                state.isEditorPresented = true
                return .none

            case let .editButtonTapped(group):
                state.editingGroup = group
                state.draftName = group.name
                state.draftOrganizerName = group.organizerName
                state.draftContributionText = group.contributionAmount.description
                state.draftPeriodKind = group.periodKind
                state.draftMemberCountText = String(group.memberCount)
                state.draftStartDate = group.startDate
                state.draftNote = group.note ?? ""
                state.editorErrorMessageKey = nil
                state.isEditorPresented = true
                return .none

            case .editorDismissed:
                state.isEditorPresented = false
                state.editorErrorMessageKey = nil
                return .none

            case let .nameChanged(value):
                state.draftName = value
                state.editorErrorMessageKey = nil
                return .none

            case let .organizerNameChanged(value):
                state.draftOrganizerName = value
                return .none

            case let .contributionTextChanged(value):
                state.draftContributionText = value
                state.editorErrorMessageKey = nil
                return .none

            case let .periodKindChanged(value):
                state.draftPeriodKind = value
                return .none

            case let .memberCountTextChanged(value):
                state.draftMemberCountText = value
                state.editorErrorMessageKey = nil
                return .none

            case let .startDateChanged(value):
                state.draftStartDate = value
                return .none

            case let .noteChanged(value):
                state.draftNote = value
                return .none

            case .saveButtonTapped:
                let name = state.draftName.trimmingCharacters(in: .whitespacesAndNewlines)
                guard name.isEmpty == false else {
                    state.editorErrorMessageKey = "hui.error.nameRequired"
                    return .none
                }
                guard
                    let contribution = Decimal(
                        string: state.draftContributionText.replacingOccurrences(of: ".", with: ""),
                        locale: nil
                    ),
                    contribution > 0
                else {
                    state.editorErrorMessageKey = "hui.error.invalidContribution"
                    return .none
                }
                guard let memberCount = Int(state.draftMemberCountText), memberCount > 0 else {
                    state.editorErrorMessageKey = "hui.error.invalidMemberCount"
                    return .none
                }
                let organizer = state.draftOrganizerName.trimmingCharacters(in: .whitespacesAndNewlines)
                let note = state.draftNote.trimmingCharacters(in: .whitespacesAndNewlines)
                let existing = state.editingGroup
                let cycles: [HuiCycle]
                if let existing, existing.memberCount == memberCount,
                   existing.periodKind == state.draftPeriodKind,
                   existing.startDate == state.draftStartDate {
                    cycles = existing.cycles
                } else {
                    cycles = HuiCycleScheduleBuilder.build(
                        memberCount: memberCount,
                        startDate: state.draftStartDate,
                        periodKind: state.draftPeriodKind
                    )
                }
                let group = HuiGroup(
                    id: existing?.id ?? uuid(),
                    name: name,
                    organizerName: organizer,
                    contributionAmount: contribution,
                    periodKind: state.draftPeriodKind,
                    memberCount: memberCount,
                    startDate: state.draftStartDate,
                    note: note.isEmpty ? nil : note,
                    cycles: cycles,
                    createdAt: existing?.createdAt ?? now
                )
                return .run { send in
                    do {
                        try await repository.save(group)
                        await send(.groupSaved(group))
                    } catch {
                        await send(.saveFailed("hui.error.saveFailed"))
                    }
                }

            case let .groupSaved(group):
                state.isEditorPresented = false
                state.groups.updateOrAppend(group)
                state.overallSummary = HuiSummaryBuilder.overall(from: Array(state.groups))
                return .none

            case let .saveFailed(key):
                state.editorErrorMessageKey = key
                return .none

            case let .deleteButtonTapped(id):
                return .run { send in
                    do {
                        try await repository.delete(id)
                        await send(.groupDeleted(id))
                    } catch {
                        await send(.deleteFailed("hui.error.deleteFailed"))
                    }
                }

            case let .groupDeleted(id):
                state.groups.remove(id: id)
                if state.selectedGroupID == id {
                    state.selectedGroupID = nil
                }
                state.overallSummary = HuiSummaryBuilder.overall(from: Array(state.groups))
                return .none

            case let .deleteFailed(key):
                state.errorMessageKey = key
                return .none

            case let .groupSelected(id):
                state.selectedGroupID = id
                return .none

            case .groupDeselected:
                state.selectedGroupID = nil
                return .none

            case let .cyclePaidToggled(groupID, cycleID):
                guard var group = state.groups[id: groupID],
                      let index = group.cycles.firstIndex(where: { $0.id == cycleID })
                else { return .none }
                group.cycles[index].isPaid.toggle()
                state.groups[id: groupID] = group
                return persist(group)

            case let .cycleReceivedToggled(groupID, cycleID):
                guard var group = state.groups[id: groupID],
                      let index = group.cycles.firstIndex(where: { $0.id == cycleID })
                else { return .none }
                let received = group.cycles[index].isReceived
                group.cycles[index].isReceived = received == false
                group.cycles[index].receivedAmount = received
                    ? nil
                    : group.contributionAmount * Decimal(group.memberCount)
                state.groups[id: groupID] = group
                return persist(group)

            case let .cyclePersisted(group):
                state.overallSummary = HuiSummaryBuilder.overall(from: Array(state.groups))
                return .none
            }
        }
    }

    private func persist(_ group: HuiGroup) -> Effect<Action> {
        .run { send in
            do {
                try await repository.save(group)
                await send(.cyclePersisted(group))
            } catch {
                await send(.saveFailed("hui.error.saveFailed"))
            }
        }
    }
}
