import mug

pub type Error {
  RESPError
  ActorError
  EmptyDBError
  ConnectionError
  TCPError(mug.Error)
  ServerError(String)
}
