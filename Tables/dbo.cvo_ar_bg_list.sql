CREATE TABLE [dbo].[cvo_ar_bg_list]
(
[doc_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[customer_code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[parent] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[parent_name] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [cvo_ar_bg_list_ind0] ON [dbo].[cvo_ar_bg_list] ([doc_ctrl_num], [customer_code]) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[cvo_ar_bg_list] TO [public]
GO
