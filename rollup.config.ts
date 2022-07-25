import { RollupOptions, Plugin } from "rollup";
import alias from "@rollup/plugin-alias";
import { nodeResolve } from "@rollup/plugin-node-resolve";
import replace from "@rollup/plugin-replace";
import inject from "@rollup/plugin-inject";
import commonjs from "@rollup/plugin-commonjs";
import WindiCSS from "rollup-plugin-windicss";
import styles from "rollup-plugin-styles";
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
  inject({ debug: ["preact/debug", "*"] }),
  replace({
    preventAssignment: true,
    values: {
      "process.env.NODE_ENV": JSON.stringify(
        isProd ? "production" : "development"
      ),
    },
  }),
  nodeResolve({
    browser: true,
  }),
  commonjs(),
  ...WindiCSS({
    config: {
      extract: {
        include: [`${DIRNAME}/**/*.{bs.js,res}`],
      },
    },
  }),
  // stylable(),
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

const createConfig = A.map(
  ({ banner: b, files, script, packageJson }) =>
    ({
      input: script,
      output: {
        format: "iife",
        file: `dist/${packageJson.name}.user.js`,
        name: packageJson.name,
        banner: banner(b),
        // globals: { react: "React", "react-dom": "ReactDom" },
      },
      // external: ["react", "react-dom"],
      plugins,
    } as RollupOptions)
) as (fa: TEValue<typeof packages>) => RollupOptions[];

const config = TE.map(createConfig)(packages);

export default config().then((config) => E.getOrElseW(() => ({}))(config));
