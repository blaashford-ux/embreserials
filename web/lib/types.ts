// TypeScript types mirroring serials schema -- keep in sync with SQL migration.

export type ContentRating = "general" | "teen" | "mature" | "explicit";
export type WorkStatus    = "draft" | "ongoing" | "hiatus" | "completed" | "stub";
export type ListType      = "tbr" | "reading" | "read" | "recommended";

export interface Work {
  id:                        string;
  slug:                      string;
  title:                     string;
  synopsis:                  string | null;
  cover_url:                 string | null;
  author_id:                 string;
  status:                    WorkStatus;
  content_rating:            ContentRating;
  word_count_total:          number;
  chapter_count:             number;
  view_count:                number;
  follow_count:              number;
  recommendation_count:      number;
  comment_count:             number;
  target_word_count:         number | null;
  target_completion_date:    string | null;
  show_target_publicly:      boolean;
  show_target_date_publicly: boolean;
  actual_avg_pace_30d:       number | null;
  listed_on_embre:           boolean;
  embre_series_id:           number | null;
  language:                  string;
  published_at:              string | null;
  created_at:                string;
  updated_at:                string;
}

// works_full view adds aggregated taxonomy + author display info
export interface WorkFull extends Work {
  author_display_name: string;
  author_avatar_url:   string | null;
  spice_level_name:    string | null;
  fflevel_name:        string | null;
  perspective_name:    string | null;
  type_name:           string | null;
  tag_names:           string[];
  theme_names:         string[];
  kink_names:          string[];
  setting_names:       string[];
}

export interface Chapter {
  id:             string;
  work_id:        string;
  chapter_number: number;
  title:          string | null;
  author_note_pre:  string | null;   // <-- add this
  author_note_post: string | null;   // <-- add this
  content_json:   unknown;     // Quill Delta JSON
  content_text:   string | null;
  word_count:     number;
  status:         "draft" | "scheduled" | "published";
  stub_visible:   boolean;
  published_at:   string | null;
  created_at:     string;
  updated_at:     string;
}

export interface AuthorProfile {
  user_id:      string;
  display_name: string | null;
  bio:          string | null;
  avatar_url:   string | null;
  banner_url:   string | null;
  website:      string | null;
  social_links: Record<string, string>;
  total_works:  number;
  total_words:  number;
}