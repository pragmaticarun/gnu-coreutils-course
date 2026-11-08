import type { HTMLAttributes } from "react";
import { cva, type VariantProps } from "class-variance-authority";
import { cn } from "@/lib/utils";

const badgeVariants = cva(
  "inline-flex items-center rounded-full border px-2 py-0.5 text-[11px] font-medium tracking-wide uppercase",
  {
    variants: {
      variant: {
        default: "border-[var(--line)] text-[var(--muted)]",
        accent: "border-transparent bg-[var(--accent)] text-[var(--accent-ink)]",
        warn: "border-transparent bg-[var(--warn-bg)] text-[var(--warn)]",
        ok: "border-transparent bg-[var(--ok-bg)] text-[var(--ok)]",
      },
    },
    defaultVariants: { variant: "default" },
  },
);

export function Badge({
  className,
  variant,
  ...props
}: HTMLAttributes<HTMLSpanElement> & VariantProps<typeof badgeVariants>) {
  return <span className={cn(badgeVariants({ variant }), className)} {...props} />;
}
