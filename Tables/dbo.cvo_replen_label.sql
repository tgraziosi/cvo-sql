CREATE TABLE [dbo].[cvo_replen_label]
(
[row_id] [int] NOT NULL IDENTITY(1, 1),
[print_value] [varchar] (300) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[user_id] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[cvo_replen_label] TO [public]
GO
GRANT SELECT ON  [dbo].[cvo_replen_label] TO [public]
GO
GRANT INSERT ON  [dbo].[cvo_replen_label] TO [public]
GO
GRANT DELETE ON  [dbo].[cvo_replen_label] TO [public]
GO
GRANT UPDATE ON  [dbo].[cvo_replen_label] TO [public]
GO
