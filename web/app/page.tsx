// app/page.tsx

import { fetchTrendingWorks, fetchRecentWorks } from "@/lib/supabase/queries";
import WorkCard from "@/components/WorkCard";

export default async function HomePage() {
  const [trending, recent] = await Promise.all([
    fetchTrendingWorks(),
    fetchRecentWorks(),
  ]);

  return (
    <main>
      <section className="hero">
        <h1>Write freely. Read deeply.</h1>
        <p>
          A fiction platform built for serialized stories — and the people
          who write them.
        </p>
        <div className="actions">
          <a href="/browse" className="btn-primary">
            Start Reading
          </a>
          <a href="/write" className="btn-secondary">
            Start Writing
          </a>
        </div>
      </section>

      <h2 className="rail-title">Trending</h2>
      {trending.length === 0 ? (
        <p>Nothing trending yet.</p>
      ) : (
        <div className="work-grid">
          {trending.map((w) => (
            <WorkCard key={w.id} work={w} />
          ))}
        </div>
      )}

      <h2 className="rail-title">Recently Updated</h2>
      {recent.length === 0 ? (
        <p>No recent updates.</p>
      ) : (
        <div className="work-grid">
          {recent.map((w) => (
            <WorkCard key={w.id} work={w} />
          ))}
        </div>
      )}
    </main>
  );
}
