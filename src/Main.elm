module Main exposing (main)

import Browser exposing (Document)
import Html
import Html.Attributes
import Html.Events
import Json.Decode as Decode
import Json.Encode as Encode
import Websockets exposing (MessageData)


type alias Message =
    { username : String
    , message : String
    }


type SocketStatus
    = Pending
    | Open
    | Closed


type Model
    = UsernameInput String
    | Chat
        { connected : SocketStatus
        , username : String
        , pendingMessage : String
        , messages : List Message
        }


type Msg
    = UpdatePendingUsername String
    | SubmitPendingUsername
    | GotMessage String
    | SendMessage
    | SocketOpened
    | SocketClosed
    | SocketMessage MessageData
    | NoOp


main : Program {} Model Msg
main =
    Browser.document
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }


init : {} -> ( Model, Cmd msg )
init _ =
    ( UsernameInput ""
    , Cmd.none
    )


view : Model -> Document Msg
view model =
    case model of
        UsernameInput username ->
            { title = "login"
            , body =
                [ Html.div []
                    [ Html.label []
                        [ Html.text "Whats your name?"
                        , Html.input
                            [ Html.Attributes.placeholder "frank"
                            , Html.Attributes.value username
                            , Html.Events.onInput UpdatePendingUsername
                            ]
                            []
                        ]
                    , Html.button
                        [ Html.Attributes.disabled <| String.length username < 3
                        , Html.Events.onClick SubmitPendingUsername
                        ]
                        [ Html.text "Login" ]
                    ]
                ]
            }

        Chat { connected, messages, pendingMessage } ->
            { title = "chat"
            , body =
                [ Html.form [ Html.Events.onSubmit SendMessage ]
                    [ Html.label []
                        [ Html.text "Give me a message"
                        , Html.input
                            [ Html.Events.onInput GotMessage
                            , Html.Attributes.value pendingMessage
                            , Html.Attributes.disabled (connected /= Open)
                            , Html.Attributes.autofocus (connected == Open)
                            ]
                            []
                        ]
                    ]
                , Html.table []
                    [ Html.tbody []
                        (List.map
                            (\message ->
                                Html.tr []
                                    [ Html.td [] [ Html.strong [] [ Html.text message.username ] ]
                                    , Html.td [] [ Html.text message.message ]
                                    ]
                            )
                            messages
                        )
                    ]
                ]
            }


encodeMessage : Message -> Encode.Value
encodeMessage { username, message } =
    Encode.object [ ( "username", Encode.string username ), ( "message", Encode.string message ) ]


decodeMessage : String -> Result String Message
decodeMessage value =
    Decode.decodeString
        (Decode.map2 Message
            (Decode.field "username" Decode.string)
            (Decode.field "message" Decode.string)
        )
        value
        |> Result.mapError Decode.errorToString


update : Msg -> Model -> ( Model, Cmd msg )
update msg model =
    case model of
        UsernameInput username ->
            case msg of
                UpdatePendingUsername pendingUsername ->
                    ( UsernameInput pendingUsername, Cmd.none )

                SubmitPendingUsername ->
                    ( Chat
                        { connected = Pending
                        , username = username
                        , pendingMessage = ""
                        , messages = []
                        }
                    , Websockets.open "chat" "ws://localhost:12345/" []
                    )

                _ ->
                    ( model, Cmd.none )

        Chat chatModel ->
            case msg of
                GotMessage message ->
                    ( Chat { chatModel | pendingMessage = message }, Cmd.none )

                SendMessage ->
                    let
                        { pendingMessage, username } =
                            chatModel
                    in
                    ( Chat { chatModel | pendingMessage = "" }
                    , encodeMessage { username = username, message = pendingMessage } |> Websockets.send "chat"
                    )

                SocketOpened ->
                    ( Chat { chatModel | connected = Open }, Cmd.none )

                SocketClosed ->
                    ( Chat { chatModel | connected = Closed }, Cmd.none )

                SocketMessage { data } ->
                    case decodeMessage data of
                        Ok message ->
                            ( Chat { chatModel | messages = List.concat [ chatModel.messages, [ message ] ] }, Cmd.none )

                        _ ->
                            ( model, Cmd.none )

                _ ->
                    ( model, Cmd.none )


subscriptions : Model -> Sub Msg
subscriptions _ =
    Websockets.onEvent
        { onOpened = always SocketOpened
        , onClosed = always SocketClosed
        , onError = always NoOp
        , onMessage = SocketMessage
        , onDecodeError = always NoOp
        }
