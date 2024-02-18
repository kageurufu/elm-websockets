module Websockets.Meta exposing (Meta, encodeMeta, metaDecoder)

import Dict exposing (Dict)
import Json.Decode as Decode
import Json.Encode as Encode


type alias Meta =
    Dict String String


metaDecoder : Decode.Decoder Meta
metaDecoder =
    Decode.dict Decode.string


encodeMeta : Meta -> Encode.Value
encodeMeta =
    Encode.dict identity Encode.string
