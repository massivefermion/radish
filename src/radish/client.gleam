import gleam/result
import gleam/bit_array
import gleam/otp/actor
import gleam/erlang/process
import radish/tcp
import radish/error
import radish/decoder.{decode}
import radish/resp.{type Value}
import mug.{type Error}

pub type Message {
  Shutdown
  Command(BitArray, process.Subject(Result(Value, error.Error)), Int)
  BlockingCommand(BitArray, process.Subject(Result(Value, error.Error)), Int)
}

pub fn start(host: String, port: Int, timeout: Int) {
  use socket <- result.then(
    tcp.connect(host, port, timeout)
    |> result.replace_error(actor.InitFailed(process.Abnormal(
      "Unable to connect to Redis server",
    ))),
  )

  use client <- result.then(actor.start(socket, handle_message))
  let client_pid = process.subject_owner(client)
  change_socket_owner(socket, client_pid)

  Ok(client)
}

fn handle_message(msg: Message, socket: mug.Socket) {
  case msg {
    Command(cmd, reply_with, timeout) -> {
      case tcp.send(socket, cmd) {
        Ok(Nil) -> {
          let selector = tcp.new_selector()
          case receive(socket, selector, <<>>, now(), timeout) {
            Ok(reply) -> {
              actor.send(reply_with, Ok(reply))
              actor.continue(socket)
            }

            Error(error) -> {
              let _ = mug.shutdown(socket)
              actor.send(reply_with, Error(error))
              actor.Stop(process.Abnormal("TCP Error"))
            }
          }
        }

        Error(error) -> {
          let _ = mug.shutdown(socket)
          actor.send(reply_with, Error(error.TCPError(error)))
          actor.Stop(process.Abnormal("TCP Error"))
        }
      }
    }

    BlockingCommand(cmd, reply_with, timeout) -> {
      case tcp.send(socket, cmd) {
        Ok(Nil) -> {
          let selector = tcp.new_selector()

          case receive_forever(socket, selector, <<>>, now(), timeout) {
            Ok(reply) -> {
              actor.send(reply_with, Ok(reply))
              actor.continue(socket)
            }

            Error(error) -> {
              let _ = mug.shutdown(socket)
              actor.send(reply_with, Error(error))
              actor.Stop(process.Abnormal("TCP Error"))
            }
          }
        }

        Error(error) -> {
          let _ = mug.shutdown(socket)
          actor.send(reply_with, Error(error.TCPError(error)))
          actor.Stop(process.Abnormal("TCP Error"))
        }
      }
    }

    Shutdown -> {
      let _ = mug.shutdown(socket)
      actor.Stop(process.Normal)
    }
  }
}

fn receive(
  socket: mug.Socket,
  selector: process.Selector(Result(BitArray, mug.Error)),
  storage: BitArray,
  start_time: #(Int, Int, Int),
  timeout: Int,
) {
  case decode(storage) {
    Ok(value) -> Ok(value)
    Error(error) -> {
      case diff(now(), start_time) >= timeout * 1000 {
        True -> Error(error)
        False ->
          case tcp.receive(socket, selector, timeout) {
            Error(tcp_error) -> Error(error.TCPError(tcp_error))
            Ok(packet) ->
              receive(
                socket,
                selector,
                bit_array.append(storage, packet),
                start_time,
                timeout,
              )
          }
      }
    }
  }
}

fn receive_forever(
  socket: mug.Socket,
  selector: process.Selector(Result(BitArray, mug.Error)),
  storage: BitArray,
  start_time: #(Int, Int, Int),
  timeout: Int,
) {
  case decode(storage) {
    Ok(value) -> Ok(value)
    Error(error) -> {
      case diff(now(), start_time) >= timeout * 1000 {
        True -> Error(error)
        False ->
          case tcp.receive_forever(socket, selector) {
            Error(tcp_error) -> Error(error.TCPError(tcp_error))
            Ok(packet) ->
              receive_forever(
                socket,
                selector,
                bit_array.append(storage, packet),
                start_time,
                timeout,
              )
          }
      }
    }
  }
}

@external(erlang, "gen_tcp", "controlling_process")
fn change_socket_owner(socket: mug.Socket, pid: process.Pid) -> b

@external(erlang, "erlang", "now")
fn now() -> #(Int, Int, Int)

@external(erlang, "timer", "now_diff")
fn diff(end: #(Int, Int, Int), start: #(Int, Int, Int)) -> Int
