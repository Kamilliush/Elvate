import Foundation
import Combine

@MainActor
final class RoutineStore: ObservableObject {
    @Published var routines: [Routine] = []
    
    func add(_ routine: Routine) {
        routines.append(routine)
    }
    
    func update(_ routine: Routine) {
        if let dbId = routine.dbId, let idx = routines.firstIndex(where: { $0.dbId == dbId }) {
            routines[idx] = routine
        } else if let idx = routines.firstIndex(where: { $0.name == routine.name }) {
            // fallback by name if dbId missing
            routines[idx] = routine
        }
    }
    
    func remove(byDbId dbId: String) {
        routines.removeAll { $0.dbId == dbId }
    }
}

