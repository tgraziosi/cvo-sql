CREATE TABLE [dbo].[cvo_lens_options]
(
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[added_by] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[added_date] [datetime] NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [cvo_lens_options_ind0] ON [dbo].[cvo_lens_options] ([part_no]) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[cvo_lens_options] TO [public]
GO
GRANT INSERT ON  [dbo].[cvo_lens_options] TO [public]
GO
GRANT DELETE ON  [dbo].[cvo_lens_options] TO [public]
GO
GRANT UPDATE ON  [dbo].[cvo_lens_options] TO [public]
GO
