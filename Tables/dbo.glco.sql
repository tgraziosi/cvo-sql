CREATE TABLE [dbo].[glco]
(
[timestamp] [timestamp] NOT NULL,
[company_id] [smallint] NOT NULL,
[company_name] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[addr1] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[addr2] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[addr3] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[addr4] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[addr5] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[addr6] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[account_format_mask] [varchar] (35) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[days_before_purge] [int] NOT NULL,
[batch_proc_flag] [smallint] NOT NULL,
[ctrl_totals_flag] [smallint] NOT NULL,
[batch_usr_flag] [smallint] NOT NULL,
[indirect_flag] [smallint] NOT NULL,
[period_end_date] [int] NOT NULL,
[prior_period_flag] [smallint] NOT NULL,
[company_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[home_currency] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[days_in_fiscal_year] [smallint] NOT NULL,
[multi_company_flag] [smallint] NOT NULL,
[multi_currency_flag] [smallint] NOT NULL,
[force_editlist_flag] [smallint] NOT NULL,
[glupdate_status_flag] [smallint] NOT NULL,
[oper_currency] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[rate_type_home] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[rate_type_oper] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[translation_rounding_acct] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[setup] [smallint] NOT NULL,
[country_code] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[gst_flag] [smallint] NOT NULL,
[magnification_flag] [smallint] NOT NULL,
[ib_flag] [int] NOT NULL,
[ib_journal_type] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ib_segment] [int] NOT NULL,
[ib_offset] [int] NOT NULL,
[ib_length] [int] NOT NULL,
[acctyp_flag] [smallint] NOT NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE TRIGGER [dbo].[glco_trigger_1]
	ON [dbo].[glco]
	FOR UPDATE AS
	IF UPDATE ( account_format_mask ) 
	BEGIN
		UPDATE	CVO_Control..ewcomp
		SET     CVO_Control..ewcomp.account_format_mask = 
			inserted.account_format_mask
		FROM 	CVO_Control..ewcomp, inserted
		WHERE 	CVO_Control..ewcomp.company_id = inserted.company_id
	END

	IF UPDATE ( batch_proc_flag )	
	BEGIN
		UPDATE	CVO_Control..ewcomp
		SET     CVO_Control..ewcomp.batch_proc_flag = 
			inserted.batch_proc_flag
		FROM 	CVO_Control..ewcomp, inserted
		WHERE 	CVO_Control..ewcomp.company_id = inserted.company_id
	END

	IF UPDATE ( multi_company_flag )	
	BEGIN
		UPDATE	CVO_Control..ewcomp
		SET     CVO_Control..ewcomp.multi_company_flag = 
			inserted.multi_company_flag
		FROM 	CVO_Control..ewcomp, inserted
		WHERE 	CVO_Control..ewcomp.company_id = inserted.company_id
	END

	IF UPDATE ( multi_currency_flag )	
	BEGIN
		UPDATE	CVO_Control..ewcomp
		SET     CVO_Control..ewcomp.multi_currency_flag = 
			inserted.multi_currency_flag
		FROM 	CVO_Control..ewcomp, inserted
		WHERE 	CVO_Control..ewcomp.company_id = inserted.company_id
	END


GO
CREATE UNIQUE CLUSTERED INDEX [glco_ind_0] ON [dbo].[glco] ([company_id]) ON [PRIMARY]
GO
EXEC sp_bindefault N'[dbo].[glupdate_ok]', N'[dbo].[glco].[glupdate_status_flag]'
GO
GRANT SELECT ON  [dbo].[glco] TO [public]
GO
GRANT INSERT ON  [dbo].[glco] TO [public]
GO
GRANT DELETE ON  [dbo].[glco] TO [public]
GO
GRANT UPDATE ON  [dbo].[glco] TO [public]
GO
