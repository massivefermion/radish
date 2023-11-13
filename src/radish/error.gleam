import mug

pub type Error {
  NotFound
  RESPError
  ActorError
  ConnectionError
  TCPError(mug.Error)
  ServerError(String)
}
