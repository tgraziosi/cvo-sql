CREATE TABLE [dbo].[cvo_receipt_reprint]
(
[po_no] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[line_no] [int] NOT NULL,
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[row_id] [int] NOT NULL IDENTITY(1, 1),
[lp_string] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[lp_value] [varchar] (550) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[receipt_no] [int] NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [cvo_receipt_reprint_ind1] ON [dbo].[cvo_receipt_reprint] ([po_no], [line_no]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [cvo_receipt_reprint_ind0] ON [dbo].[cvo_receipt_reprint] ([po_no], [part_no]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [cvo_receipt_reprint_rctno] ON [dbo].[cvo_receipt_reprint] ([receipt_no]) ON [PRIMARY]
GO
GRANT DELETE ON  [dbo].[cvo_receipt_reprint] TO [public]
GO
GRANT INSERT ON  [dbo].[cvo_receipt_reprint] TO [public]
GO
GRANT REFERENCES ON  [dbo].[cvo_receipt_reprint] TO [public]
GO
GRANT SELECT ON  [dbo].[cvo_receipt_reprint] TO [public]
GO
GRANT UPDATE ON  [dbo].[cvo_receipt_reprint] TO [public]
GO
