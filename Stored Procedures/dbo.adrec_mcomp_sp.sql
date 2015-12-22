SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create proc [dbo].[adrec_mcomp_sp] @WhereClause varchar(1024)='' AS

DECLARE 	@db_name varchar(128),
		@company_name varchar(30),
		@comp smallint,
		@indx1 int,
		@indx2 int,
		@length int,
		@sub1 varchar(255),
		@sub2 varchar(255),
		@sub3 varchar(255)


CREATE TABLE #adrec
(
	company_name	varchar(30),
	receipt_no	int,
	po_key		int NULL,
	line		int NULL,
	vendor		varchar(12),
	location	varchar(10),
	part_no		varchar(30),
	description	varchar(255) NULL,
	unit_measure	char NULL,
	qty_ordered	decimal,
	qty_received	decimal,
	date_received	datetime,
	qc_desc		varchar(3),
	status		char,
	status_desc	varchar(8),
	unit_cost	decimal,
	part_type	varchar(10) NULL,
	sku_no		varchar(30) NULL,
	who_entered	varchar(20) NULL,
	voucher_no	varchar(16) NULL,
	tolerance_cd	varchar(10) NULL,
	x_receipt_no	int,
	x_po_key	int NULL,
	x_line		int NULL,
	x_qty_ordered	decimal,
	x_qty_received	decimal,
	x_date_received	datetime,
	x_unit_cost	decimal
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
			INSERT INTO #adrec
			SELECT company_name = '''  + @company_name + ''',
			receipt_no,
			po_key,
			line,
			vendor,
			location,
			part_no,
			description,
			unit_measure,
			qty_ordered,
			qty_received,
			date_received,
			qc_desc,
			status,
			status_desc,
			unit_cost,
			part_type,
			sku_no,
			who_entered,
			voucher_no,
			tolerance_cd,
			x_receipt_no,
			x_po_key,
			x_line,
			x_qty_ordered,
			x_qty_received,
			x_date_received,
			x_unit_cost
		  FROM 
		  	' + @db_name + '..adrec_vw
		 ' + @WhereClause + ''
		)
	END
	
	 SELECT @db_name = min(db_name) 
	 FROM CVO_Control..smcomp
	 WHERE db_name > @db_name

	SELECT @company_name = ''
	
END

SELECT * FROM #adrec ORDER BY company_name

DROP TABLE #adrec

GO
GRANT EXECUTE ON  [dbo].[adrec_mcomp_sp] TO [public]
GO
