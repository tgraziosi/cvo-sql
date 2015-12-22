CREATE TABLE [dbo].[arcomm]
(
[timestamp] [timestamp] NOT NULL,
[commission_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[description] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[base_type] [smallint] NOT NULL,
[table_amt_type] [smallint] NOT NULL,
[calc_type] [smallint] NOT NULL,
[when_paid_type] [smallint] NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [arcomm_ind_0] ON [dbo].[arcomm] ([commission_code]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[arcomm] TO [public]
GO
GRANT SELECT ON  [dbo].[arcomm] TO [public]
GO
GRANT INSERT ON  [dbo].[arcomm] TO [public]
GO
GRANT DELETE ON  [dbo].[arcomm] TO [public]
GO
GRANT UPDATE ON  [dbo].[arcomm] TO [public]
GO
