import path from "path";
import { readdir, readFile } from "fs/promises";
import { equals, endsWith } from "ramda";
import {
  taskEither as TE,
  either as E,
  array as A,
  option as O,
  json,
} from "fp-ts";
import { pipe, flow } from "fp-ts/function";

export const DIRNAME = "packages";

export interface PackageJson {
  name: string;
  description: string;
  author: string;
  version: string;
}

export interface Banner extends PackageJson {
  match: string;
  icon: string;
}

const NOT_PACKAGES = ["components", "utils"];

const eqBasename = (name: string) => (p: string) => path.parse(p).base === name;

const resolveJson = <T>(
  predicate: (b: string) => boolean
): ((files: string[]) => TE.TaskEither<Error, T>) =>
  flow(
    A.findFirst(predicate),
    TE.fromOption(() => new Error("json not found")),
    TE.chain((file) =>
      TE.tryCatch(
        () =>
          readFile(file, {
            encoding: "utf8",
          }),
        (reason) => new Error(String(reason))
      )
    ),
    TE.map(json.parse),
    TE.map(E.getOrElse(() => ({} as any)))
  );

const resolvePackage = (dir: string) =>
  pipe(
    TE.tryCatch(
      () =>
        readdir(path.resolve(DIRNAME, dir)).then(
          A.map((file) => path.resolve(DIRNAME, dir, file))
        ),
      (reason) => new Error(String(reason))
    ),
    TE.bindTo("files"),
    TE.bind("script", ({ files }) =>
      TE.fromOption(() => new Error("script not found"))(
        A.findFirst(endsWith("Script.bs.js"))(files)
      )
    ),
    TE.bind("packageJson", ({ files }) =>
      resolveJson<PackageJson>(eqBasename("package.json"))(files)
    ),
    TE.bind("banner", ({ files }) =>
      resolveJson<Banner>(eqBasename("banner.json"))(files)
    ),
    TE.map(({ banner, packageJson, ...rest }) => ({
      ...rest,
      banner: Object.assign(banner, {
        name: packageJson.name,
        description: packageJson.description,
        author: packageJson.author,
        version: packageJson.version,
      }),
      packageJson,
    }))
  );

export const packages = pipe(
  DIRNAME,
  path.resolve,
  (path) =>
    TE.tryCatch(
      () => readdir(path),
      (reason) => new Error(String(reason))
    ),
  TE.map(A.filter((file) => !NOT_PACKAGES.includes(file))),
  TE.chain(TE.traverseArray(resolvePackage))
);
