--VIEWS

drop view if exists all_things_and_homes
go
create view all_things_and_homes as
    select item_id, item_name, c.category_name, s.shelf_name + b.bin_name as location from items
        join categories c on c.category_id = item_category_id
        join shelves s on s.shelf_id = item_shelf_id
        join bins b on b.bin_id = item_bin_id
go

drop view if exists checkout_history_recent
go
create view checkout_history_recent as
    SELECT checkout_item_id, MAX(checkout_transaction_date) AS most_recent_date, 
        (SELECT checkout_action_id FROM checkout_history WHERE checkout_item_id = t1.checkout_item_id AND checkout_transaction_date = MAX(t1.checkout_transaction_date)) AS checkout_action_id,
        (SELECT checkout_user_id FROM checkout_history WHERE checkout_item_id = t1.checkout_item_id AND checkout_transaction_date = MAX(t1.checkout_transaction_date)) AS checkout_user_id
    FROM checkout_history t1
    GROUP BY checkout_item_id
go

drop view if exists all_things_history
go
create view all_things_history as
    select checkout_transaction_id, checkout_transaction_date, checkout_item_id, a.action_name as action, u.user_username as last_used_by
    from checkout_history
    join actions a on a.action_id=checkout_action_id
    join users u on u.user_id=checkout_user_id
go

drop view if exists items_inventory
go
create view items_inventory AS
    select checkout_item_id, i.item_name, i.category_name, i.location, most_recent_date, a.action_name as action, u.user_username as last_used_by
        from checkout_history_recent
        join all_things_and_homes i on i.item_id = checkout_item_id
        join actions a on a.action_id = checkout_action_id
        join users u on u.user_id = checkout_user_id 
go

drop view if exists items_inventory_cat_keys
GO
create view items_inventory_cat_keys as
    select *, s.value as keyword
        from items_inventory i 
        CROSS APPLY string_split(i.category_name, ' ') s
go

drop view if exists items_inventory_item_keys
GO
create view items_inventory_item_keys as
    select *, s.value as keyword
        from items_inventory i 
        CROSS APPLY string_split(i.item_name, ' ') s
go

select * from all_things_and_homes -- user friendly, all items and homes 
select * from checkout_history_recent
select * from all_things_history -- user friendly, all checkout history 
select * from items_inventory -- user friendly, all items and checkout info 

-- 
-- command F your whole life! 
drop function if exists f_search_categories
go
create function search_categories(
    @search varchar(50)
) returns table as 
    return select * from items_inventory_cat_keys where keyword = @search
go

drop function if exists f_search_items
go
create function search_items(
    @search varchar(50)
) returns table as 
    return select * from items_inventory_item_keys where keyword = @search
go

-- Checkout items, return items, add items, remove items
drop procedure if exists checkout_item
GO
create procedure checkout_item(
    @item_name varchar(50),
    @username varchar(50)
)
AS
BEGIN
    DECLARE @item_id INT;
    DECLARE @user_id INT;

    SELECT @item_id = item_id
    FROM items
    WHERE item_name = @item_name;

    SELECT @user_id = user_id
    FROM users
    WHERE user_username = @username;

    UPDATE checkout_history 
    SET checkout_action_id = 2, checkout_user_id = @user_id, checkout_transaction_date = GETDATE()
    WHERE checkout_item_id = @item_id AND checkout_action_id in (1,3)

    IF @@ROWCOUNT = 0 throw 50100, 'Error: cannot checkout items that are already checked out',1
    IF EXISTS (SELECT * FROM checkout_history WHERE checkout_item_id = @item_id AND checkout_action_id != 2)
        throw 50101, 'Error: failed to checkout item. Please check your spelling, and make sure you are already registered as a user',1
END

drop procedure if exists return_item
GO
create procedure return_item(
    @item_name varchar(50),
    @username varchar(50)
)
AS
BEGIN
    DECLARE @item_id INT;
    DECLARE @user_id INT;

    SELECT @item_id = item_id
    FROM items
    WHERE item_name = @item_name;

    SELECT @user_id = user_id
    FROM users
    WHERE user_username = @username;

    UPDATE checkout_history 
    SET checkout_action_id = 3, checkout_user_id = @user_id, checkout_transaction_date = GETDATE()
    WHERE checkout_item_id = @item_id AND checkout_action_id=2

    IF @@ROWCOUNT = 0 throw 50100, 'Error: can only return items that are checked out',1
    IF EXISTS (SELECT * FROM checkout_history WHERE checkout_item_id = @item_id AND checkout_action_id != 3)
        throw 50101, 'Error: failed to checkout item. Please check your spelling, and make sure you are already registered as a user',1
END

drop procedure if exists add_item
GO
create procedure add_item(
    @item varchar(50),
    @category varchar(50),
    @shelf char(10),
    @bin varchar(2)
)
as 
begin
    DECLARE @bin_id INT
    DECLARE @shelf_id INT
    DECLARE @category_id INT

    SELECT @bin_id = bin_id
    FROM bins
    WHERE bin_name = @bin 

    SELECT @category_id = category_id
    FROM categories
    WHERE category_name = @category

    SELECT @shelf_id = shelf_id
    FROM shelves
    WHERE shelf_name = @shelf 

    insert into items (item_name, item_category_id, item_shelf_id, item_bin_id) VALUES
    (@item, @category_id, @shelf, @bin)
    if @@ROWCOUNT = 0 throw 50102, 'Error, item not added.',1
END


drop procedure if exists remove_item
GO
create procedure remove_item(@item varchar(50))
as begin
    delete from items where item_name = @item 
    if @@ROWCOUNT = 0 throw 50102, 'Error, item not removed.',1
END






