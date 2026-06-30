// app/browse/page.tsx
//
// Filters are driven entirely by URL search params so the page stays SSR
// and every filter combination is a real, crawlable, shareable URL.

import { fetchBrowseWorks } from "@/lib/supabase/queries";
import WorkCard from "@/components/WorkCard";

interface Props {
  searchParams: Promise<{
    type?: string;
    tag?: string;
    status?: string;
    explicit?: string;
    sort?: string;
    page?: string;
  }>;
}

export const metadata = {
  title: "Browse — Embre Serials",
};

export default async function BrowsePage({ searchParams }: Props) {
  const params = await searchParams;
  const works = await fetchBrowseWorks({
    type: params.type,
    tag: params.tag,
    status: params.status,
    includeExplicit: params.explicit === "1",
    sort: params.sort,
    page: params.page ? parseInt(params.page, 10) : 0,
  });

  // Plain <form method="get"> keeps this page filterable without client JS —
  // every filter combination becomes a real, bookmarkable URL.
  return (
    <main>
      <h1>Browse</h1>

      <form method="get" className="filter-bar">
        <select name="status" defaultValue={params.status ?? ""}>
          <option value="">All Statuses</option>
          <option value="ongoing">Ongoing</option>
          <option value="completed">Completed</option>
          <option value="hiatus">On Hiatus</option>
        </select>

        <select name="sort" defaultValue={params.sort ?? "published_at"}>
          <option value="published_at">Recently Updated</option>
          <option value="follow_count">Most Followed</option>
          <option value="word_count_total">Word Count</option>
          <option value="created_at">Newest</option>
        </select>

        <label>
          <input
            type="checkbox"
            name="explicit"
            value="1"
            defaultChecked={params.explicit === "1"}
          />{" "}
          Show Explicit
        </label>

        <button type="submit" className="btn-secondary">
          Apply
        </button>
      </form>

      {works.length === 0 ? (
        <p>No works match these filters.</p>
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
