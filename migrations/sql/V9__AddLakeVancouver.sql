insert into lake (id, name, supports_temperature, supports_tides)
values ('fb086a0d-dc93-40fc-ad41-b6dbe0358f0b', 'Pazifik bei Vancouver', true, false)
on conflict do nothing;
