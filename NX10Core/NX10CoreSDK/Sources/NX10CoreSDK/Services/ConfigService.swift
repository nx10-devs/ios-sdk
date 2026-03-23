import Foundation

@MainActor
public final class ConfigService {
    
    private let configFileName = "NX10CoreConfig"
    private let queue = DispatchQueue(label: "com.nx10.core.config-service")
    private var cached: [String: Any]? = nil

    init() {}
    
    private func moduleBundle() -> Bundle {
        #if SWIFT_PACKAGE
        return Bundle.module
        #else
        // Fallback for when compiled into an app/framework target.
        return Bundle.main
        #endif
    }

    private func loadPlistIfNeeded() {
        if cached != nil { return }
        queue.sync {
            if self.cached != nil { return }
            let bundle = self.moduleBundle()
            guard let url = bundle.url(forResource: configFileName, withExtension: "plist"),
                  let data = try? Data(contentsOf: url),
                  let plist = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any] else {
                self.cached = [:]
                return
            }
            self.cached = plist
        }
    }

    private func value(forKey key: String) -> Any? {
        loadPlistIfNeeded()
        return cached?[key]
    }

    public func string(for key: ConfigConstants) -> String? {
        guard let string = value(forKey: key.string) as? String else {
            if isDebug {
                fatalError("Wrong format for key")
            }
            return nil
        }
        return string
    }

    public func bool(for key: ConfigConstants) -> Bool? {
        if let b = value(forKey: key.string) as? Bool { return b }
        if let s = value(forKey: key.string) as? String { return (s as NSString).boolValue }
        if let n = value(forKey: key.string) as? NSNumber { return n.boolValue }
        return nil
    }

    public func double(for key: String) -> Double? {
        if let d = value(forKey: key) as? Double { return d }
        if let s = value(forKey: key) as? String { return Double(s) }
        if let n = value(forKey: key) as? NSNumber { return n.doubleValue }
        return nil
    }

    public func int(for key: String) -> Int? {
        if let i = value(forKey: key) as? Int { return i }
        if let s = value(forKey: key) as? String { return Int(s) }
        if let n = value(forKey: key) as? NSNumber { return n.intValue }
        return nil
    }

    public func url(for key: ConfigConstants) -> URL? {
        if let s = string(for: key) { return URL(string: s) }
        return nil
    }
}
