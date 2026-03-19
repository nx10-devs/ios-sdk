//
//  NX10Core.swift
//  NX10CoreSDK
//
//  Created by NX10 on 19/03/2026.
//

@MainActor
public protocol NX10Coring {
    var shared: NX10Core { get }
    init()
}

final public class NX10Core {
    
    @MainActor public static var shared = NX10Core()
//    // MARK: Internal properties
//    let telemetry: TelemetryManager
//    
//    // MARK: Private properties
//    let telemetryHandler: TelemetryHandling
//    private let errorService: ErrorServicing
//    private let accessManagementService: AccessManagementServicing
//    public var didStartSentry = false

    init () {
        
    }
}
