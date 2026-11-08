"use client";

import { useProgress } from "@/components/progress";
import { Button } from "@/components/ui/button";

export function LessonActions({ slug }: { slug: string }) {
  const { done, toggle, ready } = useProgress();
  const complete = done.has(slug);
  return (
    <Button
      type="button"
      variant={complete ? "secondary" : "default"}
      onClick={() => toggle(slug)}
      disabled={!ready}
    >
      {complete ? "Completed in this browser" : "Mark complete"}
    </Button>
  );
}
