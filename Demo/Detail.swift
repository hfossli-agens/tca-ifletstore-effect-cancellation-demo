import ComposableArchitecture
import SwiftUI

struct DetailState: Equatable {
    var time: Int = 0
    var me: AvatarState = AvatarState()
    var peer = AvatarState()
}

enum DetailAction: Equatable {
    case timerTicked
    case me(AvatarAction)
    case peer(AvatarAction)
}

struct GenericCancellationId: Hashable {
    var parent: AnyHashable?
    var current: AnyHashable
}

struct DetailEnvironment {
    var cancellationId: AnyHashable
    
    var timerID: AnyHashable {
        struct TimerID: Hashable {}
        return GenericCancellationId(parent: cancellationId, current: TimerID())
    }
    
    var meEnv: AvatarEnvironment {
        struct MeID: Hashable {}
        return AvatarEnvironment(
            cancellationId: GenericCancellationId(parent: cancellationId, current: MeID())
        )
    }
    
    var peerEnv: AvatarEnvironment {
        struct PeerID: Hashable {}
        return AvatarEnvironment(
            cancellationId: GenericCancellationId(parent: cancellationId, current: PeerID())
        )
    }
}

let detailReducer = Reducer<DetailState, DetailAction, DetailEnvironment>.combine(
    avatarReducer.pullback(
        state: \.me,
        action: /DetailAction.me,
        environment: { env in
            return env.meEnv
        }
    ),
    avatarReducer.pullback(
        state: \.peer,
        action: /DetailAction.peer,
        environment: { env in
            return env.peerEnv
        }
    ),
    Reducer { state, action, _ in
        switch action {
        case .timerTicked:
            state.time += 1
            return .none
            
        case .me(_):
            return .none
            
        case .peer(_):
            return .none
        }
    }
)
.lifecycle(onAppear: { env in
    Effect.timer(id: env.timerID, every: 1, tolerance: .zero, on: DispatchQueue.main)
        .map { _ in DetailAction.timerTicked }
}, onDisappear: { env in
    return Effect.concatenate(
        .cancel(id: env.timerID),
        .cancel(id: env.meEnv.cancellationId),
        .cancel(id: env.peerEnv.cancellationId)
    )
})

struct DetailView: View {
    let store: Store<DetailState, LifecycleAction<DetailAction>>

    var body: some View {
        WithViewStore(store) { viewStore in
            VStack {
                VStack {
                    AvatarView(
                        store: self.store.scope(
                            state: \.me,
                            action: { .action(DetailAction.me($0)) }
                        )
                    )
                    Text("Me").font(.title)
                }
                
                HStack {
                    Image(systemName: "waveform")
                    Text("Talking for \(viewStore.time) seconds")
                }
                
                VStack {
                    AvatarView(
                        store: self.store.scope(
                            state: \.me,
                            action: { .action(DetailAction.me($0)) }
                        )
                    )
                    Text("Peer").font(.title)
                }
            }.onAppear {
                viewStore.send(.onAppear)
            }.onDisappear {
                viewStore.send(.onDisappear)
            }
        }
    }
}

#if DEBUG
struct DetailView_Previews: PreviewProvider {
    static var previews: some View {
        DetailView(store: Store(
            initialState: .init(),
            reducer: .empty,
            environment: ()
        ))
    }
}
#endif

