import { RollupOptions } from "rollup";
import alias from "@rollup/plugin-alias";
import { nodeResolve } from "@rollup/plugin-node-resolve";
import commonjs from "@rollup/plugin-commonjs";
import WindiCSS from "rollup-plugin-windicss";
import styles from "rollup-plugin-styles";
import stylable from "@stylable/rollup-plugin";
import { terser } from "rollup-plugin-terser";
import { taskEither as TE, array as A, either as E } from "fp-ts";
import { packages, DIRNAME } from "./scripts/package";
import { banner } from "./scripts/banner";

const isProd = !process.env.ROLLUP_WATCH;
const plugins = [
  alias({
    entries: [
      { find: "react", replacement: "preact/compat" },
      { find: "react-dom/test-utils", replacement: "preact/test-utils" },
      { find: "react-dom", replacement: "preact/compat" },
      { find: "react/jsx-runtime", replacement: "preact/jsx-runtime" },
    ],
  }),
  nodeResolve(),
  commonjs(),

  ...WindiCSS({
    config: {
      extract: {
        include: [`${DIRNAME}/**/*.{bs.js,res}`],
      },
    },
  }),
  stylable(),
  styles({
    minimize: isProd,
    autoModules: true,
    exclude: [/\.st\.css$/],
  }),

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

export default config().then((config) => E.getOrElseW(() => ({}))(config));
