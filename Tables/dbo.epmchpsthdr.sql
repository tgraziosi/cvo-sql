CREATE TABLE [dbo].[epmchpsthdr]
(
[process_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[batch_code] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[match_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[trx_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[vendor_code] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[doc_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[amt_due] [float] NOT NULL,
[symbol] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[epmchpsthdr] TO [public]
GO
GRANT SELECT ON  [dbo].[epmchpsthdr] TO [public]
GO
GRANT INSERT ON  [dbo].[epmchpsthdr] TO [public]
GO
GRANT DELETE ON  [dbo].[epmchpsthdr] TO [public]
GO
GRANT UPDATE ON  [dbo].[epmchpsthdr] TO [public]
GO
