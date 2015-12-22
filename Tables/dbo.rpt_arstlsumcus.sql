CREATE TABLE [dbo].[rpt_arstlsumcus]
(
[settlement_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[customer_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[customer_name] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[newrc] [float] NOT NULL,
[oarc] [float] NOT NULL,
[oacm] [float] NOT NULL,
[appinv] [float] NOT NULL,
[remoa] [float] NOT NULL,
[disc] [float] NOT NULL,
[wr_off] [float] NOT NULL,
[gain] [float] NOT NULL,
[loss] [float] NOT NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_arstlsumcus] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_arstlsumcus] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_arstlsumcus] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_arstlsumcus] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_arstlsumcus] TO [public]
GO
