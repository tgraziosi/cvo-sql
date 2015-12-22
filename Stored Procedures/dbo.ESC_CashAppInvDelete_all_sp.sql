SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[ESC_CashAppInvDelete_all_sp]	@ParRecID varchar(40), 
													@ApplyManual smallint     
AS      
BEGIN      
	-- Rev 3 BNM 8/23/2012 updated to resolve issue 781, Manual cash application, add ApplyManual parameter 
	-- v1.0 CB 19/12/2013 - Issue #1430 - Unapply All 12-16-13   
      
	-- Insert the Audit record.      
	INSERT INTO ESC_CashAppAudit      
	SELECT GETDATE(), '', @ParRecID, 'ESC_CashAppInvDelete_All_sp', 10, 'Remove Transaction Details', @ParRecID, ''
           
    DELETE	ESC_CashAppInvDet      
	WHERE	ParentRecID = @ParRecID
           
	IF (@ApplyManual = 1)  -- 08/23/2012 BNM - resolve issue 781, Manual cash application, remove manual credits when checkbox cleared    
		DELETE #ManualCredits 
		WHERE  ParentRecID = @ParRecID     
    
	EXEC ESC_UpdateTotals_sp @ParRecID    
END
GO
GRANT EXECUTE ON  [dbo].[ESC_CashAppInvDelete_all_sp] TO [public]
GO
