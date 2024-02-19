module Main exposing (main)

import Browser exposing (Document)
import Browser.Dom as Dom
import Html
import Html.Attributes
import Html.Events
import Json.Decode as Decode
import Json.Encode as Encode
import Ports exposing (socket)
import Task
import Time
import Websockets exposing (WebsocketMessage)


type alias Message =
    { username : String
    , message : String
    , timestamp : Maybe Time.Posix
    }


type SocketStatus
    = Opening
    | Open
    | Closed


type Username
    = PendingUsername String
    | Username String


type alias Model =
    { username : Username
    , connected : SocketStatus
    , pendingMessage : String
    , messages : List Message
    , time : Time.Posix
    }


type Msg
    = UpdatePendingUsername String
    | SubmitUsername String
    | GotMessage String
    | SendMessage Message
    | GotTime Time.Posix
    | GotTimeMs Int
    | SocketOpened
    | SocketClosed
    | SocketMessage WebsocketMessage
    | NoOp


main : Program {} Model Msg
main =
    Browser.document
        { init = init
        , subscriptions = subscriptions
        , view = view
        , update = update
        }


init : {} -> ( Model, Cmd Msg )
init _ =
    ( { username = PendingUsername ""
      , connected = Opening
      , pendingMessage = ""
      , messages = []
      , time = Time.millisToPosix 0
      }
    , Cmd.batch
        [ Task.perform GotTime Time.now
        , socket.open "chat" "ws://localhost:12345/" []
        ]
    )


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.batch
        [ Time.every 1000 GotTime
        , socket.onEvent
            { onOpened = always SocketOpened
            , onClosed = always SocketClosed
            , onError = always NoOp
            , onMessage = SocketMessage
            , onDecodeError = always NoOp
            }
        ]


renderChatBox : Time.Posix -> List Message -> Html.Html msg
renderChatBox now messages =
    Html.div
        [ Html.Attributes.id "chat"
        , Html.Attributes.style "height" "calc(100vh - 2em)"
        , Html.Attributes.style "overflow-y" "scroll"
        ]
        [ Html.table []
            [ Html.tbody []
                (List.map
                    (\message ->
                        Html.tr []
                            [ Html.td [] [ Html.strong [] [ Html.text message.username ] ]
                            , Html.td []
                                [ Html.text <|
                                    (message.timestamp |> Maybe.map (timeAgo now) |> Maybe.withDefault "...")
                                ]
                            , Html.td [] [ Html.text message.message ]
                            ]
                    )
                    messages
                )
            ]
        ]


renderUsernameInput : String -> Html.Html Msg
renderUsernameInput username =
    Html.form
        [ Html.Events.onSubmit <| SubmitUsername username
        ]
        [ Html.label []
            [ Html.text "Whats your name?"
            , Html.input
                [ Html.Attributes.placeholder "frank"
                , Html.Attributes.value username
                , Html.Events.onInput UpdatePendingUsername
                , Html.Attributes.autofocus True
                ]
                []
            ]
        , Html.button
            [ Html.Attributes.disabled <| String.length username < 3
            , Html.Events.onClick <| SubmitUsername username
            ]
            [ Html.text "Login" ]
        ]


renderMessageInput : SocketStatus -> String -> String -> Html.Html Msg
renderMessageInput connected username pendingMessage =
    Html.form
        [ Html.Events.onSubmit <| SendMessage { username = username, message = pendingMessage, timestamp = Nothing }
        ]
        [ Html.label []
            [ Html.text "Give me a message"
            , Html.input
                [ Html.Attributes.id "chat-message"
                , Html.Events.onInput GotMessage
                , Html.Attributes.value pendingMessage
                , Html.Attributes.disabled (connected /= Open)
                , Html.Attributes.autofocus True
                ]
                []
            ]
        ]


view : Model -> Document Msg
view model =
    { title = "Elm Websocket Chat"
    , body =
        [ renderChatBox model.time model.messages
        , case model.username of
            PendingUsername username ->
                renderUsernameInput username

            Username username ->
                renderMessageInput model.connected username model.pendingMessage
        ]
    }


timeAgo : Time.Posix -> Time.Posix -> String
timeAgo now prev =
    let
        ts : Int
        ts =
            (Time.posixToMillis now - Time.posixToMillis prev) // 1000
    in
    if ts > 60 * 60 * 24 then
        String.fromInt (ts // 60 // 60 // 24) ++ " days ago"

    else if ts > 60 * 60 then
        String.fromInt (ts // 60 // 60) ++ " hours ago"

    else if ts > 60 then
        String.fromInt (ts // 60) ++ " minutes ago"

    else
        String.fromInt ts ++ " seconds ago"


encodeMessage : Message -> Encode.Value
encodeMessage { username, message, timestamp } =
    Encode.object <|
        List.concat
            [ [ ( "username", Encode.string username )
              , ( "message", Encode.string message )
              ]
            , timestamp
                |> Maybe.map Time.posixToMillis
                |> Maybe.map Encode.int
                |> Maybe.map (\v -> [ ( "timestamp", v ) ])
                |> Maybe.withDefault []
            ]


decodeMessage : String -> Result String Message
decodeMessage value =
    Decode.decodeString
        (Decode.map3 Message
            (Decode.field "username" Decode.string)
            (Decode.field "message" Decode.string)
            (Decode.maybe (Decode.field "timestamp" (Decode.map Time.millisToPosix Decode.int)))
        )
        value
        |> Result.mapError Decode.errorToString


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotTime time ->
            ( { model | time = time }, Cmd.none )

        GotTimeMs ms ->
            ( { model | time = Time.millisToPosix ms }, Cmd.none )

        GotMessage message ->
            ( { model | pendingMessage = message }, Cmd.none )

        UpdatePendingUsername username ->
            ( { model | username = PendingUsername username }, Cmd.none )

        SubmitUsername username ->
            ( { model
                | username = Username username
              }
            , focusById "chat-input"
            )

        SendMessage message ->
            ( { model | pendingMessage = "" }
            , socket.send "chat" (encodeMessage message)
            )

        SocketOpened ->
            ( { model | connected = Open }, Cmd.none )

        SocketClosed ->
            ( { model | connected = Closed }, Cmd.none )

        SocketMessage { data } ->
            case decodeMessage data of
                Ok message ->
                    ( { model | messages = model.messages ++ [ message ] }
                    , jumpToBottom "chat"
                    )

                _ ->
                    ( model, Cmd.none )

        NoOp ->
            ( model, Cmd.none )


jumpToBottom : String -> Cmd Msg
jumpToBottom id =
    Dom.getViewportOf id
        |> Task.andThen (\info -> Dom.setViewportOf id 0 info.scene.height)
        |> Task.attempt (\_ -> NoOp)


focusById : String -> Cmd Msg
focusById id =
    Dom.focus id
        |> Task.attempt (always NoOp)
