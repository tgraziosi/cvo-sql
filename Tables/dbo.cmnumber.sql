CREATE TABLE [dbo].[cmnumber]
(
[timestamp] [timestamp] NOT NULL,
[company_id] [smallint] NOT NULL,
[next_doc_num] [int] NOT NULL,
[next_doc_num_mask] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[next_trx_ctrl_num] [int] NOT NULL,
[trx_ctrl_num_mask] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[next_batch_ctrl_num] [int] NOT NULL,
[batch_ctrl_num_mask] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[next_transfer_num] [int] NOT NULL,
[transfer_num_mask] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[next_rec_id] [int] NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [cmnumber_ind_0] ON [dbo].[cmnumber] ([company_id]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[cmnumber] TO [public]
GO
GRANT SELECT ON  [dbo].[cmnumber] TO [public]
GO
GRANT INSERT ON  [dbo].[cmnumber] TO [public]
GO
GRANT DELETE ON  [dbo].[cmnumber] TO [public]
GO
GRANT UPDATE ON  [dbo].[cmnumber] TO [public]
GO
