create table lake
(
    id                   uuid primary key       not null,
    name                 character varying(128) not null,
    supports_temperature boolean                not null,
    supports_booking     boolean                not null
);

create table booking
(
    lake_id         uuid                        not null references lake (id),
    variation       text                        not null,
    begin_time      timestamp without time zone not null,
    end_time        timestamp without time zone not null,
    sale_start_time timestamp without time zone not null,
    booking_link    text                        not null,
    available       boolean                     not null,
    primary key (lake_id, variation, begin_time)
);

create table lake_data
(
    lake_id     uuid references lake (id),
    "timestamp" timestamp without time zone not null,
    temperature real                        not null,
    unique (lake_id, "timestamp")
);

create index idx_time on booking (lake_id, end_time);

create index idx_timestamp on lake_data (lake_id, "timestamp");
