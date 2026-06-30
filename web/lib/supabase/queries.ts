// lib/supabase/queries.ts
//
// Shared query functions used across homepage, browse, work, and author pages.
// Keeping these in one place avoids repeating the same .schema('serials')
// query shape in every page file.

import { createClient } from "./server";
import type { WorkFull, Chapter, AuthorProfile } from "../types";

export async function fetchTrendingWorks(limit = 6): Promise<WorkFull[]> {
  const supabase = await createClient();
  const { data } = await supabase
    .schema("serials")
    .from("works_full")
    .select("*")
    .neq("status", "draft")
    .neq("content_rating", "explicit")
    .order("follow_count", { ascending: false })
    .limit(limit);
  return (data ?? []) as WorkFull[];
}

export async function fetchRecentWorks(limit = 12): Promise<WorkFull[]> {
  const supabase = await createClient();
  const { data } = await supabase
    .schema("serials")
    .from("works_full")
    .select("*")
    .eq("status", "ongoing")
    .neq("content_rating", "explicit")
    .order("published_at", { ascending: false })
    .limit(limit);
  return (data ?? []) as WorkFull[];
}

export interface BrowseFilters {
  type?: string;
  tag?: string;
  status?: string;
  includeExplicit?: boolean;
  sort?: string;
  page?: number;
}

const PAGE_SIZE = 24;

export async function fetchBrowseWorks(filters: BrowseFilters): Promise<WorkFull[]> {
  const supabase = await createClient();
  let query = supabase
    .schema("serials")
    .from("works_full")
    .select("*")
    .neq("status", "draft");

  if (filters.status) query = query.eq("status", filters.status);
  if (!filters.includeExplicit) query = query.neq("content_rating", "explicit");
  if (filters.type) query = query.eq("type_name", filters.type);
  if (filters.tag) query = query.contains("tag_names", [filters.tag]);

  const sortColumn = filters.sort ?? "published_at";
  const page = filters.page ?? 0;
  const from = page * PAGE_SIZE;
  const to = from + PAGE_SIZE - 1;

  const { data } = await query
    .order(sortColumn, { ascending: false })
    .range(from, to);
  return (data ?? []) as WorkFull[];
}

export async function fetchWorkBySlug(slug: string): Promise<WorkFull | null> {
  const supabase = await createClient();
  const { data } = await supabase
    .schema("serials")
    .from("works_full")
    .select("*")
    .eq("slug", slug)
    .neq("status", "draft")
    .single();
  return (data as WorkFull) ?? null;
}

export async function fetchPublishedChapters(workId: string): Promise<Chapter[]> {
  const supabase = await createClient();
  const { data } = await supabase
    .schema("serials")
    .from("chapters")
    .select("id, chapter_number, title, word_count, published_at")
    .eq("work_id", workId)
    .eq("status", "published")
    .eq("stub_visible", true)
    .order("chapter_number");
  return (data ?? []) as Chapter[];
}

export async function fetchChapter(
  workId: string,
  chapterNumber: number
): Promise<Chapter | null> {
  const supabase = await createClient();
  const { data } = await supabase
    .schema("serials")
    .from("chapters")
    .select("*")
    .eq("work_id", workId)
    .eq("chapter_number", chapterNumber)
    .eq("status", "published")
    .eq("stub_visible", true)
    .single();
  return (data as Chapter) ?? null;
}

export async function fetchAuthorProfile(displayName: string): Promise<AuthorProfile | null> {
  const supabase = await createClient();
  const { data } = await supabase
    .schema("serials")
    .from("author_profiles")
    .select("*")
    .eq("display_name", displayName)
    .single();
  return (data as AuthorProfile) ?? null;
}

export async function fetchWorksByAuthor(authorId: string): Promise<WorkFull[]> {
  const supabase = await createClient();
  const { data } = await supabase
    .schema("serials")
    .from("works_full")
    .select("*")
    .eq("author_id", authorId)
    .neq("status", "draft")
    .order("published_at", { ascending: false });
  return (data ?? []) as WorkFull[];
}

// ---------------------------------------------------------------------------
// Age gate — explicit content requires a signed-in user with age_confirmed.
// ---------------------------------------------------------------------------

export interface AgeGateStatus {
  signedIn: boolean;
  ageConfirmed: boolean;
}

export async function checkAgeGate(): Promise<AgeGateStatus> {
  const supabase = await createClient();
  const { data: auth } = await supabase.auth.getUser();
  if (!auth?.user) return { signedIn: false, ageConfirmed: false };

  const { data } = await supabase
    .from("users")
    .select("age_confirmed")
    .eq("id", auth.user.id)
    .single();

  return { signedIn: true, ageConfirmed: data?.age_confirmed === true };
}
