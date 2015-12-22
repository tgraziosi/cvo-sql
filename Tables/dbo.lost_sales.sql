CREATE TABLE [dbo].[lost_sales]
(
[timestamp] [timestamp] NOT NULL,
[lost_sale_no] [int] NOT NULL,
[cust_code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ship_to] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[part_type] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[uom] [char] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[conv_factor] [decimal] (20, 8) NOT NULL,
[qty] [decimal] (20, 8) NOT NULL,
[so_no] [int] NULL,
[so_ext] [int] NULL,
[note] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[date_entered] [datetime] NOT NULL,
[who_entered] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[date_modified] [datetime] NOT NULL,
[who_modified] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE TRIGGER [dbo].[lost_sales_ins] ON [dbo].[lost_sales]
FOR INSERT AS
BEGIN
	DECLARE	@i_part_no varchar(30), 
			@i_location varchar(10), 
			@i_date_entered datetime, 
			@i_qty decimal(20, 8)
			
	if exists (select 1 from config (nolock) where flag='INV_LOSTSALES_HIST' and value_str='NO') 
          return
	
	declare inscursor CURSOR FOR 
		SELECT i.part_no, i.location, i.date_entered, i.qty * i.conv_factor
		FROM inserted i
		
	OPEN inscursor
	FETCH NEXT FROM inscursor INTO @i_part_no, @i_location, @i_date_entered, @i_qty
	WHILE @@FETCH_STATUS = 0
	BEGIN
		EXEC fs_eforecast_record_sale @i_part_no, @i_location, @i_date_entered, @i_qty, 0, 0
		FETCH NEXT FROM inscursor INTO @i_part_no, @i_location, @i_date_entered, @i_qty
	END
	CLOSE inscursor
	DEALLOCATE inscursor
END

GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE TRIGGER [dbo].[lost_sales_upd] ON [dbo].[lost_sales]
FOR UPDATE AS
BEGIN
	IF NOT UPDATE(qty) RETURN
	
	DECLARE	@i_part_no varchar(30), 
			@i_location varchar(10), 
			@i_date_entered datetime, 
			@i_qty decimal(20, 8),
			@d_part_no varchar(30),
			@d_location varchar(10),
			@d_qty decimal(20, 8),
			@neg_val decimal(20, 8)

	if exists (select 1 from config (nolock) where flag='INV_LOSTSALES_HIST' and value_str='NO') return
	
	declare updcursor CURSOR FOR 
		SELECT i.part_no, i.location, i.date_entered, i.qty * i.conv_factor, d.part_no, d.location, d.qty * d.conv_factor
		FROM inserted i, deleted d
		where i.lost_sale_no = d.lost_sale_no
		
	OPEN updcursor
	FETCH NEXT FROM updcursor INTO @i_part_no, @i_location, @i_date_entered, @i_qty, @d_part_no, @d_location, @d_qty
	WHILE @@FETCH_STATUS = 0
	BEGIN
		SELECT @neg_val = 0 - @d_qty
		EXEC fs_eforecast_record_sale @d_part_no, @d_location, @i_date_entered, @neg_val, 0, 0
		EXEC fs_eforecast_record_sale @i_part_no, @i_location, @i_date_entered, @i_qty, 0, 0
		
		FETCH NEXT FROM updcursor INTO @i_part_no, @i_location, @i_date_entered, @i_qty, @d_qty
	END
	CLOSE updcursor
	DEALLOCATE updcursor
END


GO
GRANT REFERENCES ON  [dbo].[lost_sales] TO [public]
GO
GRANT SELECT ON  [dbo].[lost_sales] TO [public]
GO
GRANT INSERT ON  [dbo].[lost_sales] TO [public]
GO
GRANT DELETE ON  [dbo].[lost_sales] TO [public]
GO
GRANT UPDATE ON  [dbo].[lost_sales] TO [public]
GO
