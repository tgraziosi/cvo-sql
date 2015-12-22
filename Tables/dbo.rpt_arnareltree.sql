CREATE TABLE [dbo].[rpt_arnareltree]
(
[relation_code] [char] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[parent] [char] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[child_1] [char] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[child_2] [char] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[child_3] [char] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[child_4] [char] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[child_5] [char] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[child_6] [char] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[child_7] [char] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[child_8] [char] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[child_9] [char] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[rel_cust] [char] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[tier_level] [smallint] NOT NULL,
[customer_name] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[description] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
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
GRANT REFERENCES ON  [dbo].[rpt_arnareltree] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_arnareltree] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_arnareltree] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_arnareltree] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_arnareltree] TO [public]
GO
