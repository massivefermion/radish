import gleam/set

pub type Value {
  Null
  Nan
  Infinity
  Integer(Int)
  Boolean(Bool)
  Double(Float)
  NegativeInifnity
  Push(List(Value))
  BigNumber(String)
  BulkError(String)
  BulkString(String)
  Array(List(Value))
  Set(set.Set(Value))
  SimpleError(String)
  IntegerAsDouble(Int)
  SimpleString(String)
  Map(List(#(Value, Value)))
}
