//  QuestView.swift — Math Quest: pick a buddy, follow the map, read a little
//  story at each stop, then battle. The foe sits top right, the buddy bottom
//  left; a move lunges, its blast flies across, and the one it hits shakes and
//  flashes. A right answer on the foe's turn dodges; on the buddy's turn it
//  lands the move. Nothing here ever ends the quest: a tired buddy rests and
//  tries the battle again. Logic lives in QuestMath.swift.

import SwiftUI

struct QuestView: View {
    @EnvironmentObject private var model: AppModel
    enum Stage: Equatable { case map, story(Int, page: Int), battle(Int), done }
    @State private var stage: Stage = .map
    @State private var picking = false

    private var save: QuestSave { model.current?.quest ?? QuestSave() }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                CircleButton(symbol: stage == .map ? "chevron.left" : "map.fill", label: stage == .map ? "Home" : "Map") {
                    if stage == .map { model.screen = .home } else { stage = .map }
                }
                Text(title).font(Theme.round(26)).foregroundStyle(Theme.text).lineLimit(1).minimumScaleFactor(0.6)
                Spacer()
                PlayerBadge()
            }
            if let buddy = Quest.buddy(save.buddy), !picking {
                switch stage {
                case .map: map(buddy)
                case .story(let i, let page): story(Quest.stops[i], page: page, buddy: buddy)
                case .battle(let i): BattleView(stop: Quest.stops[i], buddy: buddy, level: save.cleared + 1) { won in
                    if won { model.saveQuest { $0.cleared = max($0.cleared, i + 1) } }
                    stage = won && i == Quest.stops.count - 1 ? .done : .map
                }.id(i)
                case .done: finale(buddy)
                }
            } else {
                picker
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .animation(.easeInOut(duration: 0.25), value: stage)
    }

    private var title: String {
        switch stage {
        case .map, .done: return "Math Quest"
        case .story(let i, _), .battle(let i): return Quest.stops[i].place
        }
    }

    // MARK: Pick a buddy

    private var picker: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Pick a buddy to go on the quest with you!").font(Theme.round(20, .bold)).foregroundStyle(Theme.muted)
            ForEach(Quest.buddies) { b in
                Button {
                    model.saveQuest { $0.buddy = b.id }; picking = false; stage = .map; Haptics.right()
                } label: {
                    HStack(spacing: 16) {
                        Text(b.emoji).font(.system(size: 54)).frame(width: 76, height: 76)
                            .background(Theme.bg, in: RoundedRectangle(cornerRadius: 20))
                        VStack(alignment: .leading, spacing: 4) {
                            Text(b.name).font(Theme.round(24)).foregroundStyle(Theme.text)
                            Text("A \(b.kind). Moves: \(b.moves.joined(separator: ", "))").font(Theme.round(15, .semibold)).foregroundStyle(Theme.muted)
                        }
                        Spacer(minLength: 0)
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Theme.card, in: RoundedRectangle(cornerRadius: 26))
                    .overlay(RoundedRectangle(cornerRadius: 26).stroke(save.buddy == b.id ? Theme.sprout : Theme.border, lineWidth: save.buddy == b.id ? 3 : 2))
                }
                .buttonStyle(.plain)
            }
            Spacer()
        }
    }

    // MARK: Map

    private func map(_ buddy: Buddy) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    Text(buddy.emoji).font(.system(size: 44))
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(buddy.name) · Level \(save.cleared + 1)").font(Theme.round(20)).foregroundStyle(Theme.text)
                        Text(save.cleared >= Quest.stops.count ? "The Wishing Star is home! Battle again anytime." : "Bring the Wishing Star home!")
                            .font(Theme.round(15, .semibold)).foregroundStyle(Theme.muted)
                    }
                    Spacer()
                    Button("Change") { picking = true }.font(Theme.round(15, .bold)).foregroundStyle(Theme.muted)
                }
                ForEach(Quest.stops) { s in
                    let open = s.id <= save.cleared, beaten = s.id < save.cleared, next = s.id == save.cleared
                    Button { stage = .story(s.id, page: 0); Haptics.tick() } label: {
                        HStack(spacing: 14) {
                            Text(open ? s.foe.emoji : "🔒").font(.system(size: 36)).frame(width: 60, height: 60)
                                .background(Theme.bg, in: Circle())
                            VStack(alignment: .leading, spacing: 2) {
                                Text("\(s.id + 1). \(s.place)").font(Theme.round(20)).foregroundStyle(Theme.text)
                                Text(!open ? "Win the last battle to get here" : s.foe.boss ? "BOSS: \(s.foe.name)" : s.foe.name)
                                    .font(Theme.round(15, .bold)).foregroundStyle(s.foe.boss && open ? Theme.odd : Theme.muted)
                            }
                            Spacer(minLength: 0)
                            if beaten { Image(systemName: "checkmark.circle.fill").font(.system(size: 28)).foregroundStyle(Theme.sprout) }
                            else if next { Text("GO").font(Theme.round(17)).foregroundStyle(Theme.onColor).padding(.horizontal, 14).padding(.vertical, 8).background(Theme.sprout, in: Capsule()) }
                        }
                        .padding(12)
                        .background(Theme.card, in: RoundedRectangle(cornerRadius: 22))
                        .overlay(RoundedRectangle(cornerRadius: 22).stroke(next ? Theme.sprout : Theme.border, lineWidth: next ? 3 : 2))
                        .opacity(open ? 1 : 0.55)
                    }
                    .buttonStyle(.plain)
                    .disabled(!open)
                }
            }
            .padding(.bottom, 20)
        }
    }

    // MARK: Story

    private func story(_ s: QuestStop, page: Int, buddy: Buddy) -> some View {
        let last = page >= s.story.count - 1
        return VStack(spacing: 18) {
            Spacer(minLength: 0)
            Text(s.scenery).font(.system(size: 64))
            Text(s.story[min(page, s.story.count - 1)].replacingOccurrences(of: "{buddy}", with: buddy.name))
                .font(Theme.round(24, .bold)).foregroundStyle(Theme.text).multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .id(page)
                .transition(.opacity)
            Spacer(minLength: 0)
            Button {
                stage = last ? .battle(s.id) : .story(s.id, page: page + 1); Haptics.tick()
            } label: { Label(last ? (s.foe.boss ? "Boss battle!" : "Battle!") : "Next", systemImage: last ? "bolt.fill" : "arrow.right") }
            .buttonStyle(BigButtonStyle())
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, 16)
    }

    // MARK: Finale

    private func finale(_ buddy: Buddy) -> some View {
        VStack(spacing: 18) {
            Spacer(minLength: 0)
            Text("⭐").font(.system(size: 110))
            Text("You and \(buddy.name) brought the Wishing Star home!").font(Theme.round(28)).foregroundStyle(Theme.text).multilineTextAlignment(.center)
            Text("Sprout Hollow throws a party, and Smokewing comes too.").font(Theme.round(18, .bold)).foregroundStyle(Theme.muted).multilineTextAlignment(.center)
            Text("🎉 \(buddy.emoji) 🐸 🦉 🐻 🦇 🐐 🐉 🎉").font(.system(size: 30))
            Spacer(minLength: 0)
            Button("Back to the map") { stage = .map }.buttonStyle(BigButtonStyle())
        }
        .padding(.bottom, 16)
    }
}

// MARK: - Battle

private struct BattleView: View {
    @StateObject private var battle: Battle
    let level: Int
    let finish: (Bool) -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var foeLunge = false
    @State private var buddyLunge = false
    @State private var buddyDodge = false
    @State private var foeDodge = false
    @State private var foeShakes: CGFloat = 0
    @State private var buddyShakes: CGFloat = 0
    @State private var foeFlash = false
    @State private var buddyFlash = false
    @State private var shot: (emoji: String, fromFoe: Bool, hits: Bool)?
    @State private var shotOut = false
    @State private var bursts = 0
    @State private var busy = false

    init(stop: QuestStop, buddy: Buddy, level: Int, finish: @escaping (Bool) -> Void) {
        _battle = StateObject(wrappedValue: Battle(stop: stop, buddy: buddy))
        self.level = level; self.finish = finish
    }

    var body: some View {
        VStack(spacing: 12) {
            arena
            messageBox
            switch battle.phase {
            case .intro:
                Button { battle.begin(); Haptics.tick() } label: { Label("Fight!", systemImage: "bolt.fill") }.buttonStyle(BigButtonStyle())
            case .asking:
                answers
            case .result:
                Button { withAnimation { battle.next() } } label: { Label("Next", systemImage: "arrow.right") }.buttonStyle(BigButtonStyle()).disabled(busy)
            case .won:
                Button { finish(true) } label: { Label("Onward!", systemImage: "flag.fill") }.buttonStyle(BigButtonStyle())
            case .lost:
                Button { battle.restart() } label: { Label("Rest and try again", systemImage: "arrow.counterclockwise") }.buttonStyle(BigButtonStyle())
                Button("Back to the map") { finish(false) }.buttonStyle(SoftButtonStyle())
            }
            Spacer(minLength: 0)
        }
        .padding(.bottom, 8)
        .overlay { if !reduceMotion { Burst(trigger: bursts).allowsHitTesting(false) } }
        .onChange(of: battle.phase) { p in if p == .won { bursts += 1; Haptics.right() } }
    }

    // MARK: Arena

    private var arena: some View {
        GeometryReader { g in
            let foeAt = CGPoint(x: g.size.width * 0.74, y: g.size.height * 0.36)
            let buddyAt = CGPoint(x: g.size.width * 0.24, y: g.size.height * 0.68)
            ZStack(alignment: .topLeading) {
                Text(battle.stop.scenery).font(.system(size: 40)).opacity(0.35)
                    .position(x: g.size.width / 2, y: g.size.height - 26)
                plate(name: battle.stop.foe.name, sub: battle.stop.foe.boss ? "BOSS" : nil, hp: battle.foeHP, of: battle.stop.foe.hp, heart: false)
                    .position(x: g.size.width * 0.3, y: 44)
                plate(name: battle.buddy.name, sub: "Lv \(level)", hp: battle.buddyHP, of: Battle.hearts, heart: true)
                    .position(x: g.size.width * 0.7, y: g.size.height - 70)
                creature(battle.stop.foe.emoji, size: battle.stop.foe.boss ? 104 : 88, flash: foeFlash)
                    .scaleEffect(battle.phase == .won ? 0.2 : 1).opacity(battle.phase == .won ? 0 : 1)
                    .modifier(Shake(amount: 12, animatableData: foeShakes))
                    .offset(x: foeLunge ? -36 : (foeDodge ? 40 : 0), y: foeLunge ? 24 : (foeDodge ? -18 : 0))
                    .position(foeAt)
                creature(battle.buddy.emoji, size: 88, flash: buddyFlash)
                    .scaleEffect(x: -1, y: 1)                    // faces the foe
                    .modifier(Shake(amount: 12, animatableData: buddyShakes))
                    .offset(x: buddyLunge ? 36 : (buddyDodge ? -44 : 0), y: buddyLunge ? -24 : (buddyDodge ? -30 : 0))
                    .position(buddyAt)
                if let shot {
                    let from = shot.fromFoe ? foeAt : buddyAt
                    let to = shot.fromFoe ? buddyAt : foeAt
                    let miss = CGPoint(x: to.x + (shot.fromFoe ? -90 : 90), y: to.y - 70)
                    let end = shot.hits ? to : miss
                    Text(shot.emoji).font(.system(size: 44))
                        .position(shotOut ? end : from)
                        .opacity(shotOut ? 0.9 : 0)
                        .scaleEffect(shotOut ? 1.3 : 0.6)
                }
            }
        }
        .frame(height: 290)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 26))
        .overlay(RoundedRectangle(cornerRadius: 26).stroke(battle.stop.foe.boss ? Theme.odd : Theme.border, lineWidth: battle.stop.foe.boss ? 3 : 2))
        .clipShape(RoundedRectangle(cornerRadius: 26))
        .accessibilityElement()
        .accessibilityLabel("\(battle.stop.foe.name) has \(battle.foeHP) of \(battle.stop.foe.hp) left. \(battle.buddy.name) has \(battle.buddyHP) hearts.")
    }

    private func creature(_ emoji: String, size: CGFloat, flash: Bool) -> some View {
        Text(emoji).font(.system(size: size))
            .colorMultiply(flash ? Color(red: 1, green: 0.45, blue: 0.45) : .white)
    }

    private func plate(name: String, sub: String?, hp: Int, of total: Int, heart: Bool) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Text(name).font(Theme.round(17)).foregroundStyle(Theme.text)
                if let sub { Text(sub).font(Theme.round(12, .bold)).foregroundStyle(sub == "BOSS" ? Theme.odd : Theme.muted) }
            }
            HStack(spacing: 3) {
                ForEach(0..<total, id: \.self) { i in
                    Image(systemName: heart ? (i < hp ? "heart.fill" : "heart") : (i < hp ? "circle.fill" : "circle"))
                        .font(.system(size: heart ? 15 : 12, weight: .bold))
                        .foregroundStyle(i < hp ? (heart ? Color(red: 0.93, green: 0.3, blue: 0.35) : Theme.sprout) : Theme.muted.opacity(0.5))
                }
            }
        }
        .padding(.horizontal, 12).padding(.vertical, 8)
        .background(Theme.bg, in: RoundedRectangle(cornerRadius: 14))
        .animation(.spring(response: 0.35, dampingFraction: 0.6), value: hp)
    }

    // MARK: Words and answers

    private var messageBox: some View {
        VStack(spacing: 8) {
            Text(battle.message)
                .font(Theme.round(19, .bold)).foregroundStyle(Theme.text).multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            if battle.phase == .asking {
                Text("\(battle.problem.text) = ?").font(Theme.round(44)).foregroundStyle(battle.turn == .dodge ? Theme.odd : Theme.sprout)
            } else if case .result(false) = battle.phase {
                Text(battle.problem.trick).font(Theme.round(16, .semibold)).foregroundStyle(Theme.muted).multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 96)
        .padding(.horizontal, 6)
        .animation(.easeInOut(duration: 0.2), value: battle.phase)
    }

    private var answers: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
            ForEach(battle.problem.options, id: \.self) { v in
                Button { pick(v) } label: {
                    Text("\(v)").font(Theme.round(34)).foregroundStyle(Theme.text)
                        .frame(maxWidth: .infinity, minHeight: 64)
                        .background(Theme.card, in: RoundedRectangle(cornerRadius: 20))
                        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Theme.border, lineWidth: 2))
                }
                .buttonStyle(.plain)
                .disabled(busy)
            }
        }
    }

    /// Plays the move, then scores it: the foe's blast is dodged or lands; the buddy's lands or flies wide.
    private func pick(_ v: Int) {
        guard !busy else { return }
        let right = v == battle.problem.answer
        let foeTurn = battle.turn == .dodge
        let hits = foeTurn ? !right : right
        if reduceMotion { battle.answer(v); if right { Haptics.right() } else { Haptics.miss() }; return }
        busy = true
        Haptics.tick()
        shot = (foeTurn ? battle.stop.foe.blast : battle.buddy.blast, foeTurn, hits)
        shotOut = false
        withAnimation(.easeOut(duration: 0.18)) { if foeTurn { foeLunge = true } else { buddyLunge = true } }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
            withAnimation(.easeOut(duration: 0.18)) { foeLunge = false; buddyLunge = false }
            if foeTurn && right { withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) { buddyDodge = true } }
            if !foeTurn && !right { withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) { foeDodge = true } }
            withAnimation(.easeIn(duration: 0.38)) { shotOut = true }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.58) {
            withAnimation { battle.answer(v) }
            shot = nil
            if hits {
                if foeTurn { buddyFlash = true; withAnimation(.linear(duration: 0.4)) { buddyShakes += 1 }; Haptics.miss() }
                else { foeFlash = true; withAnimation(.linear(duration: 0.4)) { foeShakes += 1 }; Haptics.right() }
            } else if right { Haptics.right() }
            withAnimation(.spring(response: 0.35, dampingFraction: 0.6)) { buddyDodge = false; foeDodge = false }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.95) {
            foeFlash = false; buddyFlash = false; busy = false
        }
    }
}
