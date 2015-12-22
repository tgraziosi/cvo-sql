CREATE TABLE [dbo].[tdc_inv_master]
(
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[auto_lot_flag] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF__tdc_inv_m__auto___56342107] DEFAULT ('S'),
[auto_lot] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[mask_code] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF__tdc_inv_m__mask___57284540] DEFAULT ('NONE'),
[serial_count] [int] NOT NULL CONSTRAINT [DF__tdc_inv_m__seria__581C6979] DEFAULT ((0)),
[tdc_generated] [bit] NOT NULL CONSTRAINT [DF__tdc_inv_m__tdc_g__59108DB2] DEFAULT ((0))
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[tdc_inv_master] ADD CONSTRAINT [PK_tdc_inv_master] PRIMARY KEY NONCLUSTERED  ([part_no]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[tdc_inv_master] TO [public]
GO
GRANT SELECT ON  [dbo].[tdc_inv_master] TO [public]
GO
GRANT INSERT ON  [dbo].[tdc_inv_master] TO [public]
GO
GRANT DELETE ON  [dbo].[tdc_inv_master] TO [public]
GO
GRANT UPDATE ON  [dbo].[tdc_inv_master] TO [public]
GO
