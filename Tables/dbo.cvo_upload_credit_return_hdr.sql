CREATE TABLE [dbo].[cvo_upload_credit_return_hdr]
(
[spid] [int] NOT NULL,
[cust_code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ship_to] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ra] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[who_entered] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[orig_order_no] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[email_address] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [cvo_upload_credit_return_hdr_pk] ON [dbo].[cvo_upload_credit_return_hdr] ([spid]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[cvo_upload_credit_return_hdr] TO [public]
GO
GRANT SELECT ON  [dbo].[cvo_upload_credit_return_hdr] TO [public]
GO
GRANT INSERT ON  [dbo].[cvo_upload_credit_return_hdr] TO [public]
GO
GRANT DELETE ON  [dbo].[cvo_upload_credit_return_hdr] TO [public]
GO
GRANT UPDATE ON  [dbo].[cvo_upload_credit_return_hdr] TO [public]
GO
