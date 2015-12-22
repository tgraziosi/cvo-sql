CREATE TABLE [dbo].[po_retcode]
(
[timestamp] [timestamp] NOT NULL,
[return_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[return_desc] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[account_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ret_inv_flag] [smallint] NOT NULL,
[void] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[void_who] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[void_date] [datetime] NULL,
[return_bin] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[saleable_condition] [smallint] NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [po_retcode_1] ON [dbo].[po_retcode] ([return_code]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[po_retcode] TO [public]
GO
GRANT SELECT ON  [dbo].[po_retcode] TO [public]
GO
GRANT INSERT ON  [dbo].[po_retcode] TO [public]
GO
GRANT DELETE ON  [dbo].[po_retcode] TO [public]
GO
GRANT UPDATE ON  [dbo].[po_retcode] TO [public]
GO
