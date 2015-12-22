CREATE TABLE [dbo].[inv_recv]
(
[timestamp] [timestamp] NOT NULL,
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[po_on_order] [decimal] (20, 8) NOT NULL,
[cost] [decimal] (20, 8) NOT NULL,
[last_cost] [decimal] (20, 8) NOT NULL,
[recv_mtd] [decimal] (20, 8) NOT NULL,
[recv_ytd] [decimal] (20, 8) NOT NULL,
[hold_rcv] [decimal] (20, 8) NOT NULL,
[last_recv_date] [datetime] NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE TRIGGER [dbo].[t600delinvrv] ON [dbo].[inv_recv]   FOR DELETE AS 
begin

if NOT exists (select * from inv_list l, inserted i where i.part_no=l.part_no
	and i.location=l.location) return
if exists (select * from config where flag='TRIG_DEL_INV' and value_str='DISABLE')
	begin
		return
	end
else
	begin
	if exists (select * from deleted d,inventory i where 
	d.part_no=i.part_no and d.location=i.location and ( i.in_stock <> 0
	OR i.oe_on_order <> 0 OR i.po_on_order <> 0 ) and i.status != 'R') begin
	rollback tran
	exec adm_raiserror 73199, 'You Can Not Delete Inventory With In Stock Quantities!'
	return
		end
	end 
end

GO
CREATE NONCLUSTERED INDEX [inv_recv_111513] ON [dbo].[inv_recv] ([location]) INCLUDE ([recv_mtd], [part_no]) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [invl_recv] ON [dbo].[inv_recv] ([part_no], [location]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[inv_recv] TO [public]
GO
GRANT SELECT ON  [dbo].[inv_recv] TO [public]
GO
GRANT INSERT ON  [dbo].[inv_recv] TO [public]
GO
GRANT DELETE ON  [dbo].[inv_recv] TO [public]
GO
GRANT UPDATE ON  [dbo].[inv_recv] TO [public]
GO
