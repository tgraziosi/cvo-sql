CREATE TABLE [dbo].[cvo_buying_groups_hist]
(
[parent] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[child] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[relation_code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[start_date_int] [int] NULL,
[start_date] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[end_date_int] [int] NULL,
[end_date] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[buying_group_no] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[modified_by] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[modified_on_int] [int] NOT NULL,
[modified_on] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [cvo_buying_groups_hist_ind1] ON [dbo].[cvo_buying_groups_hist] ([child], [start_date], [end_date]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [cvo_buying_groups_hist_ind0] ON [dbo].[cvo_buying_groups_hist] ([parent], [start_date], [end_date]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[cvo_buying_groups_hist] TO [public]
GO
GRANT SELECT ON  [dbo].[cvo_buying_groups_hist] TO [public]
GO
GRANT INSERT ON  [dbo].[cvo_buying_groups_hist] TO [public]
GO
GRANT DELETE ON  [dbo].[cvo_buying_groups_hist] TO [public]
GO
GRANT UPDATE ON  [dbo].[cvo_buying_groups_hist] TO [public]
GO
