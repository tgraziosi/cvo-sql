CREATE TABLE [dbo].[cvo_adm_oehold]
(
[timestamp] [timestamp] NOT NULL,
[hold_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[hold_dept] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [cvo_adm_oehold_ind_0] ON [dbo].[cvo_adm_oehold] ([hold_code]) ON [PRIMARY]
GO
