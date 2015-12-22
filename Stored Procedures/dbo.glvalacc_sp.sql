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




































































































































































































CREATE PROCEDURE [dbo].[glvalacc_sp](
			@spid		smallint,
			@budget_code	varchar	(16),
			@account_code	varchar(32),
			@reference_code	varchar(32),
			@sequence_id 	int
			)			
AS
  DECLARE	@reference_flag	smallint
  DECLARE	@valid		smallint

BEGIN

  SET @valid = 0
  
  
  IF @account_code IS NULL OR LTRIM(@account_code) = ''
  BEGIN
    INSERT INTO #glbudimperr(spid, budget_code, account_code, reference_code, sequence_id, error_code) 
	VALUES(@spid, @budget_code, ISNULL(@account_code, ' '), ISNULL(@reference_code, ' '), @sequence_id, 3501) 
    SELECT @valid
    RETURN @valid
  END
  
  
  IF EXISTS (SELECT 1 FROM #glbuddetimp WHERE budget_code = @budget_code AND account_code = @account_code AND reference_code = ISNULL(@reference_code, ''))
    BEGIN
      INSERT INTO #glbudimperr(spid, budget_code, account_code, reference_code, sequence_id, error_code) 
  	VALUES(@spid, @budget_code, ISNULL(@account_code, ' '), ISNULL(@reference_code, ' '), @sequence_id, 3502) 
      SELECT @valid
      RETURN @valid
  END
  
  
  IF NOT EXISTS(SELECT 'X' FROM glchart where account_code = @account_code)
  BEGIN
    INSERT INTO #glbudimperr(spid, budget_code, account_code, reference_code, sequence_id, error_code) 
	VALUES(@spid, @budget_code, @account_code, ISNULL(@reference_code, ' '), @sequence_id, 2001) 
    SELECT @valid
    RETURN @valid  
  END
  
  
  IF NOT EXISTS (SELECT 'X' FROM glchart where account_code = @account_code and inactive_flag = 0)
  BEGIN
    INSERT INTO #glbudimperr(spid, budget_code, account_code, reference_code, sequence_id, error_code) 
	VALUES(@spid, @budget_code, @account_code, ISNULL(@reference_code, ' '), @sequence_id, 2017) 
    SELECT @valid
    RETURN @valid  
  END  
  
  
  IF @reference_code IS NULL OR LTRIM(@reference_code) = ''
  BEGIN

    
    DECLARE flagsBudImp CURSOR FOR 
	SELECT DISTINCT reference_flag 
	FROM glrefact
	WHERE @account_code like account_mask 
    
    
    SET @valid = 1
    OPEN flagsBudImp
      FETCH NEXT FROM flagsBudImp INTO @reference_flag
      WHILE @@FETCH_STATUS = 0
      BEGIN
        IF @reference_flag = 1 
	BEGIN
	
	
	  SET @valid = 1 
	  CLOSE flagsBudImp
	  DEALLOCATE flagsBudImp
	  SELECT @valid
	  RETURN @valid
	END
	If @reference_flag = 3 
	BEGIN
	  SET @valid = 0
 	END
	FETCH NEXT FROM flagsBudImp INTO @reference_flag
      END
    CLOSE flagsBudImp
    DEALLOCATE flagsBudImp
    IF @valid = 0 
    BEGIN

    
      INSERT INTO #glbudimperr(spid, budget_code, account_code, reference_code, sequence_id, error_code) 
	VALUES(@spid, @budget_code, @account_code, ISNULL(@reference_code, ' '), @sequence_id, 2042) 
    END
    
    
    SELECT @valid
    RETURN @valid 
  END
  ELSE 
  
  
  BEGIN
  
    
    IF NOT EXISTS (SELECT 'X' FROM glref WHERE reference_code = @reference_code)
    BEGIN
      INSERT INTO #glbudimperr(spid, budget_code, account_code, reference_code, sequence_id, error_code) 
	VALUES(@spid, @budget_code, @account_code, @reference_code, @sequence_id, 1031) 
      SELECT @valid
      RETURN @valid
    END
    
    
    IF NOT EXISTS (SELECT 'X' FROM glref_vw WHERE reference_code = @reference_code)
    BEGIN
      INSERT INTO #glbudimperr(spid, budget_code, account_code, reference_code, sequence_id, error_code) 
	VALUES(@spid, @budget_code, @account_code, @reference_code, @sequence_id, 2033) 
      SELECT @valid
      RETURN @valid
    END
    
    
    IF NOT EXISTS (SELECT 'X' 
		   FROM   glref_vw a, glratyp b
		   WHERE  a.reference_type = b.reference_type
		      AND a.reference_code = @reference_code
		      AND @account_code like b.account_mask)
    BEGIN
      INSERT INTO #glbudimperr(spid, budget_code, account_code, reference_code, sequence_id, error_code) 
	VALUES(@spid, @budget_code, @account_code, @reference_code, @sequence_id, 2030) 
      SELECT @valid
      RETURN @valid
    END
    
    
    DECLARE flagsBudImp CURSOR FOR 
	SELECT DISTINCT reference_flag 
	FROM glrefact
	WHERE @account_code like account_mask 
    
    
    OPEN flagsBudImp
      FETCH NEXT FROM flagsBudImp INTO @reference_flag
      WHILE @@FETCH_STATUS = 0
      BEGIN
        IF @reference_flag = 1 
	BEGIN
	  INSERT INTO #glbudimperr(spid, budget_code, account_code, reference_code, sequence_id, error_code) 
	    VALUES(@spid, @budget_code, @account_code, @reference_code, @sequence_id, 2031) 
	  CLOSE flagsBudImp
	  DEALLOCATE flagsBudImp
	  SELECT @valid
	  RETURN @valid
	END
	FETCH NEXT FROM flagsBudImp INTO @reference_flag
      END
    CLOSE flagsBudImp
    DEALLOCATE flagsBudImp
  END
  SET @valid = 1
  SELECT @valid
  RETURN @valid
END
/**/                                              
GO
GRANT EXECUTE ON  [dbo].[glvalacc_sp] TO [public]
GO
