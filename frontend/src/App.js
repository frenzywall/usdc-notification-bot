import React, { useEffect, useState } from "react";

function App() {
  const [transfers, setTransfers] = useState([]);

  useEffect(() => {
    fetch("/api/transfers")
      .then((res) => res.json())
      .then((data) => setTransfers(data));
  }, []);

  return (
    <div>
      <h1>USDC Transfer Tracker</h1>
      <ul>
        {transfers.map((transfer, index) => (
          <li key={index}>
            {transfer.from} → {transfer.to}: {transfer.value}
          </li>
        ))}
      </ul>
    </div>
  );
}

export default App;
