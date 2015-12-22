CREATE TABLE [dbo].[glnofin]
(
[timestamp] [timestamp] NOT NULL,
[nonfin_budget_code] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[nonfin_budget_desc] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [glnofin_ind_0] ON [dbo].[glnofin] ([nonfin_budget_code]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[glnofin] TO [public]
GO
GRANT SELECT ON  [dbo].[glnofin] TO [public]
GO
GRANT INSERT ON  [dbo].[glnofin] TO [public]
GO
GRANT DELETE ON  [dbo].[glnofin] TO [public]
GO
GRANT UPDATE ON  [dbo].[glnofin] TO [public]
GO
