CREATE TABLE [dbo].[cvo_b2b_xfer_log]
(
[issue_no] [int] NULL,
[location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[lot_ser] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[from_bin] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[to_bin] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[date_expires] [datetime] NOT NULL,
[qty] [decimal] (20, 8) NOT NULL,
[who_entered] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[reason_code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[err_msg] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[row_id] [int] NOT NULL,
[date_tran] [datetime] NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[cvo_b2b_xfer_log] TO [public]
GO
GRANT SELECT ON  [dbo].[cvo_b2b_xfer_log] TO [public]
GO
GRANT INSERT ON  [dbo].[cvo_b2b_xfer_log] TO [public]
GO
GRANT DELETE ON  [dbo].[cvo_b2b_xfer_log] TO [public]
GO
GRANT UPDATE ON  [dbo].[cvo_b2b_xfer_log] TO [public]
GO
