CREATE TABLE [dbo].[CVO_FRTOVRID_return_code_exclusions]
(
[return_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [CVO_FRTOVRID_return_code_exclusions_pk] ON [dbo].[CVO_FRTOVRID_return_code_exclusions] ([return_code]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[CVO_FRTOVRID_return_code_exclusions] TO [public]
GO
GRANT SELECT ON  [dbo].[CVO_FRTOVRID_return_code_exclusions] TO [public]
GO
GRANT INSERT ON  [dbo].[CVO_FRTOVRID_return_code_exclusions] TO [public]
GO
GRANT DELETE ON  [dbo].[CVO_FRTOVRID_return_code_exclusions] TO [public]
GO
GRANT UPDATE ON  [dbo].[CVO_FRTOVRID_return_code_exclusions] TO [public]
GO
