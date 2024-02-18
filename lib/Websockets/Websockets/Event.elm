module Websockets.Event exposing (Event(..), Name, decodeEvent)

import Json.Decode as Decode
import Json.Encode as Encode
import Websockets.Meta exposing (Meta, metaDecoder)


type alias Name =
    String


type Event
    = Opened { name : Name, meta : Meta }
    | Closed { name : Name, meta : Meta, reason : String }
    | Error { name : Name, meta : Meta, error : Maybe String }
    | Message { name : Name, meta : Meta, data : String }




decodeEventByType : String -> Decode.Decoder Event
decodeEventByType type_ =
    case type_ of
        "opened" ->
            Decode.map2 (\name meta -> Opened { name = name, meta = meta })
                (Decode.field "name" Decode.string)
                (Decode.field "meta" metaDecoder)

        "closed" ->
            Decode.map3 (\name meta reason -> Closed { name = name, meta = meta, reason = reason })
                (Decode.field "name" Decode.string)
                (Decode.field "meta" metaDecoder)
                (Decode.field "reason" Decode.string)

        "error" ->
            Decode.map3 (\name meta error -> Error { name = name, meta = meta, error = error })
                (Decode.field "name" Decode.string)
                (Decode.field "meta" metaDecoder)
                (Decode.maybe (Decode.field "error" Decode.string))

        "message" ->
            Decode.map3 (\name meta data -> Message { name = name, meta = meta, data = data })
                (Decode.field "name" Decode.string)
                (Decode.field "meta" metaDecoder)
                (Decode.field "data" Decode.string)

        _ ->
            Decode.fail ("Unknown websocket event " ++ type_)


eventDecoder : Decode.Decoder Event
eventDecoder =
    Decode.field "type" Decode.string
        |> Decode.andThen decodeEventByType


decodeEvent : Encode.Value -> Result String Event
decodeEvent value =
    value
        |> Decode.decodeValue eventDecoder
        |> Result.mapError Decode.errorToString
