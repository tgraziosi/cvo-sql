CREATE TABLE [dbo].[ksynctables]
(
[tablename] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[owner] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[subject_area] [varchar] (128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[label] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[type] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[updatable] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[hidden] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[drs_object] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[base_tables] [varchar] (254) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[remarks] [varchar] (254) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[field_info] [varchar] (254) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [idxkstbls] ON [dbo].[ksynctables] ([tablename], [owner]) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[ksynctables] TO [public]
GO
GRANT INSERT ON  [dbo].[ksynctables] TO [public]
GO
GRANT DELETE ON  [dbo].[ksynctables] TO [public]
GO
GRANT UPDATE ON  [dbo].[ksynctables] TO [public]
GO
