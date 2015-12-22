CREATE TABLE [dbo].[rpt_nbpsterrdet]
(
[process_ctrl_parent] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[process_ctrl_child] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[trx_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[module_id] [smallint] NOT NULL,
[module_code] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[module_title] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[error_description] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_nbpsterrdet] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_nbpsterrdet] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_nbpsterrdet] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_nbpsterrdet] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_nbpsterrdet] TO [public]
GO
