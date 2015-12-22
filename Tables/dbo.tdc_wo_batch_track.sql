CREATE TABLE [dbo].[tdc_wo_batch_track]
(
[prod_no] [int] NOT NULL,
[prod_ext] [int] NOT NULL CONSTRAINT [DF__tdc_wo_ba__prod___2526D558] DEFAULT ((0)),
[output_part] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[output_lot] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[input_part] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[input_lot] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[batch_status] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[userid] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[date_time] [datetime] NOT NULL CONSTRAINT [DF__tdc_wo_ba__date___261AF991] DEFAULT (getdate())
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [TDC_BATCH_TRACK_INDEX] ON [dbo].[tdc_wo_batch_track] ([prod_no], [prod_ext], [output_part], [output_lot], [input_part], [input_lot]) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[tdc_wo_batch_track] TO [public]
GO
GRANT INSERT ON  [dbo].[tdc_wo_batch_track] TO [public]
GO
GRANT DELETE ON  [dbo].[tdc_wo_batch_track] TO [public]
GO
GRANT UPDATE ON  [dbo].[tdc_wo_batch_track] TO [public]
GO
