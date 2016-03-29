CREATE TABLE [dbo].[cvo_hs_cust_reference]
(
[account_id] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[obj_id] [bigint] NULL,
[customer] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ship_to_code] [varchar] (6) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[address_obj_id] [bigint] NULL,
[addr_type] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
