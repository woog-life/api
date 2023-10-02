alter table lake
    add column time_zone_id text not null default 'Europe/Berlin';

alter table lake
    alter column time_zone_id drop default;

update lake
set time_zone_id = 'America/Vancouver'
where id = 'fb086a0d-dc93-40fc-ad41-b6dbe0358f0b';

update lake
set time_zone_id='Europe/Athens'
where id = '359e0773-e7ee-4ee0-8c11-a9eb5082d899';

update lake
set time_zone_id = 'Europe/Brussels'
where id = 'ab6fbeb2-be73-4223-8f04-425929339838';

update lake
set time_zone_id = 'Europe/Madrid'
where id = 'a2595d6a-a6fc-4ee3-86b4-871f32f28b4c';

update lake
set time_zone_id = 'Europe/Zurich'
where id = 'acf32f07-e702-4e9e-b766-fb8993a71b21';
