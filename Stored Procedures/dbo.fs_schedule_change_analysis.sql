SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


--  Copyright (c) 1998 Epicor Software, Inc. All Right Reserved.
CREATE PROCEDURE [dbo].[fs_schedule_change_analysis]
	(
	@option		VARCHAR(36) = NULL
	)

AS
BEGIN























IF @option IS NULL
	SELECT @option='ABCDEFGHIJKLMNOPQ'





CREATE TABLE #rpt_options
	(
	process_code	  CHAR(1),
        process_desc      VARCHAR(80) NULL,
	process_group     VARCHAR(80) NULL
	)








IF CHARINDEX('A',@option) > 0
	INSERT INTO #rpt_options
		 ( process_code, process_desc, process_group )
	VALUES ( 'A', 'Changes to Scenario Properties', 'PROPERTY INFORMATION' )





IF CHARINDEX('B',@option) > 0
	INSERT INTO #rpt_options
		 ( process_code, process_desc, process_group )
	VALUES ( 'B', 'New Products', 'PRODUCT INFORMATION')

IF CHARINDEX('C',@option) > 0
	INSERT INTO #rpt_options
		 ( process_code, process_desc, process_group )
	VALUES ( 'C', 'Missing Products', 'PRODUCT INFORMATION' )





IF CHARINDEX('D',@option) > 0
	INSERT INTO #rpt_options
		 ( process_code, process_desc, process_group )
	VALUES ( 'D', 'New Resources', 'RESOURCE INFORMATION' )

IF CHARINDEX('E',@option) > 0
	INSERT INTO #rpt_options
		 ( process_code, process_desc, process_group )
	VALUES ( 'E', 'Missing Resources', 'RESOURCE INFORMATION' )

IF CHARINDEX('F',@option) > 0
	INSERT INTO #rpt_options
		 ( process_code, process_desc, process_group )
	VALUES ( 'F', 'Resource Calendar Changes', 'RESOURCE INFORMATION' )





IF CHARINDEX('G',@option) > 0
	INSERT INTO #rpt_options
		 ( process_code, process_desc, process_group )
	VALUES ( 'G', 'New Orders', 'ORDER INFORMATION' )

IF CHARINDEX('H',@option) > 0
	INSERT INTO #rpt_options
		 ( process_code, process_desc, process_group )
	VALUES ( 'H', 'Missing Orders', 'ORDER INFORMATION' )

IF CHARINDEX('I',@option) > 0
	INSERT INTO #rpt_options
		 ( process_code, process_desc, process_group )
	VALUES ( 'I', 'Orders Now On-Time', 'ORDER INFORMATION' )

IF CHARINDEX('J',@option) > 0
	INSERT INTO #rpt_options
		 ( process_code, process_desc, process_group )
	VALUES ( 'J', 'Orders Now Late', 'ORDER INFORMATION' )

IF CHARINDEX('K',@option) > 0
	INSERT INTO #rpt_options
		 ( process_code, process_desc, process_group )
	VALUES ( 'K', 'Orders Now Scheduled, Previously Not Scheduled', 'ORDER INFORMATION' )

IF CHARINDEX('L',@option) > 0
	INSERT INTO #rpt_options
		 ( process_code, process_desc, process_group )
	VALUES ( 'L', 'Orders Not Scheduled, Previously Scheduled', 'ORDER INFORMATION' )





IF CHARINDEX('M',@option) > 0
	INSERT INTO #rpt_options
		 ( process_code, process_desc, process_group )
	VALUES ( 'M', 'New Production Orders', 'PRODUCTION INFORMATION' )

IF CHARINDEX('N',@option) > 0
	INSERT INTO #rpt_options
		 ( process_code, process_desc, process_group )
	VALUES ( 'N', 'Missing Production Orders', 'PRODUCTION INFORMATION' )





IF CHARINDEX('O',@option) > 0
	INSERT INTO #rpt_options
		 ( process_code, process_desc, process_group )
	VALUES ( 'O', 'New Planned Purchase Orders', 'PURCHASE ORDER INFORMATION' )

IF CHARINDEX('P',@option) > 0
	INSERT INTO #rpt_options
		 ( process_code, process_desc, process_group )
	VALUES ( 'P', 'Missing Planned Purchase Orders', 'PURCHASE ORDER INFORMATION' )

IF CHARINDEX('Q',@option) > 0
	INSERT INTO #rpt_options
		 ( process_code, process_desc, process_group )
	VALUES ( 'Q', 'Changed Planned Purchase Orders', 'PURCHASE ORDER INFORMATION' )





SELECT process_group,
	 process_code,
       process_desc
  FROM #rpt_options
ORDER BY process_code

RETURN
END
GO
GRANT EXECUTE ON  [dbo].[fs_schedule_change_analysis] TO [public]
GO
