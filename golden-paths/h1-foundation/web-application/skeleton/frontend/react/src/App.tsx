import { useState } from 'react';

function App() {
  const [count, setCount] = useState(0);

  return (
    <div style={{ maxWidth: '800px', margin: '0 auto', padding: '2rem' }}>
      <h1>${{ values.appName }}</h1>
      <p>Welcome to your new application.</p>
      <button onClick={() => setCount((c) => c + 1)}>Count: {count}</button>
    </div>
  );
}

export default App;
