function initSockets(app) {
    var sockets = new Map();
    app.ports.webSocketCommand.subscribe(function (command) {
        switch (command.type) {
            case "open": {
                var name_1 = command.name, url = command.url, meta_1 = command.meta;
                var oldSocket = sockets.get(name_1);
                if (oldSocket) {
                    oldSocket.ws.close(-1, "New socket opened with the same name");
                    sockets.delete(name_1);
                }
                var socket = {
                    ws: new WebSocket(url),
                    name: name_1,
                    meta: meta_1,
                };
                sockets.set(name_1, socket);
                socket.ws.addEventListener("open", function (ev) {
                    app.ports.webSocketEvent.send({ type: "opened", name: name_1, meta: meta_1 });
                });
                socket.ws.addEventListener("message", function (_a) {
                    var data = _a.data;
                    app.ports.webSocketEvent.send({ type: "message", name: name_1, meta: meta_1, data: data });
                });
                socket.ws.addEventListener("close", function (_a) {
                    var reason = _a.reason;
                    app.ports.webSocketEvent.send({ type: "closed", name: name_1, meta: meta_1, reason: reason });
                    sockets.delete(name_1);
                });
                socket.ws.addEventListener("error", function (ev) {
                    app.ports.webSocketEvent.send({
                        type: "error",
                        name: name_1,
                        meta: meta_1,
                        error: null,
                    });
                    sockets.delete(name_1);
                });
                break;
            }
            case "send": {
                var name_2 = command.name, data = command.data;
                var socket = sockets.get(name_2);
                if (socket) {
                    socket.ws.send(typeof data === "object" ? JSON.stringify(data) : data);
                }
                break;
            }
            case "close": {
                var name_3 = command.name;
                var socket = sockets.get(name_3);
                if (socket) {
                    socket.ws.close();
                    sockets.delete(name_3);
                }
                break;
            }
        }
    });
}
