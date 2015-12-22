SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE [dbo].[glmkchrt_sp] 
	@seg1_from 	varchar(32),	
	@seg1_thru 	varchar(32),	
	@seg2_from 	varchar(32),	
	@seg2_thru 	varchar(32),	
	@seg3_from 	varchar(32),	
	@seg3_thru 	varchar(32),
	@seg4_from 	varchar(32),	
	@seg4_thru 	varchar(32),	
	@new_flag 	smallint

AS

DECLARE @now 		datetime,		
	@largest 	smallint,
	@acct_defs 	smallint,
	@count 		smallint, 	
	@highcount 	smallint,	
	@xprod 		int, 
   	@perc_done 	float, 	
   	@msg 		varchar(80),	
   	@new_accounts 	int




SELECT @now = getdate(), @new_accounts = 0



CREATE TABLE #accts
(
	account_code		varchar(32),
	account_description	varchar(40),
	account_type		smallint,
	new_flag		smallint,
	consol_type		smallint,
	seg1			varchar(32),
	seg2			varchar(32),
	seg3			varchar(32),
	seg4			varchar(32),
	detail_flag		smallint
        ,
        rate_type_home          varchar(8) NULL,
        rate_type_oper          varchar(8) NULL
)

CREATE UNIQUE INDEX accts_ind_0
	ON #accts( account_code )



CREATE TABLE #seg1
(
	timestamp		timestamp,
	seg_code		varchar(32),
	description		varchar(40),
	short_desc		varchar(40),
	account_type		smallint,
	new_flag		smallint,
	consol_type		smallint,
	consol_detail_flag	smallint
        ,
        rate_type_home          varchar(8) NULL,
        rate_type_oper          varchar(8) NULL
)


CREATE TABLE #seg2
(
	timestamp		timestamp,
	seg_code		varchar(32),
	description		varchar(40),
	short_desc		varchar(40),
	account_type		smallint,
	new_flag		smallint,
	consol_type		smallint,
	consol_detail_flag	smallint
        ,
        rate_type_home          varchar(8) NULL,
        rate_type_oper          varchar(8) NULL
)


CREATE TABLE #seg3
(
	timestamp		timestamp,
	seg_code		varchar(32),
	description		varchar(40),
	short_desc		varchar(40),
	account_type		smallint,
	new_flag		smallint,
	consol_type		smallint,
	consol_detail_flag	smallint
        ,
        rate_type_home          varchar(8) NULL,
        rate_type_oper          varchar(8) NULL
)


CREATE TABLE #seg4
(
	timestamp		timestamp,
	seg_code		varchar(32),
	description		varchar(40),
	short_desc		varchar(40),
	account_type		smallint,
	new_flag		smallint,
	consol_type		smallint,
	consol_detail_flag	smallint
        ,
        rate_type_home          varchar(8) NULL,
        rate_type_oper          varchar(8) NULL
)





SELECT	@acct_defs = MAX(acct_level)
FROM	glaccdef












INSERT INTO #seg1
(
	timestamp,
	seg_code,
	description,
	short_desc,
	account_type,
	new_flag,
	consol_type,
	consol_detail_flag
        ,
        rate_type_home,
        rate_type_oper
)
SELECT 	NULL,
	seg_code,
	description,
	short_desc,
	account_type,
	new_flag,
	consol_type,
	consol_detail_flag
        ,
        rate_type_home,
        rate_type_oper
FROM	glseg1
WHERE	seg_code BETWEEN @seg1_from AND @seg1_thru
AND	@acct_defs >= 1



















INSERT INTO #seg2
(
	timestamp,
	seg_code,
	description,
	short_desc,
	account_type,
	new_flag,
	consol_type,
	consol_detail_flag
        ,
        rate_type_home,
        rate_type_oper
)
SELECT 	NULL,
	seg_code,
	description,
	short_desc,
	account_type,
	new_flag,
	consol_type,
	consol_detail_flag
        ,
        rate_type_home,
        rate_type_oper
FROM	glseg2
WHERE	seg_code BETWEEN @seg2_from AND @seg2_thru
AND	@acct_defs >= 2

INSERT INTO #seg3
(
	timestamp,
	seg_code,
	description,
	short_desc,
	account_type,
	new_flag,
	consol_type,
	consol_detail_flag
        ,
        rate_type_home,
        rate_type_oper
)
SELECT 	NULL,
	seg_code,
	description,
	short_desc,
	account_type,
	new_flag,
	consol_type,
	consol_detail_flag
        ,
        rate_type_home,
        rate_type_oper
FROM	glseg3
WHERE	seg_code BETWEEN @seg3_from AND @seg3_thru
AND	@acct_defs >= 3

INSERT INTO #seg4
(
	timestamp,
	seg_code,
	description,
	short_desc,
	account_type,
	new_flag,
	consol_type,
	consol_detail_flag
        ,
        rate_type_home,
        rate_type_oper
)
SELECT 	NULL,
	seg_code,
	description,
	short_desc,
	account_type,
	new_flag,
	consol_type,
	consol_detail_flag
        ,
        rate_type_home,
        rate_type_oper
FROM	glseg4
WHERE	seg_code BETWEEN @seg4_from AND @seg4_thru
AND	@acct_defs >= 4






SELECT @largest=0, @highcount = 0, @xprod = 1




SELECT @count = COUNT(seg_code) FROM #seg1

IF @count=0
        INSERT #seg1 VALUES ( NULL, "", "", "", 0, 0, 0, 0 ,NULL,NULL )
ELSE 
	SELECT @xprod = @xprod * @count

IF @count > @highcount
	SELECT @highcount = @count, @largest = 1




SELECT @count = COUNT( seg_code) FROM #seg2

IF @count=0
        INSERT #seg2 VALUES ( NULL, "", "", "", 0, 0, 0, 0 ,NULL,NULL)
ELSE 
	SELECT @xprod = @xprod * @count

IF @count > @highcount
	SELECT @highcount = @count, @largest = 2




SELECT @count = COUNT( seg_code) FROM #seg3

IF @count=0
        INSERT #seg3 VALUES ( NULL, "", "", "", 0, 0, 0, 0 ,NULL,NULL)
ELSE 
	SELECT @xprod = @xprod * @count

IF @count > @highcount
	SELECT @highcount = @count, @largest = 3




SELECT @count = COUNT( seg_code) FROM #seg4

IF @count=0
        INSERT #seg4 VALUES ( NULL, "", "", "", 0, 0, 0, 0 ,NULL,NULL)
ELSE 
	SELECT @xprod = @xprod * @count

IF @count > @highcount
	SELECT @highcount = @count, @largest = 4




SELECT @xprod = @xprod/@highcount

IF @xprod > 5000
BEGIN
	SELECT @msg = 'Too many accounts. Use a range on a segment other than "' + description + '"'
	FROM	glaccdef
	WHERE	acct_level = @largest

	SELECT @msg
	RETURN 
END






IF @largest = 1
	EXEC glmkseg1_sp @highcount, @now, @new_flag, @new_accounts OUTPUT
ELSE IF @largest = 2
	EXEC glmkseg2_sp @highcount, @now, @new_flag, @new_accounts OUTPUT
ELSE IF @largest = 3
	EXEC glmkseg3_sp @highcount, @now, @new_flag, @new_accounts OUTPUT
ELSE IF @largest = 4
	EXEC glmkseg4_sp @highcount, @now, @new_flag, @new_accounts OUTPUT




UPDATE	glseg1 
SET 	new_flag = 0
FROM 	glseg1 t1, #seg1 t2
WHERE 	t1.seg_code = t2.seg_code

UPDATE 	glseg2 
SET 	new_flag = 0
FROM 	glseg2 t1, #seg2 t2
WHERE 	t1.seg_code = t2.seg_code

UPDATE 	glseg3 
SET 	new_flag = 0
FROM 	glseg3 t1, #seg3 t2
WHERE 	t1.seg_code = t2.seg_code

UPDATE 	glseg4 
SET 	new_flag = 0
FROM 	glseg4 t1, #seg4 t2
WHERE 	t1.seg_code = t2.seg_code




DECLARE @ib_offset int,		@ib_length int,		@ib_segment int,
		@ib_flag int, 		@branch_segment varchar(32)

SELECT 	@ib_flag  = ib_flag, @ib_offset = ib_offset,	
		@ib_length = ib_length,	@ib_segment = ib_segment
FROM	glco

IF (@ib_flag  = 1 )
BEGIN			
	IF @ib_segment = 1
	BEGIN
		UPDATE #glchart SET organization_id = o.organization_id 
			FROM Organization_all o, #glchart gl
			WHERE gl.account_code = account_code 
			AND o.branch_account_number = SUBSTRING(gl.seg1_code,@ib_offset,@ib_length)
			AND gl.organization_id IS NULL
	END
	ELSE IF @ib_segment = 2
	BEGIN
		UPDATE #glchart SET organization_id = o.organization_id 
			FROM Organization_all o, #glchart gl
			WHERE gl.account_code = account_code 
			AND o.branch_account_number = SUBSTRING(gl.seg2_code,@ib_offset,@ib_length)
			AND gl.organization_id IS NULL
	END
	ELSE IF @ib_segment = 3
	BEGIN
		UPDATE #glchart SET organization_id = o.organization_id 
			FROM Organization_all o, #glchart gl
			WHERE gl.account_code = account_code 
			AND o.branch_account_number = SUBSTRING(gl.seg3_code,@ib_offset,@ib_length)
			AND gl.organization_id IS NULL
	END
	ELSE IF @ib_segment = 4
	BEGIN
		UPDATE #glchart SET organization_id = o.organization_id 
			FROM Organization_all o, #glchart gl
			WHERE gl.account_code = account_code 
			AND o.branch_account_number = SUBSTRING(gl.seg4_code,@ib_offset,@ib_length)
			AND gl.organization_id IS NULL
	END
	
END
IF 	(@ib_flag <> 1  )
BEGIN
	
	UPDATE #glchart SET organization_id = o.organization_id
	FROM	Organization_all o			
	WHERE	o.outline_num = '1'			
END







IF @new_accounts > 0
BEGIN
	EXEC	glupdsem_sp	"gl_coa_changed"

	SELECT 	@msg="Done. " + " " + ltrim(str(@new_accounts)) + " accounts added."
END
ELSE
	SELECT 	@msg = "No accounts added."


SELECT @msg

RETURN

GO
GRANT EXECUTE ON  [dbo].[glmkchrt_sp] TO [public]
GO
