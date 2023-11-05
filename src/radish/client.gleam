import gleam/result
import gleam/otp/actor
import gleam/erlang/process
import radish/tcp
import mug.{type Error}

pub type Message {
  Shutdown
  Command(BitArray, process.Subject(Result(BitArray, Error)), Int)
}

pub fn start(host: String, port: Int, timeout: Int) {
  use client <- result.then(
    tcp.connect(host, port, timeout)
    |> result.replace_error(actor.InitFailed(process.Abnormal(
      "Unable to connect to Redis server",
    ))),
  )

  actor.start(
    client,
    fn(msg: Message, client) {
      case msg {
        Command(cmd, reply_with, msg_timeout) -> {
          tcp.execute(client, cmd, msg_timeout)
          |> actor.send(reply_with, _)
          actor.continue(client)
        }
        Shutdown -> actor.Stop(process.Normal)
      }
    },
  )
}
