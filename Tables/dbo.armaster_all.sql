CREATE TABLE [dbo].[armaster_all]
(
[timestamp] [timestamp] NULL,
[customer_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ship_to_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[address_name] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[short_name] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[addr1] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[addr2] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[addr3] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[addr4] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[addr5] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[addr6] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[addr_sort1] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[addr_sort2] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[addr_sort3] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[address_type] [smallint] NULL,
[status_type] [smallint] NULL,
[attention_name] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[attention_phone] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[contact_name] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[contact_phone] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[tlx_twx] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[phone_1] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[phone_2] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[tax_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[terms_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[fob_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[freight_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[posting_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[location_code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[alt_location_code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[dest_zone_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[territory_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[salesperson_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[fin_chg_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[price_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[payment_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[vendor_code] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[affiliated_cust_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[print_stmt_flag] [smallint] NULL,
[stmt_cycle_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[inv_comment_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[stmt_comment_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[dunn_message_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[note] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[trade_disc_percent] [float] NULL,
[invoice_copies] [smallint] NULL,
[iv_substitution] [smallint] NULL,
[ship_to_history] [smallint] NULL,
[check_credit_limit] [smallint] NULL,
[credit_limit] [float] NULL,
[check_aging_limit] [smallint] NULL,
[aging_limit_bracket] [smallint] NULL,
[bal_fwd_flag] [smallint] NULL,
[ship_complete_flag] [smallint] NULL,
[resale_num] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[db_num] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[db_date] [int] NULL,
[db_credit_rating] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[late_chg_type] [smallint] NULL,
[valid_payer_flag] [smallint] NULL,
[valid_soldto_flag] [smallint] NULL,
[valid_shipto_flag] [smallint] NULL,
[payer_soldto_rel_code] [char] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[across_na_flag] [smallint] NULL,
[date_opened] [int] NULL,
[added_by_user_name] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[added_by_date] [datetime] NULL,
[modified_by_user_name] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[modified_by_date] [datetime] NULL,
[rate_type_home] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[rate_type_oper] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[limit_by_home] [smallint] NULL,
[nat_cur_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[one_cur_cust] [smallint] NULL,
[city] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[state] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[postal_code] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[country] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[remit_code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[forwarder_code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[freight_to_code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[route_code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[route_no] [int] NULL,
[url] [varchar] (256) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[special_instr] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[guid] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[price_level] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ship_via_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ddid] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[so_priority_code] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[country_code] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[tax_id_num] [varchar] (17) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ftp] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[attention_email] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[contact_email] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[dunning_group_id] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[consolidated_invoices] [smallint] NOT NULL CONSTRAINT [DF__armaster___conso__28EF0D13] DEFAULT ((0)),
[writeoff_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[delivery_days] [int] NULL,
[extended_name] [varchar] (120) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[check_extendedname_flag] [smallint] NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO



CREATE TRIGGER [dbo].[armaster_all_del_trg]
ON [dbo].[armaster_all]
FOR DELETE
AS

-- inserts audit data for field address_sort1 (customer type)     elabarbera  3/14/2013
INSERT CVOARMasterAudit (field_name, field_from, field_to, customer_code, ship_to_code, movement_flag, audit_date, user_id) SELECT 'addr_sort1', i.addr_sort1, d.addr_sort1, d.customer_code, d.ship_to_code, 0, getdate(), SUSER_SNAME() from inserted i INNER JOIN deleted d ON i.customer_code = d.customer_code AND i.address_type = d.address_type
-- above cannot be used to audit contact_email, attention_email, ftp, special_instr, note & extended_name they require varchar (255)

BEGIN

 DELETE arnarel
 FROM arnarel, deleted
 WHERE parent = deleted.customer_code
 OR child = deleted.customer_code
 AND deleted.address_type = 0


 DELETE artierrl
 FROM artierrl, deleted
 WHERE rel_cust = deleted.customer_code
 AND deleted.address_type = 0
 
 DELETE cust_rep
 FROM deleted
 WHERE cust_rep.customer_key = deleted.customer_code
 AND deleted.address_type = 0

END


GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE TRIGGER [dbo].[armaster_all_ins_trg]
on [dbo].[armaster_all]
FOR INSERT
AS

-- inserts audit data for field address_sort1 (customer type)         elabarbera  3/14/2013
/*
CREATE TABLE CVOARMasterAudit (
field_name VARCHAR(30), 
field_from VARCHAR(60), 
field_to VARCHAR(60),
customer_code VARCHAR(8), 
ship_to_code VARCHAR(8), 
movement_flag SMALLINT, 
audit_date SMALLDATETIME, 
user_id VARCHAR(60)
)
*/
INSERT CVOARMasterAudit (field_name, field_from, field_to, customer_code, ship_to_code, movement_flag, audit_date, user_id) SELECT 'addr_sort1' as field_name, '', addr_sort1, customer_code, ship_to_code, 1, getdate(), added_by_user_name 
from inserted 

INSERT CVOARMasterAudit (field_name, field_from, field_to, customer_code, ship_to_code, movement_flag, audit_date, user_id) SELECT 'price_code' as field_name, '', price_code, customer_code, ship_to_code, 1, getdate(), added_by_user_name 
from inserted 

INSERT CVOARMasterAudit (field_name, field_from, field_to, customer_code, ship_to_code, movement_flag, audit_date, user_id) SELECT 'status_type' as field_name, '', status_type, customer_code, ship_to_code, 1, getdate(), added_by_user_name 
from inserted 
-- above cannot be used to audit contact_email, attention_email, ftp, special_instr, note & extended_name they require varchar (255)


BEGIN
 

 WHILE ( 1 = 1 )
 BEGIN
 INSERT artierrl ( 
 relation_code,
 parent, 
 child_1, 
 child_2, 
 child_3, 
 child_4, 
 child_5,
 child_6, 
 child_7, 
 child_8, 
 child_9, 
 rel_cust,
 tier_level ) 
 SELECT arrelcde.relation_code, 
 inserted.customer_code, 
 '        ',
 '        ',
 '        ',
 '        ',
 '        ',
 '        ',
 '        ',
 '        ',
 '        ',
 inserted.customer_code,
 1
 FROM inserted, arrelcde
 WHERE arrelcde.tiered_flag != 0
 AND inserted.customer_code NOT IN
 ( select rel_cust from artierrl
 where artierrl.relation_code = arrelcde.relation_code )

 
 BREAK
 END

 
 
END

GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO



CREATE TRIGGER [dbo].[armaster_all_upd_trg]
ON [dbo].[armaster_all]
FOR UPDATE
AS

-- inserts audit data for field address_sort1 (customer type)       elabarbera   3/14/2013
INSERT CVOARMasterAudit (field_name, field_from, field_to, customer_code, ship_to_code, movement_flag, audit_date, user_id) SELECT 'addr_sort1', d.addr_sort1, i.addr_sort1, i.customer_code, i.ship_to_code, 2, getdate(), SUSER_SNAME() from inserted i INNER JOIN deleted d ON i.customer_code = d.customer_code AND i.address_type = d.address_type
where d.addr_sort1<>i.addr_sort1 and d.Customer_code=I.customer_code and d.ship_to_code=i.ship_to_code  -- 1/14/2014 EL - Added Cust & Ship_To compare

INSERT CVOARMasterAudit (field_name, field_from, field_to, customer_code, ship_to_code, movement_flag, audit_date, user_id) SELECT 'price_code', d.price_code, i.price_code, i.customer_code, i.ship_to_code, 2, getdate(), SUSER_SNAME() from inserted i INNER JOIN deleted d ON i.customer_code = d.customer_code AND i.address_type = d.address_type
where d.price_code<>i.price_code and d.Customer_code=I.customer_code and d.ship_to_code=i.ship_to_code -- 1/14/2014 EL - Added Cust & Ship_To compare

INSERT CVOARMasterAudit (field_name, field_from, field_to, customer_code, ship_to_code, movement_flag, audit_date, user_id) SELECT 'status_type', d.Status_type, i.Status_type, i.customer_code, i.ship_to_code, 2, getdate(), SUSER_SNAME() from inserted i INNER JOIN deleted d ON i.customer_code = d.customer_code AND i.address_type = d.address_type
where d.Status_type<>i.Status_type and d.Customer_code=I.customer_code and d.ship_to_code=i.ship_to_code -- 1/14/2014 EL - Added Cust & Ship_To compare

INSERT CVOARMasterAudit (field_name, field_from, field_to, customer_code, ship_to_code, movement_flag, audit_date, user_id) SELECT 'Territory_code', d.Territory_code, i.Territory_code, i.customer_code, i.ship_to_code, 2, getdate(), SUSER_SNAME() from inserted i INNER JOIN deleted d ON i.customer_code = d.customer_code AND i.address_type = d.address_type
where d.Territory_code<>i.Territory_code and d.Customer_code=I.customer_code and d.ship_to_code=i.ship_to_code -- 4/2/2014 EL 

INSERT CVOARMasterAudit (field_name, field_from, field_to, customer_code, ship_to_code, movement_flag, audit_date, user_id) SELECT 'Salesperson_code', d.Salesperson_code, i.Salesperson_code, i.customer_code, i.ship_to_code, 2, getdate(), SUSER_SNAME() from inserted i INNER JOIN deleted d ON i.customer_code = d.customer_code AND i.address_type = d.address_type
where d.Salesperson_code<>i.Salesperson_code and d.Customer_code=I.customer_code and d.ship_to_code=i.ship_to_code -- 4/2/2014 EL 

INSERT CVOARMasterAudit (field_name, field_from, field_to, customer_code, ship_to_code, movement_flag, audit_date, user_id) SELECT 'TERMS_CODE', d.terms_code, i.terms_code, i.customer_code, i.ship_to_code, 2, getdate(), SUSER_SNAME() from inserted i INNER JOIN deleted d ON i.customer_code = d.customer_code AND i.address_type = d.address_type
where d.terms_code<>i.terms_code and d.Customer_code=I.customer_code and d.ship_to_code=i.ship_to_code -- 4/2/2014 EL 

INSERT CVOARMasterAudit (field_name, field_from, field_to, customer_code, ship_to_code, movement_flag, audit_date, user_id) SELECT 'Address_name', d.Address_name, i.Address_name, i.customer_code, i.ship_to_code, 2, getdate(), SUSER_SNAME() from inserted i INNER JOIN deleted d ON i.customer_code = d.customer_code AND i.address_type = d.address_type
where d.Address_name<>i.Address_name and d.Customer_code=I.customer_code and d.ship_to_code=i.ship_to_code -- 4/24/2014 EL 

INSERT CVOARMasterAudit (field_name, field_from, field_to, customer_code, ship_to_code, movement_flag, audit_date, user_id) SELECT 'Addr1', d.Addr1, i.Addr1, i.customer_code, i.ship_to_code, 2, getdate(), SUSER_SNAME() from inserted i INNER JOIN deleted d ON i.customer_code = d.customer_code AND i.address_type = d.address_type
where d.Addr1<>i.Addr1 and d.Customer_code=I.customer_code and d.ship_to_code=i.ship_to_code -- 4/24/2014 EL 

INSERT CVOARMasterAudit (field_name, field_from, field_to, customer_code, ship_to_code, movement_flag, audit_date, user_id) SELECT 'BG_invoice', d.alt_location_code, i.alt_location_code, i.customer_code, i.ship_to_code, 2, getdate(), SUSER_SNAME() from inserted i INNER JOIN deleted d ON i.customer_code = d.customer_code AND i.address_type = d.address_type
where d.alt_location_code<>i.alt_location_code and d.Customer_code=I.customer_code and d.ship_to_code=i.ship_to_code -- 4/24/2014 EL 

INSERT CVOARMasterAudit (field_name, field_from, field_to, customer_code, ship_to_code, movement_flag, audit_date, user_id) SELECT 'Valid_soldto_flag', d.valid_soldto_flag, i.valid_soldto_flag, i.customer_code, i.ship_to_code, 2, getdate(), SUSER_SNAME() from inserted i INNER JOIN deleted d ON i.customer_code = d.customer_code AND i.address_type = d.address_type
where d.valid_soldto_flag<>i.valid_soldto_flag and d.Customer_code=I.customer_code and d.ship_to_code=i.ship_to_code -- 11/13/2015 tag - per KM request

INSERT CVOARMasterAudit (field_name, field_from, field_to, customer_code, ship_to_code, movement_flag, audit_date, user_id) SELECT 'Valid_shipto_flag', d.valid_shipto_flag, i.valid_shipto_flag, i.customer_code, i.ship_to_code, 2, getdate(), SUSER_SNAME() from inserted i INNER JOIN deleted d ON i.customer_code = d.customer_code AND i.address_type = d.address_type
where d.valid_shipto_flag<>i.valid_shipto_flag and d.Customer_code=I.customer_code and d.ship_to_code=i.ship_to_code -- 11/13/2015 tag - per KM request

-- add per JB - 7/7/2016

INSERT CVOARMasterAudit (field_name, field_from, field_to, customer_code, ship_to_code, movement_flag, audit_date, user_id) SELECT 'Country_code', d.country_code, i.country_code, i.customer_code, i.ship_to_code, 2, getdate(), SUSER_SNAME() from inserted i INNER JOIN deleted d ON i.customer_code = d.customer_code AND i.address_type = d.address_type
where d.country_code<>i.country_code and d.Customer_code=I.customer_code and d.ship_to_code=i.ship_to_code -- 11/13/2015 tag - per KM request

INSERT CVOARMasterAudit (field_name, field_from, field_to, customer_code, ship_to_code, movement_flag, audit_date, user_id) SELECT 'State', d.state, i.state, i.customer_code, i.ship_to_code, 2, getdate(), SUSER_SNAME() from inserted i INNER JOIN deleted d ON i.customer_code = d.customer_code AND i.address_type = d.address_type
where d.state<>i.state and d.Customer_code=I.customer_code and d.ship_to_code=i.ship_to_code -- 11/13/2015 tag - per KM request

INSERT CVOARMasterAudit 
(field_name
, field_from
, field_to
, customer_code
, ship_to_code
, movement_flag
, audit_date
, user_id) 
SELECT distinct 'Back Order Flag - Non RX'
, cast (CASE d.ship_complete_flag
			WHEN 0 THEN 'Allow BO'
			WHEN 1 THEN 'Ship Comp'
			WHEN 2 THEN 'Partial Ship'
			ELSE 'Unknown'
			end as VARCHAR(20))
, cast (CASE i.ship_complete_flag
			WHEN 0 THEN 'Allow BO'
			WHEN 1 THEN 'Ship Comp'
			WHEN 2 THEN 'Partial Ship'
			ELSE 'Unknown'
			end as varchar(20))
, i.customer_code
, i.ship_to_code
, 2 -- change
, getdate()
, SUSER_SNAME() 
from inserted i 
INNER JOIN deleted d ON 
i.customer_code = d.customer_code
AND i.ship_to_code = d.ship_to_code -- 9/21/2016 
AND i.address_type = d.address_type
where isnull(d.ship_complete_flag,0)<>isnull(i.ship_complete_flag,0)


-- above cannot be used to audit contact_email, attention_email, ftp, special_instr, note & extended_name they require varchar (255)

BEGIN
 DECLARE @trx_done smallint

 IF UPDATE ( customer_code )
 BEGIN

 UPDATE arnarel
 SET parent = inserted.customer_code
 FROM arnarel, deleted, inserted
 WHERE deleted.customer_code = arnarel.parent
			AND inserted.address_type = 0

 UPDATE arnarel
 SET child = inserted.customer_code
 FROM arnarel, deleted, inserted
 WHERE arnarel.child = deleted.customer_code
			AND inserted.address_type = 0

 UPDATE artierrl
 SET parent = inserted.customer_code,
 rel_cust = inserted.customer_code
 FROM artierrl, deleted, inserted
 WHERE artierrl.rel_cust = deleted.customer_code
			AND inserted.address_type = 0

 UPDATE cust_rep
 SET customer_key = inserted.customer_code
 FROM inserted
 WHERE cust_rep.customer_key = inserted.customer_code
 AND inserted.address_type = 0
 END

END
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/*
Name:		cvo_armaster_all_u_trg		
Type:		Trigger
Description:	Updates open orders when customer/shipto addresses are changed
Version:	1.0
Developer:	Chris Tyler

History
-------
v1.0	CT	09/08/2012	Original Version
v1.1	CT	10/08/2012	Added global ship tos
*/

CREATE TRIGGER [dbo].[cvo_armaster_all_u_trg] ON [dbo].[armaster_all]
FOR UPDATE
AS
BEGIN

	DECLARE
		@address_type			INT,
		@customer_code			VARCHAR(8),
		@ship_to_code			VARCHAR(8),
		@d_shipto_name			VARCHAR(40),
		@d_shipto_add_1			VARCHAR(40),
		@d_shipto_add_2			VARCHAR(40),
		@d_shipto_add_3			VARCHAR(40),
		@d_shipto_add_4			VARCHAR(40),
		@d_shipto_add_5			VARCHAR(40),
		@d_shipto_city			VARCHAR(40),
		@d_shipto_state			VARCHAR(40),
		@d_shipto_zip			VARCHAR(15),
		@d_shipto_country		VARCHAR(40),
		@d_country_code			VARCHAR(3),
		@i_shipto_name			VARCHAR(40),
		@i_shipto_add_1			VARCHAR(40),
		@i_shipto_add_2			VARCHAR(40),
		@i_shipto_add_3			VARCHAR(40),
		@i_shipto_add_4			VARCHAR(40),
		@i_shipto_add_5			VARCHAR(40),
		@i_shipto_city			VARCHAR(40),
		@i_shipto_state			VARCHAR(40),
		@i_shipto_zip			VARCHAR(15),
		@i_shipto_country		VARCHAR(40),
		@i_country_code			VARCHAR(3)


	-- Loop through customer records where address has changed 
	SET @customer_code = ''

	WHILE 1=1
	BEGIN
		SELECT
			@customer_code = i.customer_code,
			@i_shipto_name = i.address_name,
			@i_shipto_add_1 = i.addr2,
			@i_shipto_add_2 = i.addr3,
			@i_shipto_add_3 = i.addr4,
			@i_shipto_add_4 = i.addr5,
			@i_shipto_add_5 = i.addr6,
			@i_shipto_city = i.city,
			@i_shipto_state = i.state,
			@i_shipto_zip = i.postal_code,
			@i_shipto_country = i.country,
			@i_country_code = i.country_code,
			@d_shipto_name = d.address_name,
			@d_shipto_add_1 = d.addr2,
			@d_shipto_add_2 = d.addr3,
			@d_shipto_add_3 = d.addr4,
			@d_shipto_add_4 = d.addr5,
			@d_shipto_add_5 = d.addr6,
			@d_shipto_city = d.city,
			@d_shipto_state = d.state,
			@d_shipto_zip = d.postal_code,
			@d_shipto_country = d.country,
			@d_country_code = d.country_code
		FROM
			inserted i
		INNER JOIN
			deleted d
		ON
			i.customer_code = d.customer_code
			AND i.ship_to_code = d.ship_to_code
			AND i.address_type = d.address_type
		WHERE
			i.customer_code > @customer_code
			AND i.address_type = 0
			AND (	(i.address_name <> d.address_name)
				 OR	(i.addr2 <> d.addr2)	
				 OR	(i.addr3 <> d.addr3)
				 OR	(i.addr4 <> d.addr4)
				 OR	(i.addr5 <> d.addr5)
				 OR	(i.addr6 <> d.addr6)
				 OR	(i.city <> d.city)
				 OR	(i.state <> d.state)
				 OR	(i.postal_code <> d.postal_code)
				 OR	(i.country <> d.country)
				 OR (i.country_code <> d.country_code))
		ORDER BY
			i.customer_code
		
		IF @@ROWCOUNT = 0
			BREAK

		-- Update any open orders for this customer which have the old address
		UPDATE
			dbo.orders_all
		SET
			ship_to_name = @i_shipto_name,
			ship_to_add_1 = @i_shipto_add_1,
			ship_to_add_2 = @i_shipto_add_2, 
			ship_to_add_3 = @i_shipto_add_3,
			ship_to_add_4 = @i_shipto_add_4,
			ship_to_add_5 = @i_shipto_add_5, 
			ship_to_city = @i_shipto_city, 
			ship_to_state = @i_shipto_state, 
			ship_to_zip = @i_shipto_zip, 
			ship_to_country = @i_shipto_country,
			ship_to_country_cd = @i_country_code
		WHERE
			[type] = 'I'
			AND cust_code = @customer_code
			AND ship_to = ''
			AND [status] IN ('A','C','N')
			AND ship_to_name = @d_shipto_name
			AND ship_to_add_1 = @d_shipto_add_1
			AND ship_to_add_2 = @d_shipto_add_2 
			AND ship_to_add_3 = @d_shipto_add_3
			AND ship_to_add_4 = @d_shipto_add_4
			AND ship_to_add_5 = @d_shipto_add_5 
			AND ship_to_city = @d_shipto_city
			AND ship_to_state = @d_shipto_state 
			AND ship_to_zip = @d_shipto_zip
			AND ship_to_country_cd = @d_country_code
	END		

	-- Loop through shipto records where address has changed 
	SET @customer_code = ''

	WHILE 1=1
	BEGIN
		-- First loop through at customer level for the shiptos
		SELECT
			@customer_code = customer_code
		FROM
			inserted 
		WHERE
			customer_code > @customer_code
			AND address_type = 1
		ORDER BY
			customer_code

		IF @@ROWCOUNT = 0
			BREAK

		-- Now loop through shiptos
		SET @ship_to_code = ''
		WHILE 1=1
		BEGIN
			SELECT
				@ship_to_code = i.ship_to_code,
				@i_shipto_name = i.address_name,
				@i_shipto_add_1 = i.addr2,
				@i_shipto_add_2 = i.addr3,
				@i_shipto_add_3 = i.addr4,
				@i_shipto_add_4 = i.addr5,
				@i_shipto_add_5 = i.addr6,
				@i_shipto_city = i.city,
				@i_shipto_state = i.state,
				@i_shipto_zip = i.postal_code,
				@i_shipto_country = i.country,
				@i_country_code = i.country_code,
				@d_shipto_name = d.address_name,
				@d_shipto_add_1 = d.addr2,
				@d_shipto_add_2 = d.addr3,
				@d_shipto_add_3 = d.addr4,
				@d_shipto_add_4 = d.addr5,
				@d_shipto_add_5 = d.addr6,
				@d_shipto_city = d.city,
				@d_shipto_state = d.state,
				@d_shipto_zip = d.postal_code,
				@d_shipto_country = d.country,
				@d_country_code = d.country_code
			FROM
				inserted i
			INNER JOIN
				deleted d
			ON
				i.customer_code = d.customer_code
				AND i.ship_to_code = d.ship_to_code
				AND i.address_type = d.address_type
			WHERE
				i.customer_code = @customer_code
				AND i.ship_to_code > @ship_to_code
				AND i.address_type = 1
				AND (	(i.address_name <> d.address_name)
					 OR	(i.addr2 <> d.addr2)	
					 OR	(i.addr3 <> d.addr3)
					 OR	(i.addr4 <> d.addr4)
					 OR	(i.addr5 <> d.addr5)
					 OR	(i.addr6 <> d.addr6)
					 OR	(i.city <> d.city)
					 OR	(i.state <> d.state)
					 OR	(i.postal_code <> d.postal_code)
					 OR	(i.country <> d.country)
					 OR (i.country_code <> d.country_code))
			ORDER BY
				i.ship_to_code

			IF @@ROWCOUNT = 0
				BREAK

			-- Update any open orders for this customer/shipto which have the old address
			UPDATE
				dbo.orders_all
			SET
				ship_to_name = @i_shipto_name,
				ship_to_add_1 = @i_shipto_add_1,
				ship_to_add_2 = @i_shipto_add_2, 
				ship_to_add_3 = @i_shipto_add_3,
				ship_to_add_4 = @i_shipto_add_4,
				ship_to_add_5 = @i_shipto_add_5, 
				ship_to_city = @i_shipto_city, 
				ship_to_state = @i_shipto_state, 
				ship_to_zip = @i_shipto_zip, 
				ship_to_country = @i_shipto_country,
				ship_to_country_cd = @i_country_code
			WHERE
				[type] = 'I'
				AND cust_code = @customer_code
				AND ship_to = @ship_to_code
				AND [status] IN ('A','C','N')
				AND ship_to_name = @d_shipto_name
				AND ship_to_add_1 = @d_shipto_add_1
				AND ship_to_add_2 = @d_shipto_add_2 
				AND ship_to_add_3 = @d_shipto_add_3
				AND ship_to_add_4 = @d_shipto_add_4
				AND ship_to_add_5 = @d_shipto_add_5 
				AND ship_to_city = @d_shipto_city 
				AND ship_to_state = @d_shipto_state 
				AND ship_to_zip = @d_shipto_zip 
				AND ship_to_country_cd = @d_country_code
		END
	END

	-- START v1.1
	-- Loop through global shipto records where address has changed 
	SET @customer_code = ''

	WHILE 1=1
	BEGIN
		SELECT
			@customer_code = i.customer_code,
			@i_shipto_name = i.address_name,
			@i_shipto_add_1 = i.addr2,
			@i_shipto_add_2 = i.addr3,
			@i_shipto_add_3 = i.addr4,
			@i_shipto_add_4 = i.addr5,
			@i_shipto_add_5 = i.addr6,
			@i_shipto_city = i.city,
			@i_shipto_state = i.state,
			@i_shipto_zip = i.postal_code,
			@i_shipto_country = i.country,
			@i_country_code = i.country_code,
			@d_shipto_name = d.address_name,
			@d_shipto_add_1 = d.addr2,
			@d_shipto_add_2 = d.addr3,
			@d_shipto_add_3 = d.addr4,
			@d_shipto_add_4 = d.addr5,
			@d_shipto_add_5 = d.addr6,
			@d_shipto_city = d.city,
			@d_shipto_state = d.state,
			@d_shipto_zip = d.postal_code,
			@d_shipto_country = d.country,
			@d_country_code = d.country_code
		FROM
			inserted i
		INNER JOIN
			deleted d
		ON
			i.customer_code = d.customer_code
			AND i.ship_to_code = d.ship_to_code
			AND i.address_type = d.address_type
		WHERE
			i.customer_code > @customer_code
			AND i.address_type = 9
			AND (	(i.address_name <> d.address_name)
				 OR	(i.addr2 <> d.addr2)	
				 OR	(i.addr3 <> d.addr3)
				 OR	(i.addr4 <> d.addr4)
				 OR	(i.addr5 <> d.addr5)
				 OR	(i.addr6 <> d.addr6)
				 OR	(i.city <> d.city)
				 OR	(i.state <> d.state)
				 OR	(i.postal_code <> d.postal_code)
				 OR	(i.country <> d.country)
				 OR (i.country_code <> d.country_code))
		ORDER BY
			i.customer_code

		IF @@ROWCOUNT = 0
			BREAK

		-- Update any open orders for this global shipto which have the old address
		UPDATE
			dbo.orders_all
		SET
			sold_to_addr1 = @i_shipto_name,
			sold_to_addr2 = @i_shipto_add_1,
			sold_to_addr3 = @i_shipto_add_2, 
			sold_to_addr4 = @i_shipto_add_3,
			sold_to_addr5 = @i_shipto_add_4,
			sold_to_addr6 = @i_shipto_add_5, 
			sold_to_city = @i_shipto_city, 
			sold_to_state = @i_shipto_state, 
			sold_to_zip = @i_shipto_zip, 
			sold_to_country_cd = @i_country_code
		WHERE
			[type] = 'I'
			AND sold_to = @customer_code
			AND [status] IN ('A','C','N')
			AND sold_to_addr1 = @d_shipto_name
			AND sold_to_addr2 = @d_shipto_add_1
			AND sold_to_addr3 = @d_shipto_add_2 
			AND sold_to_addr4 = @d_shipto_add_3
			AND sold_to_addr5 = @d_shipto_add_4
			AND sold_to_addr6 = @d_shipto_add_5 
			AND sold_to_city = @d_shipto_city
			AND sold_to_state = @d_shipto_state 
			AND sold_to_zip = @d_shipto_zip
			AND sold_to_country_cd = @d_country_code
	END	
	-- END v1.1		
END
GO
CREATE NONCLUSTERED INDEX [armaster_all_ind_5] ON [dbo].[armaster_all] ([addr_sort1]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [armaster_all_ind_7] ON [dbo].[armaster_all] ([addr_sort3]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [armaster_all_ind_1] ON [dbo].[armaster_all] ([address_name]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [armaster_all_ind_addrtype] ON [dbo].[armaster_all] ([address_type]) INCLUDE ([addr_sort1], [customer_code], [ship_to_code]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [armaster_all_ind_2] ON [dbo].[armaster_all] ([address_type], [status_type]) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [armaster_all_ind_0] ON [dbo].[armaster_all] ([customer_code], [ship_to_code], [address_type]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [armaster_all_ind_3] ON [dbo].[armaster_all] ([price_code]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [armaster_all_ind_4] ON [dbo].[armaster_all] ([salesperson_code]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [armaster_all_terr_032814] ON [dbo].[armaster_all] ([territory_code]) ON [PRIMARY]
GO
GRANT DELETE ON  [dbo].[armaster_all] TO [public]
GO
GRANT INSERT ON  [dbo].[armaster_all] TO [public]
GO
GRANT REFERENCES ON  [dbo].[armaster_all] TO [public]
GO
GRANT SELECT ON  [dbo].[armaster_all] TO [public]
GO
GRANT UPDATE ON  [dbo].[armaster_all] TO [public]
GO
