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

CREATE PROCEDURE [dbo].[gldupcht_sp] 
	@basseg1 	varchar(32),	
	@newseg1 	varchar(32),	
	@basseg2 	varchar(32),	
	@newseg2 	varchar(32),	
	@basseg3 	varchar(32),	
	@newseg3 	varchar(32),
	@basseg4 	varchar(32),	
	@newseg4 	varchar(32)
AS

DECLARE @accounts_generate	int,
	@max_level 		int,
	@ib_flag 		smallint, 
	@ib_segment 		smallint, 
	@ib_offset 		smallint, 
	@ib_length 		smallint, 
	@initial_pos 		smallint



SELECT @ib_flag  = 0, @ib_segment = 0, @ib_offset = 0, @ib_length = 0

SELECT @ib_flag = ib_flag, @ib_segment = ib_segment, @ib_offset = ib_offset, @ib_length = ib_length 
FROM glco

/* FIND THE ACCOUNT LEVELS IN GLCHART */

SELECT	@max_level = MAX(acct_level)
FROM	glaccdef


/*FILL #GLCHART WITH THE BASE SEGMENTS ACCOUNTS*/

INSERT INTO #glchart
SELECT NULL,account_code,account_description,account_type, 
new_flag,seg1_code,seg2_code,seg3_code,seg4_code,consol_detail_flag,consol_type,
active_date,inactive_date,inactive_flag, 
currency_code,revaluate_flag,rate_type_home,rate_type_oper, NULL 
FROM glchart
where seg1_code like @basseg1 and seg2_code like @basseg2 
and   seg3_code like @basseg3 and seg4_code like @basseg4


/*UPDATE THE TABLE WITH THE DUPLICATE SEGMENTS*/

IF (@newseg1 <> '%')
update #glchart set seg1_code = @newseg1
IF (@newseg2 <> '%')
update #glchart set seg2_code = @newseg2
IF (@newseg3 <> '%')
update #glchart set seg3_code = @newseg3
IF (@newseg4 <> '%')
update #glchart set seg4_code = @newseg4

/*UPDATE WITH THE NEW DUPLICATE ACCOUNTS*/

update #glchart set account_code = seg1_code + seg2_code + seg3_code + seg4_code 

IF (@ib_segment = 1 ) 
	SELECT @initial_pos = @ib_offset
ELSE IF (@ib_segment = 2 ) 
	SELECT @initial_pos = MAX(len(seg_code)) + @ib_offset FROM glseg1
ELSE IF (@ib_segment = 3 ) 
	BEGIN
		SELECT @initial_pos = MAX(len(seg_code)) FROM glseg1
		SELECT @initial_pos = @initial_pos + MAX(len(seg_code)) + @ib_offset FROM glseg2
	END
ELSE IF (@ib_segment = 4 ) 
	BEGIN
		SELECT @initial_pos = MAX(len(seg_code)) FROM glseg1
		SELECT @initial_pos = @initial_pos + MAX(len(seg_code)) FROM glseg2
		SELECT @initial_pos = @initial_pos + MAX(len(seg_code)) + @ib_offset FROM glseg3
	END

IF (@ib_flag = 0 )
	BEGIN
		UPDATE #glchart set organization_id = 
		(SELECT organization_id FROM Organization_all WHERE outline_num = '1') 
	END
ELSE
	BEGIN
			update g
  			set g.organization_id = case WHEN (SELECT o.organization_id  
							 FROM Organization_all o  
							 WHERE (substring(g.account_code,@initial_pos, @ib_length ) = RTRIM(o.branch_account_number))) is null
					           THEN (SELECT organization_id FROM Organization_all WHERE outline_num = '1')			
					           ELSE  (select o.organization_id FROM Organization_all o  
                        			         WHERE (substring(g.account_code,@initial_pos, @ib_length ) = RTRIM(o.branch_account_number))) 
					      END					   
			FROM #glchart g
		        
                        
								
	END


/* UPDATE ACCOUNT_DESCRIPTION ACCORD TO SEGMENTS SHORT DESCRIPTION */

IF	@max_level >= 1 
	UPDATE 	#glchart 
	SET		account_description = left(isnull(glseg1.short_desc, '') + ' ',40)
	FROM	#glchart , glseg1
	WHERE	
			glseg1.seg_code = #glchart.seg1_code

IF	@max_level >= 2 
	UPDATE 	#glchart 
	SET		account_description = left(isnull(#glchart.account_description,'')  + isnull(glseg2.short_desc, '') + ' ',40)
	FROM	#glchart , glseg2
	WHERE	
			glseg2.seg_code = #glchart.seg2_code

IF	@max_level >= 3 
	UPDATE 	#glchart 
	SET		account_description = left(isnull(#glchart.account_description,'')  + isnull(glseg3.short_desc, '') + ' ', 40)
	FROM	#glchart , glseg3
	WHERE	
			glseg3.seg_code = #glchart.seg3_code

IF	@max_level >= 4
	UPDATE 	#glchart 
	SET		account_description = left(isnull(#glchart.account_description,'')  + isnull(glseg4.short_desc, '') + ' ', 40)
	FROM	#glchart , glseg4
	WHERE	
			glseg4.seg_code = #glchart.seg4_code

/*
update 	#glchart 
set 	account_description = left(isnull(glseg1.short_desc, '') + isnull(glseg2.short_desc, '') + isnull(glseg3.short_desc, '') + isnull(glseg4.short_desc,''), 40)
from	#glchart , glseg1, glseg2, glseg3, glseg4
where	glseg1.seg_code = @basseg1
and	glseg2.seg_code = @basseg2
and	glseg3.seg_code = @basseg3
and	glseg4.seg_code = @basseg4
*/

/*DELETE THE EXCEPTION ACCOUNTS*/
/* Delete Exception Accounts like the pattern Account_Exceptions Table, each record at the time */

DECLARE @account_pattern varchar (32)

DECLARE Account_Exceptions_Cursor CURSOR FOR
SELECT account_pattern 
FROM glchaexc

OPEN Account_Exceptions_Cursor

FETCH NEXT FROM Account_Exceptions_Cursor
INTO @account_pattern
WHILE @@FETCH_STATUS = 0
BEGIN
	DELETE #glchart 
	where account_code like (@account_pattern)
    	FETCH NEXT FROM Account_Exceptions_Cursor
	INTO @account_pattern
END

CLOSE Account_Exceptions_Cursor
DEALLOCATE Account_Exceptions_Cursor

/*IF ANY OF THE ACCOUNTS TO GENERATE IS ACTIVE AND EXISTS IN GLCHART THEN DON'T CREATE ANY ACCOUNTS*/

if not exists (select * from #glchart b where b.account_code in (select account_code from glchart where inactive_flag = 0))
BEGIN
/*ACTIVE THE ACCOUNTS THAT WHERE INACTIVE AND HAVE TO BE CREATED*/
update glchart 
set inactive_flag = 0
where account_code in (select account_code from #glchart where inactive_flag = 1)
/*DELETE THE INACTIVE ACCOUNTS, BECAUSE THEY ALREADY EXIST IN GLCHART*/
delete #glchart 
where inactive_flag = 1
END
ELSE
BEGIN
delete #glchart
END

/*COUNTS TO BE CREATED*/

SELECT @accounts_generate = (select count(*) from #glchart)

RETURN @accounts_generate

/**/                                              
GO
GRANT EXECUTE ON  [dbo].[gldupcht_sp] TO [public]
GO
