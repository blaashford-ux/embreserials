// components/AgeGateClient.tsx
"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { createClient } from "@/lib/supabase/client";

interface Props {
  signedIn: boolean;
}

/// Renders one of two states:
///   not signed in   -> prompt to sign in (handled in the Flutter app / account flow)
///   signed in       -> confirm-age button that writes to public.users and refreshes
export default function AgeGateClient({ signedIn }: Props) {
  const router = useRouter();
  const [loading, setLoading] = useState(false);

  async function confirmAge() {
    setLoading(true);
    const supabase = createClient();
    const { data: auth } = await supabase.auth.getUser();
    if (auth?.user) {
      await supabase
        .from("users")
        .update({ age_confirmed: true, age_confirmed_at: new Date().toISOString() })
        .eq("id", auth.user.id);
    }
    router.refresh();
  }

  return (
    <div className="age-gate">
      <h2>Age Restricted Content</h2>
      <p>This work is marked Explicit (18+).</p>
      {signedIn ? (
        <>
          <p>By continuing you confirm that you are 18 or older.</p>
          <button onClick={confirmAge} disabled={loading} className="btn-primary">
            {loading ? "Confirming..." : "I confirm I am 18+"}
          </button>
        </>
      ) : (
        <p>Sign in to your Embre account to view this content.</p>
      )}
    </div>
  );
}
