CREATE TABLE [dbo].[arcbstat]
(
[cb_status_code] [varchar] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[cb_status_desc] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [arcbstat_ind_0] ON [dbo].[arcbstat] ([cb_status_code]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[arcbstat] TO [public]
GO
GRANT SELECT ON  [dbo].[arcbstat] TO [public]
GO
GRANT INSERT ON  [dbo].[arcbstat] TO [public]
GO
GRANT DELETE ON  [dbo].[arcbstat] TO [public]
GO
GRANT UPDATE ON  [dbo].[arcbstat] TO [public]
GO
