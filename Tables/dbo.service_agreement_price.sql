CREATE TABLE [dbo].[service_agreement_price]
(
[timestamp] [timestamp] NOT NULL,
[item_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[curr_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[price] [decimal] (20, 8) NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


CREATE TRIGGER [dbo].[EAI_serv_agrmnt_price_insupd] ON [dbo].[service_agreement_price]   FOR INSERT, UPDATE  AS 
BEGIN
	DECLARE @item_id varchar(30), @curr_key varchar(10), @data varchar(50)
	Declare @last_item_id varchar(30), @last_curr_key varchar(10)
	Declare @send_document_flag char(1)  -- rev 4

	if exists( SELECT * FROM config WHERE flag = 'EAI' and value_str like 'Y%') begin	-- EAI is enabled

		select @last_item_id = ''
		select @last_curr_key = ''
		while 1 = 1 begin 		-- (loop through until the break)
		
			Set ROWCOUNT 1
			select @send_document_flag = 'N'

			If (not (Exists( select 'X' from deleted))) begin
				--Case of Update or insert
				select @item_id = item_id, @curr_key = curr_code 
				from inserted
				where convert(char(30), item_id) + convert(char(10), curr_code) >
				      convert(char(30), @last_item_id) + convert(char(10), @last_curr_key)
				order by item_id, curr_code
			end
			else begin
				--Case of Delete
				select @item_id = item_id, @curr_key = curr_code 
				from deleted
				where convert(char(30), item_id) + convert(char(10), curr_code) >
				      convert(char(30), @last_item_id) + convert(char(10), @last_curr_key)
				order by item_id, curr_code
			end

			If @@Rowcount <= 0 BREAK	-- this will exit the loop!

			Set ROWCOUNT 0

			if (exists(select @item_id) and exists (select @curr_key)) begin
			   if ((exists (select distinct 'X' from inserted i, deleted d
				where (i.price <> d.price) ))
				OR (not exists(select 'X' from deleted)) )
			   begin
				select @send_document_flag = 'Y'
			   end else begin
				If Update(price) begin
					select @send_document_flag = 'Y'
				end
			   end
			end

			if @send_document_flag = 'Y' begin
				-- service agreement price has been changed or inserted, send data to Front Office
				select @data = rtrim(@curr_key) + '|' + rtrim(@item_id) + '|1'
				exec EAI_process_insert 'PartPrice', @data, 'BO'
		   	end
			
			select @last_item_id = @item_id
			select @last_curr_key = @curr_key

		end	-- end while loop
	end
END
GO
CREATE UNIQUE CLUSTERED INDEX [service_agreement_price_pk] ON [dbo].[service_agreement_price] ([item_id], [curr_code]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[service_agreement_price] ADD CONSTRAINT [service_agreement_price_service_agreement_fk1] FOREIGN KEY ([item_id]) REFERENCES [dbo].[service_agreement] ([item_id])
GO
GRANT REFERENCES ON  [dbo].[service_agreement_price] TO [public]
GO
GRANT SELECT ON  [dbo].[service_agreement_price] TO [public]
GO
GRANT INSERT ON  [dbo].[service_agreement_price] TO [public]
GO
GRANT DELETE ON  [dbo].[service_agreement_price] TO [public]
GO
GRANT UPDATE ON  [dbo].[service_agreement_price] TO [public]
GO
