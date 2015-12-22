SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/*                                                      
               Confidential Information                  
    Limited Distribution of Authorized Persons Only       
    Created 2001 and Protected as Unpublished Work       
          Under the U.S. Copyright Act of 1976            
 Copyright (c) 2001 Epicor Software Corporation, 2001    
                  All Rights Reserved                    
*/   


CREATE PROCEDURE [dbo].[IntegrateOS] (@InputXml TEXT)
AS

SELECT '$FIN_RESULTS$'
SELECT '<Description>Those are the error results</Description>'
SELECT '<ErrorList>' 

CREATE TABLE #TEMPOrder
	(
	guid VARCHAR(50),
	order_number VARCHAR(50),
	approved INTEGER,
	transmitted INTEGER,
	transmit_date INTEGER
	)

CREATE UNIQUE INDEX hist_index1
ON #TEMPOrder (guid)

 
DECLARE @iError NUMERIC
DECLARE @hDoc INTEGER

DECLARE @TEMPorder_number VARCHAR(50)
DECLARE @TEMPROCorder_number VARCHAR(50)
DECLARE @TEMPapproved INTEGER
DECLARE @TEMPtransmitted INTEGER
DECLARE @TEMPtransmit_date DATETIME

SET @iError = 0 

EXEC @iError = sp_xml_preparedocument @hDoc OUTPUT, @InputXml

IF @iError <> 0 
BEGIN
	SELECT '<ErrorCode>' + CAST(@iError AS VARCHAR(10)) + '</ErrorCode>'
	SELECT '<ErrorInfo>Error trying to initialize the xml document</ErrorInfo>'
	
	GOTO EndProcedure
END

INSERT INTO #TEMPOrder 
	SELECT 	NEWID(),
			[order_number],
			[approved],
			[transmitted],
			[transmit_date]
	FROM OPENXML (@hDoc, '/Procurement.UpdateOrderStatusDoc/PurchaseOrder', 2)
	WITH #TEMPOrder

SELECT @TEMPorder_number = order_number,
		@TEMPapproved = approved,
		@TEMPtransmitted = transmitted,
		@TEMPtransmit_date = (SELECT dateadd(day, transmit_date - 693596,'01/01/1900'))
FROM #TEMPOrder

SET @TEMPROCorder_number = SUBSTRING(@TEMPorder_number,CHARINDEX(';',@TEMPorder_number) + 1,LEN(@TEMPorder_number))
SET @TEMPorder_number = SUBSTRING(@TEMPorder_number,1,CHARINDEX(';',@TEMPorder_number) - 1 )
IF (LEN(@TEMPorder_number) <> 0)
BEGIN
	EXEC adm_ep_upd_po @po_no = @TEMPorder_number, 
						@approval_ind = @TEMPapproved, 
						@transmit_ind = @TEMPtransmitted, 
						@transmit_date = @TEMPtransmit_date,
						@proc_po_no = @TEMPROCorder_number
						
END
ELSE
BEGIN
	SELECT '<ErrorCode>' + CAST(@iError AS VARCHAR(10)) + '</ErrorCode>'
	SELECT '<ErrorInfo>The order number to update can not be empty</ErrorInfo>'
END

EndProcedure:

SELECT '</ErrorList>'

GO
GRANT EXECUTE ON  [dbo].[IntegrateOS] TO [public]
GO
