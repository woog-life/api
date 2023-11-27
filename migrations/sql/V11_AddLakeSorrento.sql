insert into lake (id, name, supports_temperature, supports_tides)
values ('4ddb043b-d0d2-44a5-b321-6efbaacf98a0', 'Tyrrhenisches Meer (Sorrento)', true, false)
on conflict do nothing;
