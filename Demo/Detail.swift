import ComposableArchitecture
import SwiftUI
import Combine

struct DetailState: Equatable {
    var time: Int = 0
    var me: AvatarState = AvatarState()
    var peer = AvatarState()
}

enum DetailAction: Equatable {
    case timerTicked
    case me(AvatarAction)
    case peer(AvatarAction)
    case onAppear
    case onDisappear
}

struct TimerId: Hashable {}

struct DetailEnvironment {
    var cancellationId: AnyHashable
}

let detailReducer = Reducer<DetailState, DetailAction, DetailEnvironment>.combine(
    avatarReducer.pullback(
        state: \.me,
        action: /DetailAction.me,
        environment: { env in
            struct Cancellation: Hashable {}
            return AvatarEnvironment(cancellationId: Cancellation())
        }
    ),
    avatarReducer.pullback(
        state: \.peer,
        action: /DetailAction.peer,
        environment: { env in
            struct Cancellation: Hashable {}
            return AvatarEnvironment(cancellationId: Cancellation())
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
            
        case .onAppear:
            return Publishers.Timer(
                every: 1,
                tolerance: .zero,
                scheduler: DispatchQueue.main,
                options: nil
            )
            .autoconnect()
            .handleEvents(receiveSubscription: { (sub) in
                print("receiveSubscription")
            }, receiveOutput: { (output) in
                print("receiveOutput")
            }, receiveCompletion: { (completion) in
                print("receiveCompletion")
            }, receiveCancel: {
                print("receiveCancel")
            }, receiveRequest: { (demand) in
                print("receiveRequest")
            })
            .catchToEffect()
            .map { _ in DetailAction.timerTicked }
            
        case .onDisappear:
            return .none
        }
    }
)

struct DetailView: View {
    let store: Store<DetailState, DetailAction>

    var body: some View {
        WithViewStore(store) { viewStore in
            VStack {
                VStack {
                    AvatarView(
                        store: self.store.scope(
                            state: \.me,
                            action: { .me($0) },
                            cancellationId: [store.cancellationId, "me"]
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
                            state: \.peer,
                            action: { .peer($0) },
                            cancellationId: [store.cancellationId, "peer"]
                        )
                    )
                    Text("Peer").font(.title)
                }
            }.onAppear {
                viewStore.send(.onAppear)
            }.onDisappear {
                viewStore.cancelAll()
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
