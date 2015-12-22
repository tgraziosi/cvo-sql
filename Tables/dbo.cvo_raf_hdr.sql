CREATE TABLE [dbo].[cvo_raf_hdr]
(
[spid] [int] NOT NULL,
[order_no] [int] NOT NULL,
[ext] [int] NOT NULL,
[customer_code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[customer_name] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[contact_name] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[contact_email] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ship_to_add_1] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ship_to_add_2] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ship_to_add_3] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ship_to_add_4] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ship_to_add_5] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [cvo_raf_hdr_pk] ON [dbo].[cvo_raf_hdr] ([spid]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[cvo_raf_hdr] TO [public]
GO
GRANT SELECT ON  [dbo].[cvo_raf_hdr] TO [public]
GO
GRANT INSERT ON  [dbo].[cvo_raf_hdr] TO [public]
GO
GRANT DELETE ON  [dbo].[cvo_raf_hdr] TO [public]
GO
GRANT UPDATE ON  [dbo].[cvo_raf_hdr] TO [public]
GO
