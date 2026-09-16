import Foundation

// MARK: - Events Protocol & Provider
@MainActor
public protocol EventsProviding {
    func sendEvent(_ eventName: String)
    func sendEvent(_ eventName: String, with data: [String: Any])
    func sendOutcomeEvent(_ eventName: String, with outcome: String, and data: [String: Any])
}

public class EventsProvider: EventsProviding {
    private let networkService: Networking
    private let errorProvider: ErrorProviding

    required public init(networkService: Networking, errorProvider: ErrorProviding) {
        self.networkService = networkService
        self.errorProvider = errorProvider
    }
    
    public func sendEvent(_ event: String) {
        let customEvent = EventsProvider.Event(eventName: event)
        dispatch(event: customEvent)
    }
    
    public func sendEvent(_ event: String, with data: [String: Any]) {
        let customEvent = EventsProvider.Event(eventName: event, data: data)
        dispatch(event: customEvent)
    }
    
    public func sendOutcomeEvent(_ eventName: String, with outcome: String, and data: [String : Any]) {
        let event = EventsProvider.Event(eventName: eventName, outcome: outcome, data: data)
        
        Task(name: "events-task", priority: .utility) {
            do {
                guard let data = self.networkService.encode(event) else {
                    print("Failed to encode event")
                    if isDebug { fatalError("Encoding failure for event: \(event.eventName)") }
                    return
                }
                
                let _: GenericResponse? = try await self.networkService.POST(
                    .init(data: data),
                    for: .api(.events),
                    for: nil
                )
            } catch {
                self.errorProvider.sendError(error)
            }
        }
    }
    
    private func dispatch(event: EventsProvider.Event) {
        Task(name: "events-task", priority: .utility) {
            do {
                guard let data = self.networkService.encode(event) else {
                    print("Failed to encode event")
                    if isDebug { fatalError("Encoding failure for event: \(event.eventName)") }
                    return
                }
                
                let _: GenericResponse? = try await self.networkService.POST(
                    .init(data: data),
                    for: .api(.events),
                    for: nil
                )
            } catch {
                self.errorProvider.sendError(error)
            }
        }
    }
}
