alter table lake_data
    alter column "timestamp" type timestamptz using "timestamp" at time zone 'Etc/UTC';
