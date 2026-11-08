import type { Metadata } from "next";
import type { ReactNode } from "react";
import { Fraunces, IBM_Plex_Mono, Public_Sans } from "next/font/google";
import "./globals.css";
import { ProgressProvider } from "@/components/progress";
import { SiteShell, type NavGroup } from "@/components/site-shell";
import { getCourse } from "@/lib/content";

const sans = Public_Sans({ subsets: ["latin"], variable: "--font-public" });
const serif = Fraunces({ subsets: ["latin"], variable: "--font-fraunces" });
const mono = IBM_Plex_Mono({
  subsets: ["latin"],
  weight: ["400", "500"],
  variable: "--font-plex",
});

export const metadata: Metadata = {
  title: {
    default: "GNU Coreutils Workbench",
    template: "%s · Coreutils Workbench",
  },
  description:
    "A working course in GNU coreutils 9.4 for Ubuntu developers: lessons, a scenario cookbook, a utility reference, and bounded benchmarks.",
};

export default function RootLayout({ children }: { children: ReactNode }) {
  const course = getCourse();
  const groups = new Map<string, NavGroup>();
  for (const lesson of course.lessons) {
    const group = groups.get(lesson.module) ?? { module: lesson.module, lessons: [] };
    group.lessons.push({
      slug: lesson.slug,
      title: lesson.title,
      number: lesson.number,
      kind: "lesson",
    });
    groups.set(lesson.module, group);
  }
  return (
    <html lang="en" className={`${sans.variable} ${serif.variable} ${mono.variable}`}>
      <head>
        <script
          dangerouslySetInnerHTML={{
            __html:
              "try{var t=localStorage.getItem('theme');if(t==='dark'||(!t&&matchMedia('(prefers-color-scheme: dark)').matches))document.documentElement.classList.add('dark')}catch(e){}",
          }}
        />
      </head>
      <body>
        <ProgressProvider>
          <SiteShell nav={[...groups.values()]} lessonCount={course.lessons.length}>
            {children}
          </SiteShell>
        </ProgressProvider>
      </body>
    </html>
  );
}
