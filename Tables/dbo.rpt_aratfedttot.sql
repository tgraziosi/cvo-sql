CREATE TABLE [dbo].[rpt_aratfedttot]
(
[seq_by] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ttl_count] [int] NOT NULL,
[ttl_amt] [float] NOT NULL,
[hold_count] [int] NOT NULL,
[hold_amt] [float] NOT NULL,
[rate_home] [float] NOT NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_aratfedttot] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_aratfedttot] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_aratfedttot] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_aratfedttot] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_aratfedttot] TO [public]
GO
