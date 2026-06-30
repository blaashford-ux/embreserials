// components/CoverImage.tsx

import Image from "next/image";

const STORAGE_BASE =
  "https://jqcxnepjkdaklzxltwrm.supabase.co/storage/v1/object/public/covers";

interface Props {
  filename: string | null;
  width: number;
  alt: string;
}

// Kindle standard portrait ratio 1:1.6 — matches the Flutter app's CoverImage.
export default function CoverImage({ filename, width, alt }: Props) {
  const height = Math.round(width * 1.6);

  if (!filename) {
    return (
      <div
        className="cover-placeholder"
        style={{ width, height }}
        aria-label={alt}
      />
    );
  }

  return (
    <Image
      src={`${STORAGE_BASE}/${filename}`}
      width={width}
      height={height}
      alt={alt}
      className="cover-image"
    />
  );
}
