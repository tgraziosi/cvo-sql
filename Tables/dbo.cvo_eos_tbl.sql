CREATE TABLE [dbo].[cvo_eos_tbl]
(
[part_no] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[eff_date] [datetime] NOT NULL,
[obs_date] [datetime] NULL
) ON [PRIMARY]
GO
CREATE CLUSTERED INDEX [idx_eos_tbl_part_no] ON [dbo].[cvo_eos_tbl] ([part_no], [eff_date]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[cvo_eos_tbl] TO [public]
GO
GRANT SELECT ON  [dbo].[cvo_eos_tbl] TO [public]
GO
GRANT INSERT ON  [dbo].[cvo_eos_tbl] TO [public]
GO
GRANT DELETE ON  [dbo].[cvo_eos_tbl] TO [public]
GO
GRANT UPDATE ON  [dbo].[cvo_eos_tbl] TO [public]
GO
