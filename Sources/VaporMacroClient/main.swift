import VaporMacro

public struct Storage {
    var storage: [ObjectIdentifier: AnyStorageValue]

    struct Value<T>: AnyStorageValue {
        var value: T
    }

    public mutating func clear() {
        self.storage = [:]
    }

    public subscript<Key>(_ key: Key.Type) -> Key.Value?
        where Key: StorageKey
    {
        get {
            self.get(Key.self)
        }
        set {
            self.set(Key.self, to: newValue)
        }
    }

    public subscript<Key>(_ key: Key.Type, default defaultValue: @autoclosure () -> Key.Value) -> Key.Value
        where Key: StorageKey
    {
        mutating get {
            if let existing = self[key] { return existing }
            let new = defaultValue()
            self.set(Key.self, to: new)
            return new
        }
    }
    
    public func contains<Key>(_ key: Key.Type) -> Bool {
        self.storage.keys.contains(ObjectIdentifier(Key.self))
    }
    public func get<Key>(_ key: Key.Type) -> Key.Value?
        where Key: StorageKey
    {
        guard let value = self.storage[ObjectIdentifier(Key.self)] as? Value<Key.Value> else {
            return nil
        }
        return value.value
    }

    public mutating func set<Key>(
        _ key: Key.Type,
        to value: Key.Value?,
        onShutdown: ((Key.Value) throws -> ())? = nil
    )
        where Key: StorageKey
    {
        let key = ObjectIdentifier(Key.self)
        if let value = value {
            self.storage[key] = Value(value: value)
        } else if self.storage[key] != nil {
            self.storage[key] = nil
        }
    }
}

protocol AnyStorageValue {
}

public protocol StorageKey {
    associatedtype Value
}


struct Application {
    var storage = Storage(storage: [:])
}


struct Service {
}

extension Application {
    
    @ApplicationStroage(on: "storage")
    var service: Service

}

print("Succeed!")
