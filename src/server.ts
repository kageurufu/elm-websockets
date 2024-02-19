import { WebSocketServer, WebSocket } from "ws";

const wss = new WebSocketServer({ port: 12345 });

const history = new Array<string>();

wss.on("connection", (ws: WebSocket, req) => {
  console.log(`New connection from ${req.socket.remoteAddress}  (${wss.clients.size} connections)`);

  ws.on("closed", () => console.log(`Lost ${req.socket.remoteAddress}  (${wss.clients.size} connections)`));

  ws.on("message", (data, isBinary) => {
    if (isBinary) {
      console.error("got binary data");
      return;
    }

    let message = JSON.parse(data.toString());
    if (message.timestamp == null) {
      message.timestamp = new Date().getTime();
    }
    message = JSON.stringify(message);
    console.log(`${req.socket.remoteAddress} sent ${message}`);

    history.push(message);
    wss.clients.forEach((s) => {
      if (s.readyState === WebSocket.OPEN) {
        s.send(message);
      }
    });
  });

  for (const message of history) {
    ws.send(message);
  }
});

console.log("Listening on port 12345");
