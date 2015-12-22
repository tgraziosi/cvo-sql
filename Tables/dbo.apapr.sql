CREATE TABLE [dbo].[apapr]
(
[timestamp] [timestamp] NOT NULL,
[approval_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[description] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[sequence_flag] [smallint] NOT NULL,
[disappr_user_id] [smallint] NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [apapr_ind_0] ON [dbo].[apapr] ([approval_code]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [apapr_ind_1] ON [dbo].[apapr] ([disappr_user_id]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[apapr] TO [public]
GO
GRANT SELECT ON  [dbo].[apapr] TO [public]
GO
GRANT INSERT ON  [dbo].[apapr] TO [public]
GO
GRANT DELETE ON  [dbo].[apapr] TO [public]
GO
GRANT UPDATE ON  [dbo].[apapr] TO [public]
GO
