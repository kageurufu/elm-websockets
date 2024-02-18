elm-websockets
==============


Due to ports being banned from packages.elm-lang, I've published this as bare code.

Extending Websockets.elm to accept your own ports wouldn't be too hard (`onEvent : mySubPort -> EventHandlers msg -> Sub msg`, `send myCmdPort ...`, etc)

For now, copy lib/ and dist/ports.websocket.ts to your project, add 'lib/Websockets' to your elm.json if you don't already use a split layout (or just everying in `lib/Websockets` into your `src/`), and reference `index.html` for how to enable the javascript side ports.

Set up your subscriptions where