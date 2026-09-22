//
//  StorageProvider.swift
//  NX10CoreSDK
//

import Foundation

@MainActor
public protocol SharedStorageProviding: AnyObject {
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
        public static let networkDisabledKey = "me.nx10.sdk.networkDisabledKey"
    }
    
    // MARK: - Properties
    // Default to standard storage until AppGroupID is configured
    private var storage: UserDefaults = .standard
    private var appGroupID: String?
    
    // MARK: - Initializer
    public init() {}
    
    public func setAppGroupID(_ appGroupID: String?) {
        guard let appGroupID = appGroupID, !appGroupID.isEmpty else {
            print("LOG: [StorageProvider] Warning - No App Group ID provided. Falling back to standard defaults.")
            return
        }
        
        guard let groupStorage = UserDefaults(suiteName: appGroupID) else {
            print("LOG: [StorageProvider] Error - Could not initialize UserDefaults for AppGroup: \(appGroupID)")
            return
        }
        
        self.appGroupID = appGroupID
        self.storage = groupStorage
        
        // Synchronize in-memory cache with disk state
        self.reloadFromDisk()
        print("LOG: [StorageProvider] Successfully attached App Group ID:", appGroupID)
    }
    
    /// Forces in-memory UserDefaults cache to reload from disk across processes
    public func reloadFromDisk() {
        // CFPreferencesCopyAppValue forces IPC synchronization across App Group containers
        if let appGroupID = appGroupID as CFString? {
            CFPreferencesAppSynchronize(appGroupID)
        } else {
            CFPreferencesAppSynchronize(kCFPreferencesCurrentApplication)
        }
    }
    
    // MARK: - Storage Accessors
    public var networkingEnabled: Bool {
        get {
            reloadFromDisk()
            let enabled = storage.bool(forKey: Key.networkDisabledKey)
            return enabled
        }
        set {
            storage.set(newValue, forKey: Key.networkDisabledKey)
            reloadFromDisk()
        }
    }
    
    public var allowDataCollection: Bool {
        get {
            reloadFromDisk()
            let result = storage.bool(forKey: Key.collectionKey)
            print("LOG: [StorageProvider] getting allowDataCollection: \(result)")
            return result
        }
        set {
            print("LOG: [StorageProvider] setting allowDataCollection: \(newValue)")
            storage.set(newValue, forKey: Key.collectionKey)
            reloadFromDisk()
        }
    }
    
    public var allowTrainingData: Bool {
        get {
            reloadFromDisk()
            return storage.bool(forKey: Key.trainingKey)
        }
        set {
            storage.set(newValue, forKey: Key.trainingKey)
            reloadFromDisk()
        }
    }
    
    public func clearAll() {
        storage.removeObject(forKey: Key.collectionKey)
        storage.removeObject(forKey: Key.trainingKey)
        storage.removeObject(forKey: Key.networkDisabledKey)
        reloadFromDisk()
    }
}
