import gleam/bit_array
import gleam/erlang/process
import gleam/otp/actor

import radish/decoder.{decode}
import radish/error
import radish/resp.{type Value}
import radish/tcp

import lifeguard
import mug.{type Error}

pub type Message {
  Command(BitArray, process.Subject(Result(List(Value), error.Error)), Int)
  BlockingCommand(
    BitArray,
    process.Subject(Result(List(Value), error.Error)),
    Int,
  )
  ReceiveForever(process.Subject(Result(List(Value), error.Error)), Int)
}

pub type Client =
  lifeguard.Pool(Message)

pub fn start(
  host: String,
  port: Int,
  timeout: Int,
  pool_size: Int,
) -> Result(lifeguard.Pool(Message), lifeguard.StartError) {
  lifeguard.new(worker_spec(host, port, timeout))
  |> lifeguard.with_size(pool_size)
  |> lifeguard.start(timeout)
}

fn worker_spec(
  host: String,
  port: Int,
  timeout: Int,
) -> lifeguard.Spec(mug.Socket, Message) {
  lifeguard.Spec(
    init: fn(selector) {
      case tcp.connect(host, port, timeout) {
        Ok(socket) -> actor.Ready(socket, selector)
        Error(_) -> actor.Failed("Unable to connect to Redis server")
      }
    },
    init_timeout: timeout,
    loop: handle_message,
  )
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

    ReceiveForever(reply_with, timeout) -> {
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
  }
}

fn receive(
  socket: mug.Socket,
  selector: process.Selector(Result(BitArray, mug.Error)),
  storage: BitArray,
  start_time: Int,
  timeout: Int,
) {
  case decode(storage) {
    Ok(value) -> Ok(value)
    Error(error) -> {
      case now() - start_time >= timeout * 1_000_000 {
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
  start_time: Int,
  timeout: Int,
) {
  case decode(storage) {
    Ok(value) -> Ok(value)

    Error(error) if timeout != 0 -> {
      case now() - start_time >= timeout * 1_000_000 {
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

    Error(_) -> {
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

@external(erlang, "erlang", "monotonic_time")
fn now() -> Int
