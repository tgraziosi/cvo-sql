SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

/*                                                      
               Confidential Information                  
    Limited Distribution of Authorized Persons Only       
    Created 2001 and Protected as Unpublished Work       
          Under the U.S. Copyright Act of 1976            
 Copyright (c) 2001 Epicor Software Corporation, 2001    
                  All Rights Reserved                    
*/                                                








CREATE PROC [dbo].[glbl1_mcomp_sp] @WhereClause varchar(1024)='' AS

DECLARE 	@db_name varchar(128),
		@company_name varchar(30),
		@comp smallint,
		@indx1 int,
		@indx2 int,
		@length int,
		@sub1 varchar(255),
		@sub2 varchar(255),
		@sub3 varchar(255),

		@AUX varchar (1024),
		@AUX1 varchar (1024)

CREATE TABLE #glbl1
(
	company_name		varchar(30)	NOT NULL,
	account_code            varchar(36) 	NOT NULL,
	post_status		smallint,
	org_id			varchar(30)	NULL,
	date_period_end 	int,
	beginning_balance       float		NOT NULL,
	net_change		float		NOT NULL,
	ending_balance          float		NOT NULL,
	oper_beginning_balance  float	  	NOT NULL,
	oper_net_change		float		NOT NULL,
	oper_ending_balance     float		NOT NULL,
	x_date_period_end	int,
	x_beginning_balance	float,
	x_net_change		float,
	x_ending_balance	float,
	x_oper_beginning_balance float,
	x_oper_net_change	float,
	x_oper_ending_balance	float
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
			WHERE app_id = 6000 AND c.db_name = @db_name ))
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
		
		select @AUX = ' INSERT INTO #glbl1 EXEC glbl1_comp_sp ' + CHAR(39) + REPLACE(@WhereClause, CHAR(39), '''''') + CHAR(39) + ', ' + CHAR(39) + @company_name + CHAR(39)
	
		exec (' USE ' + @db_name + @AUX )
	END

	 SELECT @db_name = min(db_name) 
	 FROM CVO_Control..smcomp
	 WHERE db_name > @db_name	

	 SELECT @company_name = ''
END

SELECT * FROM #glbl1

GO
GRANT EXECUTE ON  [dbo].[glbl1_mcomp_sp] TO [public]
GO
