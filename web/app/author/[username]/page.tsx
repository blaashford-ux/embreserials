// app/author/[username]/page.tsx

import { notFound } from "next/navigation";
import type { Metadata } from "next";
import { fetchAuthorProfile, fetchWorksByAuthor } from "@/lib/supabase/queries";
import WorkCard from "@/components/WorkCard";

interface Props {
  params: Promise<{ username: string }>;
}

export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const { username } = await params;
  return { title: `${username} — Embre Serials` };
}

export default async function AuthorPage({ params }: Props) {
  const { username } = await params;
  const profile = await fetchAuthorProfile(decodeURIComponent(username));
  if (!profile) notFound();

  const works = await fetchWorksByAuthor(profile.user_id);

  return (
    <main>
      <div style={{ display: "flex", alignItems: "center", gap: 20 }}>
        {profile.avatar_url && (
          // eslint-disable-next-line @next/next/no-img-element
          <img
            src={profile.avatar_url}
            alt={profile.display_name ?? "Author"}
            width={80}
            height={80}
            style={{ borderRadius: "50%" }}
          />
        )}
        <div>
          <h1>{profile.display_name ?? "Unknown Author"}</h1>
          <p>
            {profile.total_works} works · {profile.total_words.toLocaleString()}{" "}
            words written
          </p>
        </div>
      </div>

      {profile.bio && <p style={{ marginTop: 16 }}>{profile.bio}</p>}

      <h2 className="rail-title">Works</h2>
      {works.length === 0 ? (
        <p>No published works yet.</p>
      ) : (
        <div className="work-grid">
          {works.map((w) => (
            <WorkCard key={w.id} work={w} />
          ))}
        </div>
      )}
    </main>
  );
}
