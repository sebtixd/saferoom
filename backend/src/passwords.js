import { randomBytes, scryptSync, timingSafeEqual } from 'node:crypto';

const N = 16384;
const R = 8;
const P = 1;
const KEY_LENGTH = 64;
const MAX_MEMORY = 64 * 1024 * 1024;

export function hashPassword(password) {
  const salt = randomBytes(16);
  const derived = scryptSync(password, salt, KEY_LENGTH, { N, r: R, p: P, maxmem: MAX_MEMORY });
  return `scrypt$${N}$${R}$${P}$${salt.toString('base64')}$${derived.toString('base64')}`;
}

export function verifyPassword(password, stored) {
  try {
    const [scheme, nRaw, rRaw, pRaw, saltRaw, hashRaw] = stored.split('$');
    if (scheme !== 'scrypt') return false;

    const expected = Buffer.from(hashRaw, 'base64');
    const actual = scryptSync(password, Buffer.from(saltRaw, 'base64'), expected.length, {
      N: Number.parseInt(nRaw, 10),
      r: Number.parseInt(rRaw, 10),
      p: Number.parseInt(pRaw, 10),
      maxmem: MAX_MEMORY,
    });
    return expected.length === actual.length && timingSafeEqual(expected, actual);
  } catch {
    return false;
  }
}
