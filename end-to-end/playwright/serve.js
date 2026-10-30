import { createServer } from './src/server.js';

const server = await createServer();
await server.start();
