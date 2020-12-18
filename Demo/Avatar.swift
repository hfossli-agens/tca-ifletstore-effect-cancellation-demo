import ComposableArchitecture
import Combine
import SwiftUI

struct AvatarState: Equatable {
    var image: UIImage?
    var error: AvatarError?
}

enum AvatarAction: Equatable {
    case onAppear
    case onDisappear
    case load
    case loaded(String)
    case failed(AvatarError)
}

enum AvatarError: Error, Equatable {
    case network
}

struct AvatarEnvironment {
    var cancellationId: AnyHashable
}

let avatarReducer = Reducer<AvatarState, AvatarAction, AvatarEnvironment> { state, action, env in
    
    struct Cancellation: Hashable {}
    
    switch action {
    
    case .load:
        return Just("faceid")
            .map { AvatarAction.loaded($0) }
            .replaceError(with: AvatarAction.failed(.network))
            .delay(for: .seconds(1), scheduler: DispatchQueue.main)
            .handleEvents(receiveSubscription: { (sub) in
                print("receiveSubscription avatar")
            }, receiveOutput: { (output) in
                print("receiveOutput avatar")
            }, receiveCompletion: { (completion) in
                print("receiveCompletion avatar")
            }, receiveCancel: {
                print("receiveCancel avatar")
            }, receiveRequest: { (demand) in
                print("receiveRequest avatar")
            })
            .eraseToEffect()
            .cancellable(id: env.cancellationId)
        
    case .loaded(let name):
        state.image = UIImage(systemName: name)
        return .none
        
    case .failed(let error):
        state.error = error
        return .none
        
    case .onAppear:
        return .init(value: .load)
        
    case .onDisappear:
        return .cancel(id: env.cancellationId)
    }
}

struct AvatarView: View {
    let store: Store<AvatarState, AvatarAction>
    
    var body: some View {
        WithViewStore(store) { viewStore in
            VStack(spacing: 16) {
                if let _ = viewStore.error {
                    Image(systemName: "person.crop.circle.badge.xmark")
                } else if let image = viewStore.image {
                    Image(uiImage: image)
                } else {
                    Image(systemName: "clock")
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
struct AvatarView_Previews: PreviewProvider {
    static var previews: some View {
        DetailView(store: Store(
            initialState: .init(),
            reducer: .empty,
            environment: ()
        ))
    }
}
#endif
