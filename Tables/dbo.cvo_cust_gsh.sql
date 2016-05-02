CREATE TABLE [dbo].[cvo_cust_gsh]
(
[cust_code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[global_ship] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [cvo_cust_gsh_ind0] ON [dbo].[cvo_cust_gsh] ([cust_code]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[cvo_cust_gsh] TO [public]
GO
GRANT SELECT ON  [dbo].[cvo_cust_gsh] TO [public]
GO
GRANT INSERT ON  [dbo].[cvo_cust_gsh] TO [public]
GO
GRANT DELETE ON  [dbo].[cvo_cust_gsh] TO [public]
GO
GRANT UPDATE ON  [dbo].[cvo_cust_gsh] TO [public]
GO
