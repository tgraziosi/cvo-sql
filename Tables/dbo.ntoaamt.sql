CREATE TABLE [dbo].[ntoaamt]
(
[user_name] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[customer_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[age_brk1] [float] NOT NULL,
[age_brk2] [float] NOT NULL,
[age_brk3] [float] NOT NULL,
[age_brk4] [float] NOT NULL,
[age_brk5] [float] NOT NULL,
[age_brk6] [float] NOT NULL,
[amount_oa] [float] NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[ntoaamt] TO [public]
GO
GRANT SELECT ON  [dbo].[ntoaamt] TO [public]
GO
GRANT INSERT ON  [dbo].[ntoaamt] TO [public]
GO
GRANT DELETE ON  [dbo].[ntoaamt] TO [public]
GO
GRANT UPDATE ON  [dbo].[ntoaamt] TO [public]
GO
