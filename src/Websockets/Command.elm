module Websockets.Command exposing (Command(..), open, send, close)

{-| Commands for interacting with Websockets

@docs Command, open, send, close

-}

import Dict
import Json.Encode as Encode
import Websockets.Meta as Meta


{-| Type for wrapping Commands before JSON encoding
-}
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


{-| JSON Encode a Open command for sending through the Command Port
-}
open : String -> String -> List ( String, String ) -> Encode.Value
open name url meta =
    Open name url (Dict.fromList meta)
        |> encodeCommand


{-| JSON Encode a Close command for sending through the Command Port
-}
close : String -> Encode.Value
close name =
    Close name
        |> encodeCommand


{-| JSON Encode a Send command for sending through the Command Port
-}
send : String -> Encode.Value -> Encode.Value
send name value =
    Send name value
        |> encodeCommand
