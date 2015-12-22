CREATE TABLE [dbo].[cvo_hs_inventory_parts_8]
(
[sku] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[mastersku] [varchar] (150) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[name] [nvarchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[unitPrice] [decimal] (10, 2) NULL,
[minQty] [int] NOT NULL,
[multQty] [int] NOT NULL,
[Manufacturer] [varchar] (11) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[barcode] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[longDesc] [nvarchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[VariantDescription] [varchar] (150) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[imageURLs] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[category:1] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[category:2] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Color] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[Size] [varchar] (9) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[|] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[COLL] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Model] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[POMDate] [datetime] NULL,
[ReleaseDate] [datetime] NULL,
[Status] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[GENDER] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[SpecialtyFit] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[APR] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[New] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[SUNPS] [varchar] (5) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[CostCo] [varchar] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ShelfQty] [decimal] (38, 8) NULL,
[NextPODueDate] [datetime] NULL,
[HIDE] [int] NULL,
[MasterHIDE] [int] NOT NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [idx_inv7] ON [dbo].[cvo_hs_inventory_parts_8] ([Manufacturer], [mastersku], [sku]) ON [PRIMARY]
GO
