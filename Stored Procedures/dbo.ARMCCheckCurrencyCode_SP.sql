SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/* PVCS Revision or Version:Revision              
I:\vcs\AR\PROCS\armcccc.SPv - e7.2.2 : 1.3
              Confidential Information                  
   Limited Distribution of Authorized Persons Only      
   Created 1996 and Protected as Unpublished Work       
         Under the U.S. Copyright Act of 1976           
Copyright (c) 1996 Epicor Software Corporation, 1996  
                 All Rights Reserved                    
*/                                                










 



					 










































 














































































































































































































































































CREATE PROC [dbo].[ARMCCheckCurrencyCode_SP]
AS

DECLARE
	@def_curr_code varchar(8),
 @table_name varchar(8)

BEGIN
	
	
	SELECT @def_curr_code = home_currency
	 FROM glco
	
	IF ( @@error != 0 )
	BEGIN
	 GOTO FAILED
	END
	
	IF EXISTS ( SELECT def_curr_code
	 FROM arco
 WHERE def_curr_code != @def_curr_code
 )
	BEGIN
	 SELECT @table_name = "arco"
 GOTO FOUND
	END

	IF ( @@error != 0 )
	BEGIN
	 GOTO FAILED
	END
	
	IF EXISTS (	SELECT	nat_cur_code
	 FROM	araccts
 WHERE	nat_cur_code != @def_curr_code
 AND	( LTRIM(nat_cur_code) IS NOT NULL AND LTRIM(nat_cur_code) != " " )
 )
	BEGIN
	 SELECT @table_name = "araccts"
 GOTO FOUND
	END

	IF ( @@error != 0 )
	BEGIN
	 GOTO FAILED
	END
	
	IF EXISTS (	SELECT	nat_cur_code
	 FROM	armaster
 WHERE	nat_cur_code != @def_curr_code
 )
	BEGIN
	 SELECT @table_name = "armaster"
 GOTO FOUND
	END

	IF ( @@error != 0 )
	BEGIN
	 GOTO FAILED
	END
	
	IF EXISTS (	SELECT	nat_cur_code
	 FROM	arcycle
 WHERE	nat_cur_code != @def_curr_code
 AND	RTRIM(nat_cur_code) IS NOT NULL
 )
	BEGIN
	 SELECT @table_name = "arcycle"
 GOTO FOUND
	END

	IF ( @@error != 0 )
	BEGIN
	 GOTO FAILED
	END
	
	
	IF EXISTS (	SELECT	nat_cur_code
	 FROM	arinpchg
 WHERE	nat_cur_code != @def_curr_code
 )
	BEGIN
	 SELECT @table_name = "arinpchg"
 GOTO FOUND
	END

	IF ( @@error != 0 )
	BEGIN
	 GOTO FAILED
	END
	
	IF EXISTS (	SELECT	nat_cur_code
	 FROM	arinppyt
 WHERE	nat_cur_code != @def_curr_code
 )
	BEGIN
	 SELECT @table_name = "arinppyt"
 GOTO FOUND
	END

	IF ( @@error != 0 )
	BEGIN
	 GOTO FAILED
	END
	
	IF EXISTS (	SELECT	nat_cur_code
	 FROM	artrx
 WHERE	nat_cur_code != @def_curr_code
 )
	BEGIN
	 SELECT @table_name = "artrx"
 GOTO FOUND
	END

	IF ( @@error != 0 )
	BEGIN
	 GOTO FAILED
	END

	IF EXISTS (	SELECT nat_cur_code
			FROM	arpymeth
			WHERE	nat_cur_code != @def_curr_code
			AND	RTRIM(nat_cur_code) IS NOT NULL
		 )

	BEGIN
		SELECT @table_name = "arpymeth"
		GOTO FOUND
	END

 SELECT @table_name = "XXX"

FOUND:
	SELECT @table_name

FAILED:
END
GO
GRANT EXECUTE ON  [dbo].[ARMCCheckCurrencyCode_SP] TO [public]
GO
