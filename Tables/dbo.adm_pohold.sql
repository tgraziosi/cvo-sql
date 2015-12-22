CREATE TABLE [dbo].[adm_pohold]
(
[timestamp] [timestamp] NOT NULL,
[hold_code] [char] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[hold_reason] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [adm_pohold_ind_0] ON [dbo].[adm_pohold] ([hold_code]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[adm_pohold] TO [public]
GO
GRANT SELECT ON  [dbo].[adm_pohold] TO [public]
GO
GRANT INSERT ON  [dbo].[adm_pohold] TO [public]
GO
GRANT DELETE ON  [dbo].[adm_pohold] TO [public]
GO
GRANT UPDATE ON  [dbo].[adm_pohold] TO [public]
GO
