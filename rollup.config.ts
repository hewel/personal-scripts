import { RollupOptions } from "rollup";
import { nodeResolve } from "@rollup/plugin-node-resolve";
import commonjs from "@rollup/plugin-commonjs";
import { terser } from "rollup-plugin-terser";
import { taskEither as TE, array as A, either as E } from "fp-ts";
import { packages } from "./scripts/package";
import { banner } from "./scripts/banner";

const isProd = !process.env.ROLLUP_WATCH;
const plugins = [
  nodeResolve(),
  commonjs(),
  isProd &&
    terser({
      format: {
        comments: /UserScript|@\w+/,
      },
    }),
];

type TEValue<T> = T extends TE.TaskEither<infer E, infer A> ? A : never;

const createConfig = A.map(({ banner: b, files, script, packageJson }) => ({
  input: script,
  output: {
    format: "iife",
    file: `dist/${packageJson.name}.user.js`,
    name: packageJson.name,
    banner: banner(b),
  },
  plugins,
})) as (fa: TEValue<typeof packages>) => RollupOptions[];

const config = TE.map(createConfig)(packages);

export default config().then((config) => E.getOrElseW(() => [])(config));
