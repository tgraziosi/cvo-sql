CREATE TABLE [dbo].[arcust_edi]
(
[timestamp] [timestamp] NOT NULL,
[customer_key] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[edi_party] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[invoice_edi] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[duns_no] [varchar] (17) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[edi_nte] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[edi_ref_car] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[edi_n1_f] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[edi_n1_t] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[edi_n3] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[edi_n4] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[edi_ref] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[edi_itd] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[edi_dtm] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[edi_fob] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[edi_pid] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[edi_it3] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[edi_po4] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[edi_cad] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[last_edi_no] [int] NULL,
[edi_terms_type_code] [char] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[edi_terms_basis] [char] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[edi_pay_type] [char] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[edi_all_chg_no] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[edi_spec_chg_code] [char] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[edi_ref_qual] [char] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[edi_ref_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[edi_version] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[isa_control_no] [char] (9) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[edi_party_810] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[store_no] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[edi_iss] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [aredi1] ON [dbo].[arcust_edi] ([customer_key]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [aredi2] ON [dbo].[arcust_edi] ([edi_party]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[arcust_edi] TO [public]
GO
GRANT SELECT ON  [dbo].[arcust_edi] TO [public]
GO
GRANT INSERT ON  [dbo].[arcust_edi] TO [public]
GO
GRANT DELETE ON  [dbo].[arcust_edi] TO [public]
GO
GRANT UPDATE ON  [dbo].[arcust_edi] TO [public]
GO
