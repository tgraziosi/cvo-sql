CREATE TABLE [dbo].[cvo_customer_types]
(
[cust_type] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[cvo_customer_types] TO [public]
GO
GRANT SELECT ON  [dbo].[cvo_customer_types] TO [public]
GO
GRANT INSERT ON  [dbo].[cvo_customer_types] TO [public]
GO
GRANT DELETE ON  [dbo].[cvo_customer_types] TO [public]
GO
GRANT UPDATE ON  [dbo].[cvo_customer_types] TO [public]
GO
