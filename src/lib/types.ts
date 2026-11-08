export type ManualRef = {
  title: string;
  url: string;
};

export type CapturedExample = {
  id: string;
  title: string;
  companion: string;
  script: string;
  stdout: string;
  stderr: string;
  exitCode: number;
  download: string;
  truncated: boolean;
};

export type CapturedExercise = {
  id: string;
  title: string;
  prompt: string;
  hint: string;
  solution: string;
  script: string;
  stdout: string;
  stderr: string;
  exitCode: number;
  download: string;
};

export type Heading = {
  level: number;
  id: string;
  text: string;
};

export type Lesson = {
  kind: "lesson" | "cookbook";
  slug: string;
  number: number;
  title: string;
  module: string;
  level: "beginner" | "intermediate" | "advanced";
  minutes: number;
  summary: string;
  objectives: string[];
  manual: ManualRef[];
  gnuVsBsd: string;
  prereq: string;
  markdown: string;
  headings: Heading[];
  examples: CapturedExample[];
  exercises: CapturedExercise[];
  wordCount: number;
};

export type ReferenceEntry = {
  name: string;
  slug: string;
  section: string;
  summary: string;
  note: string;
  lesson: string | null;
  manualUrl: string;
  versionLine: string;
};

export type CompanionEntry = {
  name: string;
  installed: boolean;
  path: string;
  package: string;
  note: string;
};

export type CourseMeta = {
  title: string;
  coreutilsVersion: string;
  packageVersion: string;
  uname: string;
  locale: string;
  umask: string;
  filesystemDf: string;
  filesystemStat: string;
  user: string;
  capturedAt: string;
  python: string;
  kernelNote: string;
  manualLocal: string;
  manualHtml: string;
  stdbufLibrary: string;
  limits: string[];
};

export type Course = {
  meta: CourseMeta;
  lessons: Lesson[];
  cookbook: Lesson[];
  reference: ReferenceEntry[];
  companions: CompanionEntry[];
};

export type BenchVariant = {
  name: string;
  trials: {
    elapsed: number;
    user: number;
    system: number;
    maxRssKb: number;
    exitCode: number;
  }[];
  median: {
    elapsed: number;
    user: number;
    system: number;
    maxRssKb: number;
  };
};

export type BenchResult = {
  id: string;
  title: string;
  question: string;
  input: string;
  variants: BenchVariant[];
  note: string;
};

export type BenchFile = {
  disclosure: Record<string, string | number | boolean>;
  benches: BenchResult[];
};
