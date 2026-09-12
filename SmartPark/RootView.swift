import SwiftUI

struct RootView: View {
    @EnvironmentObject private var appLocationState: AppLocationState

    var body: some View {
        Group {
            if appLocationState.didCompleteLocationSetup {
                ContentView()
            } else {
                LocationSetupView()
            }
        }
    }
}
