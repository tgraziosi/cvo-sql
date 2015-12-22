CREATE TABLE [dbo].[CVO_TermsXref]
(
[TCODE] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[terms_code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[CVO_TermsXref] TO [public]
GO
GRANT INSERT ON  [dbo].[CVO_TermsXref] TO [public]
GO
GRANT DELETE ON  [dbo].[CVO_TermsXref] TO [public]
GO
GRANT UPDATE ON  [dbo].[CVO_TermsXref] TO [public]
GO
