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






CREATE PROC [dbo].[arcm2_mcomp_sp] @WhereClause varchar(1024)='' AS

DECLARE 	@db_name varchar(128),
		@company_name varchar(30),
		@comp smallint,
		@indx1 int,
		@indx2 int,
		@length int,
		@sub1 varchar(255),
		@sub2 varchar(255),
		@sub3 varchar(255)

CREATE TABLE #arcm2_temp
(	
	company_name		varchar(30),
	address_name		varchar(40) NULL,
	customer_code		varchar(8) NULL,
	doc_ctrl_num		varchar(16),
	trx_ctrl_num		varchar(16),
	org_id			varchar(30) NULL,
	pyt_void_flag		varchar(3) NULL,
	pyt_posted_flag		varchar(3) NULL,
	pyt_hold_flag		varchar(3) NULL,
	date_doc		int,
	invoice_no		varchar(16),
	inv_posted_flag		varchar(3) NULL,
	inv_hold_flag		varchar(3) NULL,
	nat_cur_code		varchar(8),
	payment_amt		float,
	amt_write_off		float NULL,
	amt_disc_taken		float NULL,
	payment_desc		varchar(40),
	x_date_doc		int,
	x_payment_amt		float,
	x_amt_write_off		float NULL,
	x_amt_disc_taken	float NULL
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

			SELECT @sub2 = SUBSTRING(@WhereClause, @indx1, @indx2 - @indx1 )
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
			WHERE app_id = 2000 AND c.db_name = @db_name ))
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
			INSERT INTO #arcm2_temp
			SELECT company_name = '''  + @company_name + ''',
				address_name,
				customer_code,
				doc_ctrl_num,
				trx_ctrl_num,
				org_id,
				pyt_void_flag,
				pyt_posted_flag,
				pyt_hold_flag,
				date_doc,
				invoice_no,
				inv_posted_flag,
				inv_hold_flag,
				nat_cur_code,
				payment_amt,
				amt_write_off,
				amt_disc_taken,
				payment_desc,
				x_date_doc,
				x_payment_amt,
				x_amt_write_off,
				x_amt_disc_taken

			FROM 
		  	' + @db_name + '..arcm2_vw
		 ' + @WhereClause
		)
	END
	
	 SELECT @db_name = min(db_name) 
	 FROM CVO_Control..smcomp
	 WHERE db_name > @db_name

	SELECT @company_name = ''
	
END

SELECT * FROM #arcm2_temp ORDER BY company_name

DROP TABLE #arcm2_temp


GO
GRANT EXECUTE ON  [dbo].[arcm2_mcomp_sp] TO [public]
GO
