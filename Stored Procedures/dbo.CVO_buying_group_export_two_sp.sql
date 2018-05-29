SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/**************************************************************************************

		    Created 2011 and Protected as Unpublished Work       
			  Under the U.S. Copyright Act of 1976            
		 Copyright (c) 2011 Epicor Software Corporation, 2011    
				  All Rights Reserved      
                  
CREATED BY: 			Bruce Bishop
CREATED ON:			20111129
PURPOSE:				Generate Buying Group Eport Files
LAST UPDATE:			20120207



EXEC CVO_buying_group_export_two_sp "invoice_date between '01/01/2018' and '06/28/2018'"


-- Rev 1 BNM 9/11/2012 updated to resolve issue 728, installment invoice details on export
-- v1.1	CT 20/10/2014 - Issue #1367 - For Sales Orders and Credit Returns, if net price > list price, set list = net and discount = 0
-- v1.2 CB 08/05/2018 - Changed to use new data extraction sp
**************************************************************************************/
CREATE PROCEDURE [dbo].[CVO_buying_group_export_two_sp] (@WHERECLAUSE VARCHAR(1024))
AS
	DECLARE @SQL		VARCHAR(1000),
			@FILENAME 	VARCHAR(200),
			@BCPCOMMAND VARCHAR(2000),
			@date_from	varchar(10),
			@date_to	varchar(10),
			@FILENAME_sub VARCHAR(100),
			@file_from	varchar(10),
			@file_to	varchar(10),
			@jul_from	int,
			@jul_to		int


	-- create temp tables
	create table #buy_h (
		ID              int identity(1,1),
		record_type		varchar(1),
		customer		varchar(8),
		account_num		varchar(10),
		invoice			varchar(12),
		order_num		varchar(8),
		po_num			varchar(8),
		invoice_date	varchar(8),
		ship_to_name	varchar(36),
		ship_to_address	varchar(36),
		ship_to_address2	varchar(36),
		ship_to_city	varchar(20),
		ship_to_state	varchar(2),
		ship_to_zip		varchar(10),
		ship_to_phone	varchar(15),
		ship_via_desc	varchar(20),
		terms_desc		varchar(20),
		sub_total		varchar(12),
		freight			varchar(12),
		tax				varchar(12),
		total			varchar(12))

	create table #buy_d (
		ID              int identity(1,1),
		record_type		varchar(1),
		account_num		varchar(10),
		invoice			varchar(12),
		line_num		varchar(3),
		item_no			varchar(16),
		item_desc1		varchar(36),
		item_desc2		varchar(36),
		item_desc3		varchar(36),
		qty_shipped		varchar(20),
		disc_unit		varchar(20),
		list_unit		varchar(20))

	create table #buy_out (
		ID              int identity(1,1),
		record_type		varchar(1),
		account_num		varchar(10),
		invoice			varchar(12),
		order_num		varchar(8),
		po_num			varchar(8),
		invoice_date	varchar(8),
		ship_to_name	varchar(36),
		ship_to_address	varchar(36),
		ship_to_address2	varchar(36),
		ship_to_city	varchar(20),
		ship_to_state	varchar(2),
		ship_to_zip		varchar(10),
		ship_to_phone	varchar(15),
		ship_via_desc	varchar(20),
		terms_desc		varchar(20),
		sub_total		varchar(12),
		freight			varchar(12),
		tax				varchar(12),
		total			varchar(12))

	CREATE TABLE #raw_bg_data (
		record_type			varchar(1),
		customer			varchar(8),
		account_num			varchar(10),
		invoice				varchar(12),
		order_num			varchar(8),
		po_num				varchar(8),
		invoice_date		varchar(8),
		ship_to_name		varchar(36),
		ship_to_address		varchar(36),
		ship_to_address2	varchar(36),
		ship_to_city		varchar(20),
		ship_to_state		varchar(2),
		ship_to_zip			varchar(10),
		ship_to_phone		varchar(15),
		ship_via_desc		varchar(20),
		terms_desc			varchar(20),
		sub_total			varchar(12),
		freight				varchar(12),
		tax					varchar(12),
		total				varchar(12),
		line_num			varchar(3),
		item_no				varchar(16),
		item_desc1			varchar(36),
		item_desc2			varchar(36),
		item_desc3			varchar(36),
		qty_shipped			varchar(20))		
		

	create index idx_customer on  #buy_out (account_num) with fillfactor = 80
	create index idx_invoice on  #buy_out (invoice) with fillfactor = 80

	create table #customer (
		ID              int identity(1,1),
		customer		varchar(10))

	create index idx_customer on  #customer (customer) with fillfactor = 80

	IF (CHARINDEX ('Between',@WHERECLAUSE) = 0 )
	BEGIN
		--TEMPORARY FOR NOW
	   SELECT	@date_from = convert(varchar(10), dateadd(m,-1, getdate()),101),  
				@date_to = convert(varchar(10), getdate(),101)  
	END	
	ELSE
	BEGIN
		SELECT 	@date_from = substring(@WHERECLAUSE,charindex('BETWEEN ',@WHERECLAUSE)+9,10),	--charindex('AND',@WHERECLAUSE)-1),
				@date_to = substring(@WHERECLAUSE,charindex('AND ',@WHERECLAUSE)+5,10)					--, charindex('ORDER BY',@WHERECLAUSE)-1)
	END	

	set @jul_from = datediff(dd, '1/1/1753', @date_from) + 639906	
	set @jul_to = datediff(dd, '1/1/1753', @date_to) + 639906	
		
	set @file_from = replace (convert(varchar(12), dateadd(dd, @jul_from - 639906, '1/1/1753'),102),'.','')		
	set @file_to = replace (convert(varchar(12), dateadd(dd, @jul_to - 639906, '1/1/1753'),102),'.','')	

	--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	Declare	@sequence_num			smallint,
			@fin_sequence_id		int, 
			@fin_max_sequence_id	int,
			@customer				varchar(10),
			@child					varchar(12),
			@invoice				varchar(12),
			@type					varchar(1),
			@pcount					int,
			@mer_disc				varchar(12),
			@max_count				int,
			@inv_sequence_id		int, 
			@inv_max_sequence_id	int,
			@ship_to_address2		varchar(36),
			@ship_to_city			varchar(20),
			@ship_to_state			varchar(2),
			@ship_to_zip			varchar(10)

	INSERT	#raw_bg_data
	EXEC dbo.cvo_bg_data_extract_sp @WHERECLAUSE


	-- 1 --	HEADER RECORD
	-- 09/11/2012 BNM - resolve issue 728, extract non-installment headers first
	-- v1.2 Start
	INSERT	#buy_h
	SELECT	record_type, customer, account_num,	invoice, order_num, po_num, invoice_date, ship_to_name, ship_to_address,
			ship_to_address2, ship_to_city, ship_to_state, ship_to_zip, ship_to_phone, ship_via_desc, terms_desc,
			sub_total, freight, tax, total
	FROM	#raw_bg_data
	WHERE	record_type = 'H'

	create index idx_customer on  #buy_h (account_num) with fillfactor = 80
	create index idx_invoice on  #buy_h (invoice) with fillfactor = 80

	update	#buy_h
	set		ship_to_name = left(m.address_name,36),
			ship_to_address = left(m.addr1,36),
			ship_to_address2 = left(m.addr2,36),
			ship_to_city = left(m.city,20),
			ship_to_state = left(m.state,2),
			ship_to_zip = left(replace(m.postal_code, '-', ''),10),
			ship_to_phone = left(m.contact_phone,15),
			terms_desc = left(t.terms_desc,20)
	from	armaster_all m (nolock)
	join	artrx_all h (nolock) on m.customer_code = h.customer_code and m.ship_to_code = h.ship_to_code
	join	arterms t(nolock) on h.terms_code = t.terms_code
	where	invoice = h.doc_ctrl_num
	and		ship_to_address = ''

	-- 2a -- DETAIL RECORD FROM ORDERS	-- 09/11/2012 BNM - resolve issue 728, load non-installment invoice detail first
	INSERT	#buy_d
	SELECT	record_type, account_num, invoice, line_num, item_no, item_desc1, item_desc2, item_desc3, 
			qty_shipped, sub_total, total
	FROM	#raw_bg_data
	WHERE	record_type = 'D'


	create index idx_customer on  #buy_d (account_num) with fillfactor = 80
	create index idx_invoice on  #buy_d (invoice) with fillfactor = 80

	update	#buy_h 
	set		ship_to_address2 = '                                     '
	where	left(ship_to_address2, charindex(',',ship_to_address2)-1) = ship_to_city
	and		substring(ship_to_address2, charindex(',',ship_to_address2)+2,2) = ship_to_state
	and		replace(right(ship_to_address2, len(ltrim(rtrim(ship_to_address2))) -( charindex(',',ship_to_address2)+ 4)),'-','') = ship_to_zip
	and		charindex(',',ship_to_address2) > 0

	update	#buy_h
	set		customer =  left(customer + '        ',8),
			account_num	=  left(account_num + '          ',10),
			invoice	=  left(invoice + '             ',12),
			order_num = left(order_num +'        ',8), -- varchar(8),
			po_num = left(po_num +'        ',8), -- varchar(8),
			ship_to_name = left(ship_to_name +'                                     ',36), --	varchar(36),
			ship_to_address = left( ship_to_address +'                                     ',36),	--varchar(36),
			ship_to_address2 = left( ship_to_address2 +'                                     ',36),	--varchar(36),
			ship_to_city = left(ship_to_city +'                                     ',20),	--	varchar(20),
			ship_to_state = left(ship_to_state+'  ',2), -- 	varchar(2),
			ship_to_zip= left(ship_to_zip+'           ',10), --		varchar(10),
			ship_to_phone = left(ship_to_phone+'                 ',15), --	varchar(15),
			ship_via_desc = left(ship_via_desc+'                     ',20), --	varchar(20),
			terms_desc = left(terms_desc+'                      ',20), --		varchar(20),
			sub_total = right('             '+sub_total,10), --	varchar(12),
			freight = right('              '+freight,10), --			varchar(12),
			tax = right('             '+tax,10), --				varchar(12),
			total = right('             '+total,10) --			varchar(12)

	update	#buy_d
	set		account_num	=  left(account_num + '          ',10),
			invoice	= left(invoice+'            ',12), --		varchar(12),
			line_num = right('000'+ line_num, 3),--		varchar(3),
			item_no	= left(item_no+'                  ',16), --		varchar(16),
			item_desc1 = left(item_desc1+'                                        ',36), -- 		varchar(36),
			item_desc2 = left(item_desc2+'                                        ',36), -- 		varchar(36),
			item_desc3 = left(item_desc3+'                                        ',36), -- 		varchar(36),
			qty_shipped = right('0000000000'+qty_shipped,6),--	varchar(10),
			disc_unit = right('          '+ disc_unit,10), -- varchar(10),
			list_unit = right('          '+	list_unit,10) -- varchar(10)

	--=======================================================================================
	CREATE TABLE ##EXP2_TEMP (
		ID INT,
		LINE VARCHAR(350))

	-- select trans for export
	select @pcount = 0
	select @pcount = count(ID) from #buy_h (nolock)
	--=======================================================================================================
	-- there are records to export

	if @pcount > 0 
	begin -- records to export 
		-- #customer
		insert into #customer
		select distinct customer from #buy_h (nolock)

        select	@fin_sequence_id = '', 
				@fin_max_sequence_id = '',
				@customer = ''

        select @fin_sequence_id = min(ID), @fin_max_sequence_id = max(ID) 
        from #customer (nolock)
            
       set @pcount = 0
		--================================================================       
       WHILE (@fin_sequence_id <= @fin_max_sequence_id )  
       Begin -- buyer group loop
			truncate table #buy_out
			
			-- per buyer group
			select @customer = customer 
			from #customer (nolock)
			where ID = @fin_sequence_id
			
			truncate table #buy_out

			Insert into #buy_out
			select   
			record_type,
			account_num,
			invoice,
			order_num,
			po_num,
			invoice_date,
			ship_to_name,
			ship_to_address,
			ship_to_address2,
			ship_to_city,
			ship_to_state,
			ship_to_zip,
			ship_to_phone,
			ship_via_desc,
			terms_desc,
			sub_total,
			freight,
			tax,
			total
			from #buy_h (nolock)
			where #buy_h.customer = @customer
			order by invoice

			-- clear output file
			truncate table ##EXP2_TEMP
			
			-- per invoice loop
			select @inv_sequence_id = '',
			@inv_max_sequence_id = ''



			select @inv_sequence_id = min(ID), @inv_max_sequence_id = max(ID) 
			from #buy_out (nolock)
			--================================================================
			-- gather invoices

		    WHILE (@inv_sequence_id <= @inv_max_sequence_id)  
			Begin -- per invoice loop
				select @invoice = ''
				
				select @invoice = invoice 
				from #buy_out (nolock)
				where ID = @inv_sequence_id	
			
				-- EXPORT DATA FILE
				-- header
				INSERT INTO ##EXP2_TEMP (LINE)
				select	record_type +
						account_num +
						invoice +
						order_num +
						po_num +
						invoice_date +
						ship_to_name + 
						ship_to_address +
						ship_to_address2 +
						ship_to_city +
						ship_to_state +
						ship_to_zip +
						ship_to_phone +
						ship_via_desc +
						terms_desc +
						sub_total +
						freight +
						tax +
						total			
				from	#buy_out 
				where	ID = @inv_sequence_id	

				-- detail
				INSERT INTO ##EXP2_TEMP (LINE)
				select	record_type +
						account_num +
						invoice +
						line_num +
						item_no +
						item_desc1 +
						item_desc2 +
						item_desc3 +
						qty_shipped +
						disc_unit +
						list_unit
				from	#buy_d (nolock)
				where	invoice = @invoice
				order by line_num
		
				select @inv_sequence_id = @inv_sequence_id + 1
		
			end -- per invoice loop

			SET NOCOUNT ON
			set @FILENAME_sub = ltrim(rtrim(@customer)) + '_' + @file_from + '_' + @file_to + '_detail.txt'

			SET @FILENAME = '\\cvo-fs-01\Public_Data\Accounts Receivable\Buying Groups\Epicor_BGData\' + @FILENAME_sub
--			SET @FILENAME = 'C:\Epicor_BGData\Detail\' + @FILENAME_sub
			SET @BCPCOMMAND = 'BCP "SELECT LINE FROM CVO..##EXP2_TEMP" QUERYOUT "'
			SET @BCPCOMMAND = @BCPCOMMAND + @FILENAME + '" -T   -c'
			EXEC MASTER..XP_CMDSHELL @BCPCOMMAND

			set @fin_sequence_id = @fin_sequence_id + 1

		end -- buyer group loop

		--=======================================================================================================

	end -- records to export 

	--=======================================================================================================

drop table ##EXP2_TEMP
drop table #buy_h
drop table #buy_d
drop table #buy_out
drop table #customer

GO
GRANT EXECUTE ON  [dbo].[CVO_buying_group_export_two_sp] TO [public]
GO
