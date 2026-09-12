import SwiftUI
import SwiftData

@main
struct SmartParkApp: App {
    @StateObject private var viewModel = ParkingViewModel()
    @StateObject private var appLocationState = AppLocationState()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(viewModel)
                .environmentObject(appLocationState)
        }
        .modelContainer(for: [
            FavoriteParking.self,
            ParkingReport.self,
            ParkingPreferences.self
        ])
    }
}
