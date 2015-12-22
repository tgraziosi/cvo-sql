CREATE TABLE [dbo].[cvo_rb_data]
(
[order_no] [int] NULL,
[order_ext] [int] NULL,
[order_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[user_category] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[buying_group] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[cust_code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [cvo_rb_data_ind1] ON [dbo].[cvo_rb_data] ([buying_group], [cust_code]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [cvo_rb_data_ind2] ON [dbo].[cvo_rb_data] ([cust_code]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [cvo_rb_data_ind0] ON [dbo].[cvo_rb_data] ([order_ctrl_num]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [cvo_rb_data_ind3] ON [dbo].[cvo_rb_data] ([order_no], [order_ext]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[cvo_rb_data] TO [public]
GO
GRANT SELECT ON  [dbo].[cvo_rb_data] TO [public]
GO
GRANT INSERT ON  [dbo].[cvo_rb_data] TO [public]
GO
GRANT DELETE ON  [dbo].[cvo_rb_data] TO [public]
GO
GRANT UPDATE ON  [dbo].[cvo_rb_data] TO [public]
GO
