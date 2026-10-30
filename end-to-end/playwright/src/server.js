import Hapi from '@hapi/hapi';
import { StatusCodes } from 'http-status-codes';

const createServer = async () => {
  const server = new Hapi.server({
    port: 3000,
  });

  server.route([{
    method: 'GET', path: '/api/healthcheck', config: {
      auth: false, handler: async (request, hapi) => {

        const response = {
          name: 'healthcheck', version: 1, resources: {
            database: {
              status: 'up',
            },
          },
        };
        return hapi.response(response).code(StatusCodes.OK);
      },
    },
  }]);


  return server;
};

export { createServer };
