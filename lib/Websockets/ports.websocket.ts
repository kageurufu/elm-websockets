declare interface WebsocketPorts {
  webSocketCommand: PortFromElm<WSCommand>;
  webSocketEvent: PortToElm<WSEvent>;
}

type SocketRecord = {
  ws: WebSocket;
  name: string;
  meta: Record<string, string>;
};

type WSCommand =
  | { type: "open"; name: string; url: string; meta: Record<string, string> }
  | { type: "close"; name: string }
  | { type: "send"; name: string; data: any };

type WSEvent =
  | { type: "opened"; name: string; meta: Record<string, string> }
  | {
      type: "message";
      name: string;
      meta: Record<string, string>;
      data: unknown;
    }
  | {
      type: "closed";
      name: string;
      meta: Record<string, string>;
      reason: string;
    }
  | {
      type: "error";
      name: string;
      meta: Record<string, string>;
      error: null | string;
    };

function initSockets(app: ElmApp<WebsocketPorts>) {
  const sockets = new Map();

  app.ports.webSocketCommand.subscribe((command) => {
    switch (command.type) {
      case "open": {
        const { name, url, meta } = command;

        const oldSocket = sockets.get(name);
        if (oldSocket) {
          oldSocket.ws.close(-1, "New socket opened with the same name");
          sockets.delete(name);
        }

        const socket: SocketRecord = {
          ws: new WebSocket(url),
          name,
          meta,
        };
        sockets.set(name, socket);

        socket.ws.addEventListener("open", (ev: Event) => {
          app.ports.webSocketEvent.send({ type: "opened", name, meta });
        });

        socket.ws.addEventListener("message", ({ data }: MessageEvent<any>) => {
          app.ports.webSocketEvent.send({ type: "message", name, meta, data });
        });

        socket.ws.addEventListener("close", ({ reason }: CloseEvent) => {
          app.ports.webSocketEvent.send({ type: "closed", name, meta, reason });
          sockets.delete(name);
        });

        socket.ws.addEventListener("error", (ev: Event) => {
          app.ports.webSocketEvent.send({
            type: "error",
            name,
            meta,
            error: null,
          });

          sockets.delete(name);
        });

        break;
      }

      case "send": {
        const { name, data } = command;
        const socket = sockets.get(name);
        if (socket) {
          console.log(data)
          socket.ws.send(
            typeof data === "object" ? JSON.stringify(data) : data
          );
        }
        break;
      }

      case "close": {
        const { name } = command;
        const socket = sockets.get(name);
        if (socket) {
          socket.ws.close();
          sockets.delete(name);
        }
        break;
      }
    }
  });
}
