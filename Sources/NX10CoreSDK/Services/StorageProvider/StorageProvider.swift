//
//  StorageProvider.swift
//  NX10CoreSDK
//
//  Created by NX10 on 03/08/2026.
//

import Foundation

@MainActor
public protocol SharedStorageProviding {
    var allowDataCollection: Bool { get set }
    var allowTrainingData: Bool { get set }
    var isDemo: Bool { get set }
    var networkingEnabled: Bool { get set }
    
    init()
    func setAppGroupID(_ appGroupID: String?)
    func synchronise()
}

public final class SharedStorageProvider: SharedStorageProviding {
    
    // MARK: - Keys
    public enum Key {
        public static let collectionKey = "hasAcceptedDataCollectionConsent"
        public static let trainingKey = "hasAcceptedDataTrainingConsent"
        public static let demoKey = "demoKey"
        public static let networkIsDisabled = "networkDisabledKey"
    }
    
    // MARK: - Properties
    private var storage: UserDefaults?
    
    // MARK: - Initializer
    public init() {}
    
    public func setAppGroupID(_ appGroupID: String?) {
        if let appGroupID, let groupStorage = UserDefaults(suiteName: appGroupID) {
            self.storage = groupStorage
        } else {
            self.storage = .standard
        }
        
        synchronise()
    }
    
    // MARK: - Storage Accessors
    public var networkingEnabled: Bool {
        get {
            guard let storage else {
                if isDebug { fatalError("local storage not set") }
                return false
            }
            return storage.bool(forKey: Key.networkIsDisabled)
        }
        set {
            guard let storage else {
                if isDebug { fatalError("local storage not set") }
                return
            }
            storage.set(newValue, forKey: Key.networkIsDisabled)
            storage.synchronize()
        }
    }
    
    public var allowDataCollection: Bool {
        get {
            guard let storage else {
                if isDebug { fatalError("local storage not set") }
                return false
            }
            return storage.bool(forKey: Key.collectionKey)
        }
        set {
            guard let storage else {
                if isDebug { fatalError("local storage not set") }
                return
            }
            storage.set(newValue, forKey: Key.collectionKey)
            storage.synchronize()
        }
    }
    
    public var allowTrainingData: Bool {
        get {
            guard let storage else {
                if isDebug { fatalError("local storage not set") }
                return false
            }
            return storage.bool(forKey: Key.trainingKey)
        }
        set {
            guard let storage else {
                if isDebug { fatalError("local storage not set") }
                return
            }
            storage.set(newValue, forKey: Key.trainingKey)
            storage.synchronize()
        }
    }
    
    public var isDemo: Bool {
        get {
            guard let storage else {
                if isDebug { fatalError("local storage not set") }
                return false
            }
            return storage.bool(forKey: Key.demoKey)
        }
        set {
            guard let storage else {
                if isDebug { fatalError("local storage not set") }
                return
            }
            storage.set(newValue, forKey: Key.demoKey)
            storage.synchronize()
        }
    }
    
    // MARK: - Management
    public func synchronise() {
        guard let storage else {
            if isDebug { fatalError("local storage not set") }
            return
        }
        
        // Forces a sync from disk into memory
        storage.synchronize()
    }
    
    public func clearAll() {
        guard let storage else {
            if isDebug { fatalError("local storage not set") }
            return
        }
        
        storage.removeObject(forKey: Key.collectionKey)
        storage.removeObject(forKey: Key.trainingKey)
        storage.removeObject(forKey: Key.demoKey)
        storage.removeObject(forKey: Key.networkIsDisabled)
        storage.synchronize()
    }
}
