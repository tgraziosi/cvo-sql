CREATE TABLE [dbo].[gl_error_msg]
(
[error_Id] [smallint] NULL,
[error_description] [char] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[gl_error_msg] TO [public]
GO
GRANT SELECT ON  [dbo].[gl_error_msg] TO [public]
GO
GRANT INSERT ON  [dbo].[gl_error_msg] TO [public]
GO
GRANT DELETE ON  [dbo].[gl_error_msg] TO [public]
GO
GRANT UPDATE ON  [dbo].[gl_error_msg] TO [public]
GO
