CREATE TABLE [dbo].[rpt_cmfflayd]
(
[bank_file_id] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[sequence_id] [int] NOT NULL,
[field] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[offset] [smallint] NOT NULL,
[length] [smallint] NOT NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_cmfflayd] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_cmfflayd] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_cmfflayd] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_cmfflayd] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_cmfflayd] TO [public]
GO
