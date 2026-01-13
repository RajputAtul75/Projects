import { useEffect } from "react";

function App() {

  useEffect(() => {
    fetch("http://127.0.0.1:8000/api/products/test/")
      .then(res => res.json())
      .then(data => console.log(data));
  }, []);

  return (
    <div>
      <h1>EcoNext Frontend</h1>
      <p>Open browser console (F12)</p>
    </div>
  );
}

export default App;
