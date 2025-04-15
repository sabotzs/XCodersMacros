// The Swift Programming Language
// https://docs.swift.org/swift-book

@attached(peer, names: prefixed(Any))
public macro TypeErased() = #externalMacro(module: "XCodersMacros", type: "TypeErasedMacro")
