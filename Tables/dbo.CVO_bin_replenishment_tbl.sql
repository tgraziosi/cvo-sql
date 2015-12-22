CREATE TABLE [dbo].[CVO_bin_replenishment_tbl]
(
[id_rep] [int] NOT NULL IDENTITY(1, 1),
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[bin_no] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[min_qty] [decimal] (20, 8) NOT NULL,
[rep_qty] [decimal] (20, 8) NOT NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [cvo_bin_repl_ind_part_bin] ON [dbo].[CVO_bin_replenishment_tbl] ([part_no], [bin_no]) ON [PRIMARY]
GO
GRANT CONTROL ON  [dbo].[CVO_bin_replenishment_tbl] TO [public] WITH GRANT OPTION
GO
GRANT REFERENCES ON  [dbo].[CVO_bin_replenishment_tbl] TO [public]
GO
GRANT SELECT ON  [dbo].[CVO_bin_replenishment_tbl] TO [public]
GO
GRANT INSERT ON  [dbo].[CVO_bin_replenishment_tbl] TO [public]
GO
GRANT DELETE ON  [dbo].[CVO_bin_replenishment_tbl] TO [public]
GO
GRANT UPDATE ON  [dbo].[CVO_bin_replenishment_tbl] TO [public]
GO
