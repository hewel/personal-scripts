import { record as R, ord as O, identity as Id } from "fp-ts";
import { newIORef } from "fp-ts/IORef";
import { pipe, constant } from "fp-ts/function";
import { Banner } from "./package";

const longestKeyLen = newIORef(0);
const unOrd = O.fromCompare(constant(-1));
const recordLen = (k: keyof Banner, v: Banner[keyof Banner]) => {
  const keyLen = k.length;
  longestKeyLen().modify((len) => (keyLen > len ? keyLen : len));
  return v;
};
const render = (k: keyof Banner, v: Banner[keyof Banner]) => {
  const len = longestKeyLen().read() + 2;
  return v ? `// @${k.padEnd(len)} ${v}` : "";
};

export const banner = (b: Banner) =>
  pipe(
    b,
    R.mapWithIndex(recordLen),
    R.collect(unOrd)(render),
    Id.map((list) => list.join("\n")),
    Id.map((banner) => `// ==UserScript==\n${banner}\n// ==/UserScript==`)
  );
