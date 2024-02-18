import { WebSocketServer, WebSocket } from "ws";

const wss = new WebSocketServer({ port: 12345 });

const history = new Array<string>();

wss.on("connection", (ws) => {
  ws.on("message", (data, isBinary) => {
    console.log('received %s', data, typeof data, isBinary);
    data = isBinary ? data : data.toString();

    history.push(data);
    wss.clients.forEach((s) => {
      if (s.readyState === WebSocket.OPEN) {
        s.send(data);
      }
    });
  });

  for (const data of history) {
    ws.send(data);
  }
});

console.log("Listening on port 12345");
