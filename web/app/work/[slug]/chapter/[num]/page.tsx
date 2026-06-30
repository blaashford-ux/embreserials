// app/work/[slug]/chapter/[num]/page.tsx

import { notFound } from "next/navigation";
import Link from "next/link";
import type { Metadata } from "next";
import {
  fetchWorkBySlug,
  fetchChapter,
  checkAgeGate,
} from "@/lib/supabase/queries";
import AgeGateClient from "@/components/AgeGateClient";

interface Props {
  params: Promise<{ slug: string; num: string }>;
}

export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const { slug, num } = await params;
  const work = await fetchWorkBySlug(slug);
  if (!work) return {};
  return {
    title: `Chapter ${num} — ${work.title} — Embre Serials`,
    description: work.synopsis?.slice(0, 160),
  };
}

export default async function ChapterPage({ params }: Props) {
  const { slug, num } = await params;
  const chapterNum = Number(num);

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

  const chapter = await fetchChapter(work.id, chapterNum);

  if (!chapter) {
    // Either doesn't exist, or stubbed beyond the visibility boundary.
    return (
      <main>
        <div className="age-gate">
          <h2>Want to keep reading?</h2>
          <p>This story continues exclusively on Amazon.</p>
          <Link href={`/work/${slug}`} className="btn-primary">
            Back to Story Page
          </Link>
        </div>
      </main>
    );
  }

  return (
    <main>
      <div className="chapter-content">
        <Link href={`/work/${slug}`}>&larr; {work.title}</Link>
        <h1>
          Chapter {chapterNum}
          {chapter.title ? `: ${chapter.title}` : ""}
        </h1>

        {chapter.author_note_pre && (
          <div className="author-note">{chapter.author_note_pre}</div>
        )}

        <article>{chapter.content_text}</article>

        {chapter.author_note_post && (
          <div className="author-note">{chapter.author_note_post}</div>
        )}

        <div className="chapter-nav">
          {chapterNum > 1 ? (
            <Link href={`/work/${slug}/chapter/${chapterNum - 1}`} className="btn-secondary">
              &larr; Previous
            </Link>
          ) : (
            <span />
          )}
          {chapterNum < work.chapter_count ? (
            <Link href={`/work/${slug}/chapter/${chapterNum + 1}`} className="btn-primary">
              Next Chapter &rarr;
            </Link>
          ) : (
            <span />
          )}
        </div>
      </div>
    </main>
  );
}
