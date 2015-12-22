CREATE TABLE [dbo].[lot_cost_layers]
(
[timestamp] [timestamp] NOT NULL,
[location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[lot_ser] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[tran_code] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[tran_no] [int] NOT NULL,
[tran_ext] [int] NOT NULL,
[line_no] [int] NOT NULL,
[qty] [decimal] (20, 8) NOT NULL,
[mtrl_cost] [decimal] (20, 8) NOT NULL,
[dir_cost] [decimal] (20, 8) NOT NULL,
[ovhd_cost] [decimal] (20, 8) NOT NULL,
[util_cost] [decimal] (20, 8) NOT NULL,
[labor_cost] [decimal] (20, 8) NOT NULL,
[row_id] [int] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [lclayers1] ON [dbo].[lot_cost_layers] ([tran_code], [tran_no], [tran_ext], [line_no], [location], [part_no], [lot_ser]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[lot_cost_layers] TO [public]
GO
GRANT SELECT ON  [dbo].[lot_cost_layers] TO [public]
GO
GRANT INSERT ON  [dbo].[lot_cost_layers] TO [public]
GO
GRANT DELETE ON  [dbo].[lot_cost_layers] TO [public]
GO
GRANT UPDATE ON  [dbo].[lot_cost_layers] TO [public]
GO
