CREATE TABLE [dbo].[cvo_reprint_pick_ticket_tbl]
(
[order_no] [int] NOT NULL,
[ext] [int] NULL CONSTRAINT [DF__cvo_reprint__ext__1D8E3A54] DEFAULT ((0))
) ON [PRIMARY]
GO
GRANT DELETE ON  [dbo].[cvo_reprint_pick_ticket_tbl] TO [public]
GO
GRANT INSERT ON  [dbo].[cvo_reprint_pick_ticket_tbl] TO [public]
GO
GRANT REFERENCES ON  [dbo].[cvo_reprint_pick_ticket_tbl] TO [public]
GO
GRANT SELECT ON  [dbo].[cvo_reprint_pick_ticket_tbl] TO [public]
GO
GRANT UPDATE ON  [dbo].[cvo_reprint_pick_ticket_tbl] TO [public]
GO
