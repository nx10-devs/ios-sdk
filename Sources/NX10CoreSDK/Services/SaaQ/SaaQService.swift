//
//  SaaQService.swift
//  NX10CoreSDK
//
//  Created by NX10 on 31/03/2026.
//

@MainActor
public protocol SaaQServiceProtocol {
    func start()
    func present(prompt: SaaQTrigger.Payload)
    func present(trigger: SaaQTrigger)
    func dismiss()
    
    init(
        networkService: Networking,
        telemetryService: TelemetryService,
        promptController: SaaQPromptController,
        promptPresenter: SaaQPromptWindowPresenter
    )
}

public final class SaaQService: SaaQServiceProtocol {
    private let promptController: SaaQPromptController
    private let promptPresenter: SaaQPromptWindowPresenter
    private let networkService: Networking
    private let telemetryService: TelemetryService
    
    public init(
        networkService: Networking,
        telemetryService: TelemetryService,
        promptController: SaaQPromptController = .shared,
        promptPresenter: SaaQPromptWindowPresenter = .shared
    ) {
        self.networkService = networkService
        self.promptController = promptController
        self.promptPresenter = promptPresenter
        self.telemetryService = telemetryService
        
        // Opt in to trigger observation
        self.telemetryService.setSaaQPromptCallBack { [weak self] trigger in
            self?.present(trigger: trigger)
        }
        
        promptController.didAnswerSaaQ = { answer in
            do {
                guard
                    let url = try networkService.url(for: .saaqTriggered(version: .v1))
                else {
                    return
                }
                Task {
                    let _: GenericResponse? = try await networkService.post(answer, for: url)
                }
            } catch {
                print(error.localizedDescription)
            }
        }
    }
    
    // MARK: SwiftUI
    public func present(prompt: SaaQTrigger.Payload) {
        promptController.present(prompt: prompt)
    }
    
    public func present(trigger: SaaQTrigger) {
        promptController.present(trigger: trigger)
    }
    
    public func dismiss() {
        promptController
    }
    
    // MARK: UIKit integration necessary step
    public func start() {
        promptPresenter.start()
    }
}


