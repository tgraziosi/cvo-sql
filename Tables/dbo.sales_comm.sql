CREATE TABLE [dbo].[sales_comm]
(
[timestamp] [timestamp] NOT NULL,
[salesperson] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[invoice_no] [int] NOT NULL,
[line_no] [int] NOT NULL,
[order_no] [int] NOT NULL,
[order_ext] [int] NOT NULL,
[cust_code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[shipped] [decimal] (20, 8) NOT NULL,
[price_type] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[price] [decimal] (20, 8) NOT NULL,
[comm_type] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[sales_comm] [decimal] (20, 8) NOT NULL,
[rep_percnt] [decimal] (20, 8) NOT NULL,
[date_shipped] [datetime] NOT NULL,
[invoice_date] [datetime] NOT NULL,
[status] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[who_entered] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[date_entered] [datetime] NOT NULL,
[part_type] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__sales_com__part___42D8CA7E] DEFAULT ('P')
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO



CREATE TRIGGER [dbo].[t700delcomm] ON [dbo].[sales_comm]   FOR DELETE AS 
begin
if exists (select * from config where flag='TRIG_DEL_COMM' and value_str='DISABLE') return
if exists (select * from deleted where status > 'N') 
	begin
	rollback tran
	exec adm_raiserror 75299, 'You Can Not Delete A Posted Item!'
	return
	end
end

GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE TRIGGER [dbo].[t700updcomm] ON [dbo].[sales_comm]   FOR UPDATE AS 
begin
if exists (select * from config where flag='TRIG_UPD_COMM' and value_str='DISABLE') return
if exists (select * from deleted where status > 'N') 
	begin
	rollback tran
	exec adm_raiserror 95231 ,'You Can Not Change A Posted Item!'
	return
	end
end

GO
CREATE NONCLUSTERED INDEX [salecom2] ON [dbo].[sales_comm] ([invoice_date], [salesperson], [invoice_no], [line_no]) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [salecom1] ON [dbo].[sales_comm] ([salesperson], [invoice_no], [line_no]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[sales_comm] TO [public]
GO
GRANT SELECT ON  [dbo].[sales_comm] TO [public]
GO
GRANT INSERT ON  [dbo].[sales_comm] TO [public]
GO
GRANT DELETE ON  [dbo].[sales_comm] TO [public]
GO
GRANT UPDATE ON  [dbo].[sales_comm] TO [public]
GO
