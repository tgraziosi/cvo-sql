CREATE TABLE [dbo].[cvo_hold_reason_no_autoalloc]
(
[hold_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[cvo_hold_reason_no_autoalloc] TO [public]
GO
GRANT SELECT ON  [dbo].[cvo_hold_reason_no_autoalloc] TO [public]
GO
GRANT INSERT ON  [dbo].[cvo_hold_reason_no_autoalloc] TO [public]
GO
GRANT DELETE ON  [dbo].[cvo_hold_reason_no_autoalloc] TO [public]
GO
GRANT UPDATE ON  [dbo].[cvo_hold_reason_no_autoalloc] TO [public]
GO
