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







CREATE PROC [dbo].[arcus_mcomp_sp] @WhereClause varchar(1024)='' AS

DECLARE 	@db_name varchar(128),
		@company_name varchar(30),
		@comp smallint,
		@indx1 int,
		@indx2 int,
		@length int,
		@sub1 varchar(255),
		@sub2 varchar(255),
		@sub3 varchar(255)


CREATE TABLE #arcust
(
	company_name		varchar(30),
	address_name		varchar(40)NULL,
	customer_code		varchar(8)NULL,
	contact_name		varchar(40)NULL,
	contact_phone		varchar(30)NULL,
	territory_code		varchar(8)NULL,
	price_code		varchar(8)NULL,
	nat_cur_code		varchar(8)NULL,
	open_balance		float,
	amt_on_acct		float,
	net_balance		float NULL,
	credit_limit		float NULL,
	avail_credit_amt	float NULL,
	date_opened		int NULL,
	status_code		varchar(8),
	shipped_flag		varchar(3),
	x_open_balance		float,
	x_amt_on_acct		float,
	x_net_balance		float NULL,
	x_credit_limit		float NULL,
	x_avail_credit_amt	float NULL,
	x_date_opened		int NULL
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
			INSERT INTO #arcust
			SELECT company_name = '''  + @company_name + ''',
			address_name,
			customer_code,
			contact_name,
			contact_phone,
			territory_code,
			price_code,
			nat_cur_code,
			open_balance,
			amt_on_acct,
			net_balance,
			credit_limit,
			avail_credit_amt,
			date_opened,
			status_code,
			shipped_flag,
			x_open_balance,
			x_amt_on_acct,
			x_net_balance,
			x_credit_limit,
			x_avail_credit_amt,
			x_date_opened	
		  FROM 
		  	' + @db_name + '..arcus_vw
		 ' + @WhereClause + ''
		)
	END
	
	 SELECT @db_name = min(db_name) 
	 FROM CVO_Control..smcomp
	 WHERE db_name > @db_name

	SELECT @company_name = ''
	
END

SELECT * FROM #arcust ORDER BY company_name

DROP TABLE #arcust

GO
GRANT EXECUTE ON  [dbo].[arcus_mcomp_sp] TO [public]
GO
