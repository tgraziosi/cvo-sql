SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/*                                                      
               Confidential Information                  
    Limited Distribution of Authorized Persons Only       
    Created 2001 and Protected as Unpublished Work       
          Under the U.S. Copyright Act of 1976            
 Copyright (c) 2001 Epicor Software Corporation, 2001    
                  All Rights Reserved                    
*/                                                








CREATE PROC [dbo].[apvo2_mcomp_sp] @WhereClause varchar(1024)='' AS

DECLARE 	@db_name varchar(128),
		@company_name varchar(30),
		@comp smallint,
		@indx1 int,
		@indx2 int,
		@length int,
		@sub1 varchar(255),
		@sub2 varchar(255),
		@sub3 varchar(255)


CREATE TABLE #apvo2
(
	company_name		varchar(30),
	voucher_no		varchar(16),
	org_id			varchar(30) NULL,
	sequence_id		int,
	location_code		varchar(8),
	item_code		varchar(30),
	line_desc		varchar(60),
	qty_ordered		float,
	qty_received		float,
	unit_code		varchar(8),
	nat_cur_code		varchar(8),
	unit_price		float,
	amt_discount		float,
	amt_freight		float,
	amt_tax			float,
	amt_misc		float,
	amt_extended		float,
	rec_company_code	varchar(8),
	gl_exp_acct		varchar(36) NULL,
	reference_code		varchar(32) NULL,
	code_1099		varchar(8),
	tax_code		varchar(8),
	vendor_code		varchar(12),
	date_applied		int,
	po_ctrl_num		varchar(16),
	x_qty_ordered		float,
	x_qty_received		float,
	x_unit_price		float,
	x_amt_discount		float,
	x_amt_freight		float,
	x_amt_tax		float,
	x_amt_misc		float,
	x_amt_extended		float,
	x_date_applied		int
)




SELECT @comp = 0
SELECT @indx1 = CHARINDEX('company_name', @WhereClause)
IF(@indx1 > 0 )
BEGIN
	SELECT @comp = 1
	SELECT @sub1 = SUBSTRING(@WhereClause, 1, @indx1 - 1)
	
	SELECT @indx2 = CHARINDEX('AND', @WhereClause, @indx1)
	
	IF( @indx2 > 0)
		BEGIN
			SELECT @sub2 = SUBSTRING(@WhereClause, @indx1, @indx2 - @indx1)
			SELECT @sub3 = SUBSTRING(@WhereClause, @indx1 + LEN(@sub2) + 5, LEN(@WhereClause)-(LEN(@sub2) + 5))
			SELECT @WhereClause = @sub1 + @sub3
		END
	ELSE
		BEGIN
			SELECT @sub2 = SUBSTRING(@WhereClause, @indx1, LEN(@WhereClause))
			SELECT @WhereClause = SUBSTRING(@sub1, 1, @indx1 - 5)
		END

	IF(CHARINDEX('like',@sub2,1) > 0)
	BEGIN
		SELECT @sub3 = SUBSTRING(@sub2, 18, LEN(@sub2))
	END
	ELSE
	BEGIN
		SELECT @sub3 = SUBSTRING(@sub2, 16, LEN(@sub2))		
	END
END
IF(LEN(@WhereClause) < 6)
BEGIN
	SELECT @WhereClause = ''
END

SELECT @db_name = min(db_name) 
FROM CVO_Control..smcomp









WHILE (@db_name != '' 
	AND EXISTS( SELECT 1 from CVO_Control..smcomp c INNER JOIN CVO_Control..sminst i ON c.company_id = i.company_id		
			WHERE app_id = 4000 AND c.db_name = @db_name ))
BEGIN


	SELECT @sub3 = REPLACE (@sub3,char(39),'')

	


	SELECT @company_name = company_name
	FROM   CVO_Control..smcomp
	WHERE db_name = @db_name
	AND    company_name like RTRIM(LTRIM(@sub3))


	SELECT  @company_name = isnull(@company_name,'')

	


	IF((HAS_DBACCESS ( @db_name) = 1) AND (  (@company_name != '') OR (@comp = 0) ))
	BEGIN

		IF(@company_name = '')
		BEGIN
			SELECT @company_name = company_name
			FROM   CVO_Control..smcomp
			WHERE db_name = @db_name
		END
		EXEC ('
			INSERT INTO #apvo2
			SELECT company_name = '''  + @company_name + ''',
			voucher_no,
			org_id,
			sequence_id,
			location_code,
			item_code,
			line_desc,
			qty_ordered,
			qty_received,
			unit_code,
			nat_cur_code,
			unit_price,
			amt_discount,
			amt_freight,
			amt_tax,
			amt_misc,
			amt_extended,
			rec_company_code,
			gl_exp_acct,
			reference_code,
			code_1099,
			tax_code,
			vendor_code,
			date_applied,
			po_ctrl_num,
			x_qty_ordered,
			x_qty_received,
			x_unit_price,
			x_amt_discount,
			x_amt_freight,
			x_amt_tax,
			x_amt_misc,
			x_amt_extended,
			x_date_applied
		
		  FROM 
		  	' + @db_name + '..apvo2_vw
		 ' + @WhereClause + ''
		)
	END
	
	 SELECT @db_name = min(db_name) 
	 FROM CVO_Control..smcomp
	 WHERE db_name > @db_name

	SELECT @company_name = ''
	
END

SELECT * FROM #apvo2 ORDER BY company_name

DROP TABLE #apvo2



GO
GRANT EXECUTE ON  [dbo].[apvo2_mcomp_sp] TO [public]
GO
