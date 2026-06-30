// lib/supabase/writeActions.ts
//
// Client-side data functions for the writing flow (dashboard, work settings,
// chapter editor). All run via the browser Supabase client under the
// signed-in author's session -- the same RLS policies that protect the
// Flutter app's writes protect these too, nothing schema-side changes.

'use client';

import { createClient } from './client';
import type { WorkFull, Chapter } from '../types';

// ---------------------------------------------------------------------------
// Works
// ---------------------------------------------------------------------------

export async function fetchMyWorks(): Promise<WorkFull[]> {
  const supabase = createClient();
  const { data: auth } = await supabase.auth.getUser();
  if (!auth.user) return [];

  const { data, error } = await supabase
    .schema('serials')
    .from('works_full')
    .select('*')
    .eq('author_id', auth.user.id)
    .order('updated_at', { ascending: false });

  if (error) throw error;
  return (data ?? []) as WorkFull[];
}

export async function createWork(title: string): Promise<WorkFull> {
  const supabase = createClient();
  const { data: auth } = await supabase.auth.getUser();
  if (!auth.user) throw new Error('Not signed in');

  const { data, error } = await supabase
    .schema('serials')
    .from('works')
    .insert({
      title,
      author_id: auth.user.id,
      status: 'draft',
      content_rating: 'general',
    })
    .select()
    .single();

  if (error) throw error;
  return data as WorkFull;
}

export async function fetchWork(workId: string): Promise<WorkFull | null> {
  const supabase = createClient();
  const { data, error } = await supabase
    .schema('serials')
    .from('works_full')
    .select('*')
    .eq('id', workId)
    .maybeSingle();

  if (error) throw error;
  return (data as WorkFull) ?? null;
}

export async function updateWork(
  workId: string,
  updates: Record<string, unknown>
): Promise<void> {
  const supabase = createClient();
  const { error } = await supabase
    .schema('serials')
    .from('works')
    .update(updates)
    .eq('id', workId);

  if (error) throw error;
}

// ---------------------------------------------------------------------------
// Chapters
// ---------------------------------------------------------------------------

export async function fetchAllChapters(workId: string): Promise<Chapter[]> {
  const supabase = createClient();
  const { data, error } = await supabase
    .schema('serials')
    .from('chapters')
    .select('*')
    .eq('work_id', workId)
    .order('chapter_number');

  if (error) throw error;
  return (data ?? []) as Chapter[];
}

export async function createChapter(workId: string): Promise<Chapter> {
  const existing = await fetchAllChapters(workId);
  const nextNum =
    existing.length === 0
      ? 1
      : Math.max(...existing.map((c) => c.chapter_number)) + 1;

  const supabase = createClient();
  const { data, error } = await supabase
    .schema('serials')
    .from('chapters')
    .insert({ work_id: workId, chapter_number: nextNum, status: 'draft' })
    .select()
    .single();

  if (error) throw error;
  return data as Chapter;
}

export async function fetchChapter(chapterId: string): Promise<Chapter | null> {
  const supabase = createClient();
  const { data, error } = await supabase
    .schema('serials')
    .from('chapters')
    .select('*')
    .eq('id', chapterId)
    .maybeSingle();

  if (error) throw error;
  return (data as Chapter) ?? null;
}

export async function saveChapter(
  chapterId: string,
  updates: { title: string | null; content_text: string; word_count: number }
): Promise<void> {
  const supabase = createClient();
  const { error } = await supabase
    .schema('serials')
    .from('chapters')
    .update(updates)
    .eq('id', chapterId);

  if (error) throw error;
}

export async function publishChapter(chapterId: string): Promise<void> {
  const supabase = createClient();
  const { error } = await supabase
    .schema('serials')
    .from('chapters')
    .update({ status: 'published', published_at: new Date().toISOString() })
    .eq('id', chapterId);

  if (error) throw error;
}

export async function unpublishChapter(chapterId: string): Promise<void> {
  const supabase = createClient();
  const { error } = await supabase
    .schema('serials')
    .from('chapters')
    .update({ status: 'draft', published_at: null })
    .eq('id', chapterId);

  if (error) throw error;
}

export async function deleteChapter(chapterId: string): Promise<void> {
  const supabase = createClient();
  const { error } = await supabase
    .schema('serials')
    .from('chapters')
    .delete()
    .eq('id', chapterId);

  if (error) throw error;
}
