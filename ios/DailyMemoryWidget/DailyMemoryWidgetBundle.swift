import WidgetKit
import SwiftUI

@main
struct DailyMemoryWidgetBundle: WidgetBundle {
    var body: some Widget {
        // Small widget - Quick record
        QuickRecordWidget()

        // Medium widget - Full featured
        DailyMemoryWidget()

        // Lock Screen widget (iOS 16+)
        if #available(iOSApplicationExtension 16.0, *) {
            LockScreenWidget()
        }
    }
}
