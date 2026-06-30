// app/write/[workId]/chapter/[chapterId]/page.tsx
//
// Plain textarea editor for now -- matches the "basic now, polish later"
// priority. Saves straight to chapters.content_text, which is exactly what
// the reader pages already render, so nothing on the reading side needs to
// change. content_json (used by the Flutter Quill editor) is left null for
// chapters created here; the two editors can converge later if needed.

'use client';

import { useEffect, useState } from 'react';
import { useParams, useRouter } from 'next/navigation';
import { useAuth } from '@/lib/hooks/useAuth';
import SignInForm from '@/components/SignInForm';
import { fetchChapter, saveChapter, publishChapter } from '@/lib/supabase/writeActions';
import type { Chapter } from '@/lib/types';

function countWords(text: string): number {
  const trimmed = text.trim();
  return trimmed ? trimmed.split(/\s+/).length : 0;
}

export default function ChapterEditorPage() {
  const params = useParams<{ workId: string; chapterId: string }>();
  const { workId, chapterId } = params;
  const router = useRouter();
  const { user, loading: authLoading } = useAuth();

  const [chapter, setChapter] = useState<Chapter | null>(null);
  const [loading, setLoading] = useState(true);
  const [title, setTitle] = useState('');
  const [body, setBody] = useState('');
  const [dirty, setDirty] = useState(false);
  const [saving, setSaving] = useState(false);
  const [savedOnce, setSavedOnce] = useState(false);

  useEffect(() => {
    if (!user) {
      setLoading(false);
      return;
    }
    fetchChapter(chapterId).then((c) => {
      if (c) {
        setChapter(c);
        setTitle(c.title ?? '');
        setBody(c.content_text ?? '');
      }
      setLoading(false);
    });
  }, [user, chapterId]);

  // Autosave every 30s while there are unsaved changes.
  useEffect(() => {
    const interval = setInterval(() => {
      if (dirty) doSave(false);
    }, 30000);
    return () => clearInterval(interval);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [dirty, title, body]);

  async function doSave(showAlert = true) {
    setSaving(true);
    try {
      await saveChapter(chapterId, {
        title: title.trim() || null,
        content_text: body,
        word_count: countWords(body),
      });
      setDirty(false);
      setSavedOnce(true);
    } catch (err) {
      if (showAlert) alert(err instanceof Error ? err.message : 'Save failed');
    } finally {
      setSaving(false);
    }
  }

  async function handlePublish() {
    await doSave(false);
    await publishChapter(chapterId);
    router.push(`/write/${workId}`);
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

  if (!chapter) {
    return (
      <main>
        <p>Chapter not found.</p>
      </main>
    );
  }

  const wordCount = countWords(body);

  return (
    <main>
      <a href={`/write/${workId}`} className="back-link">
        &larr; Back to work
      </a>

      <input
        className="chapter-title-input"
        placeholder="Chapter title (optional)"
        value={title}
        onChange={(e) => {
          setTitle(e.target.value);
          setDirty(true);
        }}
      />

      <textarea
        className="chapter-body-input"
        value={body}
        onChange={(e) => {
          setBody(e.target.value);
          setDirty(true);
        }}
        rows={24}
        placeholder="Start writing..."
      />

      <div className="chapter-editor-statusbar">
        <span>
          {wordCount.toLocaleString()} words
          {dirty ? ' \u00b7 Unsaved changes' : savedOnce ? ' \u00b7 Saved' : ''}
        </span>
        <div>
          <button className="btn-secondary" onClick={() => doSave()} disabled={saving}>
            Save Draft
          </button>
          <button className="btn-primary" onClick={handlePublish} disabled={saving}>
            {chapter.status === 'published' ? 'Republish' : 'Publish'}
          </button>
        </div>
      </div>
    </main>
  );
}
