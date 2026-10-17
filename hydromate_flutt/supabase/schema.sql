-- Skema database HydroMate untuk Supabase.
-- Jalankan sekali di Supabase Dashboard -> SQL Editor.
-- Aktifkan juga: Authentication -> Sign In / Providers -> "Allow anonymous sign-ins".

-- =========================================================================
-- 1. Profil sosial: satu baris per perangkat (user anonim)
-- =========================================================================
create table if not exists public.profil_sosial (
  id uuid primary key references auth.users (id) on delete cascade,
  nama text not null check (char_length(nama) between 2 and 24),
  kode_grup text check (kode_grup ~ '^[A-Z0-9]{6}$'),
  streak int not null default 0 check (streak >= 0),
  persen_hari_ini int not null default 0 check (persen_hari_ini >= 0),
  ml_minggu_ini int not null default 0 check (ml_minggu_ini >= 0),
  diperbarui timestamptz not null default now()
);

create index if not exists profil_sosial_kode_grup_idx
  on public.profil_sosial (kode_grup);

alter table public.profil_sosial enable row level security;

-- Semua pengguna yang masuk boleh melihat leaderboard (hanya nama & statistik)
drop policy if exists "leaderboard dapat dibaca" on public.profil_sosial;
create policy "leaderboard dapat dibaca" on public.profil_sosial
  for select to authenticated using (true);

-- Setiap pengguna hanya boleh menulis barisnya sendiri
drop policy if exists "tambah profil sendiri" on public.profil_sosial;
create policy "tambah profil sendiri" on public.profil_sosial
  for insert to authenticated with check ((select auth.uid()) = id);

drop policy if exists "ubah profil sendiri" on public.profil_sosial;
create policy "ubah profil sendiri" on public.profil_sosial
  for update to authenticated
  using ((select auth.uid()) = id) with check ((select auth.uid()) = id);

drop policy if exists "hapus profil sendiri" on public.profil_sosial;
create policy "hapus profil sendiri" on public.profil_sosial
  for delete to authenticated using ((select auth.uid()) = id);

-- Leaderboard ter-update langsung (realtime)
alter publication supabase_realtime add table public.profil_sosial;

-- =========================================================================
-- 2. Titik isi ulang air minum (dikelola admin lewat dashboard)
-- =========================================================================
create table if not exists public.titik_refill (
  id bigint generated always as identity primary key,
  nama text not null,
  keterangan text not null default '',
  jenis text not null check (jenis in ('dispenser', 'refill', 'galon')),
  gratis boolean not null default true,
  jam_buka text not null default '07.00–17.00',
  lat double precision not null,
  lng double precision not null
);

alter table public.titik_refill enable row level security;

drop policy if exists "titik refill dapat dibaca" on public.titik_refill;
create policy "titik refill dapat dibaca" on public.titik_refill
  for select to anon, authenticated using (true);

-- Data awal area kampus Unsoed Grendeng (koordinat perkiraan, cek ulang di lapangan)
insert into public.titik_refill (nama, keterangan, jenis, gratis, jam_buka, lat, lng)
select * from (values
  ('Perpustakaan Pusat', 'Dispenser di lobi lantai 1', 'dispenser', true, '07.30–20.00', -7.4285, 109.2525),
  ('Gedung Rektorat', 'Dispenser dekat ruang tunggu layanan', 'dispenser', true, '07.30–16.00', -7.4299, 109.2533),
  ('Masjid Fatimatuzzahra', 'Kran air minum di area wudu utara', 'refill', true, '04.00–21.00', -7.4307, 109.2546),
  ('GOR Soesilo Soedarman', 'Refill station di pintu masuk', 'refill', true, '06.00–21.00', -7.4318, 109.2522),
  ('Kantin Pusat', 'Isi ulang galon, bayar per botol', 'galon', false, '07.00–17.00', -7.4292, 109.2556),
  ('Gedung PKM', 'Dispenser sekretariat UKM', 'dispenser', true, '08.00–21.00', -7.4278, 109.2541)
) as v(nama, keterangan, jenis, gratis, jam_buka, lat, lng)
where not exists (select 1 from public.titik_refill);
