CREATE TABLE [dbo].[aphistrx]
(
[timestamp] [timestamp] NOT NULL,
[trx_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[po_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[vend_order_num] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ticket_num] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[date_received] [int] NOT NULL,
[date_applied] [int] NOT NULL,
[date_aging] [int] NOT NULL,
[date_doc] [int] NOT NULL,
[date_required] [int] NOT NULL,
[date_discount] [int] NOT NULL,
[class_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[fob_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[terms_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [aphistrx_ind_0] ON [dbo].[aphistrx] ([trx_ctrl_num]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[aphistrx] TO [public]
GO
GRANT SELECT ON  [dbo].[aphistrx] TO [public]
GO
GRANT INSERT ON  [dbo].[aphistrx] TO [public]
GO
GRANT DELETE ON  [dbo].[aphistrx] TO [public]
GO
GRANT UPDATE ON  [dbo].[aphistrx] TO [public]
GO
