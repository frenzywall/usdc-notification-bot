// Main backend server
const express = require("express");
const fetch = require("node-fetch");

const app = express();
const PORT = process.env.PORT || 5000;
const SUBGRAPH_URL = "<SUBGRAPH_URL>";

app.get("/transfers", async (req, res) => {
  const query = `{ transfers(where: { to: "<TARGET_ADDRESS>" }) { from to value timestamp } }`;
  const response = await fetch(SUBGRAPH_URL, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ query }),
  });
  const data = await response.json();
  res.json(data.data.transfers);
});

app.listen(PORT, () => console.log(`Server running on port ${PORT}`));
