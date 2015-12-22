CREATE TABLE [dbo].[appymeth]
(
[timestamp] [timestamp] NOT NULL,
[payment_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[description] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[on_acct_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[payment_type] [smallint] NOT NULL,
[next_doc_num] [int] NOT NULL,
[doc_num_mask] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[doc_start_col] [smallint] NOT NULL,
[doc_length] [smallint] NOT NULL,
[nat_cur_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [appymeth_ind_0] ON [dbo].[appymeth] ([payment_code]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[appymeth] TO [public]
GO
GRANT SELECT ON  [dbo].[appymeth] TO [public]
GO
GRANT INSERT ON  [dbo].[appymeth] TO [public]
GO
GRANT DELETE ON  [dbo].[appymeth] TO [public]
GO
GRANT UPDATE ON  [dbo].[appymeth] TO [public]
GO
