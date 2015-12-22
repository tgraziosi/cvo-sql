CREATE TABLE [dbo].[service_agreement]
(
[timestamp] [timestamp] NOT NULL,
[item_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[description] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[call_based] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__service_a__call___14DCF5A4] DEFAULT ('N'),
[time_based] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__service_a__time___15D119DD] DEFAULT ('N'),
[contract_length] [int] NULL,
[verify_reg_flag] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__service_a__verif__16C53E16] DEFAULT ('N'),
[allow_neg_units_flag] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__service_a__allow__17B9624F] DEFAULT ('N'),
[unltd_units_flag] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__service_a__unltd__18AD8688] DEFAULT ('N'),
[use_mult_flag] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__service_a__use_m__19A1AAC1] DEFAULT ('N'),
[void_flag] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__service_a__void___1A95CEFA] DEFAULT ('N'),
[void_date] [datetime] NULL,
[void_who] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[gl_rev_acct] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[gl_ret_acct] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


CREATE TRIGGER [dbo].[EAI_serv_agrmnt_insupddel] ON [dbo].[service_agreement]   FOR INSERT, UPDATE, DELETE  AS 
BEGIN
	DECLARE @item_id varchar(30), @data varchar(40)
	Declare @send_document_flag char(1)  -- rev 4

	select @send_document_flag = 'N'

	if exists( SELECT * FROM config WHERE flag = 'EAI' and value_str like 'Y%') begin	-- EAI is enabled
		if ( (exists(select distinct 'X' from inserted i, deleted d
			where 	((i.contract_length <> d.contract_length) or
				(i.item_id <> d.item_id) or
				(i.call_based <> d.call_based) or
				(i.time_based <> d.time_based) or
				(i.unltd_units_flag <> d.unltd_units_flag) or
				(i.verify_reg_flag <> d.verify_reg_flag) or
				(i.allow_neg_units_flag <> d.allow_neg_units_flag) or
				(i.use_mult_flag <> d.use_mult_flag) or
				(i.description <> d.description) or
				(i.void_flag <> d.void_flag))))
				or (Not Exists(select 'X' from deleted))
				or (Not Exists(select 'X' from inserted)))
		begin	-- service_agreement has been inserted or updated, send data to Front Office
			select @send_document_flag = 'Y'
		end else begin
			If Update(contract_length) or Update(item_id) or Update(description) or Update(void_flag)
			or Update(call_based) or Update(time_based) or Update(unltd_units_flag) or Update(verify_reg_flag) or
			Update(allow_neg_units_flag) or Update(use_mult_flag) begin
				select @send_document_flag = 'Y'
			end
		end

		if @send_document_flag = 'Y' begin

			if (exists(select 'X' from inserted)) begin	-- insert or update
				select distinct @item_id = min(item_id) from inserted 
			end
			else begin	-- deleted 
				select distinct @item_id = min(item_id) from deleted 
			end
			while (@item_id > '') begin
				select @data = rtrim(@item_id) + '|1'
				exec EAI_process_insert 'Part', @data, 'BO'

				if (exists(select 'X' from inserted)) begin	-- insert or update
					select distinct @item_id = min(item_id) from inserted
						where item_id > @item_id
				end
				else begin		-- deleted 
					select distinct @item_id = min(item_id) from deleted
						where item_id > @item_id
				end

			end
		end
	END
END
GO
ALTER TABLE [dbo].[service_agreement] ADD CONSTRAINT [service_agreement_allow_neg_units_flag_cc1] CHECK (([allow_neg_units_flag]='N' OR [allow_neg_units_flag]='Y'))
GO
ALTER TABLE [dbo].[service_agreement] ADD CONSTRAINT [service_agreement_call_based_cc1] CHECK (([call_based]='N' OR [call_based]='Y'))
GO
ALTER TABLE [dbo].[service_agreement] ADD CONSTRAINT [service_agreement_time_based_cc1] CHECK (([time_based]='N' OR [time_based]='Y'))
GO
ALTER TABLE [dbo].[service_agreement] ADD CONSTRAINT [service_agreement_unltd_units_flag_cc1] CHECK (([unltd_units_flag]='N' OR [unltd_units_flag]='Y'))
GO
ALTER TABLE [dbo].[service_agreement] ADD CONSTRAINT [service_agreement_use_mult_flag_cc1] CHECK (([use_mult_flag]='N' OR [use_mult_flag]='Y'))
GO
ALTER TABLE [dbo].[service_agreement] ADD CONSTRAINT [service_agreement_verify_reg_flag_cc1] CHECK (([verify_reg_flag]='N' OR [verify_reg_flag]='Y'))
GO
ALTER TABLE [dbo].[service_agreement] ADD CONSTRAINT [service_agreement_void_flag_cc1] CHECK (([void_flag]='N' OR [void_flag]='V'))
GO
CREATE UNIQUE CLUSTERED INDEX [service_agreement_pk] ON [dbo].[service_agreement] ([item_id]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[service_agreement] ADD CONSTRAINT [FK_service_agreement_glchart_gl_ret_acct] FOREIGN KEY ([gl_ret_acct]) REFERENCES [dbo].[glchart] ([account_code])
GO
ALTER TABLE [dbo].[service_agreement] ADD CONSTRAINT [FK_service_agreement_glchart_gl_rev_acct] FOREIGN KEY ([gl_rev_acct]) REFERENCES [dbo].[glchart] ([account_code])
GO
GRANT REFERENCES ON  [dbo].[service_agreement] TO [public]
GO
GRANT SELECT ON  [dbo].[service_agreement] TO [public]
GO
GRANT INSERT ON  [dbo].[service_agreement] TO [public]
GO
GRANT DELETE ON  [dbo].[service_agreement] TO [public]
GO
GRANT UPDATE ON  [dbo].[service_agreement] TO [public]
GO
