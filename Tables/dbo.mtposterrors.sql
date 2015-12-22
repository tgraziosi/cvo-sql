CREATE TABLE [dbo].[mtposterrors]
(
[err_code] [int] NOT NULL,
[refer_to] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[field_desc] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[err_type] [smallint] NOT NULL,
[err_desc] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [mtposterrors_ind_0] ON [dbo].[mtposterrors] ([err_code]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[mtposterrors] TO [public]
GO
GRANT SELECT ON  [dbo].[mtposterrors] TO [public]
GO
GRANT INSERT ON  [dbo].[mtposterrors] TO [public]
GO
GRANT DELETE ON  [dbo].[mtposterrors] TO [public]
GO
GRANT UPDATE ON  [dbo].[mtposterrors] TO [public]
GO
