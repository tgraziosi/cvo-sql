CREATE TABLE [dbo].[cvo_ord_designation_codes]
(
[order_no] [int] NULL,
[order_ext] [int] NULL,
[code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [cvo_ord_designation_codes_ind0] ON [dbo].[cvo_ord_designation_codes] ([order_no], [order_ext]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[cvo_ord_designation_codes] TO [public]
GO
GRANT SELECT ON  [dbo].[cvo_ord_designation_codes] TO [public]
GO
GRANT INSERT ON  [dbo].[cvo_ord_designation_codes] TO [public]
GO
GRANT DELETE ON  [dbo].[cvo_ord_designation_codes] TO [public]
GO
GRANT UPDATE ON  [dbo].[cvo_ord_designation_codes] TO [public]
GO
