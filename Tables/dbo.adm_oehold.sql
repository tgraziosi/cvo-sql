CREATE TABLE [dbo].[adm_oehold]
(
[timestamp] [timestamp] NOT NULL,
[hold_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[hold_reason] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [adm_oehold_ind_0] ON [dbo].[adm_oehold] ([hold_code]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[adm_oehold] TO [public]
GO
GRANT SELECT ON  [dbo].[adm_oehold] TO [public]
GO
GRANT INSERT ON  [dbo].[adm_oehold] TO [public]
GO
GRANT DELETE ON  [dbo].[adm_oehold] TO [public]
GO
GRANT UPDATE ON  [dbo].[adm_oehold] TO [public]
GO
