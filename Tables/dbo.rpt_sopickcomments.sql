CREATE TABLE [dbo].[rpt_sopickcomments]
(
[o_order_no] [int] NULL,
[a_line_no] [int] NULL,
[a_note_no] [int] NULL,
[a_note] [text] COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_sopickcomments] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_sopickcomments] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_sopickcomments] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_sopickcomments] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_sopickcomments] TO [public]
GO
