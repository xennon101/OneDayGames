import { canonicalizeJson, canonicalizeQuery } from '../src/lib/canonical';
import { signPayload, verifySignature } from '../src/lib/signature';

describe('canonicalization', () => {
  it('sorts JSON keys deterministically', () => {
    const payload = { b: 2, a: 1 };
    const canonical = canonicalizeJson(payload);
    expect(canonical).toBe('{"a":1,"b":2}');
  });

  it('sorts nested JSON deterministically', () => {
    const payload = { z: { b: 2, a: 1 }, a: 0 };
    const canonical = canonicalizeJson(payload);
    expect(canonical).toBe('{"a":0,"z":{"a":1,"b":2}}');
  });

  it('builds sorted query strings', () => {
    const query = canonicalizeQuery({ b: 2, a: 1 });
    expect(query).toBe('a=1&b=2');
  });
});

describe('signature', () => {
  it('verifies matching signatures', () => {
    const secret = 'testsecret';
    const payload = 'a=1&b=2';
    const sig = signPayload(secret, payload);
    expect(verifySignature(secret, payload, sig)).toBe(true);
  });

  it('rejects mismatched signatures', () => {
    const secret = 'testsecret';
    const payload = 'a=1&b=2';
    expect(verifySignature(secret, payload, 'deadbeef')).toBe(false);
  });
});
