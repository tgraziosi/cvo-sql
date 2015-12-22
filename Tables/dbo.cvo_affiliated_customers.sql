CREATE TABLE [dbo].[cvo_affiliated_customers]
(
[timestamp] [timestamp] NOT NULL,
[customer_code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[affiliated_code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [cvo_affiliated_customers_ind0] ON [dbo].[cvo_affiliated_customers] ([customer_code], [affiliated_code]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[cvo_affiliated_customers] TO [public]
GO
GRANT SELECT ON  [dbo].[cvo_affiliated_customers] TO [public]
GO
GRANT INSERT ON  [dbo].[cvo_affiliated_customers] TO [public]
GO
GRANT DELETE ON  [dbo].[cvo_affiliated_customers] TO [public]
GO
GRANT UPDATE ON  [dbo].[cvo_affiliated_customers] TO [public]
GO
