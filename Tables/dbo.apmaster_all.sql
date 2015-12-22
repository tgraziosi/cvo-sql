CREATE TABLE [dbo].[apmaster_all]
(
[timestamp] [timestamp] NOT NULL,
[vendor_code] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[pay_to_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[address_name] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[short_name] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[addr1] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[addr2] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[addr3] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[addr4] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[addr5] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[addr6] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[addr_sort1] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[addr_sort2] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[addr_sort3] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[address_type] [smallint] NOT NULL,
[status_type] [smallint] NOT NULL,
[attention_name] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[attention_phone] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[contact_name] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[contact_phone] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[tlx_twx] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[phone_1] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[phone_2] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[tax_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[terms_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[fob_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[posting_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[location_code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[orig_zone_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[customer_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[affiliated_vend_code] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[alt_vendor_code] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[comment_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[vend_class_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[branch_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[pay_to_hist_flag] [smallint] NULL,
[item_hist_flag] [smallint] NULL,
[credit_limit_flag] [smallint] NULL,
[credit_limit] [float] NULL,
[aging_limit_flag] [smallint] NULL,
[aging_limit] [smallint] NULL,
[restock_chg_flag] [smallint] NULL,
[restock_chg] [float] NULL,
[prc_flag] [smallint] NULL,
[vend_acct] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[tax_id_num] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[flag_1099] [smallint] NULL,
[exp_acct_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[amt_max_check] [float] NULL,
[lead_time] [smallint] NULL,
[doc_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[one_check_flag] [smallint] NULL,
[dup_voucher_flag] [smallint] NULL,
[dup_amt_flag] [smallint] NULL,
[code_1099] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[user_trx_type_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[payment_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[limit_by_home] [smallint] NULL,
[rate_type_home] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[rate_type_oper] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[nat_cur_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[one_cur_vendor] [smallint] NULL,
[cash_acct_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[city] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[state] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[postal_code] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[country] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[freight_code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[url] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[note] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[country_code] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ftp] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[attention_email] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[contact_email] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[etransmit_ind] [int] NULL,
[vo_hold_flag] [int] NULL,
[po_item_flag] [int] NULL,
[buying_cycle] [int] NULL,
[proc_vend_flag] [int] NULL,
[at_tax_code_flag] [int] NULL,
[at_tax_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[voprocs_amount_acc_expense] [smallint] NULL CONSTRAINT [DF__apmaster___vopro__04DA0157] DEFAULT ((0)),
[at_usevendor_prorate_setting] [smallint] NULL CONSTRAINT [DF__apmaster___at_us__05CE2590] DEFAULT ((0)),
[tax_flag] [smallint] NULL CONSTRAINT [DF__apmaster___tax_f__06C249C9] DEFAULT ((1)),
[tax_per_1line_2qty_3amt] [smallint] NULL CONSTRAINT [DF__apmaster___tax_p__07B66E02] DEFAULT ((3)),
[freight_flag] [smallint] NULL CONSTRAINT [DF__apmaster___freig__08AA923B] DEFAULT ((0)),
[freight_per_1line_2qty_3amt] [smallint] NULL CONSTRAINT [DF__apmaster___freig__099EB674] DEFAULT ((3)),
[disc_flag] [smallint] NULL CONSTRAINT [DF__apmaster___disc___0A92DAAD] DEFAULT ((0)),
[disc_per_1line_2qty_3amt] [smallint] NULL CONSTRAINT [DF__apmaster___disc___0B86FEE6] DEFAULT ((3)),
[misc_flag] [smallint] NULL CONSTRAINT [DF__apmaster___misc___0C7B231F] DEFAULT ((0)),
[misc_per_1line_2qty_3amt] [smallint] NULL CONSTRAINT [DF__apmaster___misc___0D6F4758] DEFAULT ((3)),
[extended_name] [varchar] (120) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[check_extendedname_flag] [smallint] NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE TRIGGER [dbo].[apmaster_all_del_trg]
	ON [dbo].[apmaster_all]
	FOR DELETE AS
BEGIN
	--case of delete
	--update the modified date to current system date,
	--update the status to inactive (0)
	update epapvend
	set 	epapvend.modified_dt = GETDATE(),
		epapvend.status = 0
	from deleted d
	where epapvend.vendor_code = d.vendor_code
END
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE TRIGGER [dbo].[apmaster_all_ins_trg]
	ON [dbo].[apmaster_all]
	FOR INSERT AS
BEGIN
	--Case of insert
	
	--Check if the vendor exists within epapvend
	IF (exists(select 'X' from inserted i, epapvend e where e.vendor_code = i.vendor_code))
	BEGIN
		--Update modified_dt and status
		update epapvend
		set 	epapvend.modified_dt = GETDATE(),
			epapvend.status = CASE i.status_type
					   WHEN 5 THEN 1
					   WHEN 6 THEN 0
					   ELSE 0
				              END
		from inserted i
		where epapvend.vendor_code = i.vendor_code
	END
	ELSE
	BEGIN
		--Insert guid, vendor_code, modified_dt and status
		insert epapvend 
		select NEWID(), i.vendor_code, GETDATE(),
		status = CASE i.status_type
			 WHEN 5 THEN 1
			 WHEN 6 THEN 0
			 ELSE 0
		             END
		from inserted i
		where i.address_type = 0
	END
END
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


/*                                                      
               Confidential Information                 
    Limited Distribution of Authorized Persons Only     
    Created 2005 and Protected as Unpublished Work      
          Under the U.S. Copyright Act of 1976          
 Copyright (c) 2005 Epicor Software Corporation, 2005   
                  All Rights Reserved                   
*/

CREATE TRIGGER [dbo].[apmaster_all_integration_del_trg]
	ON [dbo].[apmaster_all]
	FOR DELETE AS
BEGIN
	INSERT INTO epintegrationrecs SELECT vendor_code, '', 1, 'D', 0 FROM Deleted WHERE proc_vend_flag = 1
END

GO
DISABLE TRIGGER [dbo].[apmaster_all_integration_del_trg] ON [dbo].[apmaster_all]
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


/*                                                      
               Confidential Information                 
    Limited Distribution of Authorized Persons Only     
    Created 2005 and Protected as Unpublished Work      
          Under the U.S. Copyright Act of 1976          
 Copyright (c) 2005 Epicor Software Corporation, 2005   
                  All Rights Reserved                   
*/

CREATE TRIGGER [dbo].[apmaster_all_integration_ins_trg]
	ON [dbo].[apmaster_all]
	FOR INSERT AS
BEGIN
	INSERT INTO epintegrationrecs SELECT vendor_code, '', 1, 'I', 0 FROM Inserted WHERE proc_vend_flag = 1
END


GO
DISABLE TRIGGER [dbo].[apmaster_all_integration_ins_trg] ON [dbo].[apmaster_all]
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


/*                                                      
               Confidential Information                 
    Limited Distribution of Authorized Persons Only     
    Created 2005 and Protected as Unpublished Work      
          Under the U.S. Copyright Act of 1976          
 Copyright (c) 2005 Epicor Software Corporation, 2005   
                  All Rights Reserved                   
*/

CREATE TRIGGER [dbo].[apmaster_all_integration_upd_trg]
	ON [dbo].[apmaster_all]
	FOR UPDATE AS
BEGIN	
	DELETE epintegrationrecs WHERE action = 'U' AND type = 1 AND id_code IN ( SELECT vendor_code FROM Inserted )
	INSERT INTO epintegrationrecs SELECT vendor_code, '', 1, 'U', 0 FROM Inserted WHERE proc_vend_flag = 1  
END

GO
DISABLE TRIGGER [dbo].[apmaster_all_integration_upd_trg] ON [dbo].[apmaster_all]
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE TRIGGER [dbo].[apmaster_all_upd_trg]
	ON [dbo].[apmaster_all]
	FOR UPDATE AS
BEGIN
	--Case of update
	--Update modified_dt and status	
	update epapvend
	set epapvend.modified_dt = GETDATE(),
	epapvend.status = CASE i.status_type
			   WHEN 5 THEN 1
			   WHEN 6 THEN 0
			   ELSE 0
		              END
	from inserted i, deleted d
	where epapvend.vendor_code = i.vendor_code and
		d.vendor_code = i.vendor_code and
		(d.address_name <> i.address_name or
		d.addr1 <> i.addr1 or
		d.addr2 <> i.addr2 or
		d.addr3 <> i.addr3 or
		d.addr4 <> i.addr4 or
		d.city <> i.city or
		d.state <> i.state or
		d.postal_code <> i.postal_code or
		d.country <> i.country or
		d.phone_1 <> i.phone_1 or
		d.tlx_twx <> i.tlx_twx or
		d.freight_code <> i.freight_code or
		d.url <> i.url or
		d.terms_code <> i.terms_code or
		d.fob_code <> i.fob_code or
		d.status_type <> i.status_type)
END
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE TRIGGER [dbo].[eft_apmaster_all_del]
ON [dbo].[apmaster_all]
FOR DELETE AS

BEGIN

DELETE eft_apms
FROM eft_apms, deleted
WHERE eft_apms.vendor_code = deleted.vendor_code
AND eft_apms.pay_to_code = deleted.pay_to_code

END 
GO
CREATE NONCLUSTERED INDEX [apmaster_all_ind_2] ON [dbo].[apmaster_all] ([addr_sort1]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [apmaster_all_ind_3] ON [dbo].[apmaster_all] ([addr_sort2]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [apmaster_all_ind_4] ON [dbo].[apmaster_all] ([addr_sort3]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [apmaster_all_ind_1] ON [dbo].[apmaster_all] ([address_name]) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [apmaster_all_ind_0] ON [dbo].[apmaster_all] ([vendor_code], [pay_to_code], [address_type]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[apmaster_all] TO [public]
GO
GRANT SELECT ON  [dbo].[apmaster_all] TO [public]
GO
GRANT INSERT ON  [dbo].[apmaster_all] TO [public]
GO
GRANT DELETE ON  [dbo].[apmaster_all] TO [public]
GO
GRANT UPDATE ON  [dbo].[apmaster_all] TO [public]
GO
