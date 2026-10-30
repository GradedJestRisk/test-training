import { test } from '@playwright/test';
import { expect } from 'chai';
import { StatusCodes } from 'http-status-codes';

test.describe('GET without payload', () => {
  test('return OK (200) and a payload', async ({ request }) => {
    // given

    // when
    const response = await request.get(`/api/healthcheck`);

    // then
    expect(response.status()).to.equal(StatusCodes.OK);
    expect(response.statusText()).to.equal('OK');
    const payload = await response.json();

    expect(payload).to.deep.equal({
      'name': 'healthcheck',
      'version': 1,
      'resources': {
        'database': {
          'status': 'up',
        },
      },
    });
  });
});
