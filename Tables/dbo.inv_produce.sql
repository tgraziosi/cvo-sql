CREATE TABLE [dbo].[inv_produce]
(
[timestamp] [timestamp] NOT NULL,
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[usage_mtd] [decimal] (20, 8) NOT NULL,
[usage_ytd] [decimal] (20, 8) NOT NULL,
[qty_scheduled] [decimal] (20, 8) NOT NULL,
[produced_mtd] [decimal] (20, 8) NOT NULL,
[produced_ytd] [decimal] (20, 8) NOT NULL,
[hold_mfg] [decimal] (20, 8) NOT NULL,
[sch_alloc] [decimal] (20, 8) NOT NULL,
[sch_date] [datetime] NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE TRIGGER [dbo].[t600delinvp] ON [dbo].[inv_produce]   FOR DELETE AS 
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
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE TRIGGER [dbo].[t602updinvp] ON [dbo].[inv_produce]
FOR UPDATE 
AS

if update(usage_mtd)
begin
if exists (select 1 from config (nolock) where flag='INV_EOM_UPD' and value_str='YES') return -- mls 4/12/00 SCR 21414 start

if exists (select 1 from inv_list l (nolock), inserted ref
  where l.part_no = ref.part_no and l.location = ref.location and l.status = 'K')
begin
  if exists (select 1 from inserted ref, inventory i (nolock)
    where ref.part_no=i.part_no and ref.location=i.location and i.status='K' and i.in_stock < 0) -- mls 4/12/00 SCR 21414 end
  begin

	insert prod_batch (prod_no, prod_ext, status, part_no, location, prod_date,
		qty, lot_ser, bin_no, project_key, 
		batch_type, qc_flag, who_entered)
	select 0, 0, 'S', ref.part_no, ref.location, getdate(),
		(i.in_stock * -1), 'N/A', 'N/A', 'N/A', 
		'A', 'N', 'AUTO-KIT'
	from inserted ref, inventory i (nolock) 
        where ref.part_no=i.part_no and ref.location=i.location and i.status='K' and i.in_stock < 0
  end
end
end
GO
CREATE UNIQUE CLUSTERED INDEX [invl_prod] ON [dbo].[inv_produce] ([part_no], [location]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[inv_produce] TO [public]
GO
GRANT SELECT ON  [dbo].[inv_produce] TO [public]
GO
GRANT INSERT ON  [dbo].[inv_produce] TO [public]
GO
GRANT DELETE ON  [dbo].[inv_produce] TO [public]
GO
GRANT UPDATE ON  [dbo].[inv_produce] TO [public]
GO
