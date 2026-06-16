# Embre Serials

Fiction platform for readers and writers -- deploys to serials.embre.net

## Structure

  app/                 Flutter app (iOS, Android, Web)
  web/                 Next.js SSR layer (public SEO pages)
  supabase/migrations/ SQL migrations

## Shared infrastructure

  Supabase project : jqcxnepjkdaklzxltwrm (same as main Embre)
  Schema           : serials (isolated; shares public taxonomy tables)
  Auth             : identical -- same users, JWTs, RBAC roles
  Storage          : shared covers bucket (Kindle 1:1.6 ratio)

## Running locally

  Flutter:   cd app  &&  flutter run -d chrome
  Next.js:   cd web  &&  npm run dev   (http://localhost:3000)

## Apply schema

  Supabase Dashboard -> SQL Editor
  Paste and run: supabase/migrations/001_serials_schema.sql

## Deploy

  Flutter web : flutter build web -> upload build/web
  Next.js     : push to Vercel (auto-deploy from GitHub)