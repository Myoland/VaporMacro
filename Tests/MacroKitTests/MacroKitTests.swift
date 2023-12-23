import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest
import MacroKit

let testMacros: [String: Macro.Type] = [
    "ApplicationStorage": ApplicationStroageMacro.self,
]

final class MacroKitTests: XCTestCase {
    func testMacro() {
        assertMacroExpansion(
            """
            struct Service {
            }
            
            extension Application {
                @ApplicationStorage(on: "storage")
                var service: Service
            }
            """,
            expandedSource: 
            """
            struct Service {
            }

            extension Application {
                var service: Service {
                    get {
                        guard let client = self.storage[ServiceStorageKey.self] else {
                            fatalError("Service not setup.")
                        }
                        return client
                    }
                    set {
                        self.storage.set(ServiceStorageKey.self, to: newValue)
                    }
                }
                struct ServiceStorageKey: StorageKey {
                    public typealias Value = Service
                }
            }
            """,
            macros: testMacros
        )
    }
}
