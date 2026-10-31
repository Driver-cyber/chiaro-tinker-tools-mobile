//  LingoSproutsApp.swift — Lingo Sprouts: letters, sounds and words for Chad's
//  kids. Number Sprouts' sibling. Offline, ad-free, nothing collected. One card
//  at a time, every miss shows the trick, and a story builder to make things.

import SwiftUI

@main
struct LingoSproutsApp: App {
    @StateObject private var model = AppModel()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(model)
        }
    }
}

struct RootView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            switch model.screen {
            case .who: WhoView().transition(.opacity)
            case .home: HomeView().transition(.move(edge: .trailing).combined(with: .opacity))
            case .play(let id): PlayView(modeID: id).transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: model.screen)
        .tint(Theme.sprout)
    }
}
