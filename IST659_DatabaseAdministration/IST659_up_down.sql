if not exists(select * from sys.databases where name = 'frank')
    create database frank
GO

use frank
go

--DOWN
if exists(select * from INFORMATION_SCHEMA.TABLE_CONSTRAINTS
    where CONSTRAINT_NAME = 'fk_checkout_history_user_id')
        alter table checkout_history drop constraint fk_checkout_history_user_id
if exists(select * from INFORMATION_SCHEMA.TABLE_CONSTRAINTS
    where CONSTRAINT_NAME = 'fk_checkout_history_action_id')
        alter table checkout_history drop constraint fk_checkout_history_action_id
if exists(select * from INFORMATION_SCHEMA.TABLE_CONSTRAINTS
    where CONSTRAINT_NAME = 'fk_checkout_history_item_id')
        alter table checkout_history drop constraint fk_checkout_history_item_id
drop table if exists checkout_history
if exists(select * from INFORMATION_SCHEMA.TABLE_CONSTRAINTS
    where CONSTRAINT_NAME = 'fk_items_item_bin_id')
        alter table items drop constraint fk_items_item_bin_id
if exists(select * from INFORMATION_SCHEMA.TABLE_CONSTRAINTS
    where CONSTRAINT_NAME = 'fk_items_item_category_id')
        alter table items drop constraint fk_items_item_category_id
if exists(select * from INFORMATION_SCHEMA.TABLE_CONSTRAINTS
    where CONSTRAINT_NAME = 'fk_items_item_shelf_id')
        alter table items drop constraint fk_items_item_shelf_id
drop table if exists items
drop table if exists shelves
drop table if exists bins
drop table if exists actions
drop table if exists categories
drop table if exists users
--

-- UP Metadata

--Shelves are numbered 1-n however many i purchase
create table shelves(
    shelf_id int identity not null,
    shelf_name char(10) not null,
    constraint pk_shelves_shelf_id primary key (shelf_id),
    constraint ck_shelves_shelf_name unique (shelf_name)
)
--bins are A1:E5
create table bins(
    bin_id int identity not null,
    bin_name varchar(2) not null,
    constraint pk_bins_bin_id primary key (bin_id),
    constraint ck_bins_bin_name unique (bin_name)
)
-- actions is a lookup table
create table actions(
    action_id int identity not null,
    action_name varchar(50) not null, 
    constraint pk_actions_action_id primary key (action_id),
    constraint ck_actions_action_name unique (action_name)
)
-- categories is also a lookup table
create table categories(
    category_id int identity not null,
    category_name varchar(50) not null,
    constraint pk_categories_category_id primary key (category_id),
    constraint ck_categories_category_name unique (category_name)
)
-- if many people are taking things in and out of frank
create table users(
    user_id int identity not null,
    user_username varchar(50) not null,
    constraint pk_users_user_id primary key (user_id),
    constraint ck_users_userrname unique (user_username)
)

create table items(
    item_id int identity not null,
    item_name varchar(50) not null,
    item_category_id int not null, --fk
    item_shelf_id int not null, --fk
    item_bin_id int not null, --fk
    constraint pk_items_item_id primary key (item_id),
    constraint u_items_item_name unique (item_name)
)
alter table items
    add constraint fk_items_item_shelf_id foreign key (item_shelf_id) 
        references shelves(shelf_id)
alter table items
    add constraint fk_items_item_category_id foreign key (item_category_id) 
        references categories(category_id)
alter table items
    add constraint fk_items_item_bin_id foreign key (item_bin_id) 
        references bins(bin_id)

create table checkout_history(
    checkout_transaction_id int IDENTITY not null,
    checkout_transaction_date date not null,
    checkout_item_id int not null, --fk
    checkout_action_id int not null, --fk
    checkout_user_id int not null, --fk
    constraint pk_checkout_history_transaction_id primary key (checkout_transaction_id),
)
alter table checkout_history
    add constraint fk_checkout_history_item_id foreign key (checkout_item_id)
        references items(item_id)
alter table checkout_history
    add constraint fk_checkout_history_action_id foreign key (checkout_action_id)
        references actions(action_id)
alter table checkout_history
    add constraint fk_checkout_history_user_id foreign key (checkout_user_id)
        references users(user_id)
--

-- Up Data
insert into shelves (shelf_name) values 
    ('avila'),('shell'),('pismo')
    -- I only have 3 kallax shelves at the moment
insert into bins (bin_name) VALUES
    ('A1'), ('A2'), ('A3'), ('A4'), ('A5'),
    ('B1'), ('B2'), ('B3'), ('B4'), ('B5'),
    ('C1'), ('C2'), ('C3'), ('C4'), ('C5'),
    ('D1'), ('D2'), ('D3'), ('D4'), ('D5'),
    ('E1'), ('E2'), ('E3'), ('E4'), ('E5')
    -- each kallax is 5x5   
insert into actions (action_name) values 
    ('new addition'), ('checked out'), ('returned')
    -- only 4 actions for now
insert into categories (category_name) values
    ('tech equipment'), ('surf accessories'), ('art supplies'), ('tools'), ('misc')
    -- four common lost items in my home
insert into users (user_username) VALUES
    ('nadia'), ('anton'),('davos'),('dante')
insert into items (item_name, item_category_id, item_shelf_id, item_bin_id) VALUES
    ('surf wax', 2, 1, 1),
    ('hdmi cable', 1, 1, 9),
    ('ceramic stamps', 3, 2, 1),
    ('screwdriver', 4, 3, 25),
    ('paintbrushes',3, 1, 12),
    ('fins', 2, 2, 18)
insert into checkout_history (checkout_transaction_date, checkout_item_id, checkout_action_id, checkout_user_id) VALUES
    ('2023-01-01', 1, 1, 1),
    ('2023-01-01', 2, 1, 1),
    ('2023-01-01', 3, 1, 2),
    ('2023-01-01', 4, 1, 3),
    ('2023-01-01', 5, 1, 3),
    ('2023-01-01', 6, 1, 1),
    ('2023-02-01', 2, 2, 4),
    ('2023-02-04', 2, 3, 4),
    ('2023-02-03', 5, 2, 2),
    ('2023-02-03', 5, 3, 2),
    ('2023-02-15', 2, 2, 1), -- unreturned
    ('2023-02-15', 5, 2, 3),
    ('2023-02-15', 5, 3, 3),    
    ('2023-02-17', 5, 2, 2),
    ('2023-02-18', 5, 3, 2),
    ('2023-02-20', 1, 4, 1)



--

select * from shelves
select * from bins
select * from actions
select * from categories
select * from users
select * from items
select * from checkout_history


