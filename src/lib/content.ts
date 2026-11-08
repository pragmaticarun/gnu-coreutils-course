import fs from "fs";
import path from "path";
import type { BenchFile, Course } from "./types";

const root = process.cwd();

export function getCourse(): Course {
  const file = path.join(root, "content", "generated", "course.json");
  return JSON.parse(fs.readFileSync(file, "utf8")) as Course;
}

export function getBenchmarks(): BenchFile | null {
  const file = path.join(root, "public", "benchmarks", "sample-run.json");
  if (!fs.existsSync(file)) return null;
  return JSON.parse(fs.readFileSync(file, "utf8")) as BenchFile;
}
