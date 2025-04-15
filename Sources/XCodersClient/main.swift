import XCoders

//@TypeErased
protocol Box {
    associatedtype Value

    func get() -> Value
    func calculate(_ other: Value) -> Value
}

struct AnyBox<Value>: Box {
    private let _get: () -> Value
    private let _calculate: (Value) -> Value

    init<T: Box>(_ box: T) where T.Value == Value {
        _get = box.get
        _calculate = box.calculate
    }

    func get() -> Value {
        _get()
    }

    func calculate(_ other: Value) -> Value {
        _calculate(other)
    }
}
