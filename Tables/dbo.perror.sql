CREATE TABLE [dbo].[perror]
(
[timestamp] [timestamp] NOT NULL,
[process_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[batch_code] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[module_id] [smallint] NOT NULL,
[err_code] [int] NOT NULL,
[info1] [char] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[info2] [char] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[infoint] [int] NOT NULL,
[infofloat] [float] NOT NULL,
[flag1] [smallint] NOT NULL,
[trx_ctrl_num] [char] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[sequence_id] [int] NOT NULL,
[source_ctrl_num] [char] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[extra] [int] NOT NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [perror_ind_1] ON [dbo].[perror] ([process_ctrl_num], [batch_code]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[perror] TO [public]
GO
GRANT SELECT ON  [dbo].[perror] TO [public]
GO
GRANT INSERT ON  [dbo].[perror] TO [public]
GO
GRANT DELETE ON  [dbo].[perror] TO [public]
GO
GRANT UPDATE ON  [dbo].[perror] TO [public]
GO
