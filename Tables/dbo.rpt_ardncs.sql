CREATE TABLE [dbo].[rpt_ardncs]
(
[dunning_level] [smallint] NOT NULL,
[dunn_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[customer_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[date_generate] [datetime] NOT NULL,
[group_id] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[message_id] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_ardncs] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_ardncs] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_ardncs] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_ardncs] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_ardncs] TO [public]
GO
