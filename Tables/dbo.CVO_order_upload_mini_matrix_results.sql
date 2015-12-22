CREATE TABLE [dbo].[CVO_order_upload_mini_matrix_results]
(
[rec_id] [int] NOT NULL IDENTITY(1, 1),
[SPID] [int] NOT NULL,
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[qty] [decimal] (20, 8) NOT NULL,
[price] [decimal] (20, 8) NOT NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [CVO_order_upload_mini_matrix_results_inx01] ON [dbo].[CVO_order_upload_mini_matrix_results] ([rec_id]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [CVO_order_upload_mini_matrix_results_inx02] ON [dbo].[CVO_order_upload_mini_matrix_results] ([SPID]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[CVO_order_upload_mini_matrix_results] TO [public]
GO
GRANT SELECT ON  [dbo].[CVO_order_upload_mini_matrix_results] TO [public]
GO
GRANT INSERT ON  [dbo].[CVO_order_upload_mini_matrix_results] TO [public]
GO
GRANT DELETE ON  [dbo].[CVO_order_upload_mini_matrix_results] TO [public]
GO
GRANT UPDATE ON  [dbo].[CVO_order_upload_mini_matrix_results] TO [public]
GO
