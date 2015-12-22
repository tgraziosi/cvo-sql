CREATE TABLE [dbo].[cmfflay]
(
[timestamp] [timestamp] NOT NULL,
[bank_file_id] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[flat_file_path] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[delimiter_flag] [smallint] NOT NULL,
[delimiter_type] [char] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[decimal_num] [smallint] NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [cmfflay_ind_0] ON [dbo].[cmfflay] ([bank_file_id]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[cmfflay] TO [public]
GO
GRANT SELECT ON  [dbo].[cmfflay] TO [public]
GO
GRANT INSERT ON  [dbo].[cmfflay] TO [public]
GO
GRANT DELETE ON  [dbo].[cmfflay] TO [public]
GO
GRANT UPDATE ON  [dbo].[cmfflay] TO [public]
GO
