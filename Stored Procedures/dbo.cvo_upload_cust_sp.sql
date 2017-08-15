SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[cvo_upload_cust_sp] 
AS
BEGIN
	-- DIRECTIVES
	SET NOCOUNT ON

	-- DECLARTIONS
	DECLARE	@msg				varchar(255),
			@customer_code		varchar(8),
			@ship_to_code		varchar(8),
			@cust_name			varchar(40),
			@addr1				varchar(40),
			@addr2				varchar(40),
			@addr3				varchar(40),
			@addr4				varchar(40),
			@city				varchar(40),
			@state				varchar(40),
			@postal_code		varchar(15),
			@country			varchar(3),
			@customer_type		varchar(40),
			@POP_POB			varchar(40),
			@attention_name		varchar(40),
			@attention_phone	varchar(30),
			@attention_email	varchar(255),
			@contact_name		varchar(40),
			@contact_phone		varchar(30),
			@contact_email		varchar(255),
			@fax_number			varchar(30),
			@tax_code			varchar(8),
			@terms_code			varchar(8),
			@fob_code			varchar(8),
			@territory_code		varchar(8),
			@fin_chg_code		varchar(8),
			@price_code			varchar(8),
			@payment_code		varchar(8),
			@statement_flag		varchar(5),
			@statement_cycle	varchar(8),
			@credit_limit		varchar(20),
			@aging_limit		varchar(20),
			@aging_check		varchar(20),
			@aging_allowance	varchar(20),
			@ship_complete		varchar(5),
			@BO_RX_sc_flag		varchar(5),
			@BO_non_RX_sc_flag	varchar(5),
			@currency_code		varchar(8),
			@carrier			varchar(8),
			@rx_carrier			varchar(8),
			@bo_carrier			varchar(8),
			@add_cases			varchar(5),
			@add_pattern		varchar(5),
			@patterns_first		varchar(5),
			@cons_shipments		varchar(5),
			@rx_consolidated	varchar(5),
			@allow_subs			varchar(5),
			@commission			varchar(5),
			@comm_perc			varchar(10),
			@door				varchar(5),
			@residential		varchar(5),
			@user_category		varchar(10),
			@credit_for_rets	varchar(5),
			@freight_chg_flag	varchar(5),
			@chargebacks		varchar(5),
			@print_cm			varchar(5),
			@co_op_eligible		varchar(5),
			@co_op_thres_flag	varchar(5),
			@co_op_thres_amt	varchar(20),
			@co_op_rate			varchar(20),
			@co_op_notes		varchar(255),
			@metal_plastic		varchar(5),
			@suns_optical		varchar(5),
			@max_dollars		varchar(20),
			@url				varchar(255),			
			@row_id				int,
			@last_file			varchar(100),
			@str_msg			varchar(255),
			@masked				varchar(16), 
			@num				int 

	-- WORKING TABLE
	CREATE TABLE #import_messages (
		row_id		int,
		message_str varchar(255))					

	-- PROCESSING
	IF NOT EXISTS (SELECT 1 FROM dbo.cvo_cust_import)
	BEGIN
		SET @msg = 'Nothing to import'
		GOTO FINISH
	END

	SET @row_id = 0
	
	WHILE (1 = 1)
	BEGIN

		SELECT	TOP 1 @row_id = row_id,
				@customer_code = customer_code,
				@ship_to_code = ship_to_code,
				@cust_name = cust_name,
				@addr1 = addr1,
				@addr2 = addr2,
				@addr3 = addr3,
				@addr4 = addr4,
				@city = city,
				@state = state,
				@postal_code = postal_code,
				@country = country,
				@customer_type = customer_type,
				@POP_POB = POP_POB,
				@attention_name = attention_name,
				@attention_phone = attention_phone,
				@attention_email = attention_email,
				@contact_name = contact_name,
				@contact_phone = contact_phone,
				@contact_email = contact_email,
				@fax_number = fax_number,
				@tax_code = tax_code,
				@terms_code = terms_code,
				@fob_code = fob_code,
				@territory_code = territory_code,
				@fin_chg_code = fin_chg_code,
				@price_code = price_code,
				@payment_code = payment_code,
				@statement_flag = statement_flag,
				@statement_cycle = statement_cycle,
				@credit_limit = credit_limit,
				@aging_limit = aging_limit,
				@aging_check = aging_check,
				@aging_allowance = aging_allowance,
				@ship_complete = ship_complete,
				@BO_RX_sc_flag = BO_RX_sc_flag,
				@BO_non_RX_sc_flag = BO_non_RX_sc_flag,
				@currency_code = currency_code,
				@carrier = carrier,
				@rx_carrier = rx_carrier,
				@bo_carrier = bo_carrier,
				@add_cases = add_cases,
				@add_pattern = add_pattern,
				@patterns_first = patterns_first,
				@cons_shipments = cons_shipments,
				@rx_consolidated = rx_consolidated,
				@allow_subs = allow_subs,
				@commission = commission,
				@comm_perc = comm_perc,
				@door = door,
				@residential = residential,
				@user_category = user_category,
				@credit_for_rets = credit_for_rets,
				@freight_chg_flag = freight_chg_flag,
				@chargebacks = chargebacks,
				@print_cm = print_cm,
				@co_op_eligible = co_op_eligible,
				@co_op_thres_flag = co_op_thres_flag,
				@co_op_thres_amt = co_op_thres_amt,
				@co_op_rate = co_op_rate,
				@co_op_notes = co_op_notes,
				@metal_plastic = metal_plastic,
				@suns_optical = suns_optical,
				@max_dollars = max_dollars,
				@url = url
		FROM	dbo.cvo_cust_import
		WHERE	row_id > @row_id
		AND		process = 0
		ORDER BY row_id ASC

		IF (@@ROWCOUNT = 0)
			BREAK

--		IF (@customer_code = '')
--		BEGIN
--			SET @msg = 'Line: ' + CAST(@row_id as varchar(10)) + ' - Customer code must be specified.'
--			INSERT	#import_messages			
--			SELECT	@row_id, @msg

--			CONTINUE
--		END

		IF (@ship_to_code = '')
		BEGIN
			IF EXISTS (SELECT 1 FROM arcust (NOLOCK) WHERE customer_code = @customer_code)
			BEGIN
				SET @msg = 'Line: ' + CAST(@row_id as varchar(10)) + ' - Customer code already exists.'
				INSERT	#import_messages			
				SELECT	@row_id, @msg

				CONTINUE
			END
		END

		IF (@ship_to_code <> '')
		BEGIN
			IF NOT EXISTS (SELECT 1 FROM arcust (NOLOCK) WHERE customer_code = @customer_code)
			BEGIN
				SET @msg = 'Line: ' + CAST(@row_id as varchar(10)) + ' - Customer code does not exists.'
				INSERT	#import_messages			
				SELECT	@row_id, @msg

				CONTINUE
			END

			IF EXISTS (SELECT 1 FROM armaster_all (NOLOCK) WHERE customer_code = @customer_code AND ship_to_code = @ship_to_code
						AND address_type = 1)
			BEGIN
				SET @msg = 'Line: ' + CAST(@row_id as varchar(10)) + ' - Ship to already exists for customer code ' + @customer_code + '.'
				INSERT	#import_messages			
				SELECT	@row_id, @msg

				CONTINUE
			END
		END

		IF (@cust_name = '')
		BEGIN
			SET @msg = 'Line: ' + CAST(@row_id as varchar(10)) + ' - Customer name must be specified.'
			INSERT	#import_messages			
			SELECT	@row_id, @msg

			CONTINUE
		END

		IF (@addr1 = '')
		BEGIN
			SET @msg = 'Line: ' + CAST(@row_id as varchar(10)) + ' - Address line 1 must be specified.'
			INSERT	#import_messages			
			SELECT	@row_id, @msg

			CONTINUE
		END

		IF (@addr2 = '')
		BEGIN
			SET @msg = 'Line: ' + CAST(@row_id as varchar(10)) + ' - Address line 2 must be specified.'
			INSERT	#import_messages			
			SELECT	@row_id, @msg

			CONTINUE
		END

		IF (@addr3 = '')
		BEGIN
			SET @msg = 'Line: ' + CAST(@row_id as varchar(10)) + ' - Address line 3 must be specified.'
			INSERT	#import_messages			
			SELECT	@row_id, @msg

			CONTINUE
		END

		IF (@city = '')
		BEGIN
			SET @msg = 'Line: ' + CAST(@row_id as varchar(10)) + ' - City must be specified.'
			INSERT	#import_messages			
			SELECT	@row_id, @msg

			CONTINUE
		END

		IF (@state = '')
		BEGIN
			SET @msg = 'Line: ' + CAST(@row_id as varchar(10)) + ' - State must be specified.'
			INSERT	#import_messages			
			SELECT	@row_id, @msg

			CONTINUE
		END

		IF (@postal_code = '')
		BEGIN
			SET @msg = 'Line: ' + CAST(@row_id as varchar(10)) + ' - Postal Code must be specified.'
			INSERT	#import_messages			
			SELECT	@row_id, @msg

			CONTINUE
		END

		IF (@country = '')
		BEGIN
			SET @msg = 'Line: ' + CAST(@row_id as varchar(10)) + '- Country must be specified.'
			INSERT	#import_messages			
			SELECT	@row_id, @msg

			CONTINUE
		END
		ELSE
		BEGIN
			IF NOT EXISTS (SELECT 1 FROM gl_country (NOLOCK) WHERE country_code = @country)
			BEGIN
				SET @msg = 'Line: ' + CAST(@row_id as varchar(10)) + '- Country code is invalid.'
				INSERT	#import_messages			
				SELECT	@row_id, @msg

				CONTINUE
			END
		END

		IF (@customer_type = '')
		BEGIN
			SET @msg = 'Line: ' + CAST(@row_id as varchar(10)) + ' - Customer Type must be specified.'
			INSERT	#import_messages			
			SELECT	@row_id, @msg

			CONTINUE
		END
		ELSE
		BEGIN
			IF NOT EXISTS (SELECT 1 FROM cvo_customer_types_vw (NOLOCK) WHERE addr_sort1 = @customer_type)
			BEGIN
				SET @msg = 'Line: ' + CAST(@row_id as varchar(10)) + ' - Invalid Customer Type.'
				INSERT	#import_messages			
				SELECT	@row_id, @msg

				CONTINUE
			END
		END

		IF NOT (@POP_POB = 'POP' OR @POP_POB = 'POB')
		BEGIN
			SET @msg = 'Line: ' + CAST(@row_id as varchar(10)) + ' - Invalid POP/POB.'
			INSERT	#import_messages			
			SELECT	@row_id, @msg

			CONTINUE
		END

		IF (@attention_phone = '')
		BEGIN
			SET @msg = 'Line: ' + CAST(@row_id as varchar(10)) + '- Attention phone number must be specified.'
			INSERT	#import_messages			
			SELECT	@row_id, @msg

			CONTINUE
		END

		IF (@attention_email = '')
		BEGIN
			SET @msg = 'Line: ' + CAST(@row_id as varchar(10)) + '- Attention email must be specified.'
			INSERT	#import_messages			
			SELECT	@row_id, @msg

			CONTINUE
		END

		IF (@contact_name = '')
		BEGIN
			SET @msg = 'Line: ' + CAST(@row_id as varchar(10)) + ' - Contact name must be specified.'
			INSERT	#import_messages			
			SELECT	@row_id, @msg

			CONTINUE
		END

		IF (@contact_phone = '')
		BEGIN
			SET @msg = 'Line: ' + CAST(@row_id as varchar(10)) + '- Contact phone number must be specified.'
			INSERT	#import_messages			
			SELECT	@row_id, @msg

			CONTINUE
		END

		-- v1.1 Start
--		IF (@contact_email = '')
--		BEGIN
--			SET @msg = 'Line: ' + CAST(@row_id as varchar(10)) + ' - Contact email must be specified.'
--			INSERT	#import_messages			
--			SELECT	@row_id, @msg
--
--			CONTINUE
--		END
		-- v1.1 End

		IF (@tax_code = '')
		BEGIN
			SET @msg = 'Line: ' + CAST(@row_id as varchar(10)) + '- Tax code must be specified.'
			INSERT	#import_messages			
			SELECT	@row_id, @msg

			CONTINUE
		END
		ELSE
		BEGIN
			IF NOT EXISTS (SELECT 1 FROM artax_vw (NOLOCK) WHERE tax_code = @tax_code AND module_flag IN (0,2))
			BEGIN
				SET @msg = 'Line: ' + CAST(@row_id as varchar(10)) + ' - Invalid Tax code.'
				INSERT	#import_messages			
				SELECT	@row_id, @msg

				CONTINUE
			END
		END

		IF (@terms_code = '')
		BEGIN
			SET @msg = 'Line: ' + CAST(@row_id as varchar(10)) + ' - Terms code must be specified.'
			INSERT	#import_messages			
			SELECT	@row_id, @msg

			CONTINUE
		END
		ELSE
		BEGIN
			IF NOT EXISTS (SELECT 1 FROM arterms (NOLOCK) WHERE terms_code = @terms_code)
			BEGIN
				SET @msg = 'Line: ' + CAST(@row_id as varchar(10)) + ' - Invalid Terms code.'
				INSERT	#import_messages			
				SELECT	@row_id, @msg

				CONTINUE
			END
		END

		IF (@fob_code = '')
		BEGIN
			SET @msg = 'Line: ' + CAST(@row_id as varchar(10)) + '- FOB code must be specified.'
			INSERT	#import_messages			
			SELECT	@row_id, @msg

			CONTINUE
		END
		ELSE
		BEGIN
			IF NOT EXISTS (SELECT 1 FROM arfob (NOLOCK) WHERE fob_code = @fob_code)
			BEGIN
				SET @msg = 'Line: ' + CAST(@row_id as varchar(10)) + ' - Invalid FOB code.'
				INSERT	#import_messages			
				SELECT	@row_id, @msg

				CONTINUE
			END
		END

		IF (@territory_code = '')
		BEGIN
			SET @msg = 'Line: ' + CAST(@row_id as varchar(10)) + ' - Territory code must be specified.'
			INSERT	#import_messages			
			SELECT	@row_id, @msg

			CONTINUE
		END
		ELSE
		BEGIN
			IF NOT EXISTS (SELECT 1 FROM arterr (NOLOCK) WHERE territory_code = @territory_code)
			BEGIN
				SET @msg = 'Line: ' + CAST(@row_id as varchar(10)) + ' - Invalid Territory code.'
				INSERT	#import_messages			
				SELECT	@row_id, @msg

				CONTINUE
			END
		END

		IF (@fin_chg_code = '')
		BEGIN
			SET @msg = 'Line: ' + CAST(@row_id as varchar(10)) + ' - Finance charge code must be specified.'
			INSERT	#import_messages			
			SELECT	@row_id, @msg

			CONTINUE
		END
		ELSE
		BEGIN
			IF NOT EXISTS (SELECT 1 FROM arfinchg (NOLOCK) WHERE fin_chg_code = @fin_chg_code)
			BEGIN
				SET @msg = 'Line: ' + CAST(@row_id as varchar(10)) + ' - Invalid Finance charge code.'
				INSERT	#import_messages			
				SELECT	@row_id, @msg

				CONTINUE
			END
		END
				
		IF (@price_code = '')
		BEGIN
			SET @msg = 'Line: ' + CAST(@row_id as varchar(10)) + '- Price code must be specified.'
			INSERT	#import_messages			
			SELECT	@row_id, @msg

			CONTINUE
		END
		ELSE
		BEGIN
			IF NOT EXISTS (SELECT 1 FROM arprice (NOLOCK) WHERE price_code = @price_code)
			BEGIN
				SET @msg = 'Line: ' + CAST(@row_id as varchar(10)) + ' - Invalid price code.'
				INSERT	#import_messages			
				SELECT	@row_id, @msg

				CONTINUE
			END
		END

		IF (@payment_code = '')
		BEGIN
			SET @msg = 'Line: ' + CAST(@row_id as varchar(10)) + ' - Payment code must be specified.'
			INSERT	#import_messages			
			SELECT	@row_id, @msg

			CONTINUE
		END
		ELSE
		BEGIN
			IF NOT EXISTS (SELECT 1 FROM arpymeth (NOLOCK) WHERE payment_code = @payment_code)
			BEGIN
				SET @msg = 'Line: ' + CAST(@row_id as varchar(10)) + ' - Invalid Payment code.'
				INSERT	#import_messages			
				SELECT	@row_id, @msg

				CONTINUE
			END
		END

		IF (@statement_flag = '')
		BEGIN
			SET @statement_flag = '1'
		END
		ELSE
		BEGIN
			IF (UPPER(@statement_flag) IN ('1','Y'))
				SET @statement_flag = '1'
			ELSE IF (UPPER(@statement_flag) IN ('0','N'))
				SET @statement_flag = '0'
			ELSE
			BEGIN
				SET @msg = 'Line: ' + CAST(@row_id as varchar(10)) + ' - Print statement flag - invalid data.'
				INSERT	#import_messages			
				SELECT	@row_id, @msg

				CONTINUE
			END
		END

		UPDATE	dbo.cvo_cust_import
		SET		statement_flag = @statement_flag
		WHERE	row_id = @row_id	

		IF (@statement_cycle = '')
		BEGIN
			SET @statement_cycle = 'STMT25'
		END
		ELSE
		BEGIN
			IF NOT EXISTS (SELECT 1 FROM arcycle (NOLOCK) WHERE cycle_code = @statement_cycle AND use_type = 2)
			BEGIN
				SET @msg = 'Line: ' + CAST(@row_id as varchar(10)) + ' - Invalid statement cycle.'
				INSERT	#import_messages			
				SELECT	@row_id, @msg

				CONTINUE
			END
		END

		UPDATE	dbo.cvo_cust_import
		SET		statement_cycle = @statement_cycle
		WHERE	row_id = @row_id	

		IF (@credit_limit = '')
		BEGIN
			SET @credit_limit = '0'
		END

		UPDATE	dbo.cvo_cust_import
		SET		credit_limit = @credit_limit
		WHERE	row_id = @row_id	

		IF (@aging_limit = '')
		BEGIN
			SET @aging_limit = '30'
		END

		SELECT @aging_limit	= CASE @aging_limit WHEN '30' THEN '1' WHEN '60' THEN '2' WHEN '90' THEN '3'
						WHEN '120' THEN '4' WHEN '150' THEN '5' ELSE '1' END

		UPDATE	dbo.cvo_cust_import
		SET		aging_limit = @aging_limit
		WHERE	row_id = @row_id	

		IF (@aging_check = '')
		BEGIN
			SET @aging_check = '30'
		END

		SELECT @aging_check	= CASE @aging_check WHEN '30' THEN '1' WHEN '60' THEN '2' WHEN '90' THEN '3'
						WHEN '120' THEN '4' WHEN '150' THEN '5' ELSE '1' END

		UPDATE	dbo.cvo_cust_import
		SET		aging_check = @aging_check
		WHERE	row_id = @row_id	
		
		IF (@aging_allowance = '')
			SET @aging_allowance = '0'

		UPDATE	dbo.cvo_cust_import
		SET		aging_allowance = @aging_allowance
		WHERE	row_id = @row_id	

		IF (@ship_complete = '') 
		BEGIN
			SET @ship_complete = '0'
		END
		ELSE
		BEGIN
			IF (@ship_complete NOT IN ('0','1','2'))
				SET @ship_complete = '0'
		END
		
		UPDATE	dbo.cvo_cust_import
		SET		ship_complete = @ship_complete
		WHERE	row_id = @row_id

		IF (@BO_RX_sc_flag = '') 
		BEGIN
			SET @BO_RX_sc_flag = '0'
		END
		ELSE
		BEGIN
			IF (@BO_RX_sc_flag NOT IN ('0','1','2'))
				SET @BO_RX_sc_flag = '0'
		END

		UPDATE	dbo.cvo_cust_import
		SET		BO_RX_sc_flag = @BO_RX_sc_flag
		WHERE	row_id = @row_id

		IF (@BO_non_RX_sc_flag = '') 
		BEGIN
			SET @BO_non_RX_sc_flag = '0'
		END
		ELSE
		BEGIN
			IF (@BO_non_RX_sc_flag NOT IN ('0','1','2'))
				SET @BO_non_RX_sc_flag = '0'
		END

		UPDATE	dbo.cvo_cust_import
		SET		BO_non_RX_sc_flag = @BO_non_RX_sc_flag
		WHERE	row_id = @row_id

		IF (@currency_code = '')
		BEGIN
			SET @currency_code = 'USD'
		END
		ELSE
		BEGIN
			IF NOT EXISTS (SELECT 1 FROM mccu1_vw (NOLOCK) WHERE currency_code = @currency_code)
			BEGIN
				SET @msg = 'Line: ' + CAST(@row_id as varchar(10)) + ' - Invalid currency code.'
				INSERT	#import_messages			
				SELECT	@row_id, @msg

				CONTINUE
			END
		END

		UPDATE	dbo.cvo_cust_import
		SET		currency_code = @currency_code
		WHERE	row_id = @row_id

		IF (@carrier = '')
		BEGIN
			SET @msg = 'Line: ' + CAST(@row_id as varchar(10)) + '- Carrier must be specified.'
			INSERT	#import_messages			
			SELECT	@row_id, @msg

			CONTINUE
		END
		ELSE
		BEGIN
			IF NOT EXISTS (SELECT 1 FROM arshipv (NOLOCK) WHERE ship_via_code = @carrier)
			BEGIN
				SET @msg = 'Line: ' + CAST(@row_id as varchar(10)) + ' - Invalid carrier.'
				INSERT	#import_messages			
				SELECT	@row_id, @msg

				CONTINUE
			END
		END

		UPDATE	dbo.cvo_cust_import
		SET		carrier = @carrier
		WHERE	row_id = @row_id

		IF (@rx_carrier = '')
		BEGIN
			SET @rx_carrier = @carrier
		END
		ELSE
		BEGIN
			IF NOT EXISTS (SELECT 1 FROM arshipv (NOLOCK) WHERE ship_via_code = @rx_carrier)
			BEGIN
				SET @msg = 'Line: ' + CAST(@row_id as varchar(10)) + ' - Invalid RX carrier.'
				INSERT	#import_messages			
				SELECT	@row_id, @msg

				CONTINUE
			END
		END

		UPDATE	dbo.cvo_cust_import
		SET		rx_carrier = @rx_carrier
		WHERE	row_id = @row_id

		IF (@bo_carrier = '')
		BEGIN
			SET @bo_carrier = @carrier
		END
		ELSE
		BEGIN
			IF NOT EXISTS (SELECT 1 FROM arshipv (NOLOCK) WHERE ship_via_code = @bo_carrier)
			BEGIN
				SET @msg = 'Line: ' + CAST(@row_id as varchar(10)) + ' - Invalid BO carrier.'
				INSERT	#import_messages			
				SELECT	@row_id, @msg

				CONTINUE
			END
		END

		UPDATE	dbo.cvo_cust_import
		SET		bo_carrier = @bo_carrier
		WHERE	row_id = @row_id

		IF (@add_cases = '')
		BEGIN
			SET @add_cases = 'Y'
		END
		ELSE
		BEGIN
			IF (UPPER(@add_cases) IN ('1','Y'))
				SET @add_cases = 'Y'
			ELSE IF (UPPER(@add_cases) IN ('0','N'))
				SET @statement_flag = 'N'
			ELSE
			BEGIN
				SET @msg = 'Line: ' + CAST(@row_id as varchar(10)) + ' - Add Cases flag - invalid data.'
				INSERT	#import_messages			
				SELECT	@row_id, @msg

				CONTINUE
			END
		END

		UPDATE	dbo.cvo_cust_import
		SET		add_cases = @add_cases
		WHERE	row_id = @row_id

		IF (@add_pattern = '')
		BEGIN
			SET @add_pattern = 'N'
		END
		ELSE
		BEGIN
			IF (UPPER(@add_pattern) IN ('1','Y'))
				SET @add_pattern = 'Y'
			ELSE IF (UPPER(@add_pattern) IN ('0','N'))
				SET @add_pattern = 'N'
			ELSE
			BEGIN
				SET @msg = 'Line: ' + CAST(@row_id as varchar(10)) + ' - Add Patterns flag - invalid data.'
				INSERT	#import_messages			
				SELECT	@row_id, @msg

				CONTINUE
			END
		END

		UPDATE	dbo.cvo_cust_import
		SET		add_pattern = @add_pattern
		WHERE	row_id = @row_id

		IF (@patterns_first = '')
		BEGIN
			SET @patterns_first = '0'
		END
		ELSE
		BEGIN
			IF (UPPER(@patterns_first) IN ('1','Y'))
				SET @patterns_first = '1'
			ELSE IF (UPPER(@patterns_first) IN ('0','N'))
				SET @patterns_first = '0'
			ELSE
			BEGIN
				SET @msg = 'Line: ' + CAST(@row_id as varchar(10)) + ' - Add Patterns First flag - invalid data.'
				INSERT	#import_messages			
				SELECT	@row_id, @msg

				CONTINUE
			END
		END

		UPDATE	dbo.cvo_cust_import
		SET		patterns_first = @patterns_first
		WHERE	row_id = @row_id

		IF (@cons_shipments = '')
		BEGIN
			SET @cons_shipments = '0'
		END
		ELSE
		BEGIN
			IF (UPPER(@cons_shipments) IN ('1','Y'))
				SET @cons_shipments = '1'
			ELSE IF (UPPER(@cons_shipments) IN ('0','N'))
				SET @cons_shipments = '0'
			ELSE
			BEGIN
				SET @msg = 'Line: ' + CAST(@row_id as varchar(10)) + ' - Consolidated Shipment flag - invalid data.'
				INSERT	#import_messages			
				SELECT	@row_id, @msg

				CONTINUE
			END
		END

		UPDATE	dbo.cvo_cust_import
		SET		cons_shipments = @cons_shipments
		WHERE	row_id = @row_id

		IF (@rx_consolidated = '')
		BEGIN
			SET @rx_consolidated = '0'
		END
		ELSE
		BEGIN
			IF (UPPER(@rx_consolidated) IN ('1','Y'))
				SET @rx_consolidated = '1'
			ELSE IF (UPPER(@rx_consolidated) IN ('0','N'))
				SET @rx_consolidated = '0'
			ELSE
			BEGIN
				SET @msg = 'Line: ' + CAST(@row_id as varchar(10)) + ' - RX Consolidate flag - invalid data.'
				INSERT	#import_messages			
				SELECT	@row_id, @msg

				CONTINUE
			END
		END

		UPDATE	dbo.cvo_cust_import
		SET		rx_consolidated = @rx_consolidated
		WHERE	row_id = @row_id

		IF (@allow_subs = '')
		BEGIN
			SET @allow_subs = '0'
		END
		ELSE
		BEGIN
			IF (UPPER(@allow_subs) IN ('1','Y'))
				SET @allow_subs = '1'
			ELSE IF (UPPER(@allow_subs) IN ('0','N'))
				SET @allow_subs = '0'
			ELSE
			BEGIN
				SET @msg = 'Line: ' + CAST(@row_id as varchar(10)) + ' - Allow Substitution flag - invalid data.'
				INSERT	#import_messages			
				SELECT	@row_id, @msg

				CONTINUE
			END
		END

		UPDATE	dbo.cvo_cust_import
		SET		allow_subs = @allow_subs
		WHERE	row_id = @row_id

		IF (@commission = '')
		BEGIN
			SET @commission = '0'
		END
		ELSE
		BEGIN
			IF (UPPER(@commission) IN ('1','Y'))
				SET @commission = '1'
			ELSE IF (UPPER(@commission) IN ('0','N'))
				SET @commission = '0'
			ELSE
			BEGIN
				SET @msg = 'Line: ' + CAST(@row_id as varchar(10)) + ' - Commissionable flag - invalid data.'
				INSERT	#import_messages			
				SELECT	@row_id, @msg

				CONTINUE
			END
		END

		UPDATE	dbo.cvo_cust_import
		SET		commission = @commission
		WHERE	row_id = @row_id

		IF (@commission = '0')
		BEGIN
			SET @comm_perc = '0'
		END
		ELSE
		BEGIN
			IF (@comm_perc = '')
			BEGIN
				SET @msg = 'Line: ' + CAST(@row_id as varchar(10)) + ' - Commission % - invalid data.'
				INSERT	#import_messages			
				SELECT	@row_id, @msg

				CONTINUE
			END
		END

		UPDATE	dbo.cvo_cust_import
		SET		comm_perc = @comm_perc
		WHERE	row_id = @row_id

		IF (@door = '')
		BEGIN
			SET @door = '0'
		END
		ELSE
		BEGIN
			IF (UPPER(@door) IN ('1','Y'))
				SET @door = '1'
			ELSE IF (UPPER(@door) IN ('0','N'))
				SET @door = '0'
			ELSE
			BEGIN
				SET @msg = 'Line: ' + CAST(@row_id as varchar(10)) + ' - Door flag - invalid data.'
				INSERT	#import_messages			
				SELECT	@row_id, @msg

				CONTINUE
			END
		END

		UPDATE	dbo.cvo_cust_import
		SET		door = @door
		WHERE	row_id = @row_id
				
		IF (@residential = '')
		BEGIN
			SET @residential = '0'
		END
		ELSE
		BEGIN
			IF (UPPER(@residential) IN ('1','Y'))
				SET @residential = '1'
			ELSE IF (UPPER(@residential) IN ('0','N'))
				SET @residential = '0'
			ELSE
			BEGIN
				SET @msg = 'Line: ' + CAST(@row_id as varchar(10)) + ' - Residential Address flag - invalid data.'
				INSERT	#import_messages			
				SELECT	@row_id, @msg

				CONTINUE
			END
		END

		UPDATE	dbo.cvo_cust_import
		SET		residential = @residential
		WHERE	row_id = @row_id

		IF (@user_category <> '')
		BEGIN
			IF NOT EXISTS (SELECT 1 FROM so_usrcateg (NOLOCK) WHERE category_code = @user_category)
			BEGIN
				SET @msg = 'Line: ' + CAST(@row_id as varchar(10)) + ' - Invalid User Category.'
				INSERT	#import_messages			
				SELECT	@row_id, @msg

				CONTINUE
			END
		END

		UPDATE	dbo.cvo_cust_import
		SET		user_category = @user_category
		WHERE	row_id = @row_id

		IF (@credit_for_rets = '')
		BEGIN
			SET @credit_for_rets = '0'
		END
		ELSE
		BEGIN
			IF (@credit_for_rets NOT IN ('0','1','2'))
				SET @credit_for_rets = '0'
		END

		UPDATE	dbo.cvo_cust_import
		SET		credit_for_rets = @credit_for_rets
		WHERE	row_id = @row_id

		IF (@freight_chg_flag = '')
		BEGIN
			SET @freight_chg_flag = '0'
		END
		ELSE
		BEGIN
			IF (@freight_chg_flag NOT IN ('0','1','2'))
				SET @freight_chg_flag = '0'
		END

		UPDATE	dbo.cvo_cust_import
		SET		freight_chg_flag = @freight_chg_flag
		WHERE	row_id = @row_id

		IF (@chargebacks = '')
		BEGIN
			SET @chargebacks = '0'
		END
		ELSE
		BEGIN
			IF (UPPER(@chargebacks) IN ('1','Y'))
				SET @chargebacks = '1'
			ELSE IF (UPPER(@chargebacks) IN ('0','N'))
				SET @chargebacks = '0'
			ELSE
			BEGIN
				SET @msg = 'Line: ' + CAST(@row_id as varchar(10)) + ' - Chargeback flag - invalid data.'
				INSERT	#import_messages			
				SELECT	@row_id, @msg

				CONTINUE
			END
		END

		UPDATE	dbo.cvo_cust_import
		SET		chargebacks = @chargebacks
		WHERE	row_id = @row_id

		IF (@print_cm = '')
		BEGIN
			SET @print_cm = '1'
		END
		ELSE
		BEGIN
			IF (UPPER(@print_cm) IN ('1','Y'))
				SET @print_cm = '1'
			ELSE IF (UPPER(@print_cm) IN ('0','N'))
				SET @print_cm = '0'
			ELSE
			BEGIN
				SET @msg = 'Line: ' + CAST(@row_id as varchar(10)) + ' - Chargeback flag - invalid data.'
				INSERT	#import_messages			
				SELECT	@row_id, @msg

				CONTINUE
			END
		END

		UPDATE	dbo.cvo_cust_import
		SET		print_cm = @print_cm
		WHERE	row_id = @row_id

		IF (@co_op_eligible = '')
		BEGIN
			SET @co_op_eligible = 'N'
		END
		ELSE
		BEGIN
			IF (UPPER(@co_op_eligible) IN ('1','Y'))
				SET @co_op_eligible = 'Y'
			ELSE IF (UPPER(@co_op_eligible) IN ('0','N'))
				SET @co_op_eligible = 'N'
			ELSE
			BEGIN
				SET @msg = 'Line: ' + CAST(@row_id as varchar(10)) + ' - Co Op Eligible flag - invalid data.'
				INSERT	#import_messages			
				SELECT	@row_id, @msg

				CONTINUE
			END
		END

		UPDATE	dbo.cvo_cust_import
		SET		co_op_eligible = @co_op_eligible
		WHERE	row_id = @row_id

		IF (@co_op_eligible = 'N')
		BEGIN
			SET @co_op_thres_flag = 'N'
			SET @co_op_thres_amt = '0'
			SET @co_op_rate = '0'
			SET @co_op_notes = ''

			UPDATE	dbo.cvo_cust_import
			SET		co_op_thres_flag = @co_op_thres_flag,
					co_op_thres_amt = @co_op_thres_amt,
					co_op_rate = @co_op_rate,
					co_op_notes = @co_op_notes
			WHERE	row_id = @row_id

		END
		ELSE
		BEGIN
			IF (@co_op_thres_flag = '')
			BEGIN
				SET @co_op_thres_flag = 'N'
			END
			ELSE
			BEGIN
				IF (UPPER(@co_op_thres_flag) IN ('1','Y'))
					SET @co_op_thres_flag = 'Y'
				ELSE IF (UPPER(@co_op_thres_flag) IN ('0','N'))
					SET @co_op_thres_flag = 'N'
				ELSE
				BEGIN
					SET @msg = 'Line: ' + CAST(@row_id as varchar(10)) + ' - Co Op Threshold flag - invalid data.'
					INSERT	#import_messages			
					SELECT	@row_id, @msg

					CONTINUE
				END
			END
			IF (@co_op_thres_flag = 'N')
			BEGIN
				SET @co_op_thres_amt = '0'
			END
			ELSE
			BEGIN
				IF(@co_op_thres_amt = '' OR @co_op_thres_amt = '0')
				BEGIN
					SET @msg = 'Line: ' + CAST(@row_id as varchar(10)) + ' - Co Op Threshold amount - invalid data.'
					INSERT	#import_messages			
					SELECT	@row_id, @msg

					CONTINUE
				END
			END
			IF (@co_op_rate = '')
				SET @co_op_rate = '0'

			UPDATE	dbo.cvo_cust_import
			SET		co_op_thres_flag = @co_op_thres_flag,
					co_op_thres_amt = @co_op_thres_amt,
					co_op_rate = @co_op_rate,
					co_op_notes = @co_op_notes
			WHERE	row_id = @row_id
		END

		IF (@metal_plastic = '')
		BEGIN
			SET @metal_plastic = '0'
		END
		ELSE
		BEGIN
			IF (UPPER(@metal_plastic) IN ('1','Y'))
				SET @metal_plastic = '1'
			ELSE IF (UPPER(@metal_plastic) IN ('0','N'))
				SET @metal_plastic = '0'
			ELSE
			BEGIN
				SET @msg = 'Line: ' + CAST(@row_id as varchar(10)) + ' - Metal/Plastic flag - invalid data.'
				INSERT	#import_messages			
				SELECT	@row_id, @msg

				CONTINUE
			END
		END				

		UPDATE	dbo.cvo_cust_import
		SET		metal_plastic = @metal_plastic
		WHERE	row_id = @row_id

		IF (@suns_optical = '')
		BEGIN
			SET @suns_optical = '0'
		END
		ELSE
		BEGIN
			IF (UPPER(@suns_optical) IN ('1','Y'))
				SET @suns_optical = '1'
			ELSE IF (UPPER(@suns_optical) IN ('0','N'))
				SET @suns_optical = '0'
			ELSE
			BEGIN
				SET @msg = 'Line: ' + CAST(@row_id as varchar(10)) + ' - Sun/Optical flag - invalid data.'
				INSERT	#import_messages			
				SELECT	@row_id, @msg

				CONTINUE
			END
		END	

		UPDATE	dbo.cvo_cust_import
		SET		suns_optical = @suns_optical
		WHERE	row_id = @row_id

		IF (@max_dollars = '')
			SET @max_dollars = '0'

		IF (@metal_plastic = '0' AND @suns_optical = '0')
			SET @max_dollars = '0'

		UPDATE	dbo.cvo_cust_import
		SET		max_dollars = @max_dollars
		WHERE	row_id = @row_id
				
	END

	UPDATE	a
	SET		process = -1,
			errormessage = b.message_str
	FROM	dbo.cvo_cust_import a
	JOIN	#import_messages b
	ON		a.row_id = b.row_id

	SET @row_id = 0
	SET @msg = ''
		
	WHILE (1 = 1)
	BEGIN

		SELECT	TOP 1 @row_id = row_id,
				@customer_code = customer_code,
				@ship_to_code = ship_to_code,
				@cust_name = cust_name,
				@addr1 = addr1,
				@addr2 = addr2,
				@addr3 = addr3,
				@addr4 = addr4,
				@city = city,
				@state = state,
				@postal_code = postal_code,
				@country = country,
				@customer_type = customer_type,
				@POP_POB = POP_POB,
				@attention_name = attention_name,
				@attention_phone = attention_phone,
				@attention_email = attention_email,
				@contact_name = contact_name,
				@contact_phone = contact_phone,
				@contact_email = contact_email,
				@fax_number = fax_number,
				@tax_code = tax_code,
				@terms_code = terms_code,
				@fob_code = fob_code,
				@territory_code = territory_code,
				@fin_chg_code = fin_chg_code,
				@price_code = price_code,
				@payment_code = payment_code,
				@statement_flag = statement_flag,
				@statement_cycle = statement_cycle,
				@credit_limit = credit_limit,
				@aging_limit = aging_limit,
				@aging_check = aging_check,
				@aging_allowance = aging_allowance,
				@ship_complete = ship_complete,
				@BO_RX_sc_flag = BO_RX_sc_flag,
				@BO_non_RX_sc_flag = BO_non_RX_sc_flag,
				@currency_code = currency_code,
				@carrier = carrier,
				@rx_carrier = rx_carrier,
				@bo_carrier = bo_carrier,
				@add_cases = add_cases,
				@add_pattern = add_pattern,
				@patterns_first = patterns_first,
				@cons_shipments = cons_shipments,
				@rx_consolidated = rx_consolidated,
				@allow_subs = allow_subs,
				@commission = commission,
				@comm_perc = comm_perc,
				@door = door,
				@residential = residential,
				@user_category = user_category,
				@credit_for_rets = credit_for_rets,
				@freight_chg_flag = freight_chg_flag,
				@chargebacks = chargebacks,
				@print_cm = print_cm,
				@co_op_eligible = co_op_eligible,
				@co_op_thres_flag = co_op_thres_flag,
				@co_op_thres_amt = co_op_thres_amt,
				@co_op_rate = co_op_rate,
				@co_op_notes = co_op_notes,
				@metal_plastic = metal_plastic,
				@suns_optical = suns_optical,
				@max_dollars = max_dollars,
				@url = url				
		FROM	dbo.cvo_cust_import
		WHERE	row_id > @row_id
		AND		process = 0
		ORDER BY row_id ASC

		IF (@@ROWCOUNT = 0)
			BREAK

		IF (@customer_code = '')
		BEGIN
			WHILE (@customer_code = '')
			BEGIN
				EXEC ARGetNextControl_SP 2090, @masked OUTPUT, @num OUTPUT 
				IF NOT EXISTS (SELECT 1 FROM armaster_all (NOLOCK) WHERE customer_code = @masked)
				BEGIN
					SET @customer_code = @masked 		
					UPDATE	dbo.cvo_cust_import
					SET		customer_code = @customer_code
					WHERE	row_id = @row_id
				END
			END
		END


		IF (@ship_to_code = '')
		BEGIN

			INSERT	armaster_all (customer_code, ship_to_code, address_name, short_name, addr1, addr2, addr3, addr4, addr5, addr6,
				addr_sort1, addr_sort2, addr_sort3, address_type, status_type, attention_name, attention_phone, contact_name, 
				contact_phone, tlx_twx, phone_1, phone_2, tax_code, terms_code, fob_code, freight_code, posting_code, location_code,
				alt_location_code, dest_zone_code, territory_code, salesperson_code, fin_chg_code, price_code, payment_code, vendor_code,
				affiliated_cust_code, print_stmt_flag, stmt_cycle_code, inv_comment_code, stmt_comment_code, dunn_message_code, note,
				trade_disc_percent, invoice_copies, iv_substitution, ship_to_history, check_credit_limit, credit_limit, check_aging_limit,
				aging_limit_bracket, bal_fwd_flag, ship_complete_flag, resale_num, db_num, db_date, db_credit_rating, late_chg_type,
				valid_payer_flag, valid_soldto_flag, valid_shipto_flag, payer_soldto_rel_code, across_na_flag, date_opened, added_by_user_name,
				added_by_date, modified_by_user_name, modified_by_date, rate_type_home, rate_type_oper, limit_by_home, nat_cur_code, one_cur_cust,
				city, state, postal_code, country, remit_code, forwarder_code, freight_to_code, route_code, route_no, url, special_instr,
				guid, price_level, ship_via_code, ddid, so_priority_code, country_code, tax_id_num, ftp, attention_email, contact_email,
				dunning_group_id, consolidated_invoices, writeoff_code, delivery_days, extended_name, check_extendedname_flag)
			VALUES (@customer_code, @ship_to_code, @cust_name, LEFT(@cust_name,10), @addr1, @addr2, @addr3, @addr4, '', '', @customer_type,
				'', @POP_POB, 0, 1, @attention_name, @attention_phone, @contact_name, @contact_phone, @fax_number, '', '', @tax_code,
				@terms_code, @fob_code, '',	'STD', '001', '0', '', @territory_code, @territory_code, @fin_chg_code, @price_code, @payment_code,
				'', '', @statement_flag, @statement_cycle, '', '', '', '', 0, 1, 0, 0, CASE WHEN @credit_limit <> '0' THEN 1 ELSE 0 END,
				@credit_limit, 1, @aging_limit, 0, @ship_complete, '', '', 0, '', 0, 1, 1, 1, 'REPORT', 0, DATEDIFF(day, '01/01/1900', GETDATE()) + 693596,
				'Imported', GETDATE(), '', NULL, 'BUY', 'BUY', 0, @currency_code, 0, @city, @state, @postal_code, '', '', '', '', '', 
				NULL, @url, '', '', 1, @carrier, '', 5, @country, '', '', @attention_email, @contact_email, NULL, 0, 'BADDEBT', NULL, 
				@cust_name, 0)

			IF (@@ERROR <> 0)
			BEGIN
				SET @msg = 'An error occurred import the customer records'
				GOTO FINISH
			END

			INSERT	cvo_armaster_all (customer_code, ship_to, coop_eligible, coop_threshold_flag, coop_threshold_amount, 
				coop_dollars, coop_notes, coop_cust_rate_flag, coop_cust_rate, coop_dollars_prev_year, coop_dollars_previous,
				rx_carrier, bo_carrier, add_cases, add_patterns, max_dollars, metal_plastic, suns_opticals, address_type,
				consol_ship_flag, coop_redeemed, allow_substitutes, patterns_foo, commissionable, commission, cvo_print_cm,
				cvo_chargebacks, freight_charge, ship_complete_flag_rx, coop_ytd, credit_for_returns, door, residential_address, 
				category_code, aging_check, aging_allowance, rx_consolidate)
			VALUES (@customer_code, @ship_to_code, @co_op_eligible, @co_op_thres_flag, @co_op_thres_amt, 0, @co_op_notes, 
				CASE WHEN @co_op_rate <> '0' THEN 1 ELSE 0 END, @co_op_rate, 0, 0, @rx_carrier, @bo_carrier, @add_cases,
				@add_pattern, @max_dollars, @metal_plastic, @suns_optical, 0, @cons_shipments, 0, @allow_subs, @patterns_first,
				@commission, @comm_perc, @print_cm, @chargebacks, @freight_chg_flag, 0, 0, @credit_for_rets, @door, @residential, 
				@user_category, @aging_check, @aging_allowance, @rx_consolidated)   		

			IF (@@ERROR <> 0)
			BEGIN
				SET @msg = 'An error occurred import the customer extra records'
				GOTO FINISH
			END	    
		END
		ELSE
		BEGIN

			INSERT	armaster_all (customer_code, ship_to_code, address_name, short_name, addr1, addr2, addr3, addr4, addr5, addr6,
				addr_sort1, addr_sort2, addr_sort3, address_type, status_type, attention_name, attention_phone, contact_name, 
				contact_phone, tlx_twx, phone_1, phone_2, tax_code, terms_code, fob_code, freight_code, posting_code, location_code,
				alt_location_code, dest_zone_code, territory_code, salesperson_code, fin_chg_code, price_code, payment_code, vendor_code,
				affiliated_cust_code, print_stmt_flag, stmt_cycle_code, inv_comment_code, stmt_comment_code, dunn_message_code, note,
				trade_disc_percent, invoice_copies, iv_substitution, ship_to_history, check_credit_limit, credit_limit, check_aging_limit,
				aging_limit_bracket, bal_fwd_flag, ship_complete_flag, resale_num, db_num, db_date, db_credit_rating, late_chg_type,
				valid_payer_flag, valid_soldto_flag, valid_shipto_flag, payer_soldto_rel_code, across_na_flag, date_opened, added_by_user_name,
				added_by_date, modified_by_user_name, modified_by_date, rate_type_home, rate_type_oper, limit_by_home, nat_cur_code, one_cur_cust,
				city, state, postal_code, country, remit_code, forwarder_code, freight_to_code, route_code, route_no, url, special_instr,
				guid, price_level, ship_via_code, ddid, so_priority_code, country_code, tax_id_num, ftp, attention_email, contact_email,
				dunning_group_id, consolidated_invoices, writeoff_code, delivery_days, extended_name, check_extendedname_flag)
			VALUES (@customer_code, @ship_to_code, @cust_name, LEFT(@cust_name,10), @addr1, @addr2, @addr3, @addr4, '', '', @customer_type,
				'', @POP_POB, 1, 1, @attention_name, @attention_phone, @contact_name, @contact_phone, @fax_number, '', '', @tax_code,
				@terms_code, @fob_code, '',	'STD', '', '', '', @territory_code, @territory_code, '', '', '',
				'', '', NULL, NULL, '', '', '', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, 
				NULL, NULL, NULL, NULL, NULL, NULL, DATEDIFF(day, '01/01/1900', GETDATE()) + 693596,
				'Imported', GETDATE(), '', NULL, 'BUY', 'BUY', NULL, @currency_code, 0, @city, @state, @postal_code, '', '', '', '', '', 
				NULL, @url, '', '', 1, @carrier, '', NULL, @country, '', '', @attention_email, @contact_email, NULL, 0, 'BADDEBT', NULL, 
				@cust_name, 0)

			IF (@@ERROR <> 0)
			BEGIN
				SET @msg = 'An error occurred import the customer records'
				GOTO FINISH
			END

			INSERT	cvo_armaster_all (customer_code, ship_to, coop_eligible, coop_threshold_flag, coop_threshold_amount, 
				coop_dollars, coop_notes, coop_cust_rate_flag, coop_cust_rate, coop_dollars_prev_year, coop_dollars_previous,
				rx_carrier, bo_carrier, add_cases, add_patterns, max_dollars, metal_plastic, suns_opticals, address_type,
				consol_ship_flag, coop_redeemed, allow_substitutes, patterns_foo, commissionable, commission, cvo_print_cm,
				cvo_chargebacks, freight_charge, ship_complete_flag_rx, coop_ytd, credit_for_returns, door, residential_address, 
				category_code, aging_check, aging_allowance,
				rx_consolidate)
			VALUES (@customer_code, @ship_to_code, NULL, NULL, 0, 0, NULL, NULL, NULL, 0, 0, @rx_carrier, @bo_carrier, NULL,
				NULL, @max_dollars, @metal_plastic, @suns_optical, 1, @cons_shipments, 0, NULL, NULL,
				NULL, NULL, 0, 0, NULL, 0, 0, NULL, @door, @residential, @user_category, @aging_check, @aging_allowance, @rx_consolidated) 

			IF (@@ERROR <> 0)
			BEGIN
				SET @msg = 'An error occurred import the customer extra records'
				GOTO FINISH
			END
		END
	END

	FINISH:
	
	IF (@msg <> '')
	BEGIN
		SELECT	0 row_id, '' customer_code, '' ship_to_code, @msg errormessage
	END
	ELSE
	BEGIN		
		SELECT	row_id, customer_code, ship_to_code, ISNULL(errormessage,'Imported') errormessage
		FROM	dbo.cvo_cust_import
		WHERE	process IN (0,-1)
	
		UPDATE	dbo.cvo_cust_import
		SET		process = 1 
		WHERE	process = 0

		UPDATE	dbo.cvo_cust_import
		SET		process = -2 
		WHERE	process = -1
	END

END
GO
GRANT EXECUTE ON  [dbo].[cvo_upload_cust_sp] TO [public]
GO
