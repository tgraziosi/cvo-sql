SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create proc [dbo].[adpos_mcomp_sp] @WhereClause varchar(1024)='' AS

DECLARE 	@db_name varchar(128),
		@company_name varchar(30),
		@comp smallint,
		@indx1 int,
		@indx2 int,
		@length int,
		@sub1 varchar(255),
		@sub2 varchar(255),
		@sub3 varchar(255)


CREATE TABLE #adpo
(
	company_name		varchar(30),
	po_key			varchar(10) NULL,
	vendor_no		varchar(12),
	vendor_name		varchar(40),
	ship_to_no		varchar(10) NULL,
	ship_name		varchar(40) NULL,
	location		varchar(10) NULL,
	buyer			varchar(10) NULL,
	prod_no			int NULL,
	ship_via		varchar(10) NULL,
	fob			varchar(10) NULL,
	terms			varchar(10) NULL,
	curr_key		varchar(10) NULL,
	tax_code		varchar(10) NULL,
	total_amt_order		decimal(13) NULL,
	total_tax		decimal NULL,
	date_of_order		datetime,
	date_order_due		datetime NULL,
	status			char NULL,
	status_desc		varchar(6),
	who_entered		varchar(20) NULL,
	print_status		varchar(24),
	blanket			char NULL,
	blanket_desc		varchar(3),
	x_po_key		int,
	x_prod_no		int NULL,
	x_total_amt_order	decimal NULL,
	x_total_tax		decimal NULL,
	x_date_of_order		datetime,
	x_date_order_due	datetime NULL
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
	AND EXISTS( SELECT 1 FROM CVO_Control..s2papprg 
		WHERE app_id = 18000 AND company_db_name = @db_name AND version_code = '7.3.5'))
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
			INSERT INTO #adpo
			SELECT company_name = '''  + @company_name + ''',
			po_key,
			vendor_no,
			vendor_name,
			ship_to_no,
			ship_name,
			location,
			buyer,
			prod_no,
			ship_via,
			fob,
			terms,
			curr_key,
			tax_code,
			total_amt_order,
			total_tax,
			date_of_order,
			date_order_due,
			status,
			status_desc,
			who_entered,
			print_status,
			blanket,
			blanket_desc,
			x_po_key,
			x_prod_no,
			x_total_amt_order,
			x_total_tax,
			x_date_of_order,
			x_date_order_due
		  FROM 
		  	' + @db_name + '..adpos_vw
		 ' + @WhereClause + ''
		)
	END
	
	 SELECT @db_name = min(db_name) 
	 FROM CVO_Control..smcomp
	 WHERE db_name > @db_name

	SELECT @company_name = ''
	
END

SELECT * FROM #adpo ORDER BY company_name

DROP TABLE #adpo

GO
GRANT EXECUTE ON  [dbo].[adpos_mcomp_sp] TO [public]
GO
