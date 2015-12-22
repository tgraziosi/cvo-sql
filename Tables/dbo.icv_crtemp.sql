CREATE TABLE [dbo].[icv_crtemp]
(
[spid] [int] NOT NULL,
[doc_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[flg] [int] NOT NULL,
[input_tables] [int] NOT NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[icv_crtemp] TO [public]
GO
GRANT SELECT ON  [dbo].[icv_crtemp] TO [public]
GO
GRANT INSERT ON  [dbo].[icv_crtemp] TO [public]
GO
GRANT DELETE ON  [dbo].[icv_crtemp] TO [public]
GO
GRANT UPDATE ON  [dbo].[icv_crtemp] TO [public]
GO
