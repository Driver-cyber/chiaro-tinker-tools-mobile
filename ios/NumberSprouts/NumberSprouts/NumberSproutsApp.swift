//  NumberSproutsApp.swift — Number Sprouts: math flash cards for Chad's kids.
//  Offline, ad-free, nothing collected. One card at a time, and every miss
//  shows the trick.

import SwiftUI

@main
struct NumberSproutsApp: App {
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
            case .games: GamesView().transition(.move(edge: .trailing).combined(with: .opacity))
            case .quest: QuestView().transition(.move(edge: .trailing).combined(with: .opacity))
            case .dots: DotsView().transition(.move(edge: .trailing).combined(with: .opacity))
            case .play(let id, let picture): PlayView(modeID: id, picture: picture).transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: model.screen)
        .tint(Theme.sprout)
    }
}
