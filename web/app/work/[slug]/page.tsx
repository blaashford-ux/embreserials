// app/work/[slug]/page.tsx

import { notFound } from "next/navigation";
import Link from "next/link";
import type { Metadata } from "next";
import {
  fetchWorkBySlug,
  fetchPublishedChapters,
  checkAgeGate,
} from "@/lib/supabase/queries";
import CoverImage from "@/components/CoverImage";
import AgeGateClient from "@/components/AgeGateClient";

interface Props {
  params: Promise<{ slug: string }>;
}

export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const { slug } = await params;
  const work = await fetchWorkBySlug(slug);
  if (!work) return {};
  return {
    title: `${work.title} — Embre Serials`,
    description: work.synopsis?.slice(0, 160),
    openGraph: {
      title: work.title,
      description: work.synopsis?.slice(0, 160),
      images: work.cover_url
        ? [`https://jqcxnepjkdaklzxltwrm.supabase.co/storage/v1/object/public/covers/${work.cover_url}`]
        : undefined,
    },
  };
}

const STATUS_LABELS: Record<string, string> = {
  ongoing: "Ongoing",
  completed: "Completed",
  hiatus: "On Hiatus",
  stub: "Preview (full story on Amazon)",
};

export default async function WorkPage({ params }: Props) {
  const { slug } = await params;
  const work = await fetchWorkBySlug(slug);
  if (!work) notFound();

  if (work.content_rating === "explicit") {
    const gate = await checkAgeGate();
    if (!gate.signedIn || !gate.ageConfirmed) {
      return (
        <main>
          <AgeGateClient signedIn={gate.signedIn} />
        </main>
      );
    }
  }

  const chapters = await fetchPublishedChapters(work.id);
  const allTags = [
    ...(work.tag_names ?? []),
    ...(work.theme_names ?? []),
    ...(work.kink_names ?? []),
  ];

  const percent =
    work.target_word_count && work.target_word_count > 0
      ? Math.min(100, Math.round((work.word_count_total / work.target_word_count) * 100))
      : null;

  // JSON-LD structured data for search engines
  const jsonLd = {
    "@context": "https://schema.org",
    "@type": "Book",
    name: work.title,
    description: work.synopsis,
    author: { "@type": "Person", name: work.author_display_name },
    numberOfPages: undefined,
  };

  return (
    <main>
      <script
        type="application/ld+json"
        dangerouslySetInnerHTML={{ __html: JSON.stringify(jsonLd) }}
      />

      <div className="work-detail-header">
        <CoverImage filename={work.cover_url} width={180} alt={work.title} />
        <div>
          <h1>{work.title}</h1>
          <p>
            by{" "}
            <Link href={`/author/${encodeURIComponent(work.author_display_name)}`}>
              {work.author_display_name}
            </Link>
          </p>
          <p>
            {work.word_count_total.toLocaleString()} words ·{" "}
            {work.chapter_count} chapters ·{" "}
            {STATUS_LABELS[work.status] ?? work.status}
          </p>

          {work.show_target_publicly && percent !== null && (
            <div className="word-count-progress">
              <div className="progress-bar-track">
                <div
                  className="progress-bar-fill"
                  style={{ width: `${percent}%` }}
                />
              </div>
              <p>
                {work.word_count_total.toLocaleString()} /{" "}
                {work.target_word_count!.toLocaleString()} words ({percent}%)
                {work.show_target_date_publicly && work.target_completion_date && (
                  <>
                    {" "}
                    · Target:{" "}
                    {new Date(work.target_completion_date).toLocaleDateString(
                      "en-US",
                      { year: "numeric", month: "short", day: "numeric" }
                    )}
                  </>
                )}
              </p>
            </div>
          )}
        </div>
      </div>

      {allTags.length > 0 && (
        <div style={{ marginTop: 16 }}>
          {allTags.map((t) => (
            <span key={t} className="chip">
              {t}
            </span>
          ))}
        </div>
      )}

      <h2 style={{ marginTop: 32 }}>Synopsis</h2>
      <p>{work.synopsis}</p>

      <h2 style={{ marginTop: 32 }}>Chapters</h2>
      {chapters.length === 0 ? (
        <p>No chapters published yet.</p>
      ) : (
        <div>
          {chapters.map((c) => (
            <Link
              key={c.id}
              href={`/work/${slug}/chapter/${c.chapter_number}`}
              className="chapter-list-row"
            >
              <span>
                Chapter {c.chapter_number}
                {c.title ? `: ${c.title}` : ""}
              </span>
              <span>{c.word_count.toLocaleString()} words</span>
            </Link>
          ))}
        </div>
      )}
    </main>
  );
}
