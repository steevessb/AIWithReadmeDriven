const express = require('express');
const path = require('path');

const app = express();
const PORT = 3001;

// Serve static files from the React app
app.use(express.static(path.join(__dirname, 'public')));

// API endpoint for health check
app.get('/health', (req, res) => {
  res.status(200).send('Server is running');
});

// Catch-all handler to serve the React app
app.get('*', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

app.listen(PORT, () => {
  console.log(`Server is running on http://localhost:${PORT}`);
});