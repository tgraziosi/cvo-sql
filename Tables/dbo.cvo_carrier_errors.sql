CREATE TABLE [dbo].[cvo_carrier_errors]
(
[spid] [int] NOT NULL,
[order_no] [int] NOT NULL,
[order_ext] [int] NOT NULL,
[carrier_error] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[order_value] [decimal] (20, 8) NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [cvo_carrier_errors_ind0] ON [dbo].[cvo_carrier_errors] ([order_no], [order_ext]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[cvo_carrier_errors] TO [public]
GO
GRANT SELECT ON  [dbo].[cvo_carrier_errors] TO [public]
GO
GRANT INSERT ON  [dbo].[cvo_carrier_errors] TO [public]
GO
GRANT DELETE ON  [dbo].[cvo_carrier_errors] TO [public]
GO
GRANT UPDATE ON  [dbo].[cvo_carrier_errors] TO [public]
GO
