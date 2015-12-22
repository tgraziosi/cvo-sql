CREATE TABLE [dbo].[cpt_ap_post_tracking]
(
[err] [int] NULL,
[module_id] [smallint] NULL,
[err_code] [int] NULL,
[info1] [char] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[other] [char] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[infoint] [int] NULL,
[infofloat] [float] NULL,
[flag1] [smallint] NULL,
[trx_ctrl_num] [char] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[sequence_id] [int] NULL,
[other2] [char] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[extra] [int] NULL,
[match_ctrl_int] [int] NULL,
[refer_to] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[field_desc] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[err_desc] [char] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[cpt_ap_post_tracking] TO [public]
GO
GRANT INSERT ON  [dbo].[cpt_ap_post_tracking] TO [public]
GO
GRANT DELETE ON  [dbo].[cpt_ap_post_tracking] TO [public]
GO
GRANT UPDATE ON  [dbo].[cpt_ap_post_tracking] TO [public]
GO
