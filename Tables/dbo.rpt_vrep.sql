CREATE TABLE [dbo].[rpt_vrep]
(
[trx_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[doc_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[trx_type] [smallint] NOT NULL,
[tax_box_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[tax_box_rep_seq] [int] NOT NULL,
[tax_type_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[tax_type_desc] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[description] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[nat_cur_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[amt_net] [float] NOT NULL,
[amt_tax] [float] NOT NULL,
[rate_home] [float] NOT NULL,
[rate_oper] [float] NOT NULL,
[date_applied] [int] NOT NULL,
[date_doc] [int] NOT NULL,
[tax_type] [smallint] NOT NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_vrep] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_vrep] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_vrep] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_vrep] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_vrep] TO [public]
GO
