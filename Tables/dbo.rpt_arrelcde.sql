CREATE TABLE [dbo].[rpt_arrelcde]
(
[relation_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[description] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[tiered_flag] [smallint] NOT NULL,
[tier_label1] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[tier_label2] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[tier_label3] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[tier_label4] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[tier_label5] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[tier_label6] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[tier_label7] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[tier_label8] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[tier_label9] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[tier_label10] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_arrelcde] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_arrelcde] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_arrelcde] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_arrelcde] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_arrelcde] TO [public]
GO
