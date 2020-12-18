import ComposableArchitecture
import SwiftUI

struct AppState: Equatable {
    var detail: DetailState?
    var detail2: DetailState? = DetailState()
    var isPresentingDetail: Bool = false
}

enum AppAction {
    case presentDetail
    case dismissDetail
    case detail(DetailAction)
    case detail2(DetailAction)
}

let appReducer = Reducer<AppState, AppAction, Void>.combine(
    detailReducer.optional().pullback(
        state: \.detail,
        action: /AppAction.detail,
        environment: { _ in
            struct Cancellation: Hashable {}
            return DetailEnvironment(cancellationId: Cancellation())
        }
    ),
    detailReducer.optional().pullback(
        state: \.detail2,
        action: /AppAction.detail2,
        environment: { _ in
            struct Cancellation: Hashable {}
            return DetailEnvironment(cancellationId: Cancellation())
        }
    ),
    Reducer { state, action, _ in
        switch action {
        case .presentDetail:
            state.detail = .init()
            state.isPresentingDetail = true
            return .none

        case .dismissDetail:
            state.isPresentingDetail = false
            return .none
            
        case .detail(.onDisappear):
            state.detail = nil
            return .none

        case .detail(_):
            return .none
            
        case .detail2(_):
            return .none
        }
    }
)

struct AppView: View {
    let store: Store<AppState, AppAction>

    var body: some View {
        WithViewStore(store) { viewStore in
            VStack(spacing: 16) {
                Text("App").font(.title).padding(.top, 100)
                if viewStore.isPresentingDetail {
                    Button(action: { viewStore.send(.dismissDetail) }) {
                        Text("Dismiss Detail")
                    }
                } else {
                    Button(action: { viewStore.send(.presentDetail) }) {
                        Text("Present Detail")
                    }
                }
                
                if viewStore.isPresentingDetail {
                    IfLetStore(self.store.scope(
                        state: \.detail,
                        action: AppAction.detail,
                        cancellationId: "testings"
                    )) { detailStore in
                        DetailView(store: detailStore) 
                    }
                }
                
                    IfLetStore(self.store.scope(
                        state: \.detail2,
                        action: AppAction.detail2
                    )) { detailStore in
                        DetailView(store: detailStore)
                    }
                Spacer()
            }
        }
    }
}

#if DEBUG
struct AppView_Previews: PreviewProvider {
    static var previews: some View {
        AppView(store: Store(
            initialState: .init(),
            reducer: .empty,
            environment: ()
        ))
    }
}
#endif
