CREATE TABLE [dbo].[gltcerror]
(
[timestamp] [timestamp] NOT NULL,
[batch_code] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[module_id] [smallint] NOT NULL,
[err_code] [int] NOT NULL,
[tc_details] [varchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[tc_helplink] [varchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[tc_name] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[tc_refersto] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[tc_severity] [int] NOT NULL,
[tc_source] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[tc_summary] [varchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[tc_transactionid] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[trx_ctrl_num] [char] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[trx_type] [int] NOT NULL,
[source_ctrl_num] [char] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[totalamount] [float] NOT NULL,
[taxamount] [float] NOT NULL,
[date_doc] [int] NOT NULL,
[remote_doc_id] [int] NOT NULL,
[doc_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[gltcerror] TO [public]
GO
GRANT SELECT ON  [dbo].[gltcerror] TO [public]
GO
GRANT INSERT ON  [dbo].[gltcerror] TO [public]
GO
GRANT DELETE ON  [dbo].[gltcerror] TO [public]
GO
GRANT UPDATE ON  [dbo].[gltcerror] TO [public]
GO
