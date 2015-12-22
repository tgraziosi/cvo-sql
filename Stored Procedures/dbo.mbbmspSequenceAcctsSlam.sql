SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO
CREATE PROC [dbo].[mbbmspSequenceAcctsSlam] 
	@CompanyCode	mbbmudtCompanyCode,
	@UserID			varchar(30),
	@BudgetCode		varchar(16)

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

	DECLARE @NewSequence int
	DECLARE @Acct varchar(32)

	SELECT  @NewSequence = (SELECT ISNULL(MAX(sequence_id), 0) + 1 FROM glbuddet WHERE budget_code = @BudgetCode)

	DECLARE crsSequence CURSOR FOR
	SELECT  Acct
	FROM    mbbmTmpUpdateGLSumSlam750
	WHERE   SequenceID = 0
	AND CompanyCode = @CompanyCode
	AND UserID = @UserID
	AND Status = 'I'

	OPEN    crsSequence
	FETCH   crsSequence
	INTO    @Acct

	WHILE (@@FETCH_STATUS = 0) BEGIN
		UPDATE mbbmTmpUpdateGLSumSlam750 SET SequenceID = @NewSequence
		WHERE Acct = @Acct
		AND CompanyCode = @CompanyCode
		AND UserID = @UserID
		AND Status = 'I'


		SELECT @NewSequence = @NewSequence + 1
		FETCH   crsSequence
		INTO    @Acct
	END

	CLOSE crsSequence
	DEALLOCATE crsSequence
END
GO
GRANT EXECUTE ON  [dbo].[mbbmspSequenceAcctsSlam] TO [Analytics]
GO
GRANT EXECUTE ON  [dbo].[mbbmspSequenceAcctsSlam] TO [public]
GO
