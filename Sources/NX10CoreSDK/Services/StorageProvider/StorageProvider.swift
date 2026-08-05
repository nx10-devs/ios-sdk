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
    var networkingEnabled: Bool { get set }
    
    init()
    func setAppGroupID(_ appGroupID: String?)
}

public final class SharedStorageProvider: SharedStorageProviding {
    
    // MARK: - Keys
    public enum Key {
        public static let collectionKey = "me.nx10.sdk.hasAcceptedDataCollectionConsent"
        public static let trainingKey = "me.nx10.sdk.hasAcceptedDataTrainingConsent"
        public static let networkIsDisabled = "me.nx10.sdk.networkDisabledKey"
    }
    
    // MARK: - Properties
    private var storage: UserDefaults?
    
    // MARK: - Initializer
    public init() {}
    
    public func setAppGroupID(_ appGroupID: String?) {
        guard
            let appGroupID
        else {
            if isDebug {
                fatalError("appGroupID not set")
            }
            return
        }
        
        let groupStorage = UserDefaults(suiteName: appGroupID)
        self.storage = groupStorage
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
    
    public func clearAll() {
        guard let storage else {
            if isDebug { fatalError("local storage not set") }
            return
        }
        
        storage.removeObject(forKey: Key.collectionKey)
        storage.removeObject(forKey: Key.trainingKey)
        storage.removeObject(forKey: Key.networkIsDisabled)
        storage.synchronize()
    }
}
