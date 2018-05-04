CREATE TABLE [dbo].[cvo_revo_cust_tbl]
(
[customer_code] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ship_to_code] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[cvo_revo_cust_tbl] ADD CONSTRAINT [PK_cvo_revo_cust_tbl] PRIMARY KEY CLUSTERED  ([customer_code], [ship_to_code]) ON [PRIMARY]
GO
GRANT DELETE ON  [dbo].[cvo_revo_cust_tbl] TO [public]
GO
GRANT INSERT ON  [dbo].[cvo_revo_cust_tbl] TO [public]
GO
GRANT REFERENCES ON  [dbo].[cvo_revo_cust_tbl] TO [public]
GO
GRANT SELECT ON  [dbo].[cvo_revo_cust_tbl] TO [public]
GO
GRANT UPDATE ON  [dbo].[cvo_revo_cust_tbl] TO [public]
GO
