CREATE TABLE [dbo].[recadjlog]
(
[user_id] [smallint] NOT NULL,
[date_change] [int] NOT NULL,
[time_change] [int] NOT NULL,
[new_item_code] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[new_item_desc] [varchar] (60) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[old_item_code] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[old_item_desc] [varchar] (60) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[comment] [varchar] (60) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[sequence_id] [int] NOT NULL,
[receipt_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[recadjlog] TO [public]
GO
GRANT SELECT ON  [dbo].[recadjlog] TO [public]
GO
GRANT INSERT ON  [dbo].[recadjlog] TO [public]
GO
GRANT DELETE ON  [dbo].[recadjlog] TO [public]
GO
GRANT UPDATE ON  [dbo].[recadjlog] TO [public]
GO
