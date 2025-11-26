import Foundation
import Combine

@MainActor
final class RoutineStore: ObservableObject {
    @Published var routines: [Routine] = []
    
    func add(_ routine: Routine) {
        routines.append(routine)
    }
}
