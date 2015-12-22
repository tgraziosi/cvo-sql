CREATE TABLE [dbo].[adm_mfghold]
(
[timestamp] [timestamp] NOT NULL,
[hold_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[hold_reason] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [adm_mfghold_ind_0] ON [dbo].[adm_mfghold] ([hold_code]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[adm_mfghold] TO [public]
GO
GRANT SELECT ON  [dbo].[adm_mfghold] TO [public]
GO
GRANT INSERT ON  [dbo].[adm_mfghold] TO [public]
GO
GRANT DELETE ON  [dbo].[adm_mfghold] TO [public]
GO
GRANT UPDATE ON  [dbo].[adm_mfghold] TO [public]
GO
