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




CREATE PROC [dbo].[apstl_mcomp_sp] @WhereClause varchar(1024)='' 

AS

DECLARE		@orderBy varchar(255),
	 	@db_name varchar(128),
		@company_name varchar(30),
		@comp smallint,
		@indx1 int,
		@indx2 int,
		@length int,
		@sub1 varchar(512),
		@sub2 varchar(512),
		@sub3 varchar(512),
		@AUX varchar (512)


create table #apstl_comp
(
	company_name			varchar(30),
	settlement_ctrl_num		varchar(16),
	org_id				varchar(30), 
	vendor_name			varchar(40),
	vendor_code			varchar(12),
	pay_to_code		        varchar(8),
	date_entered			int, 
	date_applied			int,
	posted_flag      		varchar(4),
	hold_flag               	varchar(4),	 
	disc_total_home			float,
	disc_total_oper			float,
	debit_memo_total_home		float,
	debit_memo_total_oper		float,
	on_acct_pay_total_home		float,
	on_acct_pay_total_oper		float,
	payments_total_home		float,
	payments_total_oper		float,
	put_on_acct_total_home		float,
	put_on_acct_total_oper		float,
	gain_total_home			float,
	gain_total_oper			float,
	loss_total_home			float,
	loss_total_oper			float,
	x_date_entered			int,
	x_date_applied			int,
	x_disc_total_home		float,
	x_disc_total_oper		float,
	x_debit_memo_total_home		float,
	x_debit_memo_total_oper		float,
	x_on_acct_pay_total_home	float,
	x_on_acct_pay_total_oper	float,
	x_payments_total_home		float,
	x_payments_total_oper		float,
	x_put_on_acct_total_home	float,
	x_put_on_acct_total_oper	float,
	x_gain_total_home		float,
	x_gain_total_oper		float,
	x_loss_total_home		float,
	x_loss_total_oper		float

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
		
		select @AUX = ' INSERT INTO #apstl_comp EXEC apstl_comp_sp ' + CHAR(39) + REPLACE(@WhereClause, CHAR(39), '''''') + CHAR(39) + ', ' + CHAR(39) + @company_name + CHAR(39)

		exec (' USE ' + @db_name + @AUX )
	END

	 SELECT @db_name = min(db_name) 
	 FROM CVO_Control..smcomp
	 WHERE db_name > @db_name	

	SELECT @company_name = ''
END

SELECT * FROM #apstl_comp ORDER BY company_name

DROP TABLE #apstl_comp




GO
GRANT EXECUTE ON  [dbo].[apstl_mcomp_sp] TO [public]
GO
