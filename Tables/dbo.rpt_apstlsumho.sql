CREATE TABLE [dbo].[rpt_apstlsumho]
(
[settlement_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[nat_cur_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[curr_desc] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[newpyt] [float] NOT NULL,
[oapyt] [float] NOT NULL,
[oadm] [float] NOT NULL,
[putoa] [float] NOT NULL,
[disc] [float] NOT NULL,
[gain] [float] NOT NULL,
[loss] [float] NOT NULL,
[org_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_apstlsumho] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_apstlsumho] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_apstlsumho] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_apstlsumho] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_apstlsumho] TO [public]
GO
