import SwiftUI
import WidgetKit

@main
struct KasoWidgetBundle: WidgetBundle {
    var body: some Widget {
        KasoSpendingWidget()
        if #available(iOS 16.2, *) {
            KasoSpendingLiveActivity()
        }
    }
}
