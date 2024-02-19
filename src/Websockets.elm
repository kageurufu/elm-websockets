module Websockets exposing
    ( withPorts, CommandPort, EventPort, Methods
    , EventHandlers
    , WebsocketOpened, WebsocketMessage, WebsocketClosed, WebsocketError
    )

{-| Simple interfaces for getting started with Websockets in Elm

Other modules are exposed for advanced usage.

# Defining your Ports

@docs withPorts, CommandPort, EventPort, Methods


# Event data received from your Sockets

@docs EventHandlers
@docs WebsocketOpened, WebsocketMessage, WebsocketClosed, WebsocketError

-}

import Json.Encode as Encode
import Websockets.Command
import Websockets.Event exposing (Event(..))
import Websockets.Meta exposing (Meta)


{-| Port to send Commands to the Websocket
-}
type alias CommandPort msg =
    Encode.Value -> Cmd msg


{-| Port for subscribing to income events
-}
type alias EventPort msg =
    (Encode.Value -> msg) -> Sub msg


{-| Methods for using your sockets
-}
type alias Methods msg =
    { open : String -> String -> List ( String, Maybe String ) -> Cmd msg
    , close : String -> Cmd msg
    , send : String -> Encode.Value -> Cmd msg
    , onEvent : EventHandlers msg -> Sub msg
    }


{-| Helper to wrap your Ports
-}
withPorts :
    { command : CommandPort msg
    , event : EventPort msg
    }
    -> Methods msg
withPorts { command, event } =
    { open = openWithPort command
    , close = closeWithPort command
    , send = sendWithPort command
    , onEvent = onPortEvent event
    }


{-| Record data when a socket is Opened
-}
type alias WebsocketOpened =
    { name : Websockets.Event.Name
    , meta : Meta
    }


{-| Record data when a socket is Closed
-}
type alias WebsocketClosed =
    { name : Websockets.Event.Name
    , meta : Meta
    , reason : String
    }


{-| Record data when a socket is Error
-}
type alias WebsocketError =
    { name : Websockets.Event.Name
    , meta : Meta
    , error : Maybe String
    }


{-| Record data when a socket is Message
-}
type alias WebsocketMessage =
    { name : Websockets.Event.Name
    , meta : Meta
    , data : String
    }


{-| Event handlers for subscriptions
-}
type alias EventHandlers msg =
    { onOpened : WebsocketOpened -> msg
    , onClosed : WebsocketClosed -> msg
    , onError : WebsocketError -> msg
    , onMessage : WebsocketMessage -> msg
    , onDecodeError : String -> msg
    }


openWithPort : CommandPort msg -> String -> String -> List ( String, Maybe String ) -> Cmd msg
openWithPort commandPort name url meta =
    Websockets.Command.open name
        url
        (List.filterMap
            (\( key, maybeValue ) ->
                Maybe.map (Tuple.pair key) maybeValue
            )
            meta
        )
        |> commandPort


closeWithPort : CommandPort msg -> String -> Cmd msg
closeWithPort commandPort name =
    Websockets.Command.close name
        |> commandPort


sendWithPort : CommandPort msg -> String -> Encode.Value -> Cmd msg
sendWithPort commandPort name data =
    Websockets.Command.send name data
        |> commandPort


onPortEvent : EventPort msg -> EventHandlers msg -> Sub msg
onPortEvent eventPort { onOpened, onClosed, onError, onMessage, onDecodeError } =
    eventPort
        (\event ->
            case Websockets.Event.decodeEvent event of
                Ok (Opened res) ->
                    onOpened res

                Ok (Closed res) ->
                    onClosed res

                Ok (Error res) ->
                    onError res

                Ok (Message res) ->
                    onMessage res

                Err err ->
                    onDecodeError err
        )
