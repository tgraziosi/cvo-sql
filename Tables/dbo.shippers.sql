CREATE TABLE [dbo].[shippers]
(
[timestamp] [timestamp] NOT NULL,
[cust_code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ship_to_no] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ship_to_region] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[order_no] [int] NOT NULL,
[order_ext] [int] NOT NULL,
[location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[category] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[date_shipped] [datetime] NOT NULL,
[ordered] [decimal] (20, 8) NOT NULL,
[shipped] [decimal] (20, 8) NOT NULL,
[price] [decimal] (20, 8) NOT NULL,
[price_type] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[cost] [decimal] (20, 8) NOT NULL,
[sales_comm] [decimal] (20, 8) NOT NULL,
[cr_ordered] [decimal] (20, 8) NOT NULL,
[cr_shipped] [decimal] (20, 8) NOT NULL,
[salesperson] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[labor] [decimal] (20, 8) NOT NULL,
[direct_dolrs] [decimal] (20, 8) NOT NULL,
[ovhd_dolrs] [decimal] (20, 8) NOT NULL,
[util_dolrs] [decimal] (20, 8) NOT NULL,
[line_no] [int] NOT NULL,
[cust_type] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[conv_factor] [decimal] (20, 8) NULL,
[part_type] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO



CREATE TRIGGER [dbo].[t500delship] ON [dbo].[shippers] 
 FOR DELETE 
AS
begin
if exists (select 1 from config  (nolock) where flag='TRIG_DEL_SHIP' and value_str='DISABLE')	-- mls 3/28/00 SCR 22701
	return

if exists (select 1 from deleted where part_type != '@')					-- mls 3/28/00 SCR 22701
begin
	rollback tran
	exec adm_raiserror 75499 ,'You Can Not Delete A SHIPPER!' 
	return
	end
end

GO
CREATE NONCLUSTERED INDEX [ship3] ON [dbo].[shippers] ([category], [date_shipped]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [ship1] ON [dbo].[shippers] ([cust_code], [date_shipped]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [ship6] ON [dbo].[shippers] ([date_shipped]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [ship5] ON [dbo].[shippers] ([location], [date_shipped]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [shippers_matrix_ind] ON [dbo].[shippers] ([location], [part_no], [shipped], [date_shipped]) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [ship0] ON [dbo].[shippers] ([order_no], [order_ext], [line_no], [part_no]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [ship2] ON [dbo].[shippers] ([part_no], [date_shipped]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [ship4] ON [dbo].[shippers] ([salesperson], [date_shipped]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[shippers] TO [public]
GO
GRANT SELECT ON  [dbo].[shippers] TO [public]
GO
GRANT INSERT ON  [dbo].[shippers] TO [public]
GO
GRANT DELETE ON  [dbo].[shippers] TO [public]
GO
GRANT UPDATE ON  [dbo].[shippers] TO [public]
GO
