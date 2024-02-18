port module Websockets.Ports exposing (webSocketCommand, webSocketEvent)

import Json.Encode as Encode


port webSocketCommand : Encode.Value -> Cmd msg


port webSocketEvent : (Encode.Value -> msg) -> Sub msg
