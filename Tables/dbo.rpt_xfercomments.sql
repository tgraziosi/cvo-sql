CREATE TABLE [dbo].[rpt_xfercomments]
(
[x_xfer_no] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[n_note_no] [int] NULL,
[n_note] [text] COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_xfercomments] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_xfercomments] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_xfercomments] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_xfercomments] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_xfercomments] TO [public]
GO
