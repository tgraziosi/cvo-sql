CREATE TABLE [dbo].[cc_inv_status_hist]
(
[doc_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[status_code] [varchar] (5) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[date] [int] NOT NULL,
[user_id] [smallint] NOT NULL,
[clear_date] [int] NULL,
[cleared_by] [smallint] NULL,
[sequence_num] [smallint] NOT NULL,
[customer_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [cc_inv_status_hist_idx2] ON [dbo].[cc_inv_status_hist] ([clear_date]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [cc_inv_status_hist_idx] ON [dbo].[cc_inv_status_hist] ([doc_ctrl_num], [date]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[cc_inv_status_hist] TO [public]
GO
GRANT SELECT ON  [dbo].[cc_inv_status_hist] TO [public]
GO
GRANT INSERT ON  [dbo].[cc_inv_status_hist] TO [public]
GO
GRANT DELETE ON  [dbo].[cc_inv_status_hist] TO [public]
GO
GRANT UPDATE ON  [dbo].[cc_inv_status_hist] TO [public]
GO
