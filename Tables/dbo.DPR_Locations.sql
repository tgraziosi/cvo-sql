CREATE TABLE [dbo].[DPR_Locations]
(
[location] [varchar] (80) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[DPR_Locations] TO [public]
GO
GRANT SELECT ON  [dbo].[DPR_Locations] TO [public]
GO
GRANT INSERT ON  [dbo].[DPR_Locations] TO [public]
GO
GRANT DELETE ON  [dbo].[DPR_Locations] TO [public]
GO
GRANT UPDATE ON  [dbo].[DPR_Locations] TO [public]
GO
