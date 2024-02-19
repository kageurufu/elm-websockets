# frank/websockets

A fairly ergonomic elm websockets implementation.

See `example/` for a simple Websocket chat demo


### Getting started

Reference `ports.websocket.js` in your html (For deployment, you copy this somewhere into your application).

```html
<script src="//raw.githubusercontent.com/kageurufu/elm-websockets/master/dist/ports.websocket.js"></script>
<script>
  var app = Elm.Main.init();
  initWebsockets(app);
</script>
```

Define the two necessary ports

```elm
-- src/Ports.elm
port module Ports exposing (socket)

import Websockets


port webSocketCommand : Websockets.CommandPort msg


port webSocketEvent : Websockets.EventPort msg
```

Then get your Command and Event methods

```elm
socket : Websockets.Methods msg
socket =
    Websockets.withPorts
        { command = webSocketCommand
        , event = webSocketEvent
        }
```

Define your messages and subscriptions

```elm
type Msg
    = -- ...
    | SocketOpened Websockets.WebsocketOpened
    | SocketMessage Websockets.WebsocketMessage
    | SocketClosed Websockets.WebsocketClosed
    | SocketError Websockets.WebsocketError
    | NoOp

subscriptions model =
    socket.onEvent
        { onOpened = SocketOpened
        , onClosed = SocketClosed
        , onError = SocketError
        , onMessage = SocketMessage
        , onDecodeError = always NoOp
        }
```

And start using Websockets!

```elm

encodeMessage = Encode.string
decodeMessage = Decode.decodeString Decode.String

init flags =
    ({ messages : List String }
    , socket.open "chat" "wss://my-socket-url/ws" [("metadata","chat")])

update msg model =
    case msg of
        SocketOpened { name } ->
            (model, socket.send name (encodeMessage "I opened a socket!"))
        SocketMessage { name, data } ->
            case decodeMessage of
                Ok message ->
                    ( { model | messages = model.messages ++ [message] }
                    , Cmd.none
                    )
        -- ...
```
