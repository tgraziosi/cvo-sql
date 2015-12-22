SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

/*---------------------------------------------------------------------------------------------
// REVISION HISTORY
// Rev-No	Date		Name		Issue-No			Description
// ------	----------	----------	----------------	----------------------------------------
// CVO01	10/10/2010	EGARCIA		COOP REDEEMED SP	Creation for custom Explorer View
//---------------------------------------------------------------------------------------------
*/
  
CREATE PROCEDURE [dbo].[CVO_COOPRedeemed_sp]  @where_clause varchar(8000) = ' '
AS
BEGIN
	DECLARE @customer_code varchar(100), @account_code varchar(100),
			@Sub1 varchar(300), @Sub2 varchar(300),
			@first_quote varchar(50),	
			@local_where varchar(100),
			@second_quote int

	SELECT @Sub1 = '%%'
	SELECT @Sub2 = '%%'
	SELECT @where_clause = REPLACE(@where_clause, CHAR(39), '%')

	IF (CHARINDEX('customer_code', @where_clause) = 0) 	BEGIN SELECT @Sub1 = '%%' END
	ELSE
	BEGIN
		SELECT @Sub1 = substring(@where_clause, charindex('customer_code',@where_clause), datalength(@where_clause))
		--SELECT @Sub1 -- customer_code = %%ACC0001%% AND gl_exp_acct like %%%22020100SFWE%%%

		IF (CHARINDEX('gl_exp_acct', @where_clause) = 0)  -- customer_code like %2%
		BEGIN
			SELECT @Sub1 = substring(@Sub1, charindex('%',@Sub1), datalength(@Sub1)) -- %2%
			SELECT @Sub2 = '%%'
			--SELECT @Sub1, @Sub2, 'Customer code ONLY'
		END
		ELSE
		BEGIN
			--customer_code like %2% AND gl_exp_acct = %TEST%
			SELECT @Sub1 = substring(@Sub1, charindex('%',@Sub1), datalength(@Sub1))		-- %%ACC0001%% AND gl_exp_acct like %%%22020100SFWE%%%
			SELECT @Sub1 = substring(@Sub1, charindex('%', @Sub1), charindex('AND', @Sub1) - 2) -- %%ACC0001%

			SELECT @Sub2 = substring(@where_clause, charindex('gl_exp_acct', @where_clause), datalength(@where_clause))	-- gl_exp_acct like %%%22020100SFWE%%%
			SELECT @Sub2 = substring(@Sub2, charindex('%', @Sub2), datalength(@Sub2))					-- %%%22020100SFWE%%%
			--SELECT @Sub1, @Sub2, 'customer and gl account'
		END
		GOTO lblExec
	END

	IF (CHARINDEX('gl_exp_acct', @where_clause) <> 0)		--' Where gl_exp_acct like %%%22020100SFWE%%%
	BEGIN
			SELECT @Sub1 = substring(@where_clause, charindex('gl_exp_acct',@where_clause), datalength(@where_clause))  -- gl_exp_acct like %%%22020100SFWE%%%
			SELECT @Sub2 = substring(@Sub1, charindex('gl_exp_acct',@Sub1), datalength(@Sub1))	-- gl_exp_acct like %%%22020100SFWE%%%
			
			SELECT @Sub2 = substring(@Sub2, charindex('%',@Sub2), datalength(@Sub2)) -- %%%22020100SFWE%%%
			SELECT @Sub1 = '%%'
			SELECT @Sub1, @Sub2, 'gl account only'

			GOTO lblExec
	END

	lblExec:
		SELECT @Sub1 = CHAR(39) + @Sub1 + CHAR(39)  --'+%CALLA%+'
		SELECT @Sub2 = CHAR(39) + @Sub2 + CHAR(39)		--'+%%+'

--		SELECT @where_clause = 'SELECT reference_code AS customer_code, trx_ctrl_num, sequence_id, location_code, item_code, qty_ordered, qty_received, qty_returned, code_1099, tax_code, unit_code, unit_price, 
--			amt_discount, amt_freight, amt_tax, amt_misc, amt_extended, calc_tax, gl_exp_acct, line_desc, serial_id, rec_company_code,  
--			po_orig_flag, po_ctrl_num, org_id, amt_nonrecoverable_tax, amt_tax_det
--			FROM apvodet WHERE reference_code like ' + @Sub1 + ' AND gl_exp_acct like ' + @Sub2
--
--		SELECT @where_clause
	
		----------------------- FINAL SELECT ----------------------------------------------------
		EXEC('SELECT reference_code AS customer_code, trx_ctrl_num, sequence_id, location_code, item_code, qty_ordered, qty_received, qty_returned, code_1099, tax_code, unit_code, unit_price, 
			amt_discount, amt_freight, amt_tax, amt_misc, amt_extended, calc_tax, gl_exp_acct, line_desc, serial_id, rec_company_code,  
			po_orig_flag, po_ctrl_num, org_id, amt_nonrecoverable_tax, amt_tax_det
			FROM apvodet WHERE reference_code like ' + @Sub1 + ' AND gl_exp_acct like ' + @Sub2)
END
GO
GRANT EXECUTE ON  [dbo].[CVO_COOPRedeemed_sp] TO [public]
GO
