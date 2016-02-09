CREATE TABLE [dbo].[cvo_cust_agent_tbl]
(
[phone_num] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[QUEUE_NAME] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[agent_id] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CUSTOMER_CODE] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO

GRANT REFERENCES ON  [dbo].[cvo_cust_agent_tbl] TO [public]
GO
GRANT SELECT ON  [dbo].[cvo_cust_agent_tbl] TO [public]
GO
GRANT INSERT ON  [dbo].[cvo_cust_agent_tbl] TO [public]
GO
GRANT DELETE ON  [dbo].[cvo_cust_agent_tbl] TO [public]
GO
GRANT UPDATE ON  [dbo].[cvo_cust_agent_tbl] TO [public]
GO
