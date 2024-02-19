port module Ports exposing (socket)

import Websockets


port webSocketCommand : Websockets.CommandPort msg


port webSocketEvent : Websockets.EventPort msg


socket : Websockets.Methods msg
socket =
    Websockets.withPorts
        { command = webSocketCommand
        , event = webSocketEvent
        }
