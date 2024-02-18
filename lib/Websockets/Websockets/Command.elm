module Websockets.Command exposing (Command(..), close, open, send)

import Dict
import Json.Encode as Encode
import Websockets.Meta as Meta


type Command
    = Open String String Meta.Meta
    | Close String
    | Send String Encode.Value


encodeCommand : Command -> Encode.Value
encodeCommand command =
    case command of
        Open name url meta ->
            Encode.object
                [ ( "type", Encode.string "open" )
                , ( "name", Encode.string name )
                , ( "url", Encode.string url )
                , ( "meta", Meta.encodeMeta meta )
                ]

        Close name ->
            Encode.object
                [ ( "type", Encode.string "close" )
                , ( "name", Encode.string name )
                ]

        Send name data ->
            Encode.object
                [ ( "type", Encode.string "send" )
                , ( "name", Encode.string name )
                , ( "data", data )
                ]


open : String -> String -> List ( String, String ) -> Encode.Value
open name url meta =
    Open name url (Dict.fromList meta)
        |> encodeCommand


close : String -> Encode.Value
close name =
    Close name
        |> encodeCommand


send : String -> Encode.Value -> Encode.Value
send name value =
    Send name value
        |> encodeCommand
