CREATE TABLE [dbo].[rpt_bolcomments]
(
[b_bl_no] [int] NOT NULL,
[b_src_no] [int] NOT NULL,
[b_bl_type] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[a_line_no] [int] NULL,
[a_note_no] [int] NULL,
[a_note] [text] COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_bolcomments] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_bolcomments] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_bolcomments] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_bolcomments] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_bolcomments] TO [public]
GO
