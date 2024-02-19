module Websockets.Meta exposing (Meta, encodeMeta, metaDecoder)

{-| Storing metadata as Key-Value pairs on a Websocket

@docs Meta, encodeMeta, metaDecoder

-}

import Dict exposing (Dict)
import Json.Decode as Decode
import Json.Encode as Encode


{-|

    Metadata is just a `Dict String String`

-}
type alias Meta =
    Dict String String


{-| JSON Decoder for Meta
-}
metaDecoder : Decode.Decoder Meta
metaDecoder =
    Decode.dict Decode.string


{-| JSON Encode Meta
-}
encodeMeta : Meta -> Encode.Value
encodeMeta =
    Encode.dict identity Encode.string
