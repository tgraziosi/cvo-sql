CREATE TABLE [dbo].[glbud]
(
[timestamp] [timestamp] NOT NULL,
[budget_code] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[budget_description] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[rate_type] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [glbud_ind_0] ON [dbo].[glbud] ([budget_code]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [glbud_ind_1] ON [dbo].[glbud] ([budget_description]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[glbud] TO [public]
GO
GRANT SELECT ON  [dbo].[glbud] TO [public]
GO
GRANT INSERT ON  [dbo].[glbud] TO [public]
GO
GRANT DELETE ON  [dbo].[glbud] TO [public]
GO
GRANT UPDATE ON  [dbo].[glbud] TO [public]
GO
