CREATE TABLE [dbo].[DPR_Type]
(
[type_code] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[DPR_Type] TO [public]
GO
GRANT SELECT ON  [dbo].[DPR_Type] TO [public]
GO
GRANT INSERT ON  [dbo].[DPR_Type] TO [public]
GO
GRANT DELETE ON  [dbo].[DPR_Type] TO [public]
GO
GRANT UPDATE ON  [dbo].[DPR_Type] TO [public]
GO
