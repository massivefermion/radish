import gleam/result
import mug

pub fn connect(host: String, port: Int, timeout: Int) {
  mug.connect(mug.ConnectionOptions(host, port, timeout))
}

pub fn execute(socket: mug.Socket, packet: BitArray, timeout: Int) {
  use _ <- result.then(mug.send(socket, packet))
  mug.receive(socket, timeout)
}
