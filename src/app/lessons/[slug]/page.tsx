import { notFound } from "next/navigation";
import { Article } from "@/components/article";
import { getCourse } from "@/lib/content";

export function generateStaticParams() {
  return getCourse().lessons.map((lesson) => ({ slug: lesson.slug }));
}

export function generateMetadata({ params }: { params: Promise<{ slug: string }> }) {
  return params.then(({ slug }) => {
    const lesson = getCourse().lessons.find((item) => item.slug === slug);
    return { title: lesson?.title ?? "Lesson" };
  });
}

export default async function LessonPage({ params }: { params: Promise<{ slug: string }> }) {
  const { slug } = await params;
  const lessons = getCourse().lessons;
  const index = lessons.findIndex((lesson) => lesson.slug === slug);
  if (index < 0) notFound();
  return (
    <Article
      lesson={lessons[index]}
      prev={index > 0 ? lessons[index - 1] : null}
      next={index + 1 < lessons.length ? lessons[index + 1] : null}
    />
  );
}
