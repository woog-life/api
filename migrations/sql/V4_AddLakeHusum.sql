insert into lake (id, name, supports_temperature, supports_booking)
values ('18e6931a-3729-4ad9-8301-03c5980f82b6', 'Nordsee bei Husum', true, false),
on conflict do nothing;
