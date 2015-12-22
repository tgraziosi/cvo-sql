CREATE TABLE [dbo].[rpt_nblog]
(
[timestamp] [timestamp] NOT NULL,
[proc_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[net_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[log_description] [varchar] (180) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[step] [varchar] (5) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[substep] [smallint] NOT NULL,
[error] [smallint] NOT NULL,
[trx_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [nbtrxrel_ind_0] ON [dbo].[rpt_nblog] ([proc_ctrl_num], [net_ctrl_num], [step], [substep], [trx_ctrl_num]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_nblog] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_nblog] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_nblog] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_nblog] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_nblog] TO [public]
GO
