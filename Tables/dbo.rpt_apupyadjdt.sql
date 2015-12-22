CREATE TABLE [dbo].[rpt_apupyadjdt]
(
[sequence_id] [int] NOT NULL,
[apply_to_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[trx_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[vo_amt_applied] [real] NOT NULL,
[vo_amt_disc_taken] [real] NOT NULL,
[line_desc] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[void_flag] [smallint] NOT NULL,
[vendor_code] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[gain_home] [real] NOT NULL,
[gain_oper] [real] NOT NULL,
[amt_applied] [real] NOT NULL,
[org_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_apupyadjdt] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_apupyadjdt] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_apupyadjdt] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_apupyadjdt] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_apupyadjdt] TO [public]
GO
