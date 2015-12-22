CREATE TABLE [dbo].[prrptmgd]
(
[contract_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[part_desc] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[source_trx_type] [int] NULL,
[source_extended] [float] NULL,
[source_amt_cost] [float] NULL,
[trx_type_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[rebate_amount] [float] NULL,
[margin] [float] NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[prrptmgd] TO [public]
GO
GRANT SELECT ON  [dbo].[prrptmgd] TO [public]
GO
GRANT INSERT ON  [dbo].[prrptmgd] TO [public]
GO
GRANT DELETE ON  [dbo].[prrptmgd] TO [public]
GO
GRANT UPDATE ON  [dbo].[prrptmgd] TO [public]
GO
