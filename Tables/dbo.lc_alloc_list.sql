CREATE TABLE [dbo].[lc_alloc_list]
(
[timestamp] [timestamp] NOT NULL,
[allocation_no] [int] NOT NULL,
[voucher_no] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[receipt_no] [int] NOT NULL,
[receipt_qty] [decimal] (20, 8) NULL,
[qty_on_hand] [decimal] (20, 8) NULL,
[item] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[old_ovhd_dolrs] [decimal] (20, 8) NOT NULL,
[adj_ovhd_dolrs] [decimal] (20, 8) NULL,
[old_matl_cost] [decimal] (20, 8) NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE TRIGGER [dbo].[t700inslcallocl] ON [dbo].[lc_alloc_list] 
FOR INSERT 
AS

return

GO
CREATE UNIQUE NONCLUSTERED INDEX [lc_alloc_list_pk] ON [dbo].[lc_alloc_list] ([allocation_no], [voucher_no], [receipt_no]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[lc_alloc_list] ADD CONSTRAINT [fk_lc_alloc_ref_90846_lc_histo] FOREIGN KEY ([allocation_no], [voucher_no]) REFERENCES [dbo].[lc_history] ([allocation_no], [voucher_no])
GO
GRANT REFERENCES ON  [dbo].[lc_alloc_list] TO [public]
GO
GRANT SELECT ON  [dbo].[lc_alloc_list] TO [public]
GO
GRANT INSERT ON  [dbo].[lc_alloc_list] TO [public]
GO
GRANT DELETE ON  [dbo].[lc_alloc_list] TO [public]
GO
GRANT UPDATE ON  [dbo].[lc_alloc_list] TO [public]
GO
