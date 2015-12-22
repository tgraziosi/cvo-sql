SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO



CREATE PROCEDURE [dbo].[cc_armrinv_sp]	@customer_code	varchar(8),
											@my_id	varchar(255) = '123456',											
											@print_copy		smallint = 1,	
											@posted_status	smallint = 0,
											@table_name		varchar(255) = 'cc_rpt_pfinv',
											@user_name	varchar(30) = '',
											@company_db	varchar(30) = ''
 	

AS
	SET NOCOUNT ON
	IF EXISTS (SELECT name FROM sysobjects WHERE name = 'sm_login_sp' ) EXEC sm_login_sp @user_name, @company_db
	

	DECLARE @result			int,
		@company_code		varchar(8),
		@process_user_id 	smallint,
		@user_name_proc 		char(30),
		@last_trx_ctrl_num	varchar(16),
		@total_tax		float,
		@date_maint_start	int,
		@date_maint_end int,
		@total_tax_str		varchar(255),
		@date_maint_start_str		varchar(255),
		@date_maint_end_str		varchar(255),
		@doc_num	int,
		@last_trx	varchar(16),

		@last_cust	varchar(8), 
		@curr_precision					smallint,
		@symbol									varchar(8),
		@temp_table							varchar(255),
		@domain			varchar(255)

	SELECT @temp_table = '#ccmrinvrpt'

	SELECT 	@company_code = company_code
	FROM	glco	

	









	SELECT @user_name_proc = LTRIM(RTRIM(loginame)), @domain = LTRIM(RTRIM(nt_domain)) 
	FROM master.dbo.sysprocesses 
	WHERE spid = @@SPID 

	SELECT @user_name_proc = replace(@user_name_proc, @domain, '')
	SELECT @user_name_proc = replace(@user_name_proc, '\', '')


	SELECT	@process_user_id = user_id 
	FROM 		glusers_vw
	WHERE 	[user_name] = @user_name_proc



	CREATE TABLE #possible_trxs 
	(
		trx_ctrl_num 		varchar(16)
	) 








	IF @posted_status = 0
		INSERT #possible_trxs (	trx_ctrl_num )
		SELECT 	trx_ctrl_num 
		FROM 	artrx
		WHERE customer_code = @customer_code
		AND doc_ctrl_num IN ( SELECT trx_num FROM cc_trx_table WHERE my_id = @my_id )
	ELSE
		INSERT #possible_trxs (	trx_ctrl_num )
		SELECT 	trx_ctrl_num 
		FROM 	arinpchg
		WHERE customer_code = @customer_code
		AND doc_ctrl_num IN ( SELECT trx_num FROM cc_trx_table WHERE my_id = @my_id )


	CREATE TABLE #ccmrinvrpt 
		(	trx_ctrl_num						varchar(16)	NULL,
				doc_ctrl_num						varchar(16)	NULL,
				doc_desc								varchar(40) NULL,
				date_doc								int					NULL,
				amt_gross								float				NULL,
				amt_tax									float				NULL,
				amt_net									float				NULL,
				unit_price							float				NULL,
				item_code								varchar(32)	NULL,
				tax_desc								varchar(40)	NULL,
				customer_code						varchar(8)	NULL,
				customer_name						varchar(40)	NULL,
				addr2										varchar(40)	NULL,
				addr3										varchar(40)	NULL,
				addr4										varchar(40)	NULL,
				addr5										varchar(40)	NULL,
				attention_name					varchar(40)	NULL,
				attention_phone					varchar(30)	NULL,
				tlx_twx									varchar(30)	NULL,
				country									varchar(40)	NULL,
				date_maint_start				int					NULL,
				date_maint_end					int					NULL,
				srp_price								float				NULL,
				user_count							int					NULL,
				svc_type_code						varchar(8)	NULL,
				seller_code							varchar(8)	NULL,
				pf_inv_ctrl_num					varchar(16)	NULL,
				part_no									varchar(32)	NULL,
				maint_part_no						varchar(32)	NULL,
				total_maint_charge			float				NULL,
				billing_periods					int					NULL,
				billing_frequency				int					NULL,
				billing_period_charge		float				NULL,
				nat_cur_code						varchar(8)	NULL,
				ship_to_code						varchar(8)	NULL,
				fixed_charge_type				int					NULL,
				fixed_charge_percent		int					NULL,
				fixed_charge_amt				float				NULL,
				description							varchar(255)	NULL,
				arco_company_name				varchar(40)	NULL,
				arco_addr1							varchar(40)	NULL,
				arco_addr2							varchar(40)	NULL,
				arco_addr3							varchar(40)	NULL,
				arco_addr4							varchar(40)	NULL,
				arco_addr5							varchar(40)	NULL,
				arco_addr6							varchar(40)	NULL,
				use_user_count					int 				NULL,
				curr_precision					smallint		NULL,
				symbol									varchar(8)	NULL,
				ship_to_name						varchar(40)	NULL,
				ship_to_addr1						varchar(40)	NULL,
				ship_to_addr2						varchar(40)	NULL,
				ship_to_addr3						varchar(40)	NULL,
				ship_to_addr4						varchar(40)	NULL,
				ship_to_addr5						varchar(40)	NULL,
				ship_to_addr6						varchar(40)	NULL,
				ship_to_attention_name	varchar(40)	NULL,
				date_doc_dt 						datetime		NULL,
				date_maint_start_dt 		datetime 		NULL,
				date_maint_end_dt 			datetime		NULL,
				months_covered					int					NULL,
				amt_paid								float				NULL,
				sequence_id							int					NULL,
				print_copy							smallint		NULL,
				not_prev_printed 				smallint		NULL,
				mail_company_name				varchar(40)	NULL,
				mail_addr1							varchar(40)	NULL,
				mail_addr2							varchar(40)	NULL,
				mail_addr3							varchar(40)	NULL,
				mail_addr4							varchar(40)	NULL,
				bank_name								varchar(40)	NULL,
				bank_addr1							varchar(40)	NULL,
				bank_addr2							varchar(40)	NULL,
				bank_addr3							varchar(40)	NULL,
				bank_addr4							varchar(40)	NULL,
				account_no							varchar(40)	NULL,
				routing_no							varchar(40)	NULL,
				other_data							varchar(40)	NULL,
				source_trx_ctrl_num			varchar(16)	NULL,
				total_tax								float				NULL,
				svc_type_desc						varchar(40)	NULL,
				serial_no								varchar(40) NULL,
				source_ctrl_num					varchar(16) NULL,
				my_id										varchar(255) NULL )


	









	IF @posted_status = 0
		BEGIN
			SELECT @total_tax = ISNULL(SUM(amt_tax),0) 
			FROM artrx a, #possible_trxs p 
			WHERE a.trx_ctrl_num = p.trx_ctrl_num
	
			EXEC ( 'INSERT ' + @temp_table	+
					'(	trx_ctrl_num, 			doc_ctrl_num, 			doc_desc,
						date_doc,							amt_gross,		 			amt_tax,
					 	amt_net,							unit_price,			 		tax_desc,
						customer_code,				customer_name,			addr2,
						addr3,								addr4,			 				addr5,
						attention_name,				attention_phone,		tlx_twx,
						country,							item_code,					amt_paid,
						sequence_id,					print_copy,					source_trx_ctrl_num,
						my_id
				 )
					SELECT DISTINCT	
						h.trx_ctrl_num,		h.doc_ctrl_num,		h.doc_desc,		
					 	h.date_doc,			h.amt_gross,		 	h.amt_tax,
					 	h.amt_net,			d.unit_price,			t.tax_desc,
						c.customer_code,	c.customer_name, 		c.addr2,
				 		c.addr3,				c.addr4,			 		c.addr5,
				 		c.attention_name,	c.attention_phone,	c.tlx_twx,
					 	c.country,			d.item_code,			h.amt_paid_to_date,
						d.sequence_id,		1,							source_trx_ctrl_num, "' + @my_id + '" ' +
				'	FROM artrxcdt d, artrx h LEFT OUTER JOIN artax t ON (h.tax_code = t.tax_code) , arcust c, #possible_trxs p
					WHERE h.trx_ctrl_num = p.trx_ctrl_num
					AND h.trx_ctrl_num = d.trx_ctrl_num
					AND c.customer_code = h.customer_code ' )
		END	
	ELSE
		BEGIN
			SELECT @total_tax = ISNULL(SUM(amt_tax),0) 
			FROM arinpchg a, #possible_trxs p 
			WHERE a.trx_ctrl_num = p.trx_ctrl_num

			EXEC ( 'INSERT ' + @temp_table	+
					'(	trx_ctrl_num, 			doc_ctrl_num, 			doc_desc,
						date_doc,				amt_gross,		 		amt_tax,
					 	amt_net,					unit_price,			 	tax_desc,
						customer_code,			customer_name,			addr2,
						addr3,					addr4,			 		addr5,
						attention_name,		attention_phone,		tlx_twx,
						country,					item_code,				amt_paid,
						sequence_id,			print_copy,				source_trx_ctrl_num, my_id
					 )
				SELECT DISTINCT	
						h.trx_ctrl_num,		h.doc_ctrl_num,		h.doc_desc,		
					 	h.date_doc,			h.amt_gross,		 	h.amt_tax,
					 	h.amt_net,			d.unit_price,			t.tax_desc,
						c.customer_code,	c.customer_name, 		c.addr2,
				 		c.addr3,				c.addr4,			 		c.addr5,
				 		c.attention_name,	c.attention_phone,	c.tlx_twx,
					 	c.country,			d.item_code,			h.amt_paid,
						d.sequence_id,		1,							source_trx_ctrl_num, "' + @my_id + '" ' +
				'	FROM artrxcdt d, artrx h LEFT OUTER JOIN artax t ON (h.tax_code = t.tax_code) , arcust c, #possible_trxs p
				WHERE h.trx_ctrl_num = p.trx_ctrl_num
				AND h.trx_ctrl_num = d.trx_ctrl_num
				AND c.customer_code = h.customer_code ' )
		END

	EXEC ( 'UPDATE ' + @temp_table + 
			'	SET	date_maint_start			= r.date_maint_start,
						date_maint_end 			= r.date_maint_end, 
						srp_price 					= r.srp_price, 
						user_count 					= r.user_count, 
						svc_type_code 				= r.svc_type_code, 
						seller_code 				= r.seller_code, 
						pf_inv_ctrl_num			= r.pf_inv_ctrl_num,
						part_no 						= r.part_no,
						maint_part_no 				= r.maint_part_no,
						total_maint_charge		= r.total_maint_charge,
						billing_periods 			= r.billing_periods,
						billing_frequency 		= r.billing_frequency,
						billing_period_charge 	= r.billing_period_charge,
						nat_cur_code 				= r.nat_cur_code,
						ship_to_code 				= r.ship_to_code,
						serial_no						= r.serial_no,
						source_ctrl_num			= r.source_ctrl_num
				FROM ' +  @temp_table	+ ' a, rrmrinfo r
				WHERE a.trx_ctrl_num = r.pf_inv_ctrl_num
				AND ( a.item_code = r.part_no OR a.item_code = r.maint_part_no )
				AND a.sequence_id = r.inv_sequence_id ' )


	EXEC ( 'UPDATE ' + @temp_table	+
			 '	SET 	fixed_charge_type = r.fixed_charge_type,       
						fixed_charge_percent = r.fixed_charge_percent, 
						fixed_charge_amt = r.fixed_charge_amt,
						svc_type_desc = r.svc_type_desc
				FROM ' +  @temp_table + ' a, rrsvctyp r
				WHERE a.svc_type_code = r.svc_type_code ' )
















	EXEC ( ' UPDATE ' + @temp_table	+
			 '	SET description = substring(inv_master.description,1,250)
				FROM ' + @temp_table	+ ', inv_master
				WHERE ' + @temp_table + '.part_no = inv_master.part_no ' )



	EXEC ( ' UPDATE ' + @temp_table	+
			 '	SET 	arco_company_name = company_name,
				 		arco_addr1 = arco.addr1,
						arco_addr2 = arco.addr2,
						arco_addr3 = arco.addr3,
						arco_addr4 = arco.addr4,
						arco_addr5 = arco.addr5,
						arco_addr6 = arco.addr6
				FROM arco ' )

	EXEC ( ' UPDATE ' + @temp_table	+
			 '	SET	use_user_count = rrmap.user_count
				FROM 	rrmap
				WHERE ' + @temp_table	+ '.part_no = rrmap.part_no ' )

	EXEC ( 'UPDATE ' + @temp_table	 +
			 '	SET	curr_precision = glcurr_vw.curr_precision,
						symbol = glcurr_vw.symbol
				FROM 	glcurr_vw
				WHERE 	nat_cur_code = glcurr_vw.currency_code ' )







































































	EXEC ( 'UPDATE ' + @temp_table	+
			 '	SET	ship_to_name = arshipto.ship_to_name,
						ship_to_addr1 = arshipto.addr1,
						ship_to_addr2 = arshipto.addr2,
						ship_to_addr3 = arshipto.addr3,
						ship_to_addr4 = arshipto.addr4,
						ship_to_addr5 = arshipto.addr5,
						ship_to_addr6 = arshipto.addr6,
						ship_to_attention_name = arshipto.attention_name
				FROM 	arshipto 
				WHERE ' + @temp_table	+ '.ship_to_code = arshipto.ship_to_code
				AND	' + @temp_table	+ '.customer_code = arshipto.customer_code ' )

	EXEC ( 'UPDATE ' + @temp_table	+
			 '	SET	mail_company_name = r.company_name,
						mail_addr1 = r.mail_addr1,
						mail_addr2 = r.mail_addr2,
						mail_addr3 = r.mail_addr3,
						mail_addr4 = r.mail_addr4,
						bank_name = r.bank_name,
						bank_addr1 = r.bank_addr1,
						bank_addr2 = r.bank_addr2,
						bank_addr3 = r.bank_addr3,
						bank_addr4 = r.bank_addr4,
						account_no = r.account_no,
						routing_no = r.routing_no,
						other_data = r.other_data
				FROM	rrremit r ' )

	SELECT @total_tax_str = CONVERT(varchar(30), @total_tax )

	EXEC ( 'UPDATE ' + @temp_table	+
			 '	SET	total_tax = ' + @total_tax_str )
	


	SELECT 	@date_maint_start = MIN(date_maint_start), 
				@date_maint_end = MAX(date_maint_end)
	FROM 		rrmrinfo r, #possible_trxs p
	WHERE 	pf_inv_ctrl_num = p.trx_ctrl_num
			

	INSERT cc_rpt_pfinv ( trx_ctrl_num,
												doc_ctrl_num,
												doc_desc,
												date_doc,
												amt_gross,
												amt_tax,
												amt_net,
												unit_price,
												item_code,
												tax_desc,
												customer_code,
												customer_name,
												addr2,
												addr3,
												addr4,
												addr5,
												attention_name,
												attention_phone,
												tlx_twx,
												country,
												date_maint_start,
												date_maint_end,
												srp_price,
												user_count,
												svc_type_code,
												seller_code,
												pf_inv_ctrl_num,
												part_no,
												maint_part_no,
												total_maint_charge,
												billing_periods,
												billing_frequency,
												billing_period_charge,
												nat_cur_code,
												ship_to_code,
												fixed_charge_type,
												fixed_charge_percent,
												fixed_charge_amt,
												[description],
												arco_company_name,
												arco_addr1,
												arco_addr2,
												arco_addr3,
												arco_addr4,
												arco_addr5,
												arco_addr6,
												use_user_count,
												curr_precision,
												symbol,
												ship_to_name,
												ship_to_addr1,
												ship_to_addr2,
												ship_to_addr3,
												ship_to_addr4,
												ship_to_addr5,
												ship_to_addr6,
												ship_to_attention_name,
												date_doc_dt,
												date_maint_start_dt,
												date_maint_end_dt,
												months_covered,
												amt_paid,
												sequence_id,
												print_copy,
												not_prev_printed,
												mail_company_name,
												mail_addr1,
												mail_addr2,
												mail_addr3,
												mail_addr4,
												bank_name,
												bank_addr1,
												bank_addr2,
												bank_addr3,
												bank_addr4,
												account_no,
												routing_no,
												other_data,
												source_trx_ctrl_num,
												total_tax,
												svc_type_desc,
												serial_no,
												source_ctrl_num,
												my_id)
	SELECT								trx_ctrl_num,
												doc_ctrl_num,
												doc_desc,
												date_doc,
												amt_gross,
												amt_tax,
												amt_net,
												unit_price,
												item_code,
												tax_desc,
												customer_code,
												customer_name,
												addr2,
												addr3,
												addr4,
												addr5,
												attention_name,
												attention_phone,
												tlx_twx,
												country,
												date_maint_start,
												date_maint_end,
												srp_price,
												user_count,
												svc_type_code,
												seller_code,
												pf_inv_ctrl_num,
												part_no,
												maint_part_no,
												total_maint_charge,
												billing_periods,
												billing_frequency,
												billing_period_charge,
												nat_cur_code,
												ship_to_code,
												fixed_charge_type,
												fixed_charge_percent,
												fixed_charge_amt,
												[description],
												arco_company_name,
												arco_addr1,
												arco_addr2,
												arco_addr3,
												arco_addr4,
												arco_addr5,
												arco_addr6,
												use_user_count,
												curr_precision,
												symbol,
												ship_to_name,
												ship_to_addr1,
												ship_to_addr2,
												ship_to_addr3,
												ship_to_addr4,
												ship_to_addr5,
												ship_to_addr6,
												ship_to_attention_name,
												date_doc_dt,
												date_maint_start_dt,
												date_maint_end_dt,
												months_covered,
												amt_paid,
												sequence_id,
												print_copy,
												not_prev_printed,
												mail_company_name,
												mail_addr1,
												mail_addr2,
												mail_addr3,
												mail_addr4,
												bank_name,
												bank_addr1,
												bank_addr2,
												bank_addr3,
												bank_addr4,
												account_no,
												routing_no,
												other_data,
												source_trx_ctrl_num,
												total_tax,
												svc_type_desc,
												serial_no,
												source_ctrl_num,
												@my_id
 	FROM #ccmrinvrpt

	DROP TABLE #possible_trxs


--	IF EXISTS (SELECT name FROM sysobjects WHERE name = 'sm_logoff_sp' ) EXEC sm_logoff_sp 
	SET NOCOUNT OFF 

GO
GRANT EXECUTE ON  [dbo].[cc_armrinv_sp] TO [public]
GO
