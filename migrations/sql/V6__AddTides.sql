alter table lake
    add column supports_tides bool not null default false;

alter table lake
    alter column supports_tides drop default;

create table tide_data
(
    lake_id      uuid        not null references lake (id),
    time         timestamptz not null,
    is_high_tide bool        not null
);

create index idx_tide_data_time on tide_data (lake_id, time asc);
