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


CREATE PROC [dbo].[ibget_userid_sp]
 
		@userid	integer OUTPUT,
		@username	nvarchar(30) OUTPUT,
		@override_username	nvarchar(30)=''

AS

-- #include "STANDARD DECLARES.INC"





































DECLARE @rowcount		INT
DECLARE @error			INT
DECLARE @errmsg			VARCHAR(128)
DECLARE @log_activity		VARCHAR(128)
DECLARE @procedure_name		VARCHAR(128)
DECLARE @location		VARCHAR(128)
DECLARE @buf			VARCHAR(1000)
DECLARE @ret			INT
DECLARE @text_value		VARCHAR(255)
DECLARE @int_value		INT
DECLARE @return_value		INT
DECLARE @transaction_started	INT
DECLARE @version			VARCHAR(128)
DECLARE @len				INTEGER
DECLARE @i				INTEGER

-- end "STANDARD DECLARES.INC"

DECLARE @bci		INTEGER
DECLARE @fullusername 	VARCHAR(256)


IF len(@override_username)>=0
	SELECT @fullusername = SUSER_SNAME()    
ELSE
	SELECT fullusername = @override_username

SELECT @bci = CHARINDEX('\', @fullusername)
IF @bci > 0 	SELECT @username = SUBSTRING(@fullusername, @bci + 1, LEN(@fullusername) - @bci)

SELECT @username = RTRIM(LEFT(@fullusername, 30))
SELECT @username = RTRIM(@username)
SELECT @userid = 0
SELECT @userid = ISNULL([user_id], 0), @username = RTRIM(LTRIM([domain_username]))
  FROM CVO_Control..[smusers]
 WHERE UPPER(RTRIM(LTRIM([domain_username]))) = UPPER(@username)
IF @userid = 0 
	RETURN -1

RETURN 0

SELECT SUSER_SNAME()   
/**/                                              
GO
GRANT EXECUTE ON  [dbo].[ibget_userid_sp] TO [public]
GO
