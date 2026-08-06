import SwiftUI

@main
struct BlitztextIOSApp: App {
    @StateObject private var model = AppModel.shared
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            RootView(model: model)
                .preferredColorScheme(nil)
                .onAppear {
                    model.consumeShortcutLaunch()
                }
                .onChange(of: scenePhase) { _, newPhase in
                    if newPhase == .active {
                        model.consumeShortcutLaunch()
                    } else if newPhase == .background {
                        model.appDidEnterBackground()
                    }
                }
        }
    }
}

struct RootView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        Group {
            if model.isSetupComplete {
                MainView(model: model)
            } else {
                OnboardingView(model: model)
            }
        }
        .tint(.blue)
    }
}
