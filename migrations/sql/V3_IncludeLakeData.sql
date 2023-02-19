insert into lake (id, name, supports_temperature, supports_booking)
values ('69c8438b-5aef-442f-a70d-e0d783ea2b38', 'Großer Woog', true, false),
       ('25aa2968-e34e-4f86-87cc-56b16b5aff36', 'Arheilger Mühlchen', false, false),
       ('55e5f52a-2de8-458a-828f-3c043ef458d9', 'Alster in Hamburg', true, false),
       ('d074654c-dedd-46c3-8042-af55c93c910e', 'Nordsee bei Cuxhaven', true, false),
       ('bedbdac7-7d61-48d5-b1bd-0de5be25e953', 'Potsdamer Havel', true, false),
       ('acf32f07-e702-4e9e-b766-fb8993a71b21', 'Aare (Bern Schönau)', true, false),
       ('ab337e4e-7673-4b5e-9c95-393f06f548c8', 'Rhein (Köln)', true, false),
       ('ab6fbeb2-be73-4223-8f04-425929339838', 'Blaarmeersen (Gent)', true, false),
       ('a2595d6a-a6fc-4ee3-86b4-871f32f28b4c', 'Santander (Kantabrien)', true, false),
       ('359e0773-e7ee-4ee0-8c11-a9eb5082d899', 'Heraklion (Kreta)', true, false)
on conflict do nothing;
