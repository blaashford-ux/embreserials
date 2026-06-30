// app/write/[workId]/page.tsx
'use client';

import { useEffect, useState } from 'react';
import { useParams, useRouter } from 'next/navigation';
import { useAuth } from '@/lib/hooks/useAuth';
import SignInForm from '@/components/SignInForm';
import {
  fetchWork,
  updateWork,
  fetchAllChapters,
  createChapter,
  publishChapter,
  unpublishChapter,
  deleteChapter,
} from '@/lib/supabase/writeActions';
import type { WorkFull, Chapter } from '@/lib/types';

export default function WorkEditPage() {
  const params = useParams<{ workId: string }>();
  const workId = params.workId;
  const router = useRouter();
  const { user, loading: authLoading } = useAuth();

  const [work, setWork] = useState<WorkFull | null>(null);
  const [chapters, setChapters] = useState<Chapter[]>([]);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);

  const [title, setTitle] = useState('');
  const [synopsis, setSynopsis] = useState('');
  const [contentRating, setContentRating] = useState('general');
  const [status, setStatus] = useState('draft');

  useEffect(() => {
    if (!user) {
      setLoading(false);
      return;
    }
    Promise.all([fetchWork(workId), fetchAllChapters(workId)]).then(([w, c]) => {
      if (w) {
        setWork(w);
        setTitle(w.title);
        setSynopsis(w.synopsis ?? '');
        setContentRating(w.content_rating);
        setStatus(w.status);
      }
      setChapters(c);
      setLoading(false);
    });
  }, [user, workId]);

  async function refreshChapters() {
    setChapters(await fetchAllChapters(workId));
  }

  async function handleSave() {
    setSaving(true);
    try {
      await updateWork(workId, {
        title,
        synopsis,
        content_rating: contentRating,
        status,
      });
    } catch (err) {
      alert(err instanceof Error ? err.message : 'Save failed');
    } finally {
      setSaving(false);
    }
  }

  async function handleNewChapter() {
    const chapter = await createChapter(workId);
    router.push(`/write/${workId}/chapter/${chapter.id}`);
  }

  async function handleTogglePublish(chapter: Chapter) {
    if (chapter.status === 'published') {
      await unpublishChapter(chapter.id);
    } else {
      await publishChapter(chapter.id);
    }
    await refreshChapters();
  }

  async function handleDeleteChapter(chapter: Chapter) {
    if (!window.confirm('Delete this chapter? This cannot be undone.')) return;
    await deleteChapter(chapter.id);
    await refreshChapters();
  }

  if (authLoading || loading) {
    return (
      <main>
        <p>Loading...</p>
      </main>
    );
  }

  if (!user) {
    return (
      <main>
        <SignInForm />
      </main>
    );
  }

  if (!work) {
    return (
      <main>
        <p>Work not found.</p>
      </main>
    );
  }

  return (
    <main>
      <div className="write-dashboard-header">
        <h1>{work.title}</h1>
        <a href={`/work/${work.slug}`} className="btn-secondary">
          View Live
        </a>
      </div>

      <section className="write-section">
        <h2>Settings</h2>

        <label className="write-field">
          Title
          <input value={title} onChange={(e) => setTitle(e.target.value)} />
        </label>

        <label className="write-field">
          Synopsis
          <textarea
            value={synopsis}
            onChange={(e) => setSynopsis(e.target.value)}
            rows={4}
          />
        </label>

        <label className="write-field">
          Content Rating
          <select value={contentRating} onChange={(e) => setContentRating(e.target.value)}>
            <option value="general">General</option>
            <option value="teen">Teen</option>
            <option value="mature">Mature</option>
            <option value="explicit">Explicit (18+)</option>
          </select>
        </label>

        <label className="write-field">
          Status
          <select value={status} onChange={(e) => setStatus(e.target.value)}>
            <option value="draft">Draft</option>
            <option value="ongoing">Ongoing</option>
            <option value="hiatus">On Hiatus</option>
            <option value="completed">Completed</option>
          </select>
        </label>

        <button className="btn-primary" onClick={handleSave} disabled={saving}>
          {saving ? 'Saving...' : 'Save Changes'}
        </button>
      </section>

      <section className="write-section">
        <div className="write-dashboard-header">
          <h2>Chapters</h2>
          <button className="btn-primary" onClick={handleNewChapter}>
            + New Chapter
          </button>
        </div>

        {chapters.length === 0 ? (
          <p>No chapters yet.</p>
        ) : (
          chapters.map((c) => (
            <div key={c.id} className="write-chapter-row">
              <a href={`/write/${workId}/chapter/${c.id}`}>
                Chapter {c.chapter_number}
                {c.title ? `: ${c.title}` : ''}
              </a>
              <span>
                {c.word_count.toLocaleString()} words &middot; {c.status}
              </span>
              <div className="write-chapter-actions">
                <button className="link-button" onClick={() => handleTogglePublish(c)}>
                  {c.status === 'published' ? 'Unpublish' : 'Publish'}
                </button>
                <button className="link-button" onClick={() => handleDeleteChapter(c)}>
                  Delete
                </button>
              </div>
            </div>
          ))
        )}
      </section>
    </main>
  );
}
