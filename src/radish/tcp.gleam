import gleam/result
import gleam/erlang/process
import mug

pub fn connect(host: String, port: Int, timeout: Int) {
  mug.connect(mug.ConnectionOptions(host, port, timeout))
}

pub fn send(socket: mug.Socket, packet: BitArray) {
  mug.send(socket, packet)
}

pub fn new_selector() {
  process.new_selector()
  |> mug.selecting_tcp_messages(mapper)
}

pub fn receive(
  socket: mug.Socket,
  selector: process.Selector(Result(BitArray, mug.Error)),
  timeout: Int,
) {
  mug.receive_next_packet_as_message(socket)
  selector
  |> process.select(timeout)
  |> result.replace_error(mug.Timeout)
  |> result.flatten
}

fn mapper(message: mug.TcpMessage) -> Result(BitArray, mug.Error) {
  case message {
    mug.Packet(_, packet) -> Ok(packet)
    mug.SocketClosed(_) -> Error(mug.Closed)
    mug.TcpError(_, error) -> Error(error)
  }
}
