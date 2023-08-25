alter table tide_data
    add column height text not null default '0.0';

alter table tide_data
    alter column height drop default;
