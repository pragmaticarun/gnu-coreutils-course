import { notFound } from "next/navigation";
import { Article } from "@/components/article";
import { getCourse } from "@/lib/content";

export function generateStaticParams() {
  return getCourse().cookbook.map((recipe) => ({ slug: recipe.slug }));
}

export function generateMetadata({ params }: { params: Promise<{ slug: string }> }) {
  return params.then(({ slug }) => {
    const recipe = getCourse().cookbook.find((item) => item.slug === slug);
    return { title: recipe?.title ?? "Recipe" };
  });
}

export default async function RecipePage({ params }: { params: Promise<{ slug: string }> }) {
  const { slug } = await params;
  const recipes = getCourse().cookbook;
  const index = recipes.findIndex((recipe) => recipe.slug === slug);
  if (index < 0) notFound();
  return (
    <Article
      lesson={recipes[index]}
      prev={index > 0 ? recipes[index - 1] : null}
      next={index + 1 < recipes.length ? recipes[index + 1] : null}
    />
  );
}
