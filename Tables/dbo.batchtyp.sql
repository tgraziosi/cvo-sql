CREATE TABLE [dbo].[batchtyp]
(
[timestamp] [timestamp] NOT NULL,
[batch_type] [smallint] NOT NULL,
[post_form_title] [char] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[proc_form_title] [char] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[document_name] [char] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[numbering_table] [char] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[transaction_table] [char] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[total_amt_field] [char] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [batchtyp_ind_0] ON [dbo].[batchtyp] ([batch_type]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[batchtyp] TO [public]
GO
GRANT SELECT ON  [dbo].[batchtyp] TO [public]
GO
GRANT INSERT ON  [dbo].[batchtyp] TO [public]
GO
GRANT DELETE ON  [dbo].[batchtyp] TO [public]
GO
GRANT UPDATE ON  [dbo].[batchtyp] TO [public]
GO
