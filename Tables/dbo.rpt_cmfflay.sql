CREATE TABLE [dbo].[rpt_cmfflay]
(
[bank_file_id] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[flat_file_path] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[delimiter_flag] [smallint] NOT NULL,
[delimiter_type] [char] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[decimal_num] [smallint] NOT NULL,
[delimiter_desc] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_cmfflay] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_cmfflay] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_cmfflay] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_cmfflay] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_cmfflay] TO [public]
GO
