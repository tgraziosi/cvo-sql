CREATE TABLE [dbo].[EAI_RMADetail]
(
[FO_RMAID] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[line_no] [int] NOT NULL,
[FO_orig_sales_order_id] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[FO_orig_line_no] [int] NULL,
[BO_sales_order_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[serial_no] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[cr_ordered] [decimal] (20, 8) NOT NULL,
[curr_price] [decimal] (20, 8) NULL,
[curr_factor] [decimal] (20, 8) NULL,
[note] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[date_entered] [datetime] NULL,
[who_entered] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[modified_by_date] [datetime] NULL,
[modified_by_user_name] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[EAI_RMADetail] ADD CONSTRAINT [EAI_RMADetail_pk] PRIMARY KEY CLUSTERED  ([FO_RMAID], [line_no]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[EAI_RMADetail] ADD CONSTRAINT [EAI_RMADetail_EAI_RMAHeader_fk1] FOREIGN KEY ([FO_RMAID]) REFERENCES [dbo].[EAI_RMAHeader] ([FO_RMAID])
GO
GRANT REFERENCES ON  [dbo].[EAI_RMADetail] TO [public]
GO
GRANT SELECT ON  [dbo].[EAI_RMADetail] TO [public]
GO
GRANT INSERT ON  [dbo].[EAI_RMADetail] TO [public]
GO
GRANT DELETE ON  [dbo].[EAI_RMADetail] TO [public]
GO
GRANT UPDATE ON  [dbo].[EAI_RMADetail] TO [public]
GO
