import gleam/result
import gleam/erlang/process
import mug

pub fn connect(host: String, port: Int, timeout: Int) {
  mug.connect(mug.ConnectionOptions(host, port, timeout))
}

pub fn execute(socket: mug.Socket, packet: BitArray, timeout: Int) {
  use <- receive(socket, timeout)
  mug.send(socket, packet)
}

fn receive(socket: mug.Socket, timeout: Int, rest) {
  mug.receive_next_packet_as_message(socket)
  let selector =
    process.new_selector()
    |> mug.selecting_tcp_messages(mapper)

  rest()

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
