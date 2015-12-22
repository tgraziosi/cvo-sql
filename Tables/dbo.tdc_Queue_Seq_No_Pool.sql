CREATE TABLE [dbo].[tdc_Queue_Seq_No_Pool]
(
[Queue] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[Priority] [int] NOT NULL,
[Next_Sequence] [int] NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[tdc_Queue_Seq_No_Pool] ADD CONSTRAINT [PK_tdc_Queue_Seq_No_Pool] PRIMARY KEY NONCLUSTERED  ([Queue], [Priority]) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[tdc_Queue_Seq_No_Pool] TO [public]
GO
GRANT INSERT ON  [dbo].[tdc_Queue_Seq_No_Pool] TO [public]
GO
GRANT DELETE ON  [dbo].[tdc_Queue_Seq_No_Pool] TO [public]
GO
GRANT UPDATE ON  [dbo].[tdc_Queue_Seq_No_Pool] TO [public]
GO
