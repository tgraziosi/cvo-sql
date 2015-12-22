CREATE TABLE [dbo].[amdprcrt]
(
[timestamp] [timestamp] NOT NULL,
[co_trx_id] [dbo].[smSurrogateKey] NOT NULL,
[field_type] [dbo].[smFieldType] NOT NULL,
[from_code] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[to_code] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [amdprcrt_ind_0] ON [dbo].[amdprcrt] ([co_trx_id], [field_type]) ON [PRIMARY]
GO
EXEC sp_bindefault N'[dbo].[smZero_df]', N'[dbo].[amdprcrt].[co_trx_id]'
GO
GRANT REFERENCES ON  [dbo].[amdprcrt] TO [public]
GO
GRANT SELECT ON  [dbo].[amdprcrt] TO [public]
GO
GRANT INSERT ON  [dbo].[amdprcrt] TO [public]
GO
GRANT DELETE ON  [dbo].[amdprcrt] TO [public]
GO
GRANT UPDATE ON  [dbo].[amdprcrt] TO [public]
GO
