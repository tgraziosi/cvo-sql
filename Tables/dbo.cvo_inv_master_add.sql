CREATE TABLE [dbo].[cvo_inv_master_add]
(
[timestamp] [timestamp] NOT NULL,
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[item_code] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[img_front] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[img_temple] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[img_front_HR] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[img_temple_HR] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[img_SpecialtyFit] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Future_ReleaseDate] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[prim_img] [int] NOT NULL CONSTRAINT [df_prim_img] DEFAULT ((0)),
[eye_shape] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[dbl_size] [decimal] (20, 8) NULL,
[Sugg_Retail_Price] [decimal] (20, 8) NULL,
[img_34_hr] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[img_34] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[IMG_SKU] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[IMG_WEB] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [idx_part_no] ON [dbo].[cvo_inv_master_add] ([part_no]) ON [PRIMARY]
GO
