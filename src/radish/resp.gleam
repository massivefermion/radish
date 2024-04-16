import gleam/dict
import gleam/set

pub type Value {
  Nan
  Null
  Infinity
  Integer(Int)
  Boolean(Bool)
  Double(Float)
  BigNumber(Int)
  NegativeInfinity
  Push(List(Value))
  BulkError(String)
  BulkString(String)
  Array(List(Value))
  Set(set.Set(Value))
  SimpleError(String)
  IntegerAsDouble(Int)
  SimpleString(String)
  Map(dict.Dict(Value, Value))
}
