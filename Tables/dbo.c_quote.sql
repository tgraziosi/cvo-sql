CREATE TABLE [dbo].[c_quote]
(
[timestamp] [timestamp] NOT NULL,
[customer_key] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ship_to_no] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ilevel] [int] NOT NULL,
[item] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[min_qty] [decimal] (20, 8) NOT NULL,
[type] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[rate] [decimal] (20, 8) NOT NULL,
[note] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[date_entered] [datetime] NULL,
[date_expires] [datetime] NULL,
[sales_comm] [decimal] (20, 8) NOT NULL,
[cust_part_no] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[curr_key] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[start_date] [datetime] NULL,
[style] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[res_type] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


CREATE TRIGGER [dbo].[EAI_c_quote_del] ON [dbo].[c_quote]   FOR DELETE  AS 
BEGIN
	DECLARE @cust_id varchar(10)
	Declare @item_id varchar(30), 
	@last_customer_key varchar(10), 
	@last_item varchar(30), 
	@data varchar(100),	-- rev 1
	@date_expires varchar(10),
	@last_date_expires varchar(10),
	@min_qty float,
	@last_min_qty float,
	@ship_to_no varchar(10),
	@ilevel int
	Declare @send_document_flag char(1)  -- rev 2

	select @send_document_flag = 'N'

	IF Exists( SELECT * FROM config WHERE flag = 'EAI' and value_str = 'Y')
	BEGIN	--EAI enable

		IF ((Exists( select 'X'
			from inserted i, deleted d
			where 	(i.customer_key <> d.customer_key) or 
				(i.item <> d.item) or 
				(i.type <> d.type) or 
				(i.rate <> d.rate) or 
				(i.date_entered <> d.date_entered) or 
				(i.date_expires <> d.date_expires) or
				(i.min_qty <> d.min_qty)))	 	--Case of update
			or (Not Exists(select 'X' from deleted))	--Case of inserted
			or (Not Exists(select 'X' from inserted)))	--Case of deleted
		BEGIN
			select @send_document_flag = 'Y'	--passes the initial test
		END
		ELSE BEGIN
			-- rev 2:  add ability to send individual docs through Query Analyzer
			If Update(customer_key) or Update(item) or Update(type) or Update(rate) or 
			Update(date_entered) or Update(date_expires) or Update(min_qty) begin
				select @send_document_flag = 'Y'
			end
		END


		If @send_document_flag = 'Y' BEGIN	--c_quote has been changed, send data to Front Office

			DECLARE c_quote_del CURSOR FOR
				SELECT customer_key, item, convert(char(10),date_expires, 101), min_qty, convert(char(10),date_expires, 101), min_qty, ship_to_no, ilevel FROM deleted
		
			
			OPEN c_quote_del

			FETCH NEXT FROM c_quote_del into @cust_id, @item_id, @date_expires, @min_qty, @last_date_expires, @last_min_qty, @ship_to_no, @ilevel 
			
			WHILE @@FETCH_STATUS = 0
			BEGIN

				If (@cust_id > '') and (@item_id > '') and (@date_expires > '') 
				begin
					select @data = convert(varchar(10), @cust_id) + '|' + convert(varchar(30), @item_id) + '|' + convert(varchar(10), @date_expires) + '|' + convert(varchar(12), @min_qty) + '|' + convert(varchar(10), @last_date_expires) + '|' + convert(varchar(12), @last_min_qty) + '|' + 'D' + '|' + convert(varchar(10), @ship_to_no) + '|' + convert(varchar(4), @ilevel)
					exec EAI_process_insert 'SpecialPrice', @data , 'BO'
				end

				FETCH NEXT FROM c_quote_del into @cust_id, @item_id, @date_expires, @min_qty, @last_date_expires, @last_min_qty, @ship_to_no, @ilevel 

			END	
			
			CLOSE c_quote_del
			DEALLOCATE c_quote_del

		END
	END
END

GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


CREATE TRIGGER [dbo].[EAI_c_quote_ins] ON [dbo].[c_quote]   FOR INSERT  AS 
BEGIN
	DECLARE @cust_id varchar(10)
	Declare @item_id varchar(30), 
	@last_customer_key varchar(10), 
	@last_item varchar(30), 
	@data varchar(100),	-- rev 1
	@date_expires varchar(10),
	@last_date_expires varchar(10),
	@min_qty float,
	@last_min_qty float,
	@ship_to_no varchar(10),
	@ilevel int
	Declare @send_document_flag char(1)  -- rev 2

	select @send_document_flag = 'N'

	IF Exists( SELECT * FROM config WHERE flag = 'EAI' and value_str = 'Y')
	BEGIN	--EAI enable

		IF ((Exists( select 'X'
			from inserted i, deleted d
			where 	(i.customer_key <> d.customer_key) or 
				(i.item <> d.item) or 
				(i.type <> d.type) or 
				(i.rate <> d.rate) or 
				(i.date_entered <> d.date_entered) or 
				(i.date_expires <> d.date_expires) or
				(i.min_qty <> d.min_qty)))	 	--Case of update
			or (Not Exists(select 'X' from deleted))	--Case of inserted
			or (Not Exists(select 'X' from inserted)))	--Case of deleted
		BEGIN
			select @send_document_flag = 'Y'	--passes the initial test
		END
		ELSE BEGIN
			-- rev 2:  add ability to send individual docs through Query Analyzer
			If Update(customer_key) or Update(item) or Update(type) or Update(rate) or 
			Update(date_entered) or Update(date_expires) or Update(min_qty) begin
				select @send_document_flag = 'Y'
			end
		END


		If @send_document_flag = 'Y' BEGIN	--c_quote has been changed, send data to Front Office

			DECLARE c_quote_ins CURSOR FOR
				SELECT customer_key, item, convert(char(10), date_expires, 101), min_qty, convert(char(10), date_expires, 101), min_qty, ship_to_no, ilevel FROM inserted
					
			OPEN c_quote_ins

			FETCH NEXT FROM c_quote_ins into @cust_id, @item_id, @date_expires, @min_qty, @last_date_expires, @last_min_qty, @ship_to_no, @ilevel

			WHILE @@FETCH_STATUS = 0
			BEGIN

				If (@cust_id > '') and (@item_id > '') and (@date_expires > '') 
				begin
					select @data = convert(varchar(10), @cust_id) + '|' + convert(varchar(30), @item_id) + '|' + convert(varchar(10), @date_expires) + '|' + convert(varchar(12), @min_qty) + '|' + convert(varchar(10), @last_date_expires) + '|' + convert(varchar(12), @last_min_qty) + '|' + 'I' + '|' + convert(varchar(10), @ship_to_no) + '|' + convert(varchar(4), @ilevel)
					exec EAI_process_insert 'SpecialPrice', @data , 'BO'
				end

				FETCH NEXT FROM c_quote_ins into @cust_id, @item_id, @date_expires, @min_qty, @last_date_expires, @last_min_qty, @ship_to_no, @ilevel

			END	
			
			CLOSE c_quote_ins
			DEALLOCATE c_quote_ins

		END
	END
END

GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


CREATE TRIGGER [dbo].[EAI_c_quote_upd] ON [dbo].[c_quote]   FOR UPDATE  AS 
BEGIN
	DECLARE @cust_id varchar(10)
	Declare @item_id varchar(30), 
	@last_customer_key varchar(10), 
	@last_item varchar(30), 
	@data varchar(100),	-- rev 1
	@date_expires varchar(10),
	@last_date_expires varchar(10),
	@min_qty float,
	@last_min_qty float,
	@dif_min_qty int,
	@dif_date_expires int,
	@execute_general int,
	@qty_date_upd int,
	@ship_to_no varchar(10),
	@ilevel	int
	Declare @send_document_flag char(1)  -- rev 2

	select @send_document_flag = 'N'

	IF Exists( SELECT * FROM config WHERE flag = 'EAI' and value_str = 'Y')
	BEGIN	--EAI enable

		IF ((Exists( select 'X'
			from inserted i, deleted d
			where 	(i.customer_key <> d.customer_key) or 
				(i.item <> d.item) or 
				(i.type <> d.type) or 
				(i.rate <> d.rate) or 
				(i.date_entered <> d.date_entered) or 
				(i.date_expires <> d.date_expires) or
				(i.min_qty <> d.min_qty)))	 	--Case of update
			or (Not Exists(select 'X' from deleted))	--Case of inserted
			or (Not Exists(select 'X' from inserted)))	--Case of deleted
		BEGIN
			select @send_document_flag = 'Y'	--passes the initial test
		END
		ELSE BEGIN
			-- rev 2:  add ability to send individual docs through Query Analyzer
			If Update(customer_key) or Update(item) or Update(type) or Update(rate) or 
			Update(date_entered) or Update(date_expires) or Update(min_qty) begin
				select @send_document_flag = 'Y'
			end
		END
		
		SELECT @execute_general = 0
		SELECT @qty_date_upd = 0

		SELECT 	@dif_date_expires = COUNT(*)  FROM inserted i, deleted d
		WHERE i.customer_key = d.customer_key
		AND i.item = d.item
		AND i.min_qty = d.min_qty
		AND i.date_expires != d.date_expires

		SELECT 	@dif_min_qty = COUNT(*)  FROM inserted i, deleted d
		WHERE i.customer_key = d.customer_key
		AND i.item = d.item
		AND i.date_expires = d.date_expires
		AND i.min_qty not in (SELECT min_qty FROM deleted WHERE date_expires = i.date_expires)

		If @send_document_flag = 'Y' 
		BEGIN	--c_quote has been changed, send data to Front Office

		IF Update(date_expires) AND (@dif_date_expires > 0)
		BEGIN
			DECLARE c_quote_upd CURSOR FOR
				SELECT i.customer_key, i.item, convert(char(10), i.date_expires, 101), i.min_qty, convert(char(10), d.date_expires, 101), d.min_qty, i.ship_to_no, i.ilevel  FROM inserted i, deleted d
				WHERE i.customer_key = d.customer_key
				AND i.item = d.item
				AND i.min_qty = d.min_qty

			OPEN c_quote_upd

			FETCH NEXT FROM c_quote_upd into @cust_id, @item_id, @date_expires, @min_qty, @last_date_expires, @last_min_qty, @ship_to_no, @ilevel

			WHILE @@FETCH_STATUS = 0
			BEGIN
			
				If (@cust_id > '') and (@item_id > '') and (@date_expires > '') 
				begin
					select @data = convert(varchar(10), @cust_id) + '|' + convert(varchar(30), @item_id) + '|' + convert(varchar(10), @date_expires) + '|' + convert(varchar(12), @min_qty) + '|' + convert(varchar(10), @last_date_expires) + '|' + convert(varchar(12), @last_min_qty) + '|' + 'U' + '|' + convert(varchar(10), @ship_to_no) + '|' + convert(varchar(4), @ilevel)
					exec EAI_process_insert 'SpecialPrice', @data , 'BO'
				end

				FETCH NEXT FROM c_quote_upd into @cust_id, @item_id, @date_expires, @min_qty, @last_date_expires, @last_min_qty, @ship_to_no, @ilevel

			END	
			
			CLOSE c_quote_upd
			DEALLOCATE c_quote_upd

		END
		ELSE
			SELECT @execute_general = 1

		IF Update(min_qty) AND (@dif_min_qty > 0)
		BEGIN
			DECLARE c_quote_upd CURSOR FOR
				SELECT i.customer_key, i.item, convert(char(10), i.date_expires, 101), i.min_qty, convert(char(10), d.date_expires, 101), d.min_qty, i.ship_to_no, i.ilevel  FROM inserted i, deleted d
				WHERE i.customer_key = d.customer_key
				AND i.item = d.item
				AND i.date_expires = d.date_expires

				
			

			OPEN c_quote_upd

			FETCH NEXT FROM c_quote_upd into @cust_id, @item_id, @date_expires, @min_qty, @last_date_expires, @last_min_qty, @ship_to_no, @ilevel

			WHILE @@FETCH_STATUS = 0
			BEGIN
			
				If (@cust_id > '') and (@item_id > '') and (@date_expires > '') 
				begin
					select @data = convert(varchar(10), @cust_id) + '|' + convert(varchar(30), @item_id) + '|' + convert(varchar(10), @date_expires) + '|' + convert(varchar(12), @min_qty) + '|' + convert(varchar(10), @last_date_expires) + '|' + convert(varchar(12), @last_min_qty) + '|' + 'U' + '|' + convert(varchar(10), @ship_to_no) + '|' + convert(varchar(4), @ilevel)
					exec EAI_process_insert 'SpecialPrice', @data , 'BO'
				end

				FETCH NEXT FROM c_quote_upd into @cust_id, @item_id, @date_expires, @min_qty, @last_date_expires, @last_min_qty, @ship_to_no, @ilevel

			END	
			
			CLOSE c_quote_upd
			DEALLOCATE c_quote_upd
		END
		ELSE
			SELECT @execute_general = 1

		IF (@execute_general = 1)
		BEGIN
			IF NOT EXISTS (SELECT 'X'  FROM inserted i, deleted d
				WHERE i.customer_key = d.customer_key
				AND i.item = d.item
				AND i.date_expires = d.date_expires
				AND i.min_qty = d.min_qty)
			BEGIN
				SELECT @qty_date_upd = 1
			
			END

			IF (@qty_date_upd = 1)
			BEGIN
				DECLARE c_quote_upd CURSOR FOR
				SELECT i.customer_key, i.item, convert(char(10), i.date_expires, 101), i.min_qty, convert(char(10), d.date_expires, 101), d.min_qty, i.ship_to_no, i.ilevel  FROM inserted i, deleted d
				WHERE i.customer_key = d.customer_key
				AND i.item = d.item
				AND i.date_expires <> d.date_expires
				AND i.min_qty <> d.min_qty
		
			

			OPEN c_quote_upd

			FETCH NEXT FROM c_quote_upd into @cust_id, @item_id, @date_expires, @min_qty, @last_date_expires, @last_min_qty, @ship_to_no, @ilevel

			WHILE @@FETCH_STATUS = 0
			BEGIN
			
				If (@cust_id > '') and (@item_id > '') and (@date_expires > '') 
				begin
					select @data = convert(varchar(10), @cust_id) + '|' + convert(varchar(30), @item_id) + '|' + convert(varchar(10), @date_expires) + '|' + convert(varchar(12), @min_qty) + '|' + convert(varchar(10), @last_date_expires) + '|' + convert(varchar(12), @last_min_qty) + '|' + 'U' + '|' + convert(varchar(10), @ship_to_no) + '|' + convert(varchar(4),@ilevel)
					exec EAI_process_insert 'SpecialPrice', @data , 'BO'
				end

				FETCH NEXT FROM c_quote_upd into @cust_id, @item_id, @date_expires, @min_qty, @last_date_expires, @last_min_qty, @ship_to_no, @ilevel

			END	
			
			CLOSE c_quote_upd
			DEALLOCATE c_quote_upd


			END
			ELSE
			BEGIN
				DECLARE c_quote_upd CURSOR FOR
				SELECT i.customer_key, i.item, convert(char(10), i.date_expires, 101) , i.min_qty, convert(char(10), d.date_expires, 101), d.min_qty, i.ship_to_no, i.ilevel  FROM inserted i, deleted d
				WHERE i.customer_key = d.customer_key
				AND i.item = d.item
				AND i.date_expires = d.date_expires
				AND i.min_qty = d.min_qty
		
			

			OPEN c_quote_upd

			FETCH NEXT FROM c_quote_upd into @cust_id, @item_id, @date_expires, @min_qty, @last_date_expires, @last_min_qty, @ship_to_no, @ilevel

			WHILE @@FETCH_STATUS = 0
			BEGIN
			
				If (@cust_id > '') and (@item_id > '') and (@date_expires > '') 
				begin
					select @data = convert(varchar(10), @cust_id) + '|' + convert(varchar(30), @item_id) + '|' + convert(varchar(10), @date_expires) + '|' + convert(varchar(12), @min_qty) + '|' + convert(varchar(10), @last_date_expires) + '|' + convert(varchar(12), @last_min_qty) + '|' + 'U' + '|' + convert(varchar(10), @ship_to_no) + '|' + convert(varchar(4), @ilevel)
					exec EAI_process_insert 'SpecialPrice', @data , 'BO'
				end

				FETCH NEXT FROM c_quote_upd into @cust_id, @item_id, @date_expires, @min_qty, @last_date_expires, @last_min_qty, @ship_to_no, @ilevel

			END	
			
			CLOSE c_quote_upd
			DEALLOCATE c_quote_upd

			END
		END

		END
	END
END

GO
CREATE UNIQUE CLUSTERED INDEX [cquote1] ON [dbo].[c_quote] ([customer_key], [ship_to_no], [curr_key], [ilevel], [item], [min_qty], [date_expires], [style], [res_type]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[c_quote] TO [public]
GO
GRANT SELECT ON  [dbo].[c_quote] TO [public]
GO
GRANT INSERT ON  [dbo].[c_quote] TO [public]
GO
GRANT DELETE ON  [dbo].[c_quote] TO [public]
GO
GRANT UPDATE ON  [dbo].[c_quote] TO [public]
GO
