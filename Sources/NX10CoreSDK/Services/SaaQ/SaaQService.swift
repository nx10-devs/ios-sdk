//
//  SaaQService.swift
//  NX10CoreSDK
//
//  Created by NX10 on 31/03/2026.
//

@MainActor
public protocol SaaQServiceProtocol {
    func configure()
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
    }
    
    public func configure() {
        telemetryService.setSaaQPromptCallBack { [weak self] trigger in
            self?.present(trigger: trigger)
        }
    }
    
    public func present(prompt: SaaQTrigger.Payload) {
        promptController.present(prompt: prompt)
    }
    
    public func present(trigger: SaaQTrigger) {
        promptController.present(trigger: trigger)
    }
    
    public func dismiss() {
        promptController
    }
}


