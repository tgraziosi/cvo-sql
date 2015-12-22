CREATE TABLE [dbo].[rpt_ardunltr]
(
[addr1] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[addr2] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[addr3] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[addr4] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[addr5] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[addr6] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[attention_name] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[dunn_message_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[amt_age_bracket1] [float] NOT NULL,
[amt_age_bracket2] [float] NOT NULL,
[amt_age_bracket3] [float] NOT NULL,
[amt_age_bracket4] [float] NOT NULL,
[amt_age_bracket5] [float] NOT NULL,
[amt_age_bracket6] [float] NOT NULL,
[amt_balance] [float] NOT NULL,
[message1] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[message2] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[message3] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[message4] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[message5] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[message6] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[dunn_message_desc] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[customer_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[mess1] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[mess2] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[mess3] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[mess4] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[mess5] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[mess6] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[symbol] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_ardunltr] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_ardunltr] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_ardunltr] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_ardunltr] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_ardunltr] TO [public]
GO
