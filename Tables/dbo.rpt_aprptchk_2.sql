CREATE TABLE [dbo].[rpt_aprptchk_2]
(
[trx_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[overflow_flag] [smallint] NOT NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_aprptchk_2] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_aprptchk_2] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_aprptchk_2] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_aprptchk_2] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_aprptchk_2] TO [public]
GO
