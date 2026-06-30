// app/write/page.tsx
'use client';

import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import { useAuth } from '@/lib/hooks/useAuth';
import SignInForm from '@/components/SignInForm';
import { fetchMyWorks, createWork } from '@/lib/supabase/writeActions';
import type { WorkFull } from '@/lib/types';

export default function WriteDashboardPage() {
  const { user, loading: authLoading } = useAuth();
  const router = useRouter();

  const [works, setWorks] = useState<WorkFull[]>([]);
  const [loading, setLoading] = useState(true);
  const [creating, setCreating] = useState(false);

  useEffect(() => {
    if (!user) {
      setLoading(false);
      return;
    }
    fetchMyWorks().then((w) => {
      setWorks(w);
      setLoading(false);
    });
  }, [user]);

  async function handleCreate() {
    const title = window.prompt('Title for your new work:');
    if (!title || !title.trim()) return;
    setCreating(true);
    try {
      const work = await createWork(title.trim());
      router.push(`/write/${work.id}`);
    } catch (err) {
      alert(err instanceof Error ? err.message : 'Failed to create work');
    } finally {
      setCreating(false);
    }
  }

  if (authLoading) {
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

  return (
    <main>
      <div className="write-dashboard-header">
        <h1>My Works</h1>
        <button className="btn-primary" onClick={handleCreate} disabled={creating}>
          {creating ? 'Creating...' : '+ New Work'}
        </button>
      </div>

      {loading ? (
        <p>Loading your works...</p>
      ) : works.length === 0 ? (
        <p>You haven&apos;t started a work yet.</p>
      ) : (
        <div className="write-works-list">
          {works.map((w) => (
            <a key={w.id} href={`/write/${w.id}`} className="write-work-row">
              <span className="write-work-title">{w.title}</span>
              <span className="write-work-meta">
                {w.status} &middot; {w.word_count_total.toLocaleString()} words &middot;{' '}
                {w.chapter_count} chapters
              </span>
            </a>
          ))}
        </div>
      )}
    </main>
  );
}
