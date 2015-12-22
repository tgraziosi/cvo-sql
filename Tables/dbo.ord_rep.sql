CREATE TABLE [dbo].[ord_rep]
(
[timestamp] [timestamp] NOT NULL,
[order_no] [int] NOT NULL,
[order_ext] [int] NOT NULL,
[salesperson] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[sales_comm] [decimal] (20, 8) NOT NULL,
[percent_flag] [smallint] NOT NULL,
[exclusive_flag] [smallint] NOT NULL,
[split_flag] [smallint] NOT NULL,
[note] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[display_line] [int] NOT NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


CREATE TRIGGER [dbo].[EAI_ord_rep_insupddel] ON [dbo].[ord_rep]	FOR INSERT, UPDATE, DELETE  AS 
BEGIN
	DECLARE @ord_no int, @ord_ext int
	DECLARE @data varchar(30)

	IF Exists( SELECT * FROM config WHERE flag = 'EAI' and value_str like 'Y%')
	BEGIN	--EAI enable
		IF ((Exists( select 'X'
			from inserted i, deleted d
			where (i.order_no <> d.order_no) or 
				(i.order_ext <> d.order_ext) or
				(i.sales_comm <> d.sales_comm) or 
				(i.salesperson <> d.salesperson))) 
			or (Not Exists(select 'X' from deleted))
			or (Not Exists(select 'X' from inserted)))
		BEGIN	--orders has been changed or new orders, send data to Front Office
			--Assume there would be one sales order get insert, update or delete at a time
			if (exists(select 'X' from inserted)) begin	-- insert or update
				select distinct @ord_no = order_no, @ord_ext = order_ext from inserted 
				if exists(select @ord_no) and exists(select @ord_ext)
					select @data = convert(varchar(12),@ord_ext) + '|' + convert(varchar(12),@ord_no)
				else
					select @data = '|'	-- rev 1
			end
			else begin	-- deleted 
				select distinct @ord_no = order_no, @ord_ext = order_ext from deleted
				if exists(select @ord_no) and exists(select @ord_ext)
					select @data = convert(varchar(12),@ord_ext) + '|' + convert(varchar(12),@ord_no)
				else
					select @data = '|'	-- rev 1
			end

			if (@data <> '') and (@data <> '|') begin	-- while loop for orders
				IF (Exists( SELECT 'X' FROM config WHERE flag = 'EAI_SEND_SO_IMAGE' and value_str like 'Y%'))
				BEGIN	--Send SO Image that create from BO to FO
					-- Customized to avoid sending SOI for any with Misc Parts
					IF not exists(select part_no from ord_list where part_type='M' and order_no = @ord_no and order_ext = @ord_ext)
					BEGIN
						exec EAI_process_insert 'SalesOrderImage', @data, 'BO'
					END
					-- End
				END
				ELSE --Check to see if the orders number is in EAI_ord_xref cross reference table 
				BEGIN
					IF (Exists (SELECT 'X' from EAI_ord_xref 
						WHERE BO_order_no = @ord_no and BO_order_ext = @ord_ext))
					BEGIN
						-- Customized to avoid sending SOI for any with Misc Parts
						IF not exists(select part_no from ord_list where part_type='M' and order_no = @ord_no and order_ext = @ord_ext)
						BEGIN
							exec EAI_process_insert 'SalesOrderImage', @data, 'BO'
						END
						-- End
					END
				END 	--End config for EAI_SEND_SO_IMAGE
			end	-- end while loop
		END	--End columns check
	END  --End EAI enable
END
GO
DISABLE TRIGGER [dbo].[EAI_ord_rep_insupddel] ON [dbo].[ord_rep]
GO
CREATE UNIQUE CLUSTERED INDEX [ordrep1] ON [dbo].[ord_rep] ([order_no], [order_ext], [display_line]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[ord_rep] TO [public]
GO
GRANT SELECT ON  [dbo].[ord_rep] TO [public]
GO
GRANT INSERT ON  [dbo].[ord_rep] TO [public]
GO
GRANT DELETE ON  [dbo].[ord_rep] TO [public]
GO
GRANT UPDATE ON  [dbo].[ord_rep] TO [public]
GO
