// components/WorkCard.tsx

import Link from "next/link";
import CoverImage from "./CoverImage";
import type { WorkFull } from "@/lib/types";

export default function WorkCard({ work }: { work: WorkFull }) {
  return (
    <Link href={`/work/${work.slug}`} className="work-card">
      <CoverImage filename={work.cover_url} width={150} alt={work.title} />
      <div className="work-card-title">{work.title}</div>
      <div className="work-card-author">{work.author_display_name}</div>
    </Link>
  );
}
