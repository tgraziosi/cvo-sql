CREATE TABLE [dbo].[rpt_arcusmerdtl]
(
[process_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[merged_customer] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[merged_name] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_arcusmerdtl] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_arcusmerdtl] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_arcusmerdtl] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_arcusmerdtl] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_arcusmerdtl] TO [public]
GO
