SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

 
CREATE PROCEDURE [dbo].[amNextControlNumber_sp] 
( 
	@company_id				smCompanyID,					
    @control_num_type       int,						
    @control_num            smControlNumber OUTPUT, 	
	@debug_level			smDebugLevel	= 0			
)
AS 
 
DECLARE 
	@next_num       smCounter, 
	@mask           smControlNumber, 
	@message        smErrorLongDesc, 
	@ok             smLogical, 
	@tran_started 	smLogical,
	@error			smErrorCode,
	@rowcount 		smCounter
 
IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "amnxtctl.cpp" + ", line " + STR( 124, 5 ) + " -- ENTRY: " 
 
SELECT 	@ok = 0 
SELECT 	@tran_started = 0 
 
WHILE  @ok = 0 
BEGIN 
 
    

 
    
    
    IF (@@trancount = 0)
    BEGIN 
		SELECT 	@tran_started = 1 
    	BEGIN 	TRANSACTION 
	END 
    
    
    SELECT 	@next_num 		= automatic_next, 
    		@mask 			= num_mask 
    FROM 	amauto WITH(HOLDLOCK)
    WHERE 	automatic_id 	= @control_num_type 

	SELECT	@rowcount = @@rowcount
	
	IF @debug_level >= 5
		SELECT next_num = @next_num

    IF @rowcount = 0 
    BEGIN 
        EXEC 		amGetErrorMessage_sp 20060, "amnxtctl.cpp", 156, "amauto", @error_message = @message OUTPUT 
        IF @message IS NOT NULL RAISERROR 	20060  @message 
        
        IF (@tran_started = 1)
        BEGIN 
			SELECT 		@tran_started = 0 
        	ROLLBACK 	TRANSACTION 
        END 
        RETURN 		20060 
    END 

    
    UPDATE 	amauto 
    SET 	automatic_next 	= automatic_next + 1 
    WHERE 	automatic_id 	= @control_num_type 

    SELECT @error = @@error
    IF @error <> 0
    BEGIN
        IF (@tran_started = 1)
        BEGIN 
			SELECT 		@tran_started = 0 
        	ROLLBACK 	TRANSACTION 
        END 
        RETURN 		@error 
    END
       
    
    IF (@tran_started = 1)
    BEGIN 
		SELECT 	@tran_started = 0 
    	COMMIT 	TRANSACTION 
	END 

    
    EXEC @error = amCreateControlNumber_sp  
		    		@mask, 
		    		@next_num, 
		    		@control_num OUTPUT 

	IF @debug_level >= 5
		SELECT	mask 		= @mask, 
				next_num 	= @next_num, 
				control_num	= @control_num


    IF @error <> 0
        RETURN 		@error 
    
     
    IF @control_num_type = 1
	BEGIN
	    IF NOT EXISTS(SELECT asset_ctrl_num 
	    				FROM 	amasset 
	    				WHERE 	asset_ctrl_num 	= @control_num
	    				AND		company_id		= @company_id)
	        SELECT @ok = 1 
	END
	ELSE   
	BEGIN
	    IF NOT EXISTS(SELECT trx_ctrl_num 
	    				FROM 	amtrxhdr 
	    				WHERE 	trx_ctrl_num 	= @control_num
	    				AND		company_id		= @company_id)
	        SELECT @ok = 1 
	END

	IF @debug_level >= 5
		SELECT  ok = @ok
	


END 
 
IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "amnxtctl.cpp" + ", line " + STR( 230, 5 ) + " -- EXIT: "
 
RETURN 0 
GO
GRANT EXECUTE ON  [dbo].[amNextControlNumber_sp] TO [public]
GO
