CREATE TABLE [dbo].[adm_oehold_staging]
(
[hold_code] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[hold_reason] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[adm_oehold_staging] TO [public]
GO
GRANT INSERT ON  [dbo].[adm_oehold_staging] TO [public]
GO
GRANT DELETE ON  [dbo].[adm_oehold_staging] TO [public]
GO
GRANT UPDATE ON  [dbo].[adm_oehold_staging] TO [public]
GO
