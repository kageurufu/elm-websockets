module Websockets exposing (ClosedData, ErrorData, MessageData, OpenedData,EventHandlers, close, onEvent, open, send)

import Json.Encode as Encode
import Websockets.Command
import Websockets.Event exposing (Event(..))
import Websockets.Meta exposing (Meta)
import Websockets.Ports


open : String -> String -> List ( String, Maybe String ) -> Cmd msg
open name url meta =
    Websockets.Command.open name
        url
        (List.filterMap
            (\( key, maybeValue ) ->
                Maybe.map (Tuple.pair key) maybeValue
            )
            meta
        )
        |> Websockets.Ports.webSocketCommand


close : String -> Cmd msg
close name =
    Websockets.Command.close name
        |> Websockets.Ports.webSocketCommand


send : String -> Encode.Value -> Cmd msg
send name data =
    Websockets.Command.send name data
        |> Websockets.Ports.webSocketCommand


type alias OpenedData =
    { name : Websockets.Event.Name
    , meta : Meta
    }


type alias ClosedData =
    { name : Websockets.Event.Name
    , meta : Meta
    , reason : String
    }


type alias ErrorData =
    { name : Websockets.Event.Name
    , meta : Meta
    , error : Maybe String
    }


type alias MessageData =
    { name : Websockets.Event.Name
    , meta : Meta
    , data : String
    }


type alias EventHandlers msg =
    { onOpened : OpenedData -> msg
    , onClosed : ClosedData -> msg
    , onError : ErrorData -> msg
    , onMessage : MessageData -> msg
    , onDecodeError : String -> msg
    }


onEvent : EventHandlers msg -> Sub msg
onEvent { onOpened, onClosed, onError, onMessage, onDecodeError } =
    Websockets.Ports.webSocketEvent
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
