CREATE TABLE [dbo].[batchnum]
(
[timestamp] [timestamp] NOT NULL,
[company_id] [smallint] NOT NULL,
[next_batch_ctrl_num] [int] NOT NULL,
[batch_ctrl_num_mask] [char] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[batch_start_col] [smallint] NOT NULL,
[batch_length] [smallint] NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [batchnum_ind_0] ON [dbo].[batchnum] ([company_id]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[batchnum] TO [public]
GO
GRANT SELECT ON  [dbo].[batchnum] TO [public]
GO
GRANT INSERT ON  [dbo].[batchnum] TO [public]
GO
GRANT DELETE ON  [dbo].[batchnum] TO [public]
GO
GRANT UPDATE ON  [dbo].[batchnum] TO [public]
GO
