//
//  SaaQService.swift
//  NX10CoreSDK
//
//  Created by NX10 on 31/03/2026.
//

import Foundation

public struct SaaQAnswerWrapper {
    let saaqOneAnswer: SaaQOneAnswer?
    let saaqTwoAnswer: SaaQTwoAnswer?
    
    public init(saaqOneAnswer: SaaQOneAnswer? = nil, saaqTwoAnswer: SaaQTwoAnswer? = nil) {
        self.saaqOneAnswer = saaqOneAnswer
        self.saaqTwoAnswer = saaqTwoAnswer
    }
}

public struct SaaQTriggerWrapper {
    let saaqOneTrigger: SaaQOneTrigger?
    let saaqTwoTrigger: SaaQTwoTrigger?
    
    public init(saaqOneTrigger: SaaQOneTrigger? = nil, saaqTwoTrigger: SaaQTwoTrigger? = nil) {
        self.saaqOneTrigger = saaqOneTrigger
        self.saaqTwoTrigger = saaqTwoTrigger
    }
}

@MainActor
public protocol SaaQServiceProtocol {
    func start()
    func present(prompt: SaaQTriggerWrapper)
    func present(trigger: SaaQTriggerWrapper)
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
                Task(name: "saaq-task", priority: .utility) {
                    if let answerOne = answer.saaqOneAnswer {
                        let _: GenericResponse? = try await networkService.post(answerOne, for: .saaqTriggered)
                    }
                    
                    if let answerTwo = answer.saaqTwoAnswer {
                        let _: GenericResponse? = try await networkService.post(answerTwo, for: .saaqTriggered)
                    }
                }
            } catch {
                print(error.localizedDescription)
            }
        }
    }
    
    // MARK: SwiftUI
    public func present(prompt: SaaQTriggerWrapper) {
        promptController.present(prompt: prompt)
    }
    
    public func present(trigger: SaaQTriggerWrapper) {
        promptController.present(trigger: trigger)
    }
    
    public func dismiss() {
        
    }
    
    // MARK: UIKit integration necessary step
    public func start() {
        promptPresenter.start()
    }
}


