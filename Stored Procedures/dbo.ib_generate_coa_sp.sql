SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

/*                                                      
               Confidential Information                  
    Limited Distribution of Authorized Persons Only       
    Created 2007 and Protected as Unpublished Work       
          Under the U.S. Copyright Act of 1976            
 Copyright (c) 2007 Epicor Software Corporation, 2007    
                  All Rights Reserved                    
*/                                                






















































CREATE PROC [dbo].[ib_generate_coa_sp]
 
		@org_id	varchar(30),
		@debug_level integer	


AS

DECLARE @accounts_to_create 	int,
	@max_level 		smallint,
	@ib_segment		int,
	@natural_seg		smallint,
	@organization_name	varchar(40)			


IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "ib_generate_coa.cpp" + ", line " + STR( 45, 5 ) + " -- ENTRY: "



IF (SELECT ib_flag FROM glco) = 0
	RETURN 0


SELECT	@max_level = MAX(acct_level)
FROM	glaccdef

SELECT  @natural_seg = acct_level
FROM 	glaccdef
WHERE 	natural_acct_flag = 1





SELECT 	@organization_name = LEFT(organization_name,40) 
FROM	Organization
WHERE	organization_id = @org_id

CREATE TABLE #glchart(
	timestamp		timestamp,
	account_code		varchar(32),
	account_description	varchar(40),
	account_type		smallint,
	new_flag		smallint,	
	seg1_code		varchar(32),	
	seg2_code		varchar(32),
	seg3_code		varchar(32),
	seg4_code		varchar(32),
	consol_detail_flag	smallint,	
	consol_type		smallint,
	active_date		int,		
	inactive_date		int,		
	inactive_flag		smallint,	
	currency_code		varchar(8),
        revaluate_flag          smallint,
        rate_type_home          varchar(8) NULL,
        rate_type_oper          varchar(8) NULL,
	seg1_code_org		varchar(32),
	seg2_code_org		varchar(32),
	seg3_code_org		varchar(32),
	seg4_code_org		varchar(32)
)

INSERT INTO #glchart 
(	account_code,
	account_description,
        account_type, 
	new_flag,
	seg1_code,                        
	seg2_code,                        
	seg3_code,                        
	seg4_code,                        
	consol_detail_flag, 
	consol_type, 
	active_date, 
	inactive_date, 
	inactive_flag, 
	currency_code, 
	revaluate_flag, 
	rate_type_home, 
	rate_type_oper,
	seg1_code_org,
	seg2_code_org,
	seg3_code_org,
	seg4_code_org 
)
SELECT 
	CASE  ib_segment 
		WHEN 1 THEN STUFF(seg1_code,ib_offset,ib_length,branch_account_number) + seg2_code + seg3_code + seg4_code
		WHEN 2 THEN seg1_code + STUFF(seg2_code,ib_offset,ib_length,branch_account_number) + seg3_code + seg4_code
		WHEN 3 THEN seg1_code + seg2_code + STUFF(seg3_code,ib_offset,ib_length,branch_account_number) + seg4_code
		WHEN 4 THEN seg1_code + seg2_code + seg3_code + STUFF(seg4_code,ib_offset,ib_length,branch_account_number)
	END ,
	g.account_description,
        g.account_type, 
	g.new_flag,
	CASE  ib_segment WHEN 1  THEN  STUFF(seg1_code,ib_offset,ib_length,branch_account_number)
  		ELSE	
			g.seg1_code 
		END,                        
	CASE  ib_segment WHEN 2  THEN STUFF(seg2_code,ib_offset,ib_length,branch_account_number)
		ELSE	
			g.seg2_code 
		END,                        
	CASE  ib_segment WHEN 3  THEN STUFF(seg3_code,ib_offset,ib_length,branch_account_number)
		ELSE	
			g.seg3_code 
		END,                        
	CASE  ib_segment WHEN 4  THEN STUFF(seg4_code,ib_offset,ib_length,branch_account_number)
		ELSE	
			g.seg4_code 
		END,                       
	g.consol_detail_flag, 
	g.consol_type, 
	g.active_date, 
	g.inactive_date, 
	g.inactive_flag, 
	g.currency_code, 
	g.revaluate_flag, 
	g.rate_type_home, 
	g.rate_type_oper,
	g.seg1_code,
	g.seg2_code,
	g.seg3_code,
	g.seg4_code
 FROM glchart_root_vw g, Organization o, glco
	WHERE	g.account_type != 100					
	AND	o.organization_id = @org_id 

-- select * from #glchart

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "ib_generate_coa.cpp" + ", line " + STR( 161, 5 ) + " -- MSG: " + "Records inserted in #glchart"

UPDATE #glchart
 SET account_description='' 



IF	@max_level >= 1 
	UPDATE 	#glchart 
	SET		account_description = left(isnull(glseg1.short_desc, '') + ' ',40)
	FROM	#glchart , glseg1
	WHERE	glseg1.seg_code = #glchart.seg1_code

IF	@max_level >= 2 
	UPDATE 	#glchart 
	SET		account_description = left(isnull(#glchart.account_description,'')  + isnull(glseg2.short_desc, '') + ' ',40)
	FROM	#glchart , glseg2
	WHERE	glseg2.seg_code = #glchart.seg2_code

IF	@max_level >= 3 
	UPDATE 	#glchart 
	SET		account_description = left(isnull(#glchart.account_description,'')  + isnull(glseg3.short_desc, '') + ' ', 40)
	FROM	#glchart , glseg3
	WHERE	glseg3.seg_code = #glchart.seg3_code

IF	@max_level >= 4
	UPDATE 	#glchart 
	SET		account_description = left(isnull(#glchart.account_description,'')  + isnull(glseg4.short_desc, '') + ' ', 40)
	FROM	#glchart , glseg4
	WHERE	glseg4.seg_code = #glchart.seg4_code

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "ib_generate_coa.cpp" + ", line " + STR( 192, 5 ) + " -- MSG: " + "Records deleted in #glchart"
DELETE #glchart  WHERE  account_code  IN ( 
	SELECT account_code FROM glchart )

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "ib_generate_coa.cpp" + ", line " + STR( 196, 5 ) + " -- MSG: " + "Description + org_id"
UPDATE #glchart
	SET account_description = left (account_description  + @org_id,40 )



INSERT INTO glchart 
 (	account_code,		account_description,	        account_type, 		new_flag,		seg1_code,                        
	seg2_code,		seg3_code,			seg4_code,		consol_detail_flag,	consol_type, 
	active_date,		inactive_date,			inactive_flag,		currency_code,		revaluate_flag, 
	rate_type_home, 	rate_type_oper, organization_id )
SELECT account_code,		account_description,		account_type, 		new_flag,		seg1_code,                        
	seg2_code,		seg3_code,			seg4_code,		consol_detail_flag,	consol_type, 
	active_date,		inactive_date,			inactive_flag,		currency_code,		revaluate_flag, 
	rate_type_home, 	rate_type_oper, @org_id 
FROM #glchart


IF @@error != 0
	RETURN 0

SELECT  @accounts_to_create = COUNT(account_code) 
FROM #glchart 

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "ib_generate_coa.cpp" + ", line " + STR( 220, 5 ) + " -- MSG: " + "Records inserted in glchart"

SELECT @ib_segment = ib_segment FROM glco

IF @ib_segment = 1  
BEGIN
	IF (@natural_seg = 1) 
	BEGIN
		INSERT INTO glseg1 (seg_code,	description ,		short_desc ,	account_type,	new_flag,	consol_type,	consol_detail_flag,	rate_type_home,	rate_type_oper)
		SELECT DISTINCT 	c.seg1_code,	@organization_name,	@org_id,	c.account_type,	c.new_flag,	c.consol_type,	c.consol_detail_flag,	c.rate_type_home,	c.rate_type_oper
		FROM	#glchart c, glseg1 g
		WHERE	c.seg1_code_org = g.seg_code
		AND	seg1_code NOT IN (SELECT seg_code from glseg1)		

	END
	ELSE
	BEGIN
		INSERT INTO glseg1 (seg_code,	description,	short_desc,	account_type,	new_flag,	consol_type,	consol_detail_flag,	rate_type_home,	rate_type_oper)
		SELECT 	DISTINCT   c.seg1_code,	@organization_name,	@org_id,	0,	0,	0,	0,	c.rate_type_home,	c.rate_type_oper
		FROM	#glchart c, glseg1 g
		WHERE	c.seg1_code_org = g.seg_code
		AND	seg1_code NOT IN (SELECT seg_code from glseg1)		
	END

	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "ib_generate_coa.cpp" + ", line " + STR( 244, 5 ) + " -- MSG: " + "Records inserted in glseg1"

END
ELSE IF @ib_segment = 2
BEGIN

	IF (@natural_seg = 2) 
	BEGIN
		INSERT INTO glseg2 (seg_code,	description,	short_desc,	account_type,	new_flag,	consol_type,	consol_detail_flag,	rate_type_home,	rate_type_oper)
		SELECT 	DISTINCT   c.seg2_code,	@organization_name,	@org_id,	c.account_type,	c.new_flag,	c.consol_type,	c.consol_detail_flag,	c.rate_type_home,	c.rate_type_oper
		FROM	#glchart c, glseg2 g
		WHERE	c.seg2_code_org = g.seg_code
		AND	seg2_code NOT IN (SELECT seg_code from glseg2)		
	END
	ELSE
	BEGIN

		INSERT INTO glseg2 (seg_code,	description,	short_desc,	account_type,	new_flag,	consol_type,	consol_detail_flag,	rate_type_home,	rate_type_oper)
		SELECT 	DISTINCT   c.seg2_code,	@organization_name,	@org_id,	0,	0,	0,	0,	c.rate_type_home,	c.rate_type_oper
		FROM	#glchart c, glseg2 g
		WHERE	c.seg2_code_org = g.seg_code
		AND	seg2_code NOT IN (SELECT seg_code from glseg2)		
	
	END

	
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "ib_generate_coa.cpp" + ", line " + STR( 270, 5 ) + " -- MSG: " + "Records inserted in glseg2"

END
ELSE IF @ib_segment = 3
BEGIN

	IF (@natural_seg = 3) 
	BEGIN
		INSERT INTO glseg3 (seg_code,	description,	short_desc,	account_type,	new_flag,	consol_type,	consol_detail_flag,	rate_type_home,	rate_type_oper)
		SELECT	DISTINCT 	c.seg3_code,	@organization_name,	@org_id,	c.account_type,	c.new_flag,	c.consol_type,	c.consol_detail_flag,	c.rate_type_home,	c.rate_type_oper
		FROM	#glchart c, glseg3 g
		WHERE	c.seg3_code_org = g.seg_code
		AND	seg3_code NOT IN (SELECT seg_code from glseg3)			
	END
	ELSE
	BEGIN
		INSERT INTO glseg3 (seg_code,	description,	short_desc,	account_type,	new_flag,	consol_type,	consol_detail_flag,	rate_type_home,	rate_type_oper)
		SELECT	DISTINCT 	c.seg3_code,	@organization_name,	@org_id,	0,	0,	0,	0,	c.rate_type_home,	c.rate_type_oper
		FROM	#glchart c, glseg3 g
		WHERE	c.seg3_code_org = g.seg_code
		AND	seg3_code NOT IN (SELECT seg_code from glseg3)				

	END

	
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "ib_generate_coa.cpp" + ", line " + STR( 295, 5 ) + " -- MSG: " + "Records inserted in glseg3"

END
ELSE IF @ib_segment = 4
BEGIN
	
	IF (@natural_seg = 4) 
	BEGIN
		INSERT INTO glseg4 (seg_code,	description,	short_desc,	account_type,	new_flag,	consol_type,	consol_detail_flag,	rate_type_home,	rate_type_oper)
		SELECT DISTINCT 	c.seg4_code,	@organization_name,	@org_id,	c.account_type,	c.new_flag,	c.consol_type,	c.consol_detail_flag,	c.rate_type_home,	c.rate_type_oper
		FROM	#glchart c, glseg4 g
		WHERE	c.seg4_code_org = g.seg_code
		AND	seg4_code NOT IN (SELECT seg_code from glseg4)	
	END
	ELSE
	BEGIN
		INSERT INTO glseg4 (seg_code,	description,	short_desc,	account_type,	new_flag,	consol_type,	consol_detail_flag,	rate_type_home,	rate_type_oper)
		SELECT DISTINCT 	c.seg4_code,	@organization_name,	@org_id,	0,	0,	0,	0,	c.rate_type_home,	c.rate_type_oper
		FROM	#glchart c, glseg4 g
		WHERE	c.seg4_code_org = g.seg_code
		AND	seg4_code NOT IN (SELECT seg_code from glseg4)	

	END

		
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "ib_generate_coa.cpp" + ", line " + STR( 320, 5 ) + " -- MSG: " + "Records inserted in glseg4"		

END	



RETURN @accounts_to_create


IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "ib_generate_coa.cpp" + ", line " + STR( 329, 5 ) + " -- EXIT: "


GO
GRANT EXECUTE ON  [dbo].[ib_generate_coa_sp] TO [public]
GO
