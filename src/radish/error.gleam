import mug

pub type Error {
  RESPError
  ConnectionError
  TCPError(mug.Error)
  ServerError(String)
}
