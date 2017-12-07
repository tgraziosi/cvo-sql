CREATE TABLE [dbo].[cvo_allocation_simulation_summary_det]
(
[user_spid] [int] NULL,
[bin_group] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[bin_no] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[alloc_qty] [decimal] (20, 8) NULL
) ON [PRIMARY]
GO
GRANT DELETE ON  [dbo].[cvo_allocation_simulation_summary_det] TO [public]
GO
GRANT INSERT ON  [dbo].[cvo_allocation_simulation_summary_det] TO [public]
GO
GRANT SELECT ON  [dbo].[cvo_allocation_simulation_summary_det] TO [public]
GO
GRANT UPDATE ON  [dbo].[cvo_allocation_simulation_summary_det] TO [public]
GO
