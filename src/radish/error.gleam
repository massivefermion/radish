import mug

pub type Error {
  RESPError
  ActorError
  ConnectionError
  TCPError(mug.Error)
  ServerError(String)
}
