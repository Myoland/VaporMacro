// The Swift Programming Language
// https://docs.swift.org/swift-book

import Foundation

@attached(accessor)
@attached(peer, names: arbitrary)
public macro ApplicationStroage(on storage:String) = #externalMacro(module: "MacroKit", type: "ApplicationStroageMacro")
