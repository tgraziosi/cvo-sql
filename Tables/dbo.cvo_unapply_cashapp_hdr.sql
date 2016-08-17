CREATE TABLE [dbo].[cvo_unapply_cashapp_hdr]
(
[row_id] [int] NOT NULL IDENTITY(1, 1),
[customer_code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[doc_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[entry_date] [int] NULL,
[process_flag] [int] NULL,
[userid] [int] NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[cvo_unapply_cashapp_hdr] TO [public]
GO
GRANT SELECT ON  [dbo].[cvo_unapply_cashapp_hdr] TO [public]
GO
GRANT INSERT ON  [dbo].[cvo_unapply_cashapp_hdr] TO [public]
GO
GRANT DELETE ON  [dbo].[cvo_unapply_cashapp_hdr] TO [public]
GO
GRANT UPDATE ON  [dbo].[cvo_unapply_cashapp_hdr] TO [public]
GO
