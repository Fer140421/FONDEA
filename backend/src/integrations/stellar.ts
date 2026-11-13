import { Horizon, Networks } from '@stellar/stellar-sdk';
import type { Config } from '../config/env.js';

export function createStellarIntegration(config: Config) {
  const horizon = new Horizon.Server(config.STELLAR_HORIZON_URL);
  horizon.httpClient.defaults.timeout = 10_000;
  return {
    network: config.STELLAR_NETWORK,
    networkPassphrase: Networks.TESTNET,
    horizon,
  };
}
