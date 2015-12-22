SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO
CREATE PROC [dbo].[mbbmspValidateAcctFull]
	@CompanyCode	        mbbmudtCompanyCode,
	@Acct 			mbbmudtAccountCode,
        @ExclInact              mbbmudtYesNo,
        @BalTypeFilter          smallint,
        @Extended               smallint,
	@Found                  smallint OUTPUT,
        @Description            varchar(255) OUTPUT
WITH ENCRYPTION
AS
BEGIN
/************************************************************************************
* Copyright 2008 Sage Software, Inc. All rights reserved.                           *
* This procedure, trigger or view is the intellectual property of Sage Software,    *
* Inc.  You may not reverse engineer, alter, or redistribute this code without the  *
* express written permission of Sage Software, Inc.  This code, or any portions of  *
* it, may not be used for any other purpose except for the use of the application   *
* software that it was shipped with.  This code falls under the licensing agreement *
* shipped with the software.  See your license agreement for further information.   *
************************************************************************************/

	SELECT @Found = 0
	SELECT @Description = ''

	SELECT	@Found = 1,
		@Description = account_description
	FROM 	glchart c, glco
	WHERE  	company_code = @CompanyCode AND
		account_code = @Acct AND
		((@ExclInact = 1 AND inactive_flag = 0) or 
		@ExclInact = 0)

/* NOTE: Other integrations need to implement this clause                             * 
 *                                                                                    *
 * AND (((@BalTypeFilter & 1) > 0 AND (is an actual account, return 1, else 0) > 0) OR *
 *     ((@BalTypeFilter & 2) > 0 AND (is a budget account, return 1, else 0)  > 0) OR *
 *     ((@BalTypeFilter & 4) > 0 and (is a budget account, return 1, else 0)  > 0))    *
 *        								              */

	IF @Extended = 1 BEGIN
		SELECT  BalType = 7,
/* NOTE: Other integrations need to implement this clause                             * 
 *                                                                                    *
 * BalType = (is an actual account, return 1, else 0) +                               *
 *           (is a budget account, return 1, else 0) * 2 +                            * 
 *           (is a statistical account, return 1, else 0) * 4                         *
 *        								              */
			Active = (1 - inactive_flag),
                	CreditBal	= isnull((SELECT 1 WHERE c.account_type >= 200 AND c.account_type <= 449 OR c.account_type = 600),0),
			ActiveDate      = active_date,
		        InactiveDate    = inactive_date
		FROM	glchart c, glco
        	WHERE   company_code = @CompanyCode AND
	                account_code = @Acct AND
			((@ExclInact = 1 AND inactive_flag = 0) or 
                	 @ExclInact = 0) 

/* NOTE: Other integrations need to implement this clause                             * 
 *                                                                                    *
 * AND (((@BalTypeFilter & 1) > 0 AND (is an actual account, return 1, else 0) > 0) OR *
 *     ((@BalTypeFilter & 2) > 0 AND (is a budget account, return 1, else 0)  > 0) OR *
 *     ((@BalTypeFilter & 4) > 0 and (is a budget account, return 1, else 0)  > 0))    *
 *        								              */

	END
END
GO
GRANT EXECUTE ON  [dbo].[mbbmspValidateAcctFull] TO [Analytics]
GO
GRANT EXECUTE ON  [dbo].[mbbmspValidateAcctFull] TO [public]
GO
