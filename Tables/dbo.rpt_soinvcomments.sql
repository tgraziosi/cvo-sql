CREATE TABLE [dbo].[rpt_soinvcomments]
(
[o_order_no] [int] NOT NULL,
[o_invoice_no] [int] NULL,
[o_type] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[a_line_no] [int] NULL,
[a_note_no] [int] NULL,
[a_note] [text] COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_soinvcomments] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_soinvcomments] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_soinvcomments] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_soinvcomments] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_soinvcomments] TO [public]
GO
